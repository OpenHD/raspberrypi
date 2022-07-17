#!/bin/bash

PACKAGE_ARCH=$1
OS=$2
DISTRO=$3
BUILD_TYPE=$4

# There are no distro specific options in this because this package only works on a raspberry pi, the jetson
# veye library is entirely separate

if [ "${BUILD_TYPE}" == "docker" ]; then
    cat << EOF > /etc/resolv.conf
options rotate
options timeout:1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
fi

PACKAGE_NAME=veye-raspberrypi

TMPDIR=/tmp/${PACKAGE_NAME}-installdir

rm -rf ${TMPDIR}/*

mkdir -p ${TMPDIR}/usr/local/share/veye-raspberrypi || exit 1

cp -a i2c_cmd/bin/* ${TMPDIR}/usr/local/share/veye-raspberrypi/ || exit 1
chmod +x ${TMPDIR}/usr/local/share/veye-raspberrypi/* || exit 1

VER2=$(git rev-parse --short HEAD) ||exit
echo ${VER2}
VERSION="2.2.0-evo-$(date '+%m%d%H%M')-${VER2}"

rm ${PACKAGE_NAME}_${VERSION}_${PACKAGE_ARCH}.deb > /dev/null 2>&1

fpm -a ${PACKAGE_ARCH} -s dir -t deb -n ${PACKAGE_NAME} -v ${VERSION//v} -C ${TMPDIR} \
  -p ${PACKAGE_NAME}_VERSION_ARCH.deb || exit 1

#
# Only push to cloudsmith for tags. If you don't want something to be pushed to the repo, 
# don't create a tag. You can build packages and test them locally without tagging.
#
git describe --exact-match HEAD > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
    echo "Pushing package to OpenHD repository"
    cloudsmith push deb openhd/openhd-2-1/${OS}/${DISTRO} ${PACKAGE_NAME}_${VERSION}_${PACKAGE_ARCH}.deb
else
    echo "Pushing package to OpenHD evo repository"
    cloudsmith push deb openhd/openhd-2-2-evo/${OS}/${DISTRO} ${PACKAGE_NAME}_${VERSION}_${PACKAGE_ARCH}.deb
fi
