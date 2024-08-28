#!/usr/bin/env python3

import json
import os
import re
import sys

import yaml
import http
import docker
import shutil
import logging
import requests
import argparse
import subprocess

from pathlib import Path

"""
This script packages CSAR archives.

It expects the CSAR files to be organized in the following way:

csar-root-directory/
    |--- csar-chart-1/
    |--- csar-chart-2/
    |--- values/              <------ values files directory for corresponding helm charts (optional)
    |--- imports/             <------ directory with import files (optional) 
    csar-vnfd.yaml            <------ VNF descriptor for the CSAR
    csar-manifest.mf          <------ manifest file for the CSAR (must have the same name as vnfd)
"""

LOG = logging.getLogger(__name__)
logging.basicConfig(format="[%(asctime)s] [%(levelname)s]: %(message)s", level=logging.INFO)

_nexus_host = 'https://arm1s11-eiffel052.eiffel.gic.ericsson.se:8443'
_jfrog_host = 'https://arm.epk.ericsson.se'
_global_docker_registry = 'armdocker.rnd.ericsson.se'
_package_manager_image = f'{_global_docker_registry}/proj-am/releases/eric-am-package-manager'
_package_manager_image_repository = 'proj-am-docker-global'
_package_manager_image_path = 'proj-am/releases/eric-am-package-manager'

_build_command_name = 'build'
_upload_command_name = 'upload'

_repositories_file = 'scripts/repositories.yaml'
_imports_directory = 'imports'
_licenses_directory = 'licenses'
_values_directory = 'values'
_charts_directory = 'charts'
_changelog_directory = 'changelogs'
_certificates_directory = 'certificates'
_common_manifest = "manifest.mf"
_working_directory_path = os.getcwd()
_config_json_path = f'{_working_directory_path}/config.json'
_change_log_name = 'ChangeLog.txt'
_dev_suffix = '-DEV'


class Context:
    def __init__(self, csar, build_configuration, build_parameters, jfrog_api, nexus_api):
        self.csar = csar
        self.build_configuration = build_configuration
        self.build_parameters = build_parameters
        self.jfrog_api = jfrog_api
        self.nexus_api = nexus_api


class BuildParameters:
    def __init__(self, build_configuration, cmd_arguments, jfrog_api):
        self.pm_version = self.__get_pm_version(cmd_arguments, jfrog_api)
        self.pm_image = self.__get_pm_image()
        self.no_images = cmd_arguments.no_images
        self.helm3 = build_configuration.is_helm3
        self.is_option1 = build_configuration.is_option1
        self.is_option2 = build_configuration.is_option2
        self.option1_configuration = build_configuration.option1
        self.option2_configuration = build_configuration.option2
        self.helmfile_directory = self.__get_helmfile_directory(cmd_arguments)
        self.cnf_values_directory = self.__get_cnf_values_directory(cmd_arguments, build_configuration)
        self.license = build_configuration.license
        self.sol_version = build_configuration.sol_version

    def __get_pm_image(self):
        pm_image = f'{_package_manager_image}:{self.pm_version}'
        if BuildParameters.__image_is_present_locally(pm_image):
            LOG.info(f'Package manager image {pm_image} has already been downloaded')
        else:
            BuildParameters.__pull_package_manager_image(pm_image)

        return pm_image

    @staticmethod
    def __get_pm_version(cmd_arguments, jfrog_api):
        if cmd_arguments.pm_version is None:
            return BuildParameters.__get_latest_pm_version(jfrog_api)
        return cmd_arguments.pm_version

    @staticmethod
    def __get_helmfile_directory(cmd_arguments):
        if cmd_arguments.helmfile_directory is not None:
            result = os.path.join(cmd_arguments.csar_directory, cmd_arguments.helmfile_directory)
            BuildParameters.__validate_path(result)
            return result

    @staticmethod
    def __get_cnf_values_directory(cmd_arguments, build_configuration):
        if build_configuration.include_additional_values:
            path = os.path.join(cmd_arguments.csar_directory, _values_directory)
            BuildParameters.__validate_values_directory(path)
            return _values_directory
        else:
            return None

    @staticmethod
    def __get_latest_pm_version(jfrog_api):
        jfrog_response = jfrog_api.get_latest_image(_package_manager_image_repository, _package_manager_image_path)

        if jfrog_response.status_code == http.HTTPStatus.OK:
            LOG.info(f'Response from JFrog: {jfrog_response.text}')
            return BuildParameters.__get_image_version_from_response(jfrog_response)
        else:
            LOG.error(f'Received error while searching for latest package manager image: '
                      f'{jfrog_response.text}, code: {jfrog_response.status_code}')
            raise Exception(f'Could not retrieve information about latest package manager image from {_jfrog_host}')

    @staticmethod
    def __get_image_version_from_response(jfrog_response):
        response_json = json.loads(jfrog_response.text)
        response_results = response_json['results']
        response_results_length = len(response_results)
        if not response_results_length == 1:
            raise Exception(f'Length of response from JFrog must be 1, but was {response_results_length}')
        image_path = response_results[0]['path']
        version_start = image_path.rfind('/') + 1
        latest_pm_version = image_path[version_start:]

        LOG.info(f'Latest package manager version is {latest_pm_version}')
        return latest_pm_version

    @staticmethod
    def __image_is_present_locally(image_tag):
        for image in docker.from_env().images.list():
            if image_tag in image.tags:
                return True
        return False

    @staticmethod
    def __pull_package_manager_image(pm_image):
        LOG.info(f"Pulling package manager image {pm_image}")
        run_cmd(f'docker pull {pm_image}')

    @staticmethod
    def __validate_path(directory):
        if directory:
            if not os.path.exists(directory):
                exit_and_fail(f"Path {directory} does not exists")

    @staticmethod
    def __validate_values_directory(directory):
        BuildParameters.__validate_path(directory)

        files = os.listdir(directory)

        if not files:
            exit_and_fail(f"Directory '{directory}' is empty")

        for file in files:
            if not file.endswith('.yaml'):
                exit_and_fail(f"File {file} has wrong extension (not yaml)")


