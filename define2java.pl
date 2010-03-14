#!/usr/bin/perl
# Hack to create CurlGlue.java from curl.h
# Initial version: Daniel <daniel@haxx.se>
# Updated version: Guenter <eflash@gmx.net>
#

open(IN, "${ARGV[1]}");
while(<IN>) {
    if(/^#define LIBCURL_VERSION \"(\d{1,3}\.\d{1,3}\.\d{1,3}.*)\"$/) {
         $curl_ver = $1;
    }
}
close(IN);

print <<EOTXT;
/*
 * The curl class is a JNI wrapper for libcurl. Please bear with me, I'm no
 * true java dude (yet). Improve what you think is bad and send me the updates!
 * daniel@haxx.se
 *
 * This is meant as a raw, crude and low-level interface to libcurl. If you
 * want fancy stuff, build upon this.
 */

public class CurlGlue
{
  // start of generated list - this list is up-to-date as of Curl $curl_ver
EOTXT

open(GCC, "gcc -E ${ARGV[0]}|");

while(<GCC>) {
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

        print "    public static final int $var = $expr;\n";
    }
}

close(GCC);

print <<EOTXT;
  // end of generated list

  public CurlGlue() {
    try {
      javacurl_handle = jni_init();
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  public void finalize() {
    jni_cleanup(javacurl_handle);
  }

  private int javacurl_handle;

  /* constructor and destructor for the libcurl handle */
  private native int jni_init();
  private native void jni_cleanup(int javacurl_handle);
  private native synchronized int jni_perform(int javacurl_handle);

  // Instead of varargs, we have different functions for each
  // kind of type setopt() can take
  private native int jni_setopt(int libcurl, int option, String value);
  private native int jni_setopt(int libcurl, int option, int value);
  private native int jni_setopt(int libcurl, int option, CurlWrite value);

  public native int getinfo();

  public int perform() {
    return jni_perform(javacurl_handle);
  }
  public int setopt(int option, int value) {
    return jni_setopt(javacurl_handle, option, value);
  }
  public int setopt(int option, String value) {
    return jni_setopt(javacurl_handle, option, value);
  }
  public int setopt(int option, CurlWrite value) {
    return jni_setopt(javacurl_handle, option, value);
  }

  static {
    try {
      // Loading up javacurl.dll
      System.loadLibrary("javacurl");
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

}

EOTXT


