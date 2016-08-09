/*
** Ugly hack from a Java newbie to fetch the curl defines from the
** curl.h header for creating a list inside the CurlGlue JNI class. 
** Reads a preprocessed compiler output from STDIN and parses with
** a regex for the wanted defines, then writes them to STDOUT. 
** Initial version 2008-01-26 hacked by Guenter.
**
** $Id: MakeCurlGlue.java 42 2008-10-20 09:27:21Z patrick $
*/
import java.io.*;
import java.util.regex.*;

public class MakeCurlGlue
{
  public static void main( String[] args )
  {
    if( args.length < 1 ) {
      System.err.println( "Error: Parameter missing." );
      System.err.println( "Usage: java CreateCurlGlue [STDIN] InputFile" );
    }
    else
      try {
        String v = MakeCurlGlue.GetCurlVersion( args[0] );
        MakeCurlGlue.GetCurlDefines( v );
        System.exit( 0 );
      } catch( IOException ex ) {
        System.out.println( "Error: " + ex );
      }
    System.exit( 1 );
  }

  public static String GetCurlVersion( String sFileSrc )
  throws IOException
  {
    String s;
    BufferedReader fis = new BufferedReader(
                         new InputStreamReader(
                         new FileInputStream( sFileSrc ) ) );

    while( null != (s = fis.readLine()) )
    {
      if ( ( s.indexOf("#define LIBCURL_VERSION") ) != -1 )
      {
        s = s.substring( s.indexOf("\"") + 1, s.length() - 1 );
        return ( s );
      }
    }
    return "N/A";
  }

  public static void GetCurlDefines( String sVersion )
  throws IOException
  {
    String ls = System.getProperty( "line.separator" );
    String s;
    BufferedReader fis = new BufferedReader(
                         new InputStreamReader( System.in ) );

    s = "// Automatically created class with defines extracted from curl.h." + ls +
        "// The curl class is a JNI wrapper for libcurl." + ls +
        "// This is meant as a raw, crude and low-level interface to libcurl." + ls +
        "// this list is up-to-date as of cURL " + sVersion + ls + ls +
        "public class CurlGlue" + ls +
        "{" + ls +
        "  // start of generated list" + ls;
    System.out.print( s );

    Pattern p = Pattern.compile( "(CURLOPT_[A-Z_]+)\\s+=\\s+(\\d+)\\s+\\+\\s+(\\d+)" );
    while( null != (s = fis.readLine()) )
    {
      for (Matcher m = p.matcher( s ); m.find(); )
      {
        s = "  public static final int " + m.group( 1 ) + " = " +
            ( Integer.parseInt( m.group( 2 ) ) + Integer.parseInt( m.group( 3 ) ) ) + ";" + ls;
        System.out.print( s );
      }
    }
    fis.close();

    s= "  // end of generated list" + ls + ls;
    System.out.print( s );
    s = "  public CurlGlue() {" + ls +
        "    try {" + ls +
        "      curljava_handle = jni_init();" + ls +
        "    } catch (Exception e) {" + ls +
        "      e.printStackTrace();" + ls +
        "    }" + ls +
        "  }" + ls + ls;
    System.out.print( s );
    s = "  public void finalize() {" + ls +
        "    jni_cleanup(curljava_handle);" + ls +
        "  }" + ls + ls +
        "  private int curljava_handle;" + ls + ls +
        "  // constructor and destructor for the libcurl handle" + ls +
        "  private native int jni_init();" + ls +
        "  private native void jni_cleanup(int curljava_handle);" + ls +
        "  private native synchronized int jni_perform(int curljava_handle);" + ls + ls;
    System.out.print( s );
    s = "  // Instead of varargs, we have different functions for each" + ls +
        "  // kind of type setopt() can take" + ls +
        "  private native int jni_setopt(int libcurl, int option, String value);" + ls +
        "  private native int jni_setopt(int libcurl, int option, int value);" + ls +
        "  private native int jni_setopt(int libcurl, int option, CurlWrite value);" + ls +
        "  private native int jni_setopt(int libcurl, int option, CurlRead value);" + ls +
        "  private native int jni_setopt(int libcurl, int option, CurlIO value);" + ls + ls +
        "  public native int getinfo();" + ls +
        "  public static native String version();" + ls + ls;
    System.out.print( s );
    s = "  public int perform() {" + ls +
        "    return jni_perform(curljava_handle);" + ls +
        "  }" + ls +
        "  public int setopt(int option, int value) {" + ls +
        "    return jni_setopt(curljava_handle, option, value);" + ls +
        "  }" + ls +
        "  public int setopt(int option, String value) {" + ls +
        "    return jni_setopt(curljava_handle, option, value);" + ls +
        "  }" + ls;
    System.out.print( s );
    s = "  public int setopt(int option, CurlWrite value) {" + ls +
        "    return jni_setopt(curljava_handle, option, value);" + ls +
        "  }" + ls +
        "  public int setopt(int option, CurlRead value) {" + ls +
        "    return jni_setopt(curljava_handle, option, value);" + ls +
        "  }" + ls +
        "  public int setopt(int option, CurlIO value) {" + ls +
        "    return jni_setopt(curljava_handle, option, value);" + ls +
        "  }" + ls + ls;
    System.out.print( s );
    s = "  static {" + ls +
        "    try {" + ls +
        "      // Loading up the shared JNI" + ls +
        "      System.loadLibrary(\"curljava\");" + ls +
        "    } catch (Exception e) {" + ls +
        "      e.printStackTrace();" + ls +
        "    }" + ls +
        "  }" + ls + ls +
        "}" + ls + ls;
    System.out.print( s );
  }
}


