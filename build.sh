#!/bin/bash
[[ "$1" =~ ^(--version)$ ]] && {
    echo "2023-05-13";
    exit 0
};

#
# CONST
#

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
BUILDFOLDER="haiwen-build"
BUILDPATH="${SCRIPTPATH}/${BUILDFOLDER}"
THIRDPARTYFOLDER="${BUILDPATH}/seahub_thirdparty"
PKGSOURCEDIR="built-seafile-sources"
PKGDIR="built-seafile-server-pkgs"
DISTRO=`lsb_release -d | awk '{ print $2 }'`
ARCH=$(arch)
PREFIX="${HOME}/opt/local"
# Temporary folder for seafile-server dependency builds for shared libraries (ld)
# see https://github.com/haiwen/seahub/blob/eab3ba2f6d3a311728130d8752c716e782b8d62e/scripts/build/build-server.py#L324

LIBSEARPC_VERSION_LATEST="3.3-latest" # check if new tag is available on https://github.com/haiwen/libsearpc/releases
LIBSEARPC_VERSION_FIXED="3.1.0" # libsearpc sticks to 3.1.0 https://github.com/haiwen/libsearpc/commit/43d768cf2eea6afc6e324c2b1a37a69cd52740e3
VERSION="10.0.1"
VERSION_SEAFILE="6.0.1" # dummy version for seafile (see configure.ac)
MYSQL_CONFIG_PATH="/usr/bin/mysql_config" # ensure compilation with mysql support

VERSION_TAG="v${VERSION}-server"
LIBSEARPC_TAG="v${LIBSEARPC_VERSION_LATEST}"

STEPS=0
STEPCOUNTER=0

CONF_INSTALL_DEPENDENCIES=false
CONF_INSTALL_THIRDPART=false
CONF_BUILD_LIBEVHTP=false
CONF_BUILD_LIBSEARPC=false
CONF_BUILD_SEAFILE=false
CONF_BUILD_SEAFILE_GO_FILESERVER=false
CONF_BUILD_SEAFILE_NOTIFICATION_SERVER=false
CONF_BUILD_SEAHUB=false
CONF_BUILD_SEAFOBJ=false
CONF_BUILD_SEAFDAV=false
CONF_BUILD_SEAFILE_SERVER=false
PREP_BUILD=false
COPY_PKG_SOURCE=false

# colors used in functions for better readability
TXT_YELLOW="\033[93m"
TXT_DGRAY="\033[1;30m"
TXT_LGRAY="\033[0;37m"
TXT_LRED="\033[1;31m"
TXT_RED="\033[0;31m"
TXT_BLUE="\033[0;34m"
TXT_GREEN="\033[0;32m"
TXT_BOLD="\033[1m"
TXT_ITALIC="\033[3m"
TXT_UNDERSCORE="\033[4m"
# 48;5 for background, 38;5 for foreground
TXT_GREEN_ON_GREY="\033[48;5;240;38;5;040m"
TXT_ORANGE_ON_GREY="\033[48;5;240;38;5;202m"
OFF="\033[0m"

msg()
{
  echo -e "\n${TXT_YELLOW}$1${OFF}\n"
}

error()
{
    echo -e "${TXT_LRED}error:${OFF} $1";
    exit 1
}

alldone()
{
    echo -e " ${TXT_GREEN}done! ${OFF}"
}

mkmissingdir()
{
    if [ ! -d "${1}" ]; then
        echo -en "create missing directory ${TXT_BLUE}$1${OFF}...";
        mkdir -p "${1}" || error "failed!";
        alldone;
    fi
}

exitonfailure()
{
  if [ $? -ne 0 ]; then
    error "$1"
  fi
}

if [[ $1 == "" ]] ; then
  echo -e "
