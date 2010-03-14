LDFLAGS = -shared -Wl,--add-stdcall-alias


#
# Platform-specific stuff. Note that the Windows stuff is untested as I don't have a Windows machine.
#

UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)

# Assumes DarwinPorts directory structure
LIB_DIR=/opt/local/lib/
CURL_H=/opt/local/include/curl/curl.h
CURLVER_H=/opt/local/include/curl/curlver.h


LDFLAGS = -L$(LIB_DIR) -lssl -lcrypto -lcurl -framework JavaVM -dynamiclib
CFLAGS = -c -I/System/Library/Frameworks/JavaVM.framework/Headers
CPPFLAGS = -I$(JAVA_HOME)/include 
TARGET = libjavacurl.jnilib
endif

###################

ifeq ($(UNAME), Windows) # someone who actually has a Windows system, please change this to the real uname value
# Note: this makefile has been tested with MingW32 gcc 
#       under Windows XP using Curl 7.17.1 and OpenSSL 0.9.8g

ifndef LIBCURL_PATH
LIBCURL_PATH = ../../mingw32/curl-7.17.1
endif
ifndef ZLIB_PATH
ZLIB_PATH = ../../mingw32/zlib-1.2.3
endif
ifndef OPENSSL_PATH
OPENSSL_PATH = ../../sdks/openssl_mingw32-0.9.8g
endif
TARGET = javacurl.dll

CURL_H=$(LIBCURL_PATH)/include/curl/curl.h
CURLVER_H=$(LIBCURL_PATH)/include/curl/curlver.h

CPPFLAGS = -I$(JAVA_HOME)/include -I$(JAVA_HOME)/include/win32
LDFLAGS = -lwsock32 -lwinmm
LDFLAGS += -lcurldll -lzdll
LDFLAGS += -L$(OPENSSL_PATH)/out
LDFLAGS += -L$(LIBCURL_PATH)/lib
LDFLAGS += -L$(ZLIB_PATH)
LDFLAGS += -lssl32 -leay32
CFLAGS = -c

endif

###################
#
# End platform-specific stuff
#

OBJS = javacurl.o
CC = gcc
PERL = perl

# Note: with JDK1.3 you might have to replace "__int64" in jni_md.h by "signed long"
#       if you are encountering any compilation problem
#CPPFLAGS = -ID:/jdk/include -ID:/jdk/include/win32 -I./include
CPPFLAGS += -I$(LIBCURL_PATH)/include

# Note: the libraries used below are for libcurl with SSL. You will probably need to 
#       rebuild OpenSSL under Cygwin and then rebuild libcurl with SSL support. Using
# 	the default libcurl.a from the Curl distribution is likely to cause a failure
#       at link time
#LDFLAGS = -v -shared -Wl,--add-stdcall-alias -L. -lcurl -lssl -lcrypto
#LDFLAGS = -shared -Wl,--add-stdcall-alias -L$(LIBCURL_PATH)/lib -lcurl -lssl -lcrypto
#LDFLAGS = -shared -Wl,--add-stdcall-alias
#LDFLAGS += -lcurl -lz



all: $(TARGET) test.class


# Note: CurlGlue needs to be able to load javacurl.dll from the current directory, or 
#       wherever it is stored. Update java.library.path as needed
test: test.class
	java -Djava.library.path=./ -classpath ./ test

javacurl.o: javacurl.c CurlGlue.h
	$(CC) $(CPPFLAGS) $(CFLAGS) $<

CurlGlue.h: CurlGlue.java CurlGlue.class
	javah CurlGlue
	touch CurlGlue.h

test.class: test.java CurlGlue.class $(TARGET)
	javac $<

CurlGlue.class: CurlGlue.java
	javac $<

CurlGlue.java: $(CURL_H)  $(CURLVER_H)
	$(PERL) define2java.pl $^ > $@

$(TARGET): $(OBJS)
	$(CC) -o $(TARGET) $(OBJS) $(LDFLAGS) 

clean:
	$(RM) $(TARGET) javacurl.o CurlGlue.h CurlGlue.class CurlWrite.class

testclean:
	$(RM) test.class *.log


