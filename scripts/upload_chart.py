#!/usr/bin/env python3

import os
import requests
import subprocess
import logging
import sys
import argparse
import http
import hashlib

"""
Script for uploading new chart to the artifactory

E.g.:
scripts/upload_chart.py upload \
    --chart-name=<chart_name> \
    --chart-version=<chart_version> \
    --login=<username> \
    --password=<password>
"""

LOG = logging.getLogger(__name__)
logging.basicConfig(format="[%(asctime)s] [%(levelname)s]: %(message)s", level=logging.INFO)

_upload_command = "upload"
_jfrog_host = "https://arm.seli.gic.ericsson.se/artifactory/proj-eo-evnfm-helm/am-csar-charts"
_working_directory_path = os.getcwd()
_charts_directory = "charts"


class JFrogApi:
    def __init__(self, host, credentials):
        self.host = host
        self.credentials = credentials

    def is_chart_present(self, chart_name, chart_version):
        chart_url = f"{_jfrog_host}/{chart_name}/{chart_name}-{chart_version}.tgz"
        response = requests.head(chart_url, auth=(self.credentials.login, self.credentials.password))

        return response.status_code == http.HTTPStatus.OK

    @staticmethod
    def calculate_checksums(file_path):
        md5_checksum = hashlib.md5()
        sha1_checksum = hashlib.sha1()
        sha256_checksum = hashlib.sha256()

        with open(file_path, "rb") as file_content:
            for chunk in iter(lambda: file_content.read(8192), b""):
                md5_checksum.update(chunk)
                sha1_checksum.update(chunk)
                sha256_checksum.update(chunk)

        return {
            "md5": md5_checksum.hexdigest(),
            "sha1": sha1_checksum.hexdigest(),
            "sha256": sha256_checksum.hexdigest(),
        }

    def upload_chart(self, chart_name, chart_version):
        chart_file_name = f'{chart_name}-{chart_version}.tgz'
        chart_path = os.path.join(_charts_directory, chart_file_name)
        chart_url = f"{_jfrog_host}/{chart_name}/{chart_file_name}"

        checksums = self.calculate_checksums(chart_path)
        headers = {
            "Content-Type": "application/x-gzip",
            "X-Checksum-Md5": checksums["md5"],
            "X-Checksum-Sha1": checksums["sha1"],
            "X-Checksum-Sha256": checksums["sha256"],
        }

        with open(chart_path, "rb") as chart_content:
            response = requests.put(
                chart_url,
                auth=(self.credentials.login, self.credentials.password),
                headers=headers,
                data=chart_content,
            )

        if response.status_code == http.HTTPStatus.CREATED:
            print(f"Artifact uploaded successfully to {chart_url}")
        else:
            print(f"Failed to upload artifact to Artifactory. Status code: {response.status_code}")


class Credentials:
    def __init__(self, login, password):
        self.login = login
        self.password = password


def build_chart(chart_name, chart_version):
    chart_dir = os.path.join(_charts_directory, chart_name, chart_version)
    if os.path.exists(chart_dir):
        LOG.info(f'Packaging chart in ')
        run_cmd(f'helm package {chart_dir} -d {_charts_directory}', working_directory=_working_directory_path)
    else:
        LOG.error(f'Chart in directory {chart_dir} was not found')
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
        LOG.error("Command execution failed: %s. Output: %s" % (cmd, error.output))
        sys.exit(1)


def add_parameters_to_parser(parser):
    parser.add_argument(
        '--chart-name',
        help="Name of chart to upload",
        required=True
    )
    parser.add_argument(
        '--chart-version',
        help="Version of chart to upload",
        required=True
    )
    parser.add_argument(
        '--login',
        help="Login for JFrog artifactory",
        required=True
    )
    parser.add_argument(
        '--password',
        help="Password for JFrog artifactory",
        required=True
    )


def parse_command_line_arguments():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest='command')
    upload_command_parser = subparsers.add_parser('upload', help=f'Upload csar to nexus repository')
    add_parameters_to_parser(upload_command_parser)

    return parser.parse_args()


def upload_chart(jfrog_api, cmd_arguments):
    if jfrog_api.is_chart_present(cmd_arguments.chart_name, cmd_arguments.chart_version):
        LOG.error(f'Failed to upload artifact. '
                  f'Chart {cmd_arguments.chart_name}:{cmd_arguments.chart_version} is already present on artifactory')
    else:
        LOG.info(f'Chart {cmd_arguments.chart_name}:{cmd_arguments.chart_version} is not found on the artifactory')
        build_chart(cmd_arguments.chart_name, cmd_arguments.chart_version)
        jfrog_api.upload_chart(cmd_arguments.chart_name, cmd_arguments.chart_version)


def main():
    cmd_arguments = parse_command_line_arguments()

    if cmd_arguments.command == _upload_command:
        credentials = Credentials(cmd_arguments.login, cmd_arguments.password)
        jfrog_api = JFrogApi(_jfrog_host, credentials)
        upload_chart(jfrog_api, cmd_arguments)


if __name__ == '__main__':
    main()