Usage:
  ${TXT_BOLD}build.sh${OFF} ${TXT_DGRAY}${TXT_ITALIC}[OPTIONS]${OFF}

  ${TXT_UNDERSCORE}OPTIONS${OFF}:
    ${TXT_BOLD}-D${OFF}          Install build dependencies
    ${TXT_BOLD}-T${OFF}          Install thirdparty requirements

    ${TXT_BOLD}-1${OFF}          Build/update libevhtp
    ${TXT_BOLD}-2${OFF}          Build/update libsearpc
    ${TXT_BOLD}-3${OFF}          Build/update seafile (c_fileserver)
    ${TXT_BOLD}-4${OFF}          Build/update seafile (go_fileserver)
    ${TXT_BOLD}-5${OFF}          Build/update seafile (notification_server)
    ${TXT_BOLD}-6${OFF}          Build/update seahub
    ${TXT_BOLD}-7${OFF}          Build/update seafobj
    ${TXT_BOLD}-8${OFF}          Build/update seafdav
    ${TXT_BOLD}-9${OFF}          Build/update Seafile server

    ${TXT_BOLD}-A${OFF}          All options ${TXT_BOLD}-1${OFF} to ${TXT_BOLD}-9${OFF} in one go

    ${TXT_BOLD}-v${OFF} ${TXT_RED}${TXT_ITALIC}<vers>${OFF}   Set seafile server version to build
                ${TXT_LGRAY}default:${OFF} ${TXT_BLUE}${VERSION}${OFF}
    ${TXT_BOLD}-r${OFF} ${TXT_RED}${TXT_ITALIC}<vers>${OFF}   Set libsearpc version
                ${TXT_LGRAY}default:${OFF} ${TXT_BLUE}${LIBSEARPC_VERSION_LATEST}${OFF}
    ${TXT_BOLD}-f${OFF} ${TXT_RED}${TXT_ITALIC}<vers>${OFF}   Set fixed libsearpc version
                ${TXT_LGRAY}default:${OFF} ${TXT_BLUE}${LIBSEARPC_VERSION_FIXED}${OFF}

    ${TXT_DGRAY}use${OFF} ${TXT_BOLD}--version${OFF} ${TXT_DGRAY}for version info of this script.${OFF}
"
  exit 0
fi

# get the options
while getopts ":123456789ADTv:r:f:h:d:" OPT; do
    case $OPT in
        D) CONF_INSTALL_DEPENDENCIES=true >&2
           STEPS=$((STEPS+1)) >&2
           ;;
        T) CONF_INSTALL_THIRDPART=true >&2
           STEPS=$((STEPS+1)) >&2
           ;;
        1) CONF_BUILD_LIBEVHTP=true >&2
           PREP_BUILD=true >&2
           STEPS=$((STEPS+1)) >&2
           ;;
        2) CONF_BUILD_LIBSEARPC=true >&2
           PREP_BUILD=true >&2
           COPY_PKG_SOURCE=true >&2
           STEPS=$((STEPS+1)) >&2
           ;;
        3) CONF_BUILD_SEAFILE=true >&2
           PREP_BUILD=true >&2
           COPY_PKG_SOURCE=true >&2
           STEPS=$((STEPS+1)) >&2
           ;;
        4) CONF_BUILD_SEAFILE_GO_FILESERVER=true >&2
           PREP_BUILD=true >&2
           COPY_PKG_SOURCE=true >&2
           STEPS=$((STEPS+1)) >&2
           ;;
        5) CONF_BUILD_SEAFILE_NOTIFICATION_SERVER=true >&2
           PREP_BUILD=true >&2
           COPY_PKG_SOURCE=true >&2
           STEPS=$((STEPS+1)) >&2
           ;;
        6) CONF_BUILD_SEAHUB=true >&2
           PREP_BUILD=true >&2
           COPY_PKG_SOURCE=true >&2
           STEPS=$((STEPS+1)) >&2
           ;;
        7) CONF_BUILD_SEAFOBJ=true >&2
           PREP_BUILD=true >&2
           COPY_PKG_SOURCE=true >&2
           STEPS=$((STEPS+1)) >&2
           ;;
        8) CONF_BUILD_SEAFDAV=true >&2
           PREP_BUILD=true >&2
           COPY_PKG_SOURCE=true >&2
           STEPS=$((STEPS+1)) >&2
           ;;
        9) CONF_BUILD_SEAFILE_SERVER=true >&2
           PREP_BUILD=true >&2
           COPY_PKG_SOURCE=true >&2
           STEPS=$((STEPS+1)) >&2
           ;;
        A) CONF_BUILD_LIBEVHTP=true >&2
           CONF_BUILD_LIBSEARPC=true >&2
           CONF_BUILD_SEAFILE=true >&2
           CONF_BUILD_SEAFILE_GO_FILESERVER=true >&2
           CONF_BUILD_SEAFILE_NOTIFICATION_SERVER=true >&2
           CONF_BUILD_SEAHUB=true >&2
           CONF_BUILD_SEAFOBJ=true >&2
           CONF_BUILD_SEAFDAV=true >&2
           CONF_BUILD_SEAFILE_SERVER=true >&2
           PREP_BUILD=true >&2
           COPY_PKG_SOURCE=true >&2
           STEPS=$((STEPS+9)) >&2
           ;;
        v) VERSION=$OPTARG >&2
           VERSION_TAG="v${VERSION}-server" >&2
           ;;
        r) LIBSEARPC_VERSION_LATEST=$OPTARG >&2
           LIBSEARPC_TAG="v${LIBSEARPC_VERSION_LATEST}" >&2
           ;;
        f) LIBSEARPC_VERSION_FIXED=$OPTARG >&2
           ;;
        \?)
           error "Invalid option: ${TXT_BOLD}-$OPTARG${OFF}" >&2
           ;;
        :)
           error "Option ${TXT_BOLD}-$OPTARG${OFF} requires an argument." >&2
           ;;
    esac
