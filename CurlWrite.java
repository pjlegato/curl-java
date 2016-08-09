/*
** $Id: CurlWrite.java 42 2008-10-20 09:27:21Z patrick $
*/
public interface CurlWrite
{
  /**
   * handleString gets called by libcurl on each chunk of data
   * we receive from the remote server
   */
  int handleString(byte s[]);
}

