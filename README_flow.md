# This is an overview of the program flow for the tests.

# Normal Starting of tests: (as used by me for rocky)
* ./containers/runner/launch -j 2 -p rocky9  (list of tests)

   * launch script
       * this builds up a cmdline and runs the podman container with appropriate -v mappings
       * The "CMD" used by the container is: containers/runner/run-kstest

   * run-kstest
       * Sets up some envs, prepares virtproxyd
       * Then runs:  scripts/run_kickstart_tests.sh and passes a BOOT_ISO along with KSTESTS_TEST (list of tests) and a few other misc
         * Args passed:  -x (timeout) -k (keep) -i (iso) 
         *   Possible to use -s to skip tests (like knownfailure)
       * Afterwards copies /var/tmp/kstest-* to the LOGS_DIR to keep on host
           * Note this can be problematic if many tests are run as /var/tmp stays in memory, and can get full
       * Then runs the summary report:  scripts/run_report.sh  (which parses the TEST_LOG (kstest.log) from stdin

   * run_kickstart_tests.sh
       * sources scripts/defaults.sh
       * Then sources scripts/default-${PLATFORM_NAME}.sh
       * Then $HOME/.kstests.defaults.sh
       * Runs scripts/probe_boot_iso to get some key info
       * Does substitutions on *.ks.in files (being used) to write *.ks (uses scripts/apply-ksappend.py)
       * Somehow looks up pre-reqs to take care of for each test
       * Finally uses gnu parallel to run: scripts/launcher/run_one_test.py (I believe parallel farms out the tests, 1ea, to multiple run_one_test.py instances)

   NOTE: overall test timeout in minutes set to 30 in functions.sh (default)
   * scripts/launcher/run_one_test.py
      * Usually called the same way:  PYTHONPATH= scripts/launcher/run_one_test.py -i /opt/kstest/data/images/boot-rocky9.iso -k 1 --append-host-id
      * The main routine parses the config (?) and then calls: run_test_in_temp(config)
        * This creates a 'Runner' instance with a temp_dir, and calls runner.run_test()
      * The run_test() method:
        * calls _prepare_test()  
        * calls _create_virtual_conf
        * Instantiates VirtualManager, then runs it.
        * runs _validate_all()

      


# Note, even successfull runs start with:
2024-09-23 20:55:16.954+0000: 33: error : virGDBusGetSessionBus:126 : internal error: Unable to get session bus connection: Cannot autolaunch D-Bus without X11 $DISPLAY
2024-09-23 20:55:16.954+0000: 33: error : virGDBusGetSystemBus:99 : internal error: Unable to get system bus connection: Could not connect: No such file or directory
Extract filename /LiveOS/rootfs.img can't be resolved

# To look into skipped tests, see: ./containers/runner/skip-testtypes