done


# set counter accordingly
${PREP_BUILD} && STEPS=$((STEPS+2))
${COPY_PKG_SOURCE} && STEPS=$((STEPS+1))

mkmissingdir "${BUILDPATH}"

#
# START
#

echo_start()
{
  msg "Build seafile-rpi ${VERSION_TAG}"
}

#
# INSTALL DEPENDENCIES
#

install_dependencies()
{
  STEPCOUNTER=$((STEPCOUNTER+1))
  msg "-> [${STEPCOUNTER}/${STEPS}] Install dependencies"

  # https://github.com/haiwen/seafile/issues/1158
  # onigposix (libonig-dev) is dependency for /usr/local/include/evhtp.h

  msg "Downloads the package lists from the repositories and updates them"
  (set -x; apt-get update)
  msg "Install build-essential package"
  (set -x; apt-get install -y build-essential)
  msg "Install build dependencies"
  (set -x; apt-get install -y \
     cargo \
     cmake \
     git \
     golang-go \
     intltool \
     libarchive-dev \
     libcurl4-openssl-dev \
     libevent-dev \
     libffi-dev \
     libfuse-dev \
     libglib2.0-dev \
     libjansson-dev \
     libjpeg-dev \
     libjwt-dev \
     libldap2-dev \
     libmariadbclient-dev-compat \
     libonig-dev \
     libpq-dev \
     libsqlite3-dev \
     libssl-dev \
     libtool \
     libxml2-dev \
     libxslt-dev \
     python3-distro \
     python3-lxml \
     python3-ldap \
     python3-pip \
     python3-setuptools \
     python3-venv \
     python3-wheel \
     uuid-dev \
     valac \
     wget)
}

#
# PREPARE build (without privileges)
#

prepare_build()
{
  STEPCOUNTER=$((STEPCOUNTER+1))
  msg "-> [${STEPCOUNTER}/${STEPS}] Prepare build"

  mkmissingdir "${PREFIX}"
  msg "   Export LIBRARY_PATH, LD_LIBRARY_PATH, CPATH"
  export LIBRARY_PATH="${PREFIX}/lib"
  export LD_LIBRARY_PATH="${PREFIX}/lib"
  export CPATH="${PREFIX}/include"

  # print ${LIBRARY_PATH}, ${LD_LIBRARY_PATH} and ${CPATH}
  msg "   LIBRARY_PATH = ${LIBRARY_PATH} "
  msg "   LD_LIBRARY_PATH = ${LD_LIBRARY_PATH} "
  msg "   CPATH = ${CPATH} "
}

#
# BUILD libevhtp
#

build_libevhtp()
{
  STEPCOUNTER=$((STEPCOUNTER+1))
  msg "-> [${STEPCOUNTER}/${STEPS}] Build libevhtp"

  cd "${BUILDPATH}"

  if [ -d "libevhtp" ]; then
    cd libevhtp
    (set -x; make clean)
    (set -x; git fetch origin --tags)
    (set -x; git reset --hard origin/master)
  else
    (set -x; git clone "https://www.github.com/haiwen/libevhtp.git")
    cd libevhtp
  fi
  (set -x; cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} -DEVHTP_DISABLE_SSL=ON -DEVHTP_BUILD_SHARED=OFF .)
  (set -x; make)
  (set -x; make install)
  exitonfailure "Build libevhtp failed"
  cd "${SCRIPTPATH}"
}