class SignatureConfiguration:
    def __init__(self, key, certificate):
        self.key = key
        self.certificate = certificate


class BuildConfiguration:
    def __init__(self, build_configuration, general_conf):
        self.__load_from_yaml(build_configuration, general_conf)

    @property
    def is_option1(self):
        return self.option1 is not None

    @property
    def is_option2(self):
        return self.option2 is not None

    @property
    def is_helm3(self):
        return True

    def __load_from_yaml(self, build_configuration, general_conf):
        self.classifier = build_configuration['classifier']
        self.name = general_conf['name']
        self.license = general_conf['license']
        self.sol_version = general_conf['sol_version']
        self.groupId = general_conf['groupid']

        if 'signatures' in build_configuration.keys():
            self.__load_signatures(build_configuration['signatures'])
        else:
            self.option1 = None
            self.option2 = None

        self.include_additional_values = False
        if 'include_additional_values' in general_conf.keys():
            self.include_additional_values = general_conf['include_additional_values']

    def __load_signatures(self, signatures_yaml):
        if 'option1' in signatures_yaml:
            key = signatures_yaml['option1']['key']
            certificate = signatures_yaml['option1']['certificate']
            self.option1 = SignatureConfiguration(key, certificate)
        else:
            self.option1 = None

        if 'option2' in signatures_yaml:
            key = signatures_yaml['option2']['key']
            certificate = signatures_yaml['option2']['certificate']
            self.option2 = SignatureConfiguration(key, certificate)
        else:
            self.option2 = None


class CsarProperties:
    def __init__(self, cmd_arguments):
        self.__infer_data_from_vnfd_path(cmd_arguments.vnfd_path)
        self.__load_from_path(get_csar_properties_path(cmd_arguments.csar_directory))

    def __get_groupid(self, groupid):
        return f'{groupid}.{Path(self.name).stem}'

    def __infer_data_from_vnfd_path(self, vnfd_path):
        self.name = Path(vnfd_path).name

    def __populate_general_conf(self, properties):
        general_conf = {}
        general_conf['include_additional_values'] = properties['include_additional_values']
        general_conf['license'] = properties['license']
        general_conf['sol_version'] = properties['sol_version']
        general_conf['groupid'] = self.__get_groupid(properties['groupid'])
        general_conf['name'] = self.name
        return general_conf

    def __load_from_path(self, properties_path):
        with open(properties_path) as read_stream:
            properties = yaml.safe_load(read_stream)
            general_conf = self.__populate_general_conf(properties)
            self.build_configurations = []
            for build_conf in properties['buildConfigurations']:
                self.build_configurations.append(BuildConfiguration(build_conf, general_conf))


