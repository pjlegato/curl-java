/*
** $Id: CurlRead.java 42 2008-10-20 09:27:21Z patrick $
*/
public interface CurlRead
{
  /**
   * retrieveString gets called by libcurl to obtain chunks of data
   * to send to the remote server.
   */
  int retrieveString(byte s[]);
}

