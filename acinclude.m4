#
# $Id: acinclude.m4 42 2008-10-20 09:27:21Z patrick $
#

dnl These are the top-level macros provided:
dnl
dnl AC_PATH_JDK		Finds the JDK or accepts the location argument
dnl AC_PROG_JAVATOOL	Finds the JDK tool or accepts the location argument
dnl AC_PATH_JAVACLASS	Finds the jar file or directory with the classes or
dnl			accepts the location argument
dnl
dnl Also, there are others, but I wouldn't recommend to use them just for
dnl consistency sake (VT).

dnl Find the 'false program, I'll need it as a substitute later
dnl Result goes in FALSE
AC_DEFUN([AC_PROG_FALSE],
[
AC_PATH_PROG(FALSE,false,$PATH)
])

dnl Find the JDK
dnl Results go in JDK_HOME
dnl Also sets JAVA_PLATFORM to 1 for 1.1 and to 2 for 1.2
dnl See also AC_WITH_PLATFORM
dnl
dnl Accepts also --with-jdk-home=none

AC_DEFUN([AC_PATH_JDK],
[

    AC_MSG_CHECKING([for JDK location (please wait)])

    dnl The order is: --with-jdk first, environment second, guessed value third.

    AC_ARG_WITH(jdk-home,
    [  --with-jdk-home=DIR     Where is your JDK root directory.],
    [

        # This stuff works if the command line parameter --with-jdk-home was
        # specified, so it takes priority rightfully.

	JDK_HOME=${withval}

	if test "${JDK_HOME}" != none -a ! -d "${JDK_HOME}" ; then
	    AC_MSG_ERROR(Not a directory: ${JDK_HOME})
	fi

	AC_MSG_RESULT(${JDK_HOME})

    ],
    [
        # This works if the parameter was NOT specified, so it's a good time
        # to see what the enviroment says.

        # Since Sun uses JAVA_HOME a lot, we check it first and ignore the
        # JDK_HOME, otherwise just use whatever JDK_HOME was specified.

        if test -n "${JAVA_HOME}" ; then

            JDK_HOME=${JAVA_HOME}
        fi
    ])

    if test "${JDK_HOME}" != none; then
        dnl This is a safe default. Could screw up on the security features, but
        dnl oh well, this is what --with-java2 is for.

        JAVA_PLATFORM="1"

        if test -z "${JDK_HOME}" ; then

            # Oh well, nobody set neither JAVA_HOME nor JDK_HOME, have to guess

            # The following code is based on the code submitted by Henner Zeller
            # for ${srcdir}/src/scripts/package/rpm/ApacheJServ.spec

            # Two variables will be set as a result:
            #
            # JDK_HOME
            # JAVA_PLATFORM


            for JDK_PREFIX in \
    	        /usr/local \
    	        /usr/local/lib \
	        /usr/java \
    	        /usr \
    	        /usr/lib \
                /opt  \
    	        /
            do
		for VARIANT in default latest java jdk;
		do	GUESS="${JDK_PREFIX}/${VARIANT}"
dnl			AC_MSG_CHECKING([$GUESS}])

			if test -d "${GUESS}/bin" && test -d "${GUESS}/include";
			then	JDK_HOME="${GUESS}"
				AC_MSG_RESULT([${GUESS}])
				break
			fi

		done

		if test -n "${JDK_HOME}" ; then
			break;
		fi

                for JAVA_PLATFORM in 6 5 4 3 2 1 ;
                do

                    for subversion in .9 .8 .7 .6 .5 .4 .3 .2 .1 .0 "" ;
                    do
                        for VARIANT in java java- jdk jdk-;
                        do
                            GUESS="${JDK_PREFIX}/${VARIANT}1.${JAVA_PLATFORM}${subversion}"
dnl                            AC_MSG_CHECKING([${GUESS}])

                            if test -d "${GUESS}/bin" \
                            && test -d "${GUESS}/include" ; then

                                JDK_HOME="${GUESS}"
                                AC_MSG_RESULT([${GUESS}])
                                break
                            fi

                        done

                        if test -n "${JDK_HOME}" ; then
                            break;
                        fi

                    done

                    if test -n "${JDK_HOME}" ; then
                        break;
                    fi

                done

                if test -n "${JDK_HOME}" ; then
                    break;
                fi

            done

            if test -n "${JDK_HOME}" ; then

                dnl Just to have the messages looking uniformly

                AC_MSG_CHECKING(Java platform)
                AC_MSG_RESULT([guess ${JAVA_PLATFORM}])
            fi

        else

            AC_MSG_CHECKING(Java platform)

            AC_ARG_WITH(java-platform,
            [  --with-java-platform=VAL Force the Java platorm
                              (value is 1 for 1.1.x or 2 for 1.2.x or greater)],
            [
                dnl This requires a bit of tweaking to be handled properly, but
                dnl the default is good enough

                JAVA_PLATFORM="2"
            ])

            AC_MSG_RESULT(forced Java ${JAVA_PLATFORM})

        fi

        if test -z "${JDK_HOME}" ; then

            AC_MSG_ERROR([JDK home not found, please specify one with --with-jdk-home option (run ./configure --help for more options)])
        fi

        AC_SUBST(JDK_HOME)
        AC_PROVIDE([$0])
    fi
])

