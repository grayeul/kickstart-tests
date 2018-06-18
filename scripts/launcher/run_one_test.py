#!/usr/bin/python3

#
# Copyright (C) 2018  Red Hat, Inc.
#
# This copyrighted material is made available to anyone wishing to use,
# modify, copy, or redistribute it subject to the terms and conditions of
# the GNU General Public License v.2, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY expressed or implied, including the implied warranties of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.  You should have received a copy of the
# GNU General Public License along with this program; if not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.  Any Red Hat trademarks that are incorporated in the
# source code or documentation are not subject to the GNU General Public
# License and may only be used or replicated with the express permission of
# Red Hat, Inc.
#
# Red Hat Author(s): Jiri Konecny <jkonecny@redhat.com>

# This script runs a single kickstart test on a single system.  It takes
# command line arguments instead of environment variables because it is
# designed to be driven by run_kickstart_tests.sh via parallel.  It is
# not for direct use.

# Possible return values:
# 0  - Everything worked
# 1  - Test failed for unspecified reasons
# 2  - Test failed due to time out
# 3  - Test failed due to kernel panic
# 77 - Something needed by the test doesn't exist, so skip
# 99 - Test preparation failed

import os
import shutil
import subprocess

from lib.temp_manager import TempManager
from lib.configuration import RunnerConfiguration, VirtualConfiguration
from lib.shell_launcher import ShellLauncher
from lib.virtual_controller import VirtualManager
from lib.validator import KickstartValidator, LogValidator, ResultFormatter
from lib.test_logging import setup_logger, get_logger

log = get_logger()


class Runner(object):

    def __init__(self, configuration, tmp_dir):
        super().__init__()
        self._conf = configuration
        self._tmp_dir = tmp_dir
        self._ks_file = None

        self._shell = ShellLauncher(configuration, tmp_dir)
        self._result_formatter = ResultFormatter(self._conf.ks_test_name)
        # test prepare function can change place of the kickstart test
        # so the validator will be set later
        self._validator = None

    def _prepare_test(self):
        log.debug("Preparing test")
        self._copy_image_to_tmp()

        try:
            shell_out = self._shell.run_prepare()
            shell_out.check_ret_code_with_exception()
            self._ks_file = shell_out.stdout
        except subprocess.CalledProcessError as e:
            self._result_formatter.report_result(result=False, msg="Test prep failed")
            self._shell.run_cleanup()
            return False

        self._validator = KickstartValidator(self._conf.ks_test_name, self._ks_file)
        self._validator.check_ks_substitution()
        if not self._validator.result:
            self._validator.report_result()
            self._shell.run_cleanup()
            return False

        return True

    def _copy_image_to_tmp(self):
        log.info("Copying image to temp directory {}".format(self._tmp_dir))
        shutil.copy2(self._conf.boot_image_path, self._tmp_dir)

    def run_test(self):
        if not self._prepare_test():
            return 99

        kernel_args = self._get_kernel_args()

        if self._conf.updates_img_path:
            kernel_args += " inst.updates={}".format(self._conf.updates_img_path)

        disk_args = self._collect_disks()
        nics_args = self._collect_network()
        boot_args = self._get_boot_args()

        target_boot_iso = os.path.join(self._tmp_dir, self._conf.boot_image_name)

        v_conf = VirtualConfiguration(target_boot_iso, [self._ks_file])
        v_conf.kernel_args = kernel_args
        v_conf.test_name = self._conf.ks_test_name
        v_conf.temp_dir = self._tmp_dir
        v_conf.log_path = os.path.join(self._tmp_dir, "livemedia.log")
        v_conf.ram = 1024
        v_conf.vnc = "vnc"
        v_conf.boot_image = boot_args
        v_conf.timeout = 60
        v_conf.disk_paths = disk_args
        v_conf.networks = nics_args

        virt_manager = VirtualManager(v_conf)

        if not virt_manager.run():
            self._result_formatter.report_result(False, "Virtual machine installation failed.")
            return 1

        validator = self._validate_logs(v_conf)

        if not validator.result:
            validator.report_result()
            self._shell.run_cleanup()
            return validator.return_code

        ret = self._validate_result()
        if ret.check_ret_code():
            self._result_formatter.report_result(True, "test done")

        self._shell.run_cleanup()
        return ret.return_code

    def _collect_disks(self):
        ret = []

        out = self._shell.run_prepare_disks()
        out.check_ret_code_with_exception()

        for d in out.stdout_as_array:
            ret.append("{},cache=unsafe".format(d))

        return ret

    def _collect_network(self):
        ret = []

        out = self._shell.run_prepare_network()
        out.check_ret_code_with_exception()

        for n in out.stdout_as_array:
            ret.append("--nic")
            ret.append(n)

        return ret

    def _get_runner_args(self):
        ret = []

        out = self._shell.run_additional_runner_args()
        out.check_ret_code_with_exception()
        for arg in out.stdout_as_array:
            ret.append(arg)

        return ret

    def _get_kernel_args(self):
        out = self._shell.run_kernel_args()

        out.check_ret_code_with_exception()
        return out.stdout

    def _get_boot_args(self):
        out = self._shell.run_boot_args()

        out.check_ret_code_with_exception()
        return out.stdout_as_array

    def _validate_logs(self, virt_configuration):
        validator = LogValidator(self._conf.ks_test_name)
        validator.check_install_errors(virt_configuration.install_logpath)

        if validator.result:
            validator.check_virt_errors(virt_configuration.log_path)

        return validator

    def _validate_result(self):
        output = self._shell.run_validate()

        if not output.check_ret_code():
            msg = "Validation failed with return code {}".format(output.return_code)
            self._result_formatter.report_result(False, msg)

        return output


if __name__ == '__main__':
    config = RunnerConfiguration()

    config.process_argument()

    print("================================================================")

    with TempManager(config.keep_level, config.ks_test_name) as temp_dir:
        setup_logger(temp_dir)
        runner = Runner(config, temp_dir)
        ret_code = runner.run_test()

    exit(ret_code)