class Csar:
    def __init__(self, build_configuration, cmd_arguments):
        self.csar_directory = cmd_arguments.csar_directory
        self.build_charts = cmd_arguments.build_charts
        self.vnfd = Vnfd(cmd_arguments.vnfd_path)
        self.manifest = self.__search_manifest()
        self.artifact_name = self.__build_artifact_name(build_configuration)
        self.csar_name = self.__build_csar_name(cmd_arguments, build_configuration)
        self.csar_file_name = self.__get_csar_file_name(build_configuration)
        self.change_log = self.__search_changelog()
        self.licenses = os.path.join(self.vnfd.path, _licenses_directory)

    @property
    def csar_path(self):
        return os.path.join(self.csar_directory, self.csar_file_name)

    def __validate_manifest(self, manifest):
        if '.mf' not in manifest:
            exit_and_fail(f'Manifest file {manifest} must have .mf extension')
        if not os.path.exists(os.path.join(self.csar_directory, manifest)):
            exit_and_fail(f'Provided manifest file {manifest} does not exist in {self.csar_directory}')

    def __search_manifest(self):
        manifest_options = [file for file in os.listdir(self.csar_directory)
                            if os.path.isfile(os.path.join(self.csar_directory, file)) and file == _common_manifest]
        if len(manifest_options) == 0:
            raise Exception(f'Could not find manifest file in {self.csar_directory}')
        elif len(manifest_options) > 1:
            raise Exception(f'Found multiple manifest files in {self.csar_directory}: {manifest_options},'
                            f' please select 1 to build a csar')

        manifest_name = self.vnfd.stem + ".mf"
        shutil.copy(os.path.join(self.csar_directory, manifest_options[0]),
                    os.path.join(self.csar_directory, manifest_name))

        return manifest_name

    def __list_changelogs(self, changelogs_path):
        return [file for file in os.listdir(changelogs_path)
                if os.path.isfile(os.path.join(changelogs_path, file))
                and file.startswith(f"ChangeLog.{self.vnfd.stem}.txt")]

    def __search_changelog(self):
        changelogs_path = os.path.join(self.csar_directory, _changelog_directory)
        changelog_files = self.__list_changelogs(changelogs_path)

        if not changelog_files:
            raise Exception(
                f'Could not find ChangeLog.{self.vnfd.stem}.txt for vnfd {self.vnfd.name} in {changelogs_path}')

        shutil.copy(os.path.join(changelogs_path, changelog_files[0]),
                    os.path.join(changelogs_path, _change_log_name))
        return os.path.join(_changelog_directory, _change_log_name)

    def __build_artifact_name(self, build_configuration):
        csar_name = self.vnfd.stem
        if build_configuration.classifier is not None:
            csar_name = f'{csar_name}-{build_configuration.classifier}'
        if build_configuration.is_option1:
            csar_name = f'{csar_name}-option1'
        if build_configuration.is_option2:
            csar_name = f'{csar_name}-option2'
        return csar_name

    def __build_csar_name(self, cmd_arguments, build_configuration):
        csar_name = f'{self.artifact_name}-{self.vnfd.descriptor_version}'
        if build_configuration.classifier is not None:
            csar_name = f'{csar_name}-{build_configuration.classifier}'
        if cmd_arguments.no_images:
            csar_name = f'{csar_name}-imageless'
        if cmd_arguments.build_charts:
            csar_name = f'{csar_name}{_dev_suffix}'
        return csar_name

    def __get_csar_file_name(self, build_configuration):
        if build_configuration.is_option2:
            csar_extension = 'zip'
        else:
            csar_extension = 'csar'
        return f'{self.csar_name}.{csar_extension}'

    @staticmethod
    def __get_vnfd_name(manifest):
        return f'{manifest[0:-2]}yaml'


class Repository:
    def __init__(self, name, url):
        self.name = name
        self.url = url


class Artefact:
    def __init__(self, name, description, artefact_type, path, artefact_file_name):
        self.name = name
        self.description = description
        self.type = artefact_type
        self.path = path
        self.artefact_file_name = artefact_file_name


class Chart(Artefact):
    def __init__(self, name, description, artefact_type, path, artefact_file_name, chart_name, chart_version):
        super().__init__(name, description, artefact_type, path, artefact_file_name)
        self.chart_name = chart_name
        self.chart_version = chart_version


class Artefacts:
    def __init__(self, charts, software_images, scaling_mapping):
        self.charts = charts
        self.software_images = software_images
        self.scaling_mapping = scaling_mapping


