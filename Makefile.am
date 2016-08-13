jardir			=	@jardir@


lib_LTLIBRARIES		=	libcurljava.la

libcurljava_la_SOURCES	=	curljava.c

libcurljava_la_LDFLAGS	=	-version-info @CURLJAVA_SONAME@	\
				@LA_LDFLAGS@

curljava.o curljava.lo:		CurlGlue.h curljava.c

CurlGlue.h:			CurlGlue.java CurlGlue.class
	@JAVA_PATH@/javah CurlGlue
	touch CurlGlue.h


.PREFIXES:	.java .class

.java.class:
	@JAVA_PATH@/javac $<


CLASSES			=	CurlGlue.class				\
				CurlRead.class				\
				CurlWrite.class				\
				CurlIO.class

jar_DATA		=	curljava.jar

curljava.jar:			$(CLASSES)
	@JAVA_PATH@/jar cvf $@ $(CLASSES)

CurlGlue.java:	MakeCurlGlue.class					\
		@CURL_INC@/curl/curl.h @CURL_INC@/curl/curlver.h
	$(CC) -E -I@CURL_INC@ @CURL_INC@/curl/curl.h		|	\
		@JAVA_PATH@/java MakeCurlGlue @CURL_INC@/curl/curlver.h > $@


test:				test.class
	JAVA_LIBRARY_PATH=`find . \( -name "*.so" -o -name "*.dll" \) -print`; \
	JAVA_LIBRARY_PATH=`dirname "$${JAVA_LIBRARY_PATH}"`;		\
	java -Djava.library.path="$${JAVA_LIBRARY_PATH}" -classpath . test


clean-local:
	$(RM) -rf aclocal.m4.bak
	$(RM) -rf $(CLASSES) curljava.jar CurlGlue.h CurlGlue.java
	$(RM) -rf test.class cookie.txt


#	OS dependent files.

OS_DEPENDENT		=	Makefile.m32				\
				Makefile.netware nwlib.c		\
				GetJniVersion.java			\
				curl-java.spec


#	Obsolete files.

OBSOLETE		=	Makefile.unix				\
				MakeCurlGlue.pl				\
				MANIFEST


EXTRA_DIST		=	buildconf				\
				CurlRead.java				\
				CurlWrite.java				\
				CurlIO.java				\
				MakeCurlGlue.java			\
				test.java				\
				README					\
				$(OS_DEPENDENT)				\
				$(OBSOLETE)