#
# PREPARE libs
#

export_pkg_config_path()
{
  STEPCOUNTER=$((STEPCOUNTER+1))
  msg "-> [${STEPCOUNTER}/${STEPS}] Prepare libs"
  # Export PKG_CONFIG_PATH for seafile-server and libsearpc
  msg "   Export PKG_CONFIG_PATH for seafile-server and libsearpc"
  export PKG_CONFIG_PATH="${BUILDPATH}/libsearpc:${PKG_CONFIG_PATH}"
  export PKG_CONFIG_PATH="${BUILDPATH}/seafile-server/lib:${PKG_CONFIG_PATH}"

  # print ${PKG_CONFIG_PATH}
  msg "   PKG_CONFIG_PATH = ${PKG_CONFIG_PATH} "
}

#
# BUILD libsearpc
#

build_libsearpc()
{
  STEPCOUNTER=$((STEPCOUNTER+1))
  msg "-> [${STEPCOUNTER}/${STEPS}] Build libsearpc"

  cd "${BUILDPATH}"
  if [ -d "libsearpc" ]; then
    cd libsearpc
    (set -x; make clean && make distclean)
    (set -x; git fetch origin --tags)
    (set -x; git reset --hard origin/master)
  else
    (set -x; git clone "https://github.com/haiwen/libsearpc.git")
    cd libsearpc
  fi
  (set -x; git reset --hard "${LIBSEARPC_TAG}")
  (set -x; ./autogen.sh)
  (set -x; ./configure)
  (set -x; make dist)
  exitonfailure "Build libsearpc failed"
  cd "${SCRIPTPATH}"
}

#
# BUILD seafile (c_fileserver)
#

build_seafile()
{
  STEPCOUNTER=$((STEPCOUNTER+1))
  msg "-> [${STEPCOUNTER}/${STEPS}] Build seafile-server (c_fileserver)"

  cd "${BUILDPATH}"
  if [ -d "seafile-server" ]; then
    cd seafile-server
    (set -x; make clean && make distclean)
    (set -x; git fetch origin --tags)
    (set -x; git reset --hard origin/master)
  else
    (set -x; git clone "https://github.com/haiwen/seafile-server.git")
    cd seafile-server
  fi
  (set -x; git reset --hard "${VERSION_TAG}")
  (set -x; ./autogen.sh)
  (set -x; ./configure --with-mysql=${MYSQL_CONFIG_PATH} --enable-ldap)
  (set -x; make dist)
  exitonfailure "Build seafile-server failed"
  cd "${SCRIPTPATH}"
}

#
# BUILD seafile (go_fileserver)
#

build_seafile_go_fileserver()
{
  STEPCOUNTER=$((STEPCOUNTER+1))
  msg "-> [${STEPCOUNTER}/${STEPS}] Build seafile-server (go_fileserver)"

  cd "${BUILDPATH}"
  if [ -d "seafile-server" ]; then
    cd seafile-server
    (set -x; make clean && make distclean)
    (set -x; git fetch origin --tags)
    (set -x; git reset --hard origin/master)
  else
    (set -x; git clone "https://github.com/haiwen/seafile-server.git")
    cd seafile-server
  fi
  (set -x; git reset --hard "${VERSION_TAG}")
  (set -x; cd fileserver && CGO_ENABLED=0 go build .)
  exitonfailure "Build seafile-server (go_fileserver) failed"
  cd "${SCRIPTPATH}"
}

#
# BUILD seafile (notification_server)
#