class Vnfd:
    def __init__(self, vnfd_path):
        self.path = Path(vnfd_path)
        self.name = Path(vnfd_path).name
        self.stem = Path(vnfd_path).stem
        self.__load_from_path(vnfd_path)

    @staticmethod
    def is_url(string):
        return string.startswith('http')

    @staticmethod
    def get_import_path(import_name):
        import_path = os.path.join(_imports_directory, import_name)
        if not os.path.exists(import_path):
            raise Exception(f'Could not find {import_name} in {_imports_directory} directory')
        return import_path

    def __load_from_path(self, vnfd_path):
        self.__validate_vnfd_path(vnfd_path)
        with open(vnfd_path) as vnfd_read_stream:
            vnfd = yaml.safe_load(vnfd_read_stream)
            self.__load_from_yaml(vnfd)

    def __load_from_yaml(self, vnfd):
        node_type = self.__get_node_type(vnfd)

        artefacts_section = node_type['artifacts']

        self.descriptor_version = node_type['properties']['descriptor_version']['default']
        self.artefacts = self.__parse_artefacts(artefacts_section)
        self.imports = self.__parse_imports(vnfd)

    def __parse_artefacts(self, artefacts_section):
        charts = []
        scaling_mapping = None
        software_images = None
        for artefact_name, artefact_definition in artefacts_section.items():
            artefact = self.__parse_artefact(artefact_name, artefact_definition)
            if artefact_name == 'software_images':
                software_images = artefact
            elif artefact_name == 'scaling_mapping':
                scaling_mapping = artefact
            else:
                charts.append(artefact)
        return Artefacts(charts, software_images, scaling_mapping)

    def __parse_artefact(self, artefact_name, artefact_definition):
        description = artefact_definition['description']
        artefact_type = artefact_definition['type']
        artefact_path = artefact_definition['file']
        artefact_file_name = self.__parse_artefact_path(artefact_path)
        if artefact_name == 'software_images' or artefact_name == 'scaling_mapping':
            return Artefact(artefact_name, description, artefact_type, artefact_path, artefact_file_name)
        else:
            chart_name, chart_version = self.__parse_chart_file_name(artefact_file_name)
            return Chart(artefact_name, description, artefact_type, artefact_path,
                         artefact_file_name, chart_name, chart_version)

    def __parse_imports(self, vnfd):
        result = self.__get_imports_from_definitions(vnfd)
        import_index = 0
        while import_index < len(result):
            current_import = result[import_index]
            import_index += 1
            if not self.is_url(current_import):
                with open(self.get_import_path(current_import)) as read_stream:
                    import_yaml = yaml.safe_load(read_stream)
                    result.extend(self.__get_imports_from_definitions(import_yaml))

        return result

    @staticmethod
    def __parse_artefact_path(path):
        return path.split('/')[-1]

    @staticmethod
    def __parse_chart_file_name(chart_file_name):
        chart_file_name_without_extension = chart_file_name[:-4]
        first_digit = re.search(r'\d', chart_file_name)
        first_digit_index = first_digit.start()
        return chart_file_name_without_extension[:first_digit_index - 1], \
               chart_file_name_without_extension[first_digit_index:]

    @staticmethod
    def __get_node_type(vnfd):
        for _, node_type in vnfd['node_types'].items():
            return node_type

    @staticmethod
    def __validate_vnfd_path(vnfd_path):
        if not os.path.exists(vnfd_path):
            exit_and_fail(f'Expected {vnfd_path} to contain vnfd for the csar')

    @staticmethod
    def __get_imports_from_definitions(definitions_yaml):
        if 'imports' in definitions_yaml:
            return definitions_yaml['imports']
        return []


class NexusArtifact:
    def __init__(self, context):
        self.repository = 'evnfm_testing_artifacts'
        self.groupId = context.build_configuration.groupId
        self.artifactId = context.csar.artifact_name
        self.version = context.csar.vnfd.descriptor_version
        if context.build_configuration.is_option2:
            self.packaging = 'zip'
        else:
            self.packaging = 'csar'

        if context.build_configuration.classifier is not None and context.build_parameters.no_images:
            self.classifier = f'{context.build_configuration.classifier}-imageless'
        elif context.build_configuration.classifier is not None:
            self.classifier = context.build_configuration.classifier
        elif context.build_parameters.no_images:
            self.classifier = f'imageless'
        else:
            self.classifier = None

    def to_dict(self):
        parameters = {
            'r': self.repository,
            'g': self.groupId,
            'a': self.artifactId,
            'v': self.version,
            'p': self.packaging
        }
        if self.classifier is not None:
            parameters['c'] = self.classifier

        return parameters


class Credentials:
    def __init__(self, login, password):
        self.login = login
        self.password = password


class NexusApi:
    def __init__(self, host, credentials):
        self.host = host
        self.credentials = credentials

    def get_nexus_artifact(self, nexus_artifact):
        return requests.get(f'{self.host}/nexus/service/local/artifact/maven/content', params=nexus_artifact.to_dict())

    def upload_nexus_artifact(self, nexus_artifact, artifact_path):
        parameters = nexus_artifact.to_dict()
        files = {'file': open(artifact_path, 'rb')}
        return requests.post(
            f'{self.host}/nexus/service/local/artifact/maven/content',
            data=parameters, files=files,
            auth=(self.credentials.login, self.credentials.password))


class JFrogApi:
    def __init__(self, host, credentials):
        self.host = host
        self.credentials = credentials

    def get_latest_image(self, image_repository, image_path):
        headers = {
            'content-type': 'text/plain'
        }
        search_query = f'items.find({{"repo":{{"$eq":"{image_repository}"}},' \
                       f'"path":{{"$match":"{image_path}/*"}}}}).sort({{"$desc": ["created"]}}).limit(1)'
        return requests.post(f'{self.host}/artifactory/api/search/aql',
                             headers=headers, data=search_query,
                             auth=(self.credentials.login, self.credentials.password))


def exit_and_fail(error_message):
    """This function logs the given error message, and then exits with a 1 exit code."""
    if error_message:
        LOG.error(error_message)
    sys.exit(1)


