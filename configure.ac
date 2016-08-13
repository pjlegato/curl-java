#
# $Id: configure.ac 43 2008-10-20 09:46:19Z patrick $
#

AC_PREREQ(2.57)
AC_INIT([curljava.c])
AC_CONFIG_SRCDIR([curljava.c])

#	Version control.

CURLJAVA_MAJOR=0
CURLJAVA_MINOR=2
CURLJAVA_MICRO=3
CURLJAVA_EXT=			# CVS, SVN or whatever...

CURLJAVA_VERSION="${CURLJAVA_MAJOR}.${CURLJAVA_MINOR}.${CURLJAVA_MICRO}"

#	SONAME control.

CURLJAVA_SONAME="0:0:0"

#	Initialisation of automake.

AM_INIT_AUTOMAKE(curl-java, ${CURLJAVA_VERSION}${CURLJAVA_EXT})
AC_SUBST(CURLJAVA_MAJOR)
AC_SUBST(CURLJAVA_MINOR)
AC_SUBST(CURLJAVA_MICRO)
AC_SUBST(CURLJAVA_EXT)
AC_SUBST(CURLJAVA_VERSION)
AC_SUBST(CURLJAVA_SONAME)

#	Disable building of static libraries.

AM_DISABLE_STATIC

#	Check for programs.

AC_PROG_CC
AC_PROG_INSTALL
AC_LIBTOOL_WIN32_DLL
AM_PROG_LIBTOOL
AM_PROG_CC_C_O
PKG_PROG_PKG_CONFIG

#	The following flag is needed on Solaris.

CFLAGS="-D_REENTRANT ${CFLAGS}"

#	Check for header files.

AC_HEADER_STDC
AC_CHECK_HEADERS([stdlib.h string.h])

#	Checks for typedefs, structures, and compiler characteristics.

AC_C_CONST

#	Checks for library functions.

AC_FUNC_MALLOC
AC_CHECK_FUNCS([printf fprintf fwrite])

#	Add optional libtool argument for shared libraries.

LA_LDFLAGS=
case "${host_os}" in
cygwin)		LA_LDFLAGS=-no-undefined;;
esac

AC_SUBST(LA_LDFLAGS)

#	Check for curl.

PKG_CHECK_MODULES(CURL, [libcurl])
CFLAGS="${CFLAGS} ${CURL_CFLAGS}"
LDFLAGS="${CURL_LIBS} ${LDFLAGS}"

#	Get curl include directory.

CURL_INC="${prefix}/include"
TMPSTR=`"${PKG_CONFIG}" --cflags-only-I libcurl | sed -e 's/-I//'`
TMPSTR=`find ${TMPSTR} -name curl.h`

if test "${TMPSTR}"
then	TMPSTR=`dirname "${TMPSTR}"`
	CURL_INC=`dirname "${TMPSTR}"`
fi

AC_SUBST(CURL_INC)

#	Check for JDK.

AC_PATH_JDK

if test "${JDK_HOME}" = none
then	AC_MSG_ERROR([Cannot determine JDK home])
fi

JAVA_PATH="${JDK_HOME}/bin"
AC_SUBST(JAVA_PATH)
CFLAGS="${CFLAGS} -I${JDK_HOME}/include"

#	Determine the machine-dependent JDK sub-include directory.

JDK_MDINCLUDE="${host_os}"

case "${JDK_MDINCLUDE}" in
linux*)		JDK_MDINCLUDE=linux;;
cygwin)		JDK_MDINCLUDE=win32;;
esac

AC_SUBST(JDK_MDINCLUDE)
CFLAGS="${CFLAGS} -I${JDK_HOME}/include/${JDK_MDINCLUDE}"

#	Define the jar destination directory.

jardir="${prefix}/share/java"
AC_SUBST(jardir)

#	Generate configurated files.

AC_CONFIG_FILES([Makefile curl-java.spec])
AC_OUTPUT