build_seafile_notification_server()
{
  STEPCOUNTER=$((STEPCOUNTER+1))
  msg "-> [${STEPCOUNTER}/${STEPS}] Build seafile-server (notification_server)"

  cd "${BUILDPATH}"
  if [ -d "seafile-server" ]; then
    cd seafile-server
    (set -x; make clean && make distclean)
    (set -x; git fetch origin --tags)
    (set -x; git reset --hard origin/master)
  else
    (set -x; git clone "https://github.com/haiwen/seafile-server.git")
    cd seafile-server
  fi
  (set -x; git reset --hard "${VERSION_TAG}")
  (set -x; cd notification-server && CGO_ENABLED=0 go build .)
  exitonfailure "Build seafile-server (notification_server) failed"
  cd "${SCRIPTPATH}"
}

#
# INSTALL thirdparty requirements
#

install_thirdparty()
{
  STEPCOUNTER=$((STEPCOUNTER+1))
  msg "-> [${STEPCOUNTER}/${STEPS}] Install Seafile thirdparty requirements"

  # if distro and arch matches, add piwheels to pip config file
  msg "   Only add \"piwheels\" to pip config file if distro is DEBIAN (Buster or Bullseye) and the architecture is ARM."
  if [ "${DISTRO}" = Debian -o "${DISTRO}" = Raspbian ] && [ "${ARCH}" = armv7l -o "${ARCH}" = armv8l -o "${ARCH}" = aarch64 ]; then
    msg "   Detected \"${DISTRO}\" distro for \"${ARCH}\". We can make use of \"piwheels\", pre-compiled binary Python packages."
    if [ ! -f "${HOME}/.config/pip/pip.conf" ]; then
      msg "   Adding \"piwheels\" to pip config file under '${HOME}/.config/pip/pip.conf'..."
      mkdir -p "${HOME}/.config" "${HOME}/.config/pip" && touch "${HOME}/.config/pip/pip.conf"
      echo "[global]" > "${HOME}/.config/pip/pip.conf"
      echo "extra-index-url=https://www.piwheels.org/simple" >> "${HOME}/.config/pip/pip.conf"
      msg "   Added 'extra-index-url=https://www.piwheels.org/simple' to pip config file."
    else
      msg "   The pip config file '${HOME}/.config/pip/pip.conf' is already present on the system."
      if grep -Fxq "extra-index-url=https://www.piwheels.org/simple" ${HOME}/.config/pip/pip.conf; then
        msg "   Found the line 'extra-index-url=https://www.piwheels.org/simple' already inside of the pip config file '${HOME}/.config/pip/pip.conf'."
      else
        msg "   Adding 'extra-index-url=https://www.piwheels.org/simple' to '${HOME}/.config/pip/pip.conf'"
        echo "[global]" >> "${HOME}/.config/pip/pip.conf"
        echo "extra-index-url=https://www.piwheels.org/simple" >> "${HOME}/.config/pip/pip.conf"
        msg "   Added 'extra-index-url=https://www.piwheels.org/simple' to the pip config file."
      fi
    fi
  fi

  # While pip alone is sufficient to install from pre-built binary archives, up to date copies of the setuptools and wheel projects are useful to ensure we can also install from source archives
  # e.g. default shipped pip=9.0.1 in Ubuntu Bionic => need update to pip=20.*
  # script executed like as seafile user, therefore pip upgrade only for seafile user, not system wide; pip installation goes to /home/seafile/.local/lib/python3.6/site-packages
  msg "   Download and update pip(3), setuptools and wheel from PyPI"
  (set -x; python3 -m pip install --user --upgrade pip setuptools wheel)

  mkmissingdir "${THIRDPARTYFOLDER}"

  # install Seahub and SeafDAV thirdparty requirements
  # on pip=20.* DEPRECATION: --install-option: ['--install-lib', '--install-scripts']
  msg "   Install Seahub and SeafDAV thirdparty requirements"
  (set -x; python3 -m pip install -r "requirements/requirements.txt" --target "${THIRDPARTYFOLDER}" --no-cache --upgrade --no-deps)
  exitonfailure "Thirdparty requirements installation failed"

  # clean up
  msg "   Clean up"
  rm "${THIRDPARTYFOLDER}/requirements.txt" "${THIRDPARTYFOLDER}/requirements_SeafDAV.txt"
  rm -rf $(find . -name "__pycache__")
}

#
# BUILD seahub
#