def run_cmd(cmd, working_directory='./'):
    """This function runs the given command in the given working directory"""
    LOG.info("Execute: " + cmd)

    try:
        output = subprocess.check_output(cmd, cwd=working_directory, shell=True)

        LOG.info("--OUT--")
        LOG.info(output.decode('utf-8'))
        LOG.info("--END--")

        return output.decode('utf-8')
    except subprocess.CalledProcessError as error:
        exit_and_fail("Command execution failed: %s. Output: %s" % (cmd, error.output))


def remove_file(path):
    if os.path.exists(path):
        os.remove(path)


def clean_existing_archives(csar_directory):
    LOG.info(f'Removing all existing archives in {csar_directory}')
    tgz_archives = [file.path for file in os.scandir(csar_directory) if file.is_file() and '.tgz' in file.name]
    if len(tgz_archives) == 0:
        LOG.info(f'No archives found in {csar_directory}')
    else:
        archives_list_str = ','.join(tgz_archives)
        LOG.info(f'Archives to be deleted: {archives_list_str}')
        for tgz_archive in tgz_archives:
            remove_file(tgz_archive)


def get_charts_list(charts):
    csar_chart_directories = []
    for chart in charts:
        if 'helm_package' in chart.name:
            chart_path = os.path.join(_working_directory_path, _charts_directory, chart.chart_name, chart.chart_version)
            if os.path.exists(chart_path):
                csar_chart_directories.append(chart_path)
            else:
                LOG.info(f'Chart with path {chart_path} does not exist')
    return csar_chart_directories


def package_charts(csar_directory, charts, helmfile_directory):
    csar_chart_directories = get_charts_list(charts)
    if helmfile_directory:
        csar_chart_directories.remove(os.path.basename(helmfile_directory))
        helmfile_directory_path = os.path.join(_working_directory_path, helmfile_directory)
        LOG.info(f'Packaging helmfile from directory: {helmfile_directory_path}')
        run_cmd(f'tar -cvf {helmfile_directory_path}.tgz .', working_directory=helmfile_directory_path)

    for csar_chart_directory in csar_chart_directories:
        LOG.info(f'Packaging chart in {csar_chart_directory}')
        run_cmd(f'helm package {csar_chart_directory}', working_directory=csar_directory)

    chart_archive_paths = [file.name for file in os.scandir(csar_directory) if file.is_file() and '.tgz' in file.name]
    chart_archives_string = ', '.join(chart_archive_paths)
    LOG.info(f'Packaged charts : {chart_archives_string}')


def download_chart(csar_directory, chart, repositories):
    if chart.chart_name in repositories:
        LOG.info(f'Downloading chart {chart.artefact_file_name}')
        run_cmd(f'wget -nvc {repositories[chart.chart_name].url}/{chart.artefact_file_name}', csar_directory)
    else:
        LOG.info(f'No matching repository found for chart {chart.artefact_file_name}')


def download_charts(csar_directory, charts, download_all, repositories):
    for chart in charts:
        if download_all:
            download_chart(csar_directory, chart, repositories)
        else:
            if os.path.exists(os.path.join(csar_directory, chart.artefact_file_name)):
                LOG.info(f'Chart {chart.artefact_file_name} is already present in {csar_directory} path')
            else:
                download_chart(csar_directory, chart, repositories)


def validate_all_charts_present(csar_directory, charts):
    for chart in charts:
        chart_path = os.path.join(csar_directory, chart.artefact_file_name)
        if not os.path.exists(chart_path):
            raise Exception(f'Chart {chart.artefact_file_name} not found in {csar_directory}')


def prepare_charts(csar, build_parameters):
    if csar.build_charts:
        package_charts(csar.csar_directory, csar.vnfd.artefacts.charts, build_parameters.helmfile_directory)

    download_charts(csar.csar_directory, csar.vnfd.artefacts.charts, csar.build_charts, load_repositories())
    validate_all_charts_present(csar.csar_directory, csar.vnfd.artefacts.charts)


def prepare_imports(csar):
    imports_directory_path = os.path.join(csar.csar_directory, 'imports')
    for an_import in csar.vnfd.imports:
        if Vnfd.is_url(an_import):
            LOG.info(f'Do not copy {an_import} to the imports directory, because it is an url')
        else:
            LOG.info(f'Copy {an_import} to the imports directory, because it is an url')
            import_source_path = Vnfd.get_import_path(an_import)
            import_target_path = os.path.join(imports_directory_path, an_import)
            shutil.copyfile(import_source_path, import_target_path)


def prepare_licenses(csar, build_parameters):
    try:
        csar_directory_path = os.path.join(csar.csar_directory, _licenses_directory)
        license_file_path = os.path.join(os.path.abspath(_licenses_directory), build_parameters.license)
        shutil.copy2(license_file_path, csar_directory_path)
    except Exception as e:
        LOG.error(f"Cannot copy license file {build_parameters.license} to CSAR directory: {e}")


