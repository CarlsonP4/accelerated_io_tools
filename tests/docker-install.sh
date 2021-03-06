#!/bin/sh

set -o errexit


# Install prerequisites
## https://github.com/red-data-tools/packages.red-data-tools.org#ubuntu
## No packages for Debian jessie, use Ubuntu trusty
cat <<APT_LINE | tee /etc/apt/sources.list.d/red-data-tools.list
deb https://packages.red-data-tools.org/ubuntu/ trusty universe
APT_LINE

apt-get update
apt-get install --assume-yes --no-install-recommends --allow-unauthenticated \
        red-data-tools-keyring
apt-get update
apt-get install --assume-yes --no-install-recommends \
        libarrow-dev=$ARROW_VER                      \
        libarrow0=$ARROW_VER                         \
        libpqxx-dev

wget --no-verbose https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip install pandas pyarrow scidb-py


# Reset SciDB instance count to 4
scidb.py stopall $SCIDB_NAME
rm --recursive $SCIDB_INSTALL_PATH/DB-$SCIDB_NAME
sed --in-place s/server-0=127.0.0.1,1/server-0=127.0.0.1,3/ \
    $SCIDB_INSTALL_PATH/etc/config.ini
scidb.py init-all --force $SCIDB_NAME
scidb.py startall $SCIDB_NAME
iquery --afl --query "list('instances')"


# Compile and install plugin
scidb.py stopall $SCIDB_NAME
make --directory /accelerated_io_tools
cp /accelerated_io_tools/libaccelerated_io_tools.so $SCIDB_INSTALL_PATH/lib/scidb/plugins/
scidb.py startall $SCIDB_NAME
iquery --afl --query "load_library('accelerated_io_tools')"
