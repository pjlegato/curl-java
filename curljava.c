/*****************************************************************************
 *                                  _   _ ____  _
 *  Project                     ___| | | |  _ \| |
 *                             / __| | | | |_) | |
 *                            | (__| |_| |  _ <| |
 *                             \___|\___/|_| \_\_____|
 *
 * Copyright (C) 2001 - 2008 Daniel Stenberg, <daniel@haxx.se>, et al.
 *
 * In order to be useful for every potential user, curl and libcurl are
 * dual-licensed under the MPL and the MIT/X-derivate licenses.
 *
 * You may opt to use, copy, modify, merge, publish, distribute and/or sell
 * copies of the Software, and permit persons to whom the Software is
 * furnished to do so, under the terms of the MPL or the MIT/X-derivate
 * licenses. You may pick one of these licenses.
 *
 * This software is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY
 * KIND, either express or implied.
 *
 * $Id: curljava.c 42 2008-10-20 09:27:21Z patrick $
 *****************************************************************************/

#include <stdlib.h>
#include <string.h>
#include <curl/curl.h> /* libcurl header */
#include "CurlGlue.h"  /* the JNI-generated glue header file */

/*
 * This is a private struct allocated for every 'CurlGlue' object.
 */
struct jcallback {
    jmethodID mid;
    JNIEnv *java;
    jclass cls; /* global reference */
    jobject object;
};

struct curljava {
  void *libcurl;
  void *whatever;
  struct jcallback write;
  struct jcallback read;
};



/*
 * CurlGlue.version()
 */

JNIEXPORT jstring JNICALL Java_CurlGlue_version(JNIEnv * java, jclass myclass)

{
  return (*java)->NewStringUTF(java, curl_version());
}


JNIEXPORT jint JNICALL Java_CurlGlue_jni_1init(JNIEnv *java,
                                               jobject myself)
{
  void *libhandle;
  struct curljava *jcurl=NULL;

  libhandle = curl_easy_init();

  if(libhandle) {
    jcurl=(struct curljava *)malloc(sizeof(struct curljava));
    if(jcurl) {
      memset(jcurl, 0, sizeof(struct curljava));
      jcurl->libcurl = libhandle;

    }
    else {
      curl_easy_cleanup(libhandle);
      return (jint)0;
    }
  }

  return (jint) jcurl; /* nasty typecast */
}

JNIEXPORT void JNICALL Java_CurlGlue_jni_1cleanup(JNIEnv *java,
                                                  jobject myself,
                                                  jint jcurl)
{

  struct curljava *curl = (struct curljava*)jcurl;

  if(curl->write.cls) {
    /* a global reference we must delete */
    (*java)->DeleteGlobalRef(java, curl->write.cls);
    (*java)->DeleteGlobalRef(java, curl->write.object);
  }

  if(curl->read.cls) {
    /* a global reference we must delete */
    (*java)->DeleteGlobalRef(java, curl->read.cls);
    (*java)->DeleteGlobalRef(java, curl->read.object);
  }

  curl_easy_cleanup(curl->libcurl); /* cleanup libcurl stuff */

  free((void *)curl); /* free the struct too */
}

/*
 * setopt() int + string
 */
JNIEXPORT jint JNICALL Java_CurlGlue_jni_1setopt__IILjava_lang_String_2
  (JNIEnv *java, jobject myself, jint jcurl, jint option, jstring value)
{
  /* get the actual string C-style */
  const char *str = (*java)->GetStringUTFChars(java, value, 0);

  void *handle = (void *)((struct curljava*)jcurl)->libcurl;

#ifdef DEBUG
  puts("setopt int + string");
#endif

  return (jint)curl_easy_setopt(handle, (CURLoption)option, str);

}

/*
 * setopt() int + int
 */
JNIEXPORT jint JNICALL Java_CurlGlue_jni_1setopt__III
  (JNIEnv *java, jobject myself, jint jcurl, jint option, jint value)
{
  void *handle = (void *)((struct curljava*)jcurl)->libcurl;
  CURLoption opt = (CURLoption)option;

#ifdef DEBUG
  puts("setopt int + int");
#endif

  switch(opt) {
  case CURLOPT_WRITEDATA:
  case CURLOPT_READDATA:
    /* silently ignored, we don't need user-specified callback data when
       we have an object, and besides the CURLOPT_WRITEDATA and CURLOPT_READDATA
       are not exported to the java interface */
    return 0;
  }

  return (jint) curl_easy_setopt(handle, (CURLoption) option, value);
}

static int curljava_write_callback(void *ptr,
                                   size_t size,
                                   size_t nmemb,
                                   FILE  *stream)
{
  struct curljava *curl = (struct curljava *)stream;
  size_t realsize = size * nmemb;
  JNIEnv *java = curl->write.java;
  jbyteArray jb=NULL;
  int ret=0;

#ifdef DEBUG
  fprintf(stderr, "%d bytes data received in callback:\n"
          "ptr=%p, java=%p cls=%p\n",
          realsize, curl, java, curl->write.cls);
#endif

  jb=(*java)->NewByteArray(java, realsize);
  (*java)->SetByteArrayRegion(java, jb, 0,
                              realsize, (jbyte *)ptr);

#ifdef DEBUG
  fprintf(stderr, "created byte-array\n");
#endif

  ret = (*java)->CallIntMethod(java,
                               curl->write.object,
                               curl->write.mid,
                               jb);

#ifdef DEBUG
  fprintf(stderr, "java-method returned %d\n", ret);
#endif

  return realsize;
}