def configure_additional_values_version(csar):
    for chart in csar.vnfd.artefacts.charts:
        additional_values_name = "{}.yaml".format(chart.chart_name)
        additional_values = os.path.join(csar.csar_directory, _values_directory, additional_values_name)

        if os.path.exists(additional_values):
            versioned_values_name = "{}-{}.yaml".format(chart.chart_name, chart.chart_version)
            versioned_additional_values = os.path.join(csar.csar_directory, _values_directory, versioned_values_name)
            os.rename(additional_values, versioned_additional_values)


def remove_additional_values_version(csar):
    for chart in csar.vnfd.artefacts.charts:
        versioned_values_name = "{}-{}.yaml".format(chart.chart_name, chart.chart_version)
        versioned_additional_values = os.path.join(csar.csar_directory, _values_directory, versioned_values_name)

        if os.path.exists(versioned_additional_values):
            additional_values_name = "{}.yaml".format(chart.chart_name)
            additional_values = os.path.join(csar.csar_directory, _values_directory, additional_values_name)
            os.rename(versioned_additional_values, additional_values)


def load_repositories():
    with open(_repositories_file) as read_repositories_path:
        result = {}
        repositories = yaml.safe_load(read_repositories_path)
        for repository in repositories['repositories']:
            result[repository['name']] = Repository(repository['name'], repository['url'])
        return result


def build_package_manger_command(csar, build_parameters):
    chart_paths = [chart.artefact_file_name for chart in csar.vnfd.artefacts.charts]
    joined_charts = ' \\\n'.join(chart_paths)

    package_manager_cmd = f'docker run --rm \\\n\
-u $(id -u):$(getent group docker | cut -d: -f3) \\\n\
-v /var/run/docker.sock:/var/run/docker.sock \\\n\
-v $PWD:/csar \\\n\
-v {_config_json_path}:/config/.docker/config.json \\\n\
-w /csar {build_parameters.pm_image} generate \\\n\
--docker-config /config/.docker/ \\\n\
--agentk \\\n\
--helm \\\n\
{joined_charts} \\\n\
--manifest {csar.manifest} \\\n\
--vnfd {csar.vnfd.name}  \\\n\
--sol-version {build_parameters.sol_version}  \\\n\
--name {csar.csar_name} \\\n\
--helm3'

    if os.path.exists(os.path.join(csar.csar_directory, 'imports')):
        package_manager_cmd = f'{package_manager_cmd} \\\n--definitions imports'

    if build_parameters.cnf_values_directory is not None:
        package_manager_cmd = f'{package_manager_cmd} \\\n--values-cnf-dir {build_parameters.cnf_values_directory}'

    if csar.vnfd.artefacts.scaling_mapping is not None:
        scaling_mapping_name = csar.vnfd.artefacts.scaling_mapping.artefact_file_name
        package_manager_cmd = f'{package_manager_cmd} \\\n--scale-mapping {scaling_mapping_name}'

    if build_parameters.no_images:
        package_manager_cmd = f'{package_manager_cmd} \\\n--no-images'
    if csar.change_log:
        package_manager_cmd = f'{package_manager_cmd} \\\n--history {csar.change_log}'
    if csar.licenses:
        package_manager_cmd = f'{package_manager_cmd} \\\n--licenses {_licenses_directory}'

    if build_parameters.is_option1:
        key = build_parameters.option1_configuration.key
        certificate = build_parameters.option1_configuration.certificate
        package_manager_cmd = f'{package_manager_cmd} \\\n--pkgOption 1'
        package_manager_cmd = f'{package_manager_cmd} \\\n--key {key}'
        package_manager_cmd = f'{package_manager_cmd} \\\n--certificate {certificate}'
    elif build_parameters.is_option2:
        key = build_parameters.option2_configuration.key
        certificate = build_parameters.option2_configuration.certificate
        package_manager_cmd = f'{package_manager_cmd} \\\n--pkgOption 2'
        package_manager_cmd = f'{package_manager_cmd} \\\n--key {key}'
        package_manager_cmd = f'{package_manager_cmd} \\\n--certificate {certificate}'

    return package_manager_cmd


def build_option2_signing_command(csar, build_parameters):
    return f'openssl cms -sign -in {csar.csar_name}.csar \
-binary -inkey {build_parameters.option2_configuration.key} \
-signer {build_parameters.option2_configuration.certificate} \
-out {csar.csar_name}.cms -outform pem \
-certfile {build_parameters.option2_configuration.certificate} \
-nocerts '


def build_option2_zip_command(csar, build_parameters):
    return f'zip -r {csar.csar_name}.zip \
{csar.csar_name}.csar \
{build_parameters.option2_configuration.certificate} \
{csar.csar_name}.cms'


