#!/usr/bin/perl
# Hack to create CurlGlue.java from curl.h
# Reads a preprocessed compiler output from STDIN and parses with
# a regex for the wanted defines, then writes them to STDOUT. 
# Initial version: Daniel <daniel@haxx.se>
# Updated version: Guenter <eflash@gmx.net>
#
# $Id: MakeCurlGlue.pl 42 2008-10-20 09:27:21Z patrick $
#

open(IN, "${ARGV[0]}");
while(<IN>) {
    if(/^#define LIBCURL_VERSION \"(\d+\.\d+\.\d+.*)\"$/) {
         $curl_ver = $1;
    }
}
close(IN);

print <<EOTXT;
/*
 * The curl class is a JNI wrapper for libcurl.
 * Please bear with me, I'm no true java dude (yet) - Daniel S.
 * Improve what you think is bad and send the updates to the libcurl list!
 *
 * This is meant as a raw, crude and low-level interface to libcurl.
 * If you want fancy stuff, build upon this.
 */

public class CurlGlue
{
  // start of generated list - this list is up-to-date as of Curl $curl_ver
EOTXT

while(<STDIN>) {
    if($_ =~ /(CURLOPT_(.*)) += (.*)/) {
        $var= $1;
        $expr = $3;
        $f=$3;
        if($expr =~ / *(\d+) *\+ *(\d+)/) {
            $expr = $1+$2;
        }

        # nah, keep the CURL prefix to make them look like other
        # languages' defines
        # $var =~ s/^CURL//g;

        $var =~ s/ $//g;

        print "  public static final int $var = $expr;\n";
    }
}

print <<EOTXT;
  // end of generated list

  public CurlGlue() {
    try {
      curljava_handle = jni_init();
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  public void finalize() {
    jni_cleanup(curljava_handle);
  }

  private int curljava_handle;

  /* constructor and destructor for the libcurl handle */
  private native int jni_init();
  private native void jni_cleanup(int curljava_handle);
  private native synchronized int jni_perform(int curljava_handle);

  // Instead of varargs, we have different functions for each
  // kind of type setopt() can take
  private native int jni_setopt(int libcurl, int option, String value);
  private native int jni_setopt(int libcurl, int option, int value);
  private native int jni_setopt(int libcurl, int option, CurlWrite value);
  private native int jni_setopt(int libcurl, int option, CurlRead value);
  private native int jni_setopt(int libcurl, int option, CurlIO value);

  public native int getinfo();
  public static native String version();

  public int perform() {
    return jni_perform(curljava_handle);
  }
  public int setopt(int option, int value) {
    return jni_setopt(curljava_handle, option, value);
  }
  public int setopt(int option, String value) {
    return jni_setopt(curljava_handle, option, value);
  }
  public int setopt(int option, CurlWrite value) {
    return jni_setopt(curljava_handle, option, value);
  }
  public int setopt(int option, CurlRead value) {
    return jni_setopt(curljava_handle, option, value);
  }
  public int setopt(int option, CurlIO value) {
    return jni_setopt(curljava_handle, option, value);
  }

  static {
    try {
      // Loading up the shared JNI
      System.loadLibrary("curljava");
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

}

EOTXT
