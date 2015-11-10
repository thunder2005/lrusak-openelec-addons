################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2013 Stephan Raue (stephan@openelec.tv)
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with OpenELEC.tv; see the file COPYING.  If not, write to
#  the Free Software Foundation, 51 Franklin Street, Suite 500, Boston, MA 02110, USA.
#  http://www.gnu.org/copyleft/gpl.html
################################################################################

PKG_NAME="docker"
PKG_VERSION="1.9.0"
PKG_REV="0"
PKG_ARCH="any"
PKG_LICENSE="ASL"
PKG_SITE="http://www.docker.com/"
PKG_URL="https://github.com/docker/docker/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain sqlite btrfs-progs go:host"
PKG_PRIORITY="optional"
PKG_SECTION="system"
PKG_SHORTDESC="Docker is an open-source engine that automates the deployment of any application as a lightweight, portable, self-sufficient container that will run virtually anywhere."
PKG_LONGDESC="Docker containers can encapsulate any payload, and will run consistently on and between virtually any server. The same container that a developer builds and tests on a laptop will run at scale, in production*, on VMs, bare-metal servers, OpenStack clusters, public instances, or combinations of the above."
PKG_AUTORECONF="no"

PKG_IS_ADDON="yes"
PKG_ADDON_TYPE="xbmc.service"
PKG_ADDON_PROVIDES=""
PKG_ADDON_REPOVERSION="6.0"

PKG_SECTION="service/system"
PKG_MAINTAINER="Lukas Rusak (lorusak@gmail.com)"

unpack() {
  tar xf $ROOT/$SOURCES/$PKG_NAME/v$PKG_VERSION.tar.gz -C $ROOT/$BUILD
}

configure_target() {
  ./hack/vendor.sh

  ln -fs $ROOT/$PKG_BUILD $ROOT/$PKG_BUILD/vendor/src/github.com/docker/docker

  export DOCKER_BUILDTAGS="daemon \
                           exclude_graphdriver_devicemapper \
                           exclude_graphdriver_aufs"

  case $TARGET_ARCH in
    x86_64)
      export GOARCH=amd64
      ;;
    arm)
      export GOARCH=arm

      case $PROJECT in
        RPi)
          export GOARM=6
          ;;
        RPi2|WeTek_Play|imx6)
         export GOARM=7
         ;;
      esac
      ;;
  esac

  export GOOS=linux
  export CGO_ENABLED=1
  export CGO_NO_EMULATION=1
  export CGO_CFLAGS=$CFLAGS
  export LDFLAGS="-w -linkmode external -extldflags -Wl,--unresolved-symbols=ignore-in-shared-libs -extld $TARGET_CC"
  export GOLANG=$ROOT/$TOOLCHAIN/lib/golang/bin/go
  export GOPATH=$ROOT/$PKG_BUILD/.gopath:$ROOT/$PKG_BUILD/vendor

  # used for docker version
  export GITCOMMIT=$PKG_VERSION
  export VERSION=$PKG_VERSION
  export BUILDTIME="$(date --utc)"
  bash ./hack/make/.go-autogen
}

make_target() {
  mkdir -p bin
  $GOLANG build -v -o bin/docker -a -tags "$DOCKER_BUILDTAGS" -ldflags "$LDFLAGS" ./docker
}

makeinstall_target() {
  :
}

addon() {
  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/bin/
    cp -a $ROOT/$PKG_BUILD/bin/docker $ADDON_BUILD/$PKG_ADDON_ID/bin/
}