build_seahub()
{
  STEPCOUNTER=$((STEPCOUNTER+1))
  msg "-> [${STEPCOUNTER}/${STEPS}] Build seahub"

  # get source code
  cd "${BUILDPATH}"
  if [ -d "seahub" ]; then
    cd seahub
    (set -x; make clean)
    (set -x; git fetch origin --tags)
    (set -x; git reset --hard origin/master)
  else
    (set -x; git clone "https://github.com/haiwen/seahub.git")
    cd seahub
  fi
  (set -x; git reset --hard "${VERSION_TAG}")

  # export ${THIRDPARTYFOLDER} to ${PATH}
  msg "   Export THIRDPARTYFOLDER to PATH"
  export PATH="${THIRDPARTYFOLDER}:${PATH}"
  # print ${PATH} which includes now ${THIRDPARTYFOLDER}
  msg "   PATH = ${PATH}"

  # export ${THIRDPARTYFOLDER} to $PYTHONPATH
  msg "   Export THIRDPARTYFOLDER to PYTHONPATH"
  export PYTHONPATH="${THIRDPARTYFOLDER}"
  # print $PYTHONPATH
  msg "   PYTHONPATH = $PYTHONPATH${OFF}"

  # to fix [ERROR] django-admin scripts not found in PATH
  msg "   export THIRDPARTYFOLDER/django/bin to PATH"
  export PATH="${THIRDPARTYFOLDER}/django/bin:${PATH}"
  msg "   PATH = ${PATH}"

  # generate package
  # if python != python3.6 we need to "sudo ln -s /usr/bin/python3.6 /usr/bin/python" or with "pyenv global 3.6.9"
  (set -x; python3 "${BUILDPATH}/seahub/tools/gen-tarball.py" --version="${VERSION_SEAFILE}" --branch=HEAD)
  exitonfailure "Build seahub failed"
  cd "${SCRIPTPATH}"
}

#
# BUILD seafobj
#

build_seafobj()
{
  STEPCOUNTER=$((STEPCOUNTER+1))
  msg "-> [${STEPCOUNTER}/${STEPS}] Build seafobj"

  cd "${BUILDPATH}"
  if [ -d "seafobj" ]; then
    cd seafobj
    (set -x; git fetch origin --tags)
    (set -x; git reset --hard origin/master)
  else
    (set -x; git clone "https://github.com/haiwen/seafobj.git")
    cd seafobj
  fi
  (set -x; git reset --hard "${VERSION_TAG}")
  (set -x; make dist)
  exitonfailure "Build seafobj failed"
  cd "${SCRIPTPATH}"
}

#
# BUILD seafdav
#

build_seafdav()
{
  STEPCOUNTER=$((STEPCOUNTER+1))
  msg "-> [${STEPCOUNTER}/${STEPS}] Build seafdav"

  cd "${BUILDPATH}"
  if [ -d "seafdav" ]; then
    cd seafdav
    (set -x; git fetch origin --tags)
    (set -x; git reset --hard origin/master)
  else
    (set -x; git clone "https://github.com/haiwen/seafdav.git")
    cd seafdav
  fi
  (set -x; git reset --hard "${VERSION_TAG}")
  (set -x; make)
  exitonfailure "Build seafdav failed"
  cd "${SCRIPTPATH}"
}

#
# COPY package sources
#

copy_pkg_source()
{
  STEPCOUNTER=$((STEPCOUNTER+1))
  msg "-> [${STEPCOUNTER}/${STEPS}] Copy sources to ${PKGSOURCEDIR}/R${VERSION} "

  mkmissingdir "${SCRIPTPATH}/${PKGSOURCEDIR}/R${VERSION}"
  for i in \
      "${BUILDPATH}/libsearpc/libsearpc-${LIBSEARPC_VERSION_FIXED}.tar.gz" \
      "${BUILDPATH}/seafile-server/seafile-${VERSION_SEAFILE}.tar.gz" \
      "${BUILDPATH}/seafile-server/fileserver/fileserver" \
      "${BUILDPATH}/seafile-server/notification-server/notification-server" \
      "${BUILDPATH}/seahub/seahub-${VERSION_SEAFILE}.tar.gz" \
      "${BUILDPATH}/seafobj/seafobj.tar.gz" \
      "${BUILDPATH}/seafdav/seafdav.tar.gz"
  do
      [ -f "$i" ] && (set -x; cp "$i" "${SCRIPTPATH}/${PKGSOURCEDIR}/R${VERSION}")
  done
}