dnl Find the  rmic program (so far useful only for EJBoss
dnl (http://www.ejboss.org/), but preserved because doesn't break anything and
dnl allows this file to be reused for Jserv, ECS, Jukebox and EJBoss.
dnl
dnl I guess I'd work on this one later. I don't like it, it's not generic (VT).

dnl Result goes in RMIC (bare location) and RMICX (with classpath and flag
dnl adjustments)

dnl The order is: --with-rmic first, environment second, guessed value third.

AC_DEFUN([AC_PROG_RMIC],
[
    AC_REQUIRE([AC_PATH_JDK])
    AC_REQUIRE([AC_PROG_FALSE])
    AC_MSG_CHECKING(rmic binary)

    AC_ARG_WITH(rmic,
    [  --with-rmic=prog        Java RMI compiler you want to use, if not the one from JDK],
    [
        if test "$withval" = "yes" || test "$withval" = "no" ; then
            AC_MSG_ERROR(You must specify the rmic binary as the parameter for --with-rmic)
        fi

        if test ! -x "$withval" ; then
            AC_MSG_ERROR(Bad value for --with-rmic: $withval)
        fi
    ],
    [
        RMIC="${JDK_HOME}/bin/rmic"
        if test ! -x "${RMIC}" ; then
            AC_MSG_ERROR(rmic binary not found in ${JDK_HOME})
        fi
    ])

    AC_MSG_RESULT(${RMIC})
    AC_SUBST(RMIC)
    AC_PROVIDE([$0])

    if test "${JAVA_PLATFORM}" = "2" ; then
    	RMICX="${RMIC} -classpath \${TARGET_CLASSPATH}:${JDK_HOME}/jre/lib/rt.jar"
    else
    	RMICX="CLASSPATH=\${CLASSPATH}:\${TARGET_CLASSPATH}:${JDK_HOME}/lib/classes.zip ${RMIC}"
    fi

    AC_SUBST(RMICX)
])

dnl Locate the Java tool within a JDK tree or by --with-* option.

dnl First parameter is the name of the variable it goes to
dnl Second parameter is the name of the binary to look up
dnl Third parameter is the --help message (pay attention to alignment)
dnl If the forth parameter is present and the binary is not found, just
dnl substitute it with $FALSE and display a warning message instead of bailing
dnl out.

dnl Results go to $1 (bare location) and $1X (with classpath and flag
dnl adjustments).

AC_DEFUN([AC_PROG_JAVATOOL],
[
    AC_REQUIRE([AC_PATH_JDK])
    AC_REQUIRE([AC_PROG_FALSE])
    AC_MSG_CHECKING($2)

    AC_ARG_WITH($2,
    [  --with-$2=prog    $3 you want to use],
    [
        if test "$withval" = "yes" || test "$withval" = "no" ; then
            AC_MSG_ERROR([You must specify the $2 binary as the parameter for --with-$2])
        fi

        if test ! -x "$withval" ; then
            AC_MSG_ERROR([Bad value for --with-$2: $withval])
        fi
        $1="${withval}"

        if test -n "`${ECHO} ${withval}|${GREP} -i /jikes`" ; then
            JIKES="true"
        else
            JIKES="false"
        fi

    ],
    [
        $1="${JDK_HOME}/bin/$2"
        if test ! -x "${$1}" ; then
            if test -n "$4" ; then
                AC_MSG_WARN($4)
                $1=${FALSE}
            else
                AC_MSG_ERROR([$2 binary not found in ${JDK_HOME}])
            fi
        fi
    ])

    AC_MSG_RESULT(${$1})
    AC_SUBST($1)

    AC_PROVIDE($1)

    dnl VT: This ugly bypass is here because autoconf complains about its
    dnl bug. In the future, I'll be checking it once in a while


    OPTION=$1
    OPTION="${OPTION}_OPT"

    if test "${JAVA_PLATFORM}" = "2" && test "${JIKES}" = "false" ; then
    	$1X="${$1} \${$OPTION} -classpath \${TARGET_CLASSPATH}"
    else
        if test -z "${TCSETA}" && test -r "${JDK_HOME}/lib/classes.zip" ; then
            TARGET_CLASSPATH="$TARGET_CLASSPATH:${JDK_HOME}/lib/classes.zip"
            TCSETA="true"
        fi

        dnl Why 'or'? And! On the other hand, I don't remember whether there
        dnl is an rt.jar in 1.1...

        if test -z "${TCSETB}" && test -r "${JDK_HOME}/jre/lib/rt.jar" ; then
            TARGET_CLASSPATH="$TARGET_CLASSPATH:${JDK_HOME}/jre/lib/rt.jar"
            TCSETB="true"
        fi

        $1X="CLASSPATH=\${CLASSPATH}:\${TARGET_CLASSPATH} ${$1} \${$OPTION}"
    fi

    AC_SUBST($1X)
])

dnl Find the Java class set.

dnl The first parameter is the name of the variable it goes to
dnl The second parameter is a guessed location basename
dnl The third parameter defines a name of the class that has to be present
dnl in the target entity
dnl The forth parameter is a --help message
dnl If the fifth parameter is not empty, this package is optional.
dnl The output goes into $1_CLASSES

dnl FIXME: Look for the signature class in the ${CLASSPATH}

AC_DEFUN([AC_PATH_JAVACLASS],
[
    AC_MSG_CHECKING($1)

    dnl Find out if we have a parameter

    AC_ARG_WITH($1,
    [  --with-$1=DIR/JAR $4],
    [
        $1_CLASSES=$withval
    ],
    [
        dnl Guess

        $1_CLASSES="/usr/local/$2"
    ])

    dnl Find out if it exists at all

    if test ! -e "${$1_CLASSES}" ; then
        if test -z "$5" ; then
            AC_MSG_ERROR(Does not exist: '${$1_CLASSES}')
        else
            AC_MSG_RESULT(not found in ${$1_CLASSES})
        fi
    else

        dnl Transform the class name into the path name

        CLASS="`echo $3|${TR} "." "/"`.class"

        dnl Find out what it is

        if test -d "${$1_CLASSES}" ; then

            dnl OK, so this is a directory.

            AC_PATH_SEARCHCLASS($1,${$1_CLASSES},${CLASS})

            if test -z "${$1}" ; then

                AC_PATH_SEARCHJAR($1,${$1_CLASSES},${CLASS})

                if test -z "${$1}" ; then
                    if test -z "$5" ; then
                        AC_MSG_ERROR([no $3 class or jar with it in ${$1_CLASSES}])
                    else
                        AC_MSG_RESULT(not found)
                    fi
                fi
            fi
        else

            AC_PATH_VERIFYJAR($1,${$1_CLASSES},${CLASS})

            if test -z "${$1}" ; then
                AC_MSG_ERROR([$3 not found in ${$1_CLASSES}])
            fi
        fi
    fi

    $1_CLASSES=${$1}

    if test -n "${$1_CLASSES}" ; then
        AC_MSG_RESULT([${$1_CLASSES}])
    fi
    AC_SUBST($1_CLASSES)
    AC_PROVIDE($1_CLASSES)

    dnl It appears that it's not possible to use the substitution in AM_CONDITIONAL,
    dnl so by now it's required to use it in configure.in, unfortunately.

    dnl AM_CONDITIONAL($1,test -n "${$1_CLASSES}")
])

dnl This one verifies if the $3 class exists in the $2 jar file and places
dnl the $2 in $1 if it is, otherwise sets it to empty string.

AC_DEFUN([AC_PATH_VERIFYJAR],
[
    if test -z "${JAR}" ; then

        dnl This happens when you try to call AC_PATH_VERIFYJAR *before* defining JAR.
        dnl Modify your configure.in to include AC_PATH_JAVATOOL(JAR) above the invocation of,
        dnl most likely, AC_PATH_JAVACLASS.

        AC_MSG_ERROR([Find this string in acinclude.m4 and read the comments])
    fi

    dnl You may want to call it before, just to make the output look good

    $1=`${JAR} -tvf $2 2>&1|${GREP} $3`

    if test -n "${$1}" ; then
    	$1=$2
    else
        $1=""
    fi
    AC_SUBST($1)
])

dnl Find a $3 class file in the $2 directory.
dnl If the directory is a classpath root, return it in $1.
dnl If it is not, but the class is there, bail out.
dnl If it doesn't contain the class file at all, return the empty string.

# IMPORTANT: Don't replace 'cd' with '${CD}. Reason: at least on Solaris, it
# breaks the behavior by treating ${CD} as an executable program, and
# consequently RETURNING TO THE CURRENT DIRECTORY after ${CD} is executed.

AC_DEFUN([AC_PATH_SEARCHCLASS],
[
    PRESENT=`(cd $2 && ${FIND} . -name "*.class"|${GREP} "$3"|${CUT} -c 3-)`

    if test -n "${PRESENT}" ; then

        PRESENT=`echo ${PRESENT}|${GREP} -x "${CLASS}"`

        if test -z "${PRESENT}" ; then

            dnl OK, here's a misajustment - let's try to fix it later by
            dnl calculating the length difference, so far - error

            AC_MSG_ERROR([$2 is not a classpath root for $3 - adjust it])
        else
            $1=$2
        fi
    fi

    AC_SUBST($1)
])

dnl Find all the jar and zip files below $2 and check them for $3 class until found.
dnl Bail out if there's no file in there.
dnl If the jar/zip is found, return it in $1.

dnl (VT: looks like AC_PATH_VERIFYJAR, may be just use it?)

AC_DEFUN([AC_PATH_SEARCHJAR],
[
    JARS=`${FIND} $2 \( -name "*.jar" -o -name "*.zip" \) -print|tr "\n" " "`

    if test -n "$JARS" ; then
        for JARFILE in ${JARS} ; do
dnl            AC_MSG_CHECKING('$JARFILE' for $3)
            PRESENT=`${JAR} -tf ${JARFILE} 2>&1|${GREP} $3`

dnl            AC_MSG_RESULT(Got '${PRESENT}')

            if test -n "${PRESENT}" ; then
                $1=${JARFILE}
                AC_SUBST($1)
                break
            fi
        done
    fi
])