/*
 * setopt() int + object
 */

JNIEXPORT jint JNICALL Java_CurlGlue_jni_1setopt__IILCurlWrite_2
  (JNIEnv *java, jobject myself, jint jcurl, jint option, jobject object)
{
  jclass cls_local = (*java)->GetObjectClass(java, object);
  jmethodID mid;
  struct curljava *curl = (struct curljava *)jcurl;
  jclass cls;
  jobject obj_global;

  switch(option) {
  case CURLOPT_WRITEFUNCTION:
    /* this makes a reference that'll be alive until we kill it! */
    cls = (*java)->NewGlobalRef(java, cls_local);

#ifdef DEBUG
    printf("setopt int + object, option = %d cls= %p\n",
           option, cls);
#endif

    if(!cls) {
      fputs("couldn't make local reference global\n", stderr);
      return 0;
    }

    /* this is the write callback */
    mid = (*java)->GetMethodID(java, cls, "handleString", "([B)I");
    if(!mid) {
      fputs("no callback method found\n", stderr);
      return 0;
    }

    obj_global = (*java)->NewGlobalRef(java, object);

    curl->write.mid = mid;
    curl->write.cls = cls;
    curl->write.object = obj_global;
    /*curl->write.java = java; stored on perform */

#ifdef DEBUG
    fprintf(stderr,
            "setopt write callback and write file pointer %p, java = %p\n",
            curl, java);
#endif

    curl_easy_setopt(curl->libcurl, CURLOPT_WRITEFUNCTION,
                     curljava_write_callback);
    curl_easy_setopt(curl->libcurl, CURLOPT_FILE,
                     curl);

    break;
  }
  return 0;
}


static int curljava_read_callback(void *ptr,
                                  size_t size,
                                  size_t nmemb,
                                  FILE  *stream)
{
  struct curljava *curl = (struct curljava *)stream;
  size_t realsize = size * nmemb;
  JNIEnv *java = curl->read.java;
  jbyteArray jb;
  int ret;

  jb = (*java)->NewByteArray(java, realsize);
  ret = (*java)->CallIntMethod(java, curl->read.object, curl->read.mid, jb);

  if (ret > 0) {
    if (ret > realsize)
      ret = realsize;

    (*java)->GetByteArrayRegion(java, jb, 0, ret, ptr);
    }

  return ret;
}

/*
 * setopt() int + object
 */

JNIEXPORT jint JNICALL Java_CurlGlue_jni_1setopt__IILCurlRead_2
  (JNIEnv *java, jobject myself, jint jcurl, jint option, jobject object)
{
  jclass cls_local = (*java)->GetObjectClass(java, object);
  jmethodID mid;
  struct curljava *curl = (struct curljava *)jcurl;
  jclass cls;
  jobject obj_global;

  switch(option) {
  case CURLOPT_READFUNCTION:
    /* this makes a reference that'll be alive until we kill it! */
    cls = (*java)->NewGlobalRef(java, cls_local);

#ifdef DEBUG
    printf("setopt int + object, option = %d cls= %p\n",
           option, cls);
#endif

    if(!cls) {
      fputs("couldn't make local reference global\n", stderr);
      return 0;
    }

    /* this is the read callback */
    mid = (*java)->GetMethodID(java, cls, "retrieveString", "([B)I");
    if(!mid) {
      fputs("no callback method found\n", stderr);
      return 0;
    }

    obj_global = (*java)->NewGlobalRef(java, object);

    curl->read.mid = mid;
    curl->read.cls = cls;
    curl->read.object = obj_global;

#ifdef DEBUG
    fprintf(stderr,
            "setopt read callback and read file pointer %p, java = %p\n",
            curl, java);
#endif

    curl_easy_setopt(curl->libcurl, CURLOPT_READFUNCTION,
                     curljava_read_callback);
    curl_easy_setopt(curl->libcurl, CURLOPT_READDATA,
                     curl);

    break;
  }
  return 0;
}

/*
 * setopt() int + object
 */

JNIEXPORT jint JNICALL Java_CurlGlue_jni_1setopt__IILCurlIO_2
  (JNIEnv *java, jobject myself, jint jcurl, jint option, jobject object)
{
  switch(option) {

  case CURLOPT_WRITEFUNCTION:
    return Java_CurlGlue_jni_1setopt__IILCurlWrite_2(java, myself,
                                                     jcurl, option, object);

  case CURLOPT_READFUNCTION:
    return Java_CurlGlue_jni_1setopt__IILCurlRead_2(java, myself,
                                                    jcurl, option, object);
  }

  return 0;
}

JNIEXPORT jint JNICALL Java_CurlGlue_getinfo
  (JNIEnv *java, jobject value)
{
    return 0;
}

JNIEXPORT jint JNICALL Java_CurlGlue_jni_1perform
  (JNIEnv *java, jobject myself, jint jcurl)
{
  struct curljava *curl=(struct curljava*)jcurl;
  curl->write.java = java;
  curl->read.java = java;
  return (jint)curl_easy_perform(curl->libcurl);
}
