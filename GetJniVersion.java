/*
** Quick hack from a Java newbie to fetch the function names
** from the JNI header for creating an export list. 
** Version: 0.1.0 - 2008-01-24 by Guenter.
**
** $Id: GetJniVersion.java 42 2008-10-20 09:27:21Z patrick $
*/
import java.io.*;

public class GetJniVersion
{
  public static void main( String[] args )
  {
    if( args.length < 2 ) {
      System.out.println( "Error: Parameter missing." );
      System.out.println( "Usage: java GetJniVersion InputFile OutputFile" );
    }
    else
      try {
        GetJniVersion.extract( args[0], args[1] );
        System.exit( 0 );
      } catch( IOException ex ) {
        System.out.println( "Error: " + ex );
      }
    System.exit( 1 );
  }

  public static void extract( String sFileSrc, String sFileDst )
  throws IOException
  {
    String s;
    int i;

    BufferedReader fis = new BufferedReader(
                         new InputStreamReader(
                         new FileInputStream( sFileSrc ) ) );
    BufferedWriter fos = new BufferedWriter(
                         new OutputStreamWriter(
                         new FileOutputStream( sFileDst, false ) ) );
    s = "# JNI Version number extracted from " + sFileSrc;
    fos.write( s, 0, s.length() );
    fos.newLine();
    while( null != (s = fis.readLine()) )
    {
      if ( ( i = s.indexOf("CURLJAVA_MAJOR=") ) != -1)
      {
        s = s.substring( i );
        fos.write( s.trim(), 0, s.length() );
        fos.newLine();
      }
      if ( ( i = s.indexOf("CURLJAVA_MINOR=") ) != -1)
      {
        s = s.substring( i );
        fos.write( s.trim(), 0, s.length() );
        fos.newLine();
      }
      if ( ( i = s.indexOf("CURLJAVA_MICRO=") ) != -1)
      {
        s = s.substring( i );
        fos.write( s.trim(), 0, s.length() );
        fos.newLine();
      }
    }
    fos.newLine();
    fos.newLine();
    fos.flush();
    fos.close();
    fis.close();
  }
}


