# Default settings for testing CentOS10

source ./network-device-names.cfg
export KSTEST_URL='http://mirror.stream.centos.org/10-stream/BaseOS/x86_64/os/'
export KSTEST_MODULAR_URL='http://mirror.stream.centos.org/10-stream/AppStream/x86_64/os/'
export KSTEST_FTP_URL='ftp://mirror.stream.centos.org/10-stream/BaseOS/x86_64/os/'
export KSTEST_OSTREECONTAINER_URL='quay.io/centos-bootc/centos-bootc:stream10'
export KSTEST_METALINK='https://mirror.stream.centos.org/metalink?repo=BaseOS-$releasever&arch=x86_64'
export KSTEST_MIRRORLIST='https://mirror.stream.centos.org/mirrorlist?repo=BaseOS-$releasever&arch=x86_64'