#
# BUILD Seafile server
#

build_server()
{
  STEPCOUNTER=$((STEPCOUNTER+1))
  msg "-> [${STEPCOUNTER}/${STEPS}] Build Seafile server"

  cd "${BUILDPATH}"
  mkmissingdir "${SCRIPTPATH}/${PKGDIR}"

  # TODO: remove at seafile 10.0.2 release
  msg "-> Patch build-server.py"
  echo "--- build-server.py.old	2023-04-23 17:26:19.233328609 +0200
+++ build-server.py	2023-04-23 17:22:58.625726460 +0200
@@ -549,6 +549,15 @@
 
     must_copy(src_go_fileserver, dst_bin_dir)
 
+# copy notification_server "notification-server" to directory seafile-server/seafile/bin
+def copy_notification_server():
+    builddir = conf[CONF_BUILDDIR]
+    srcdir = conf[CONF_SRCDIR]
+    src_notification_server = os.path.join(srcdir, 'notification-server')
+    dst_bin_dir = os.path.join(builddir, 'seafile-server', 'seafile', 'bin')
+
+    must_copy(src_notification_server, dst_bin_dir)
+
 def copy_seafdav():
     dst_dir = os.path.join(conf[CONF_BUILDDIR], 'seafile-server', 'seahub', 'thirdpart')
     tarball = os.path.join(conf[CONF_SRCDIR], 'seafdav.tar.gz')
@@ -578,6 +587,8 @@
               serverdir)
     must_copy(os.path.join(scripts_srcdir, 'seafile.sh'),
               serverdir)
+    must_copy(os.path.join(scripts_srcdir, 'seafile-monitor.sh'),
+              serverdir)
     must_copy(os.path.join(scripts_srcdir, 'seahub.sh'),
               serverdir)
     must_copy(os.path.join(scripts_srcdir, 'reset-admin.sh'),
@@ -635,6 +646,9 @@
     # copy go_fileserver
     copy_go_fileserver()
 
+    # copy notification_server
+    copy_notification_server()
+
 def copy_pdf2htmlex():
     '''Copy pdf2htmlEX exectuable and its dependent libs'''
     pdf2htmlEX_executable = find_in_path('pdf2htmlEX')" | patch -N -b -u "${BUILDPATH}/seahub/scripts/build/build-server.py"

  msg "-> Executing build-server.py"
  (set -x; python3 "${BUILDPATH}/seahub/scripts/build/build-server.py" \
    --libsearpc_version="${LIBSEARPC_VERSION_FIXED}" \
    --seafile_version="${VERSION_SEAFILE}" \
    --version="${VERSION}" \
    --thirdpartdir="${THIRDPARTYFOLDER}" \
    --srcdir="${SCRIPTPATH}/${PKGSOURCEDIR}/R${VERSION}" \
    --mysql_config="${MYSQL_CONFIG_PATH}" \
    --outputdir="${SCRIPTPATH}/${PKGDIR}" \
    --yes)
  exitonfailure "Build Seafile server failed"
  cd "${SCRIPTPATH}"
}

#
# COMPLETE
#

echo_complete()
{
  msg "-> BUILD COMPLETED."
}

#
# MAIN
#

echo_start

if ${PREP_BUILD} ; then
    prepare_build
    export_pkg_config_path
fi

${CONF_INSTALL_DEPENDENCIES} && install_dependencies
${CONF_INSTALL_THIRDPART} && install_thirdparty

${CONF_BUILD_LIBEVHTP} && build_libevhtp
${CONF_BUILD_LIBSEARPC} && build_libsearpc
${CONF_BUILD_SEAFILE} && build_seafile
${CONF_BUILD_SEAFILE_GO_FILESERVER} && build_seafile_go_fileserver
${CONF_BUILD_SEAFILE_NOTIFICATION_SERVER} && build_seafile_notification_server
${CONF_BUILD_SEAHUB} && build_seahub
${CONF_BUILD_SEAFOBJ} && build_seafobj
${CONF_BUILD_SEAFDAV} && build_seafdav

${COPY_PKG_SOURCE} && copy_pkg_source

${CONF_BUILD_SEAFILE_SERVER} && build_server

echo_complete