def login_global_docker_registry(cmd_arguments) -> None:
    docker_login_cmd = f'docker --config {_working_directory_path} login --username {cmd_arguments.login} --password {cmd_arguments.password} {_global_docker_registry}'
    run_cmd(docker_login_cmd)


def run_package_manager(csar, build_parameters):
    LOG.info('Building CSAR')
    package_manager_cmd = build_package_manger_command(csar, build_parameters)
    run_cmd(package_manager_cmd, csar.csar_directory)

    if build_parameters.is_option1 and build_parameters.is_option2:
        signing_cmd = build_option2_signing_command(csar, build_parameters)
        run_cmd(signing_cmd, csar.csar_directory)
        zip_cmd = build_option2_zip_command(csar, build_parameters)
        run_cmd(zip_cmd, csar.csar_directory)


def build_csar(csar, build_parameters):
    clean_existing_archives(csar.csar_directory)

    prepare_charts(csar, build_parameters)
    prepare_imports(csar)
    prepare_licenses(csar, build_parameters)

    run_package_manager(csar, build_parameters)

    LOG.info(f'Successfully built csar file : {csar.csar_path}')


def package_has_been_built(context):
    return os.path.exists(context.csar.csar_path)


def package_present_in_nexus(context):
    artifact = NexusArtifact(context)
    get_artifact_response = context.nexus_api.get_nexus_artifact(artifact)

    full_artifact_name = f'{artifact.groupId}.{artifact.artifactId}'
    if get_artifact_response.status_code == http.HTTPStatus.OK:
        LOG.info(f'Package {full_artifact_name}:{artifact.version} is already on Nexus')
        return True
    elif get_artifact_response.status_code == http.HTTPStatus.NOT_FOUND:
        LOG.info(f'Package {full_artifact_name}:{artifact.version} has not been found on Nexus, uploading it now')
        return False
    else:
        LOG.error(f'Received error while searching for csar package {full_artifact_name}:{artifact.version}: '
                  f'{get_artifact_response.text}, code: {get_artifact_response.status_code}')
        raise Exception(f'Could not search for csar package on Nexus')


def get_nexus_link(context):
    artifact = NexusArtifact(context)
    artifact_group_id = artifact.groupId.replace(".", "/")
    endpoint = f'/nexus/service/local/repositories/{artifact.repository}/content/{artifact_group_id}/{artifact.artifactId}/{artifact.version}/{context.csar.csar_file_name}'
    nexus_link = f'{context.nexus_api.host}{endpoint}'
    return nexus_link


def upload_csar_to_nexus(context):
    nexus_link = get_nexus_link(context)
    artifact = NexusArtifact(context)
    LOG.info(f'Uploading to: {nexus_link}')
    upload_artifact_response = context.nexus_api.upload_nexus_artifact(artifact, context.csar.csar_path)

    full_artifact_name = f'{artifact.groupId}.{artifact.artifactId}'
    if upload_artifact_response.status_code == http.HTTPStatus.CREATED:
        LOG.info(f'Successfully uploaded artifact {full_artifact_name} to Nexus')
    else:
        LOG.error(f'Received error while uploading csar package: {full_artifact_name} to Nexus, '
                  f'{upload_artifact_response.text}, code: {upload_artifact_response.status_code}')
        raise Exception(f'Could not upload csar package to Nexus')


def get_csar_properties_path(csar_directory):
    csar_properties_path = os.path.join(csar_directory, 'properties.yaml')
    if not os.path.exists(csar_properties_path):
        raise Exception(f'Expected {csar_properties_path} to contain file with csar properties')
    return csar_properties_path


def add_parameters_to_parser(parser):
    parser.add_argument(
        '--vnfd-path',
        help="Path to VNFD based on which CSAR will be built",
        required=True
    )
    parser.add_argument(
        '--no-images',
        help="Flag to skip generation of the docker.tar file",
        action='store_true'
    )
    parser.add_argument(
        '--build-charts',
        help="Build local helm charts",
        action='store_true',
        default=False,
        required=False
    )
    parser.add_argument(
        '--pm-version',
        help="Version of package manager image to be used for building CSAR",
        required=False
    )
    parser.add_argument(
        '--helmfile-directory',
        help="Directory name of the helmfile sources to be archived. Directory must be available in csar directory",
        required=False
    )
    parser.add_argument(
        '--login',
        help="Login for JFrog/Nexus artifactory",
        required=True
    )
    parser.add_argument(
        '--password',
        help="Password for JFrog/Nexus artifactory",
        required=True
    )


def parse_command_line_arguments():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest='command')

    build_command_parser = subparsers.add_parser(_build_command_name, help=f'Build csar')
    upload_command_parser = subparsers.add_parser(_upload_command_name, help=f'Upload csar to nexus repository')

    add_parameters_to_parser(build_command_parser)
    add_parameters_to_parser(upload_command_parser)

    return parser.parse_args()


