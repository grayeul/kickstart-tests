# Default settings for testing Rocky 10

source ./network-device-names.cfg
export KSTEST_URL='http://dl.rockylinux.org/stg/rocky/10/BaseOS/x86_64/os/'
export KSTEST_MODULAR_URL='http://dl.rockylinux.org/stg/rocky/10/AppStream/x86_64/os/'
export KSTEST_FTP_URL='ftp://dl.rockylinux.org/stg/rocky/10/BaseOS/x86_64/os/'
export KSTEST_OSTREECONTAINER_URL='quay.io/centos-bootc/centos-bootc:stream9'
export KSTEST_METALINK='https://mirrors.rockylinux.org/metalink?repo=BaseOS-$releasever&arch=x86_64'
export KSTEST_MIRRORLIST='https://mirrors.rockylinux.org/mirrorlist?repo=BaseOS-$releasever&arch=x86_64'