def create_imports_directory_if_not_exists(csar):
    imports_directory_path = os.path.join(csar.csar_directory, 'imports')
    if not os.path.exists(imports_directory_path):
        os.mkdir(imports_directory_path)


def create_licenses_directory_if_not_exists(csar):
    licenses_directory_path = os.path.join(csar.csar_directory, 'licenses')
    if not os.path.exists(licenses_directory_path):
        os.mkdir(licenses_directory_path)


def remove_imports_directory_if_exists(csar):
    imports_directory_path = os.path.join(csar.csar_directory, 'imports')
    if os.path.exists(imports_directory_path):
        shutil.rmtree(imports_directory_path)


def remove_licenses_directory_if_exists(csar):
    licenses_directory_path = os.path.join(csar.csar_directory, 'licenses')
    if os.path.exists(licenses_directory_path):
        shutil.rmtree(licenses_directory_path)


def copy_certificates_to_csar_directory(csar, build_configuration):
    if build_configuration.is_option1:
        source_key_path = os.path.join(_certificates_directory, build_configuration.option1.key)
        target_key_path = os.path.join(csar.csar_directory, build_configuration.option1.key)
        source_certificate_path = os.path.join(_certificates_directory, build_configuration.option1.certificate)
        target_certificate_path = os.path.join(csar.csar_directory, build_configuration.option1.certificate)
        shutil.copyfile(source_key_path, target_key_path)
        shutil.copyfile(source_certificate_path, target_certificate_path)

    if build_configuration.is_option2:
        source_key_path = os.path.join(_certificates_directory, build_configuration.option2.key)
        target_key_name = f'{csar.csar_name}.key'
        target_key_path = os.path.join(csar.csar_directory, target_key_name)
        build_configuration.option2.key = target_key_name

        source_certificate_path = os.path.join(_certificates_directory, build_configuration.option2.certificate)
        target_certificate_name = f'{csar.csar_name}.cert'
        target_certificate_path = os.path.join(csar.csar_directory, target_certificate_name)
        build_configuration.option2.certificate = target_certificate_name

        shutil.copyfile(source_key_path, target_key_path)
        shutil.copyfile(source_certificate_path, target_certificate_path)


def remove_certificates_from_csar_directory(csar, build_configuration):
    if build_configuration.is_option1:
        remove_file(os.path.join(csar.csar_directory, build_configuration.option1.key))
        remove_file(os.path.join(csar.csar_directory, build_configuration.option1.certificate))

    if build_configuration.is_option2:
        remove_file(os.path.join(csar.csar_directory, build_configuration.option2.key))
        remove_file(os.path.join(csar.csar_directory, build_configuration.option2.certificate))


def execute_build_command(context):
    try:
        create_imports_directory_if_not_exists(context.csar)
        copy_certificates_to_csar_directory(context.csar, context.build_configuration)
        configure_additional_values_version(context.csar)
        create_licenses_directory_if_not_exists(context.csar)
        build_csar(context.csar, context.build_parameters)
    except Exception as e:
        LOG.error(f'Error: {e}')
    finally:
        remove_imports_directory_if_exists(context.csar)
        remove_licenses_directory_if_exists(context.csar)
        remove_certificates_from_csar_directory(context.csar, context.build_configuration)
        remove_additional_values_version(context.csar)


def execute_upload_command(context):
    try:
        if not package_present_in_nexus(context):
            if package_has_been_built(context):
                LOG.info("Package has already been built")
            else:
                LOG.info("Package has not been built, building it now")
                execute_build_command(context)
            if _dev_suffix in context.csar.csar_name:
                LOG.error(f'Failed to upload {context.csar.csar_name}. CSAR contains helm charts built locally')
            else:
                upload_csar_to_nexus(context)
    except Exception as e:
        LOG.error(f'Error: {e}')


def main():
    cmd_arguments = parse_command_line_arguments()
    cmd_arguments.csar_directory = Path(cmd_arguments.vnfd_path).parent
    print(cmd_arguments.csar_directory)

    credentials = Credentials(cmd_arguments.login, cmd_arguments.password)
    jfrog_api = JFrogApi(_jfrog_host, credentials)
    nexus_api = NexusApi(_nexus_host, credentials)

    csar_properties = CsarProperties(cmd_arguments)
    login_global_docker_registry(cmd_arguments)
    try:
        for build_configuration in csar_properties.build_configurations:
            build_parameters = BuildParameters(build_configuration, cmd_arguments, jfrog_api)
            csar = Csar(build_configuration, cmd_arguments)

            context = Context(csar, build_configuration, build_parameters, jfrog_api, nexus_api)
            if cmd_arguments.command == _build_command_name:
                execute_build_command(context)
            elif cmd_arguments.command == _upload_command_name:
                execute_upload_command(context)
    finally:
        os.remove(_config_json_path)


if __name__ == '__main__':
    main()
