<div class='scroll_area'>
<code><pre>
Xythos Client 4.2 (build 109) on WXP
Service: WebDAV:\\www.sharemation.com\maxdunn
Proxy: none
Sharing Level: 2
Secure connection: No
----------------------

==== Request ===================================================================
OPTIONS /maxdunn/ HTTP/1.1
Content-Length: 0
Accept: */*
Host: www.sharemation.com:80
Connection: Keep-Alive
User-Agent: Xythos Client 4.2 (build 109)



==== Reply ============================= reply time 47 ms ======================
HTTP/1.1 401 Unauthorized
Date: Tue, 21 Nov 2006 20:09:11 GMT
Server: Apache-Coyote/1.1
WWW-Authenticate: BASIC realm=&quot;www.sharemation.com&quot;
WWW-Authenticate: Digest realm=&quot;www.sharemation.com&quot;, stale=false, nonce=&quot;4ecc229d12691ff7a46a739dade6c7d9&quot;, qop=&quot;auth&quot;, algorithm=&quot;MD5&quot;
Cache-Control: no-cache
Pragma: no-cache
Content-Type: text/html;charset=UTF-8
Content-Length: 182
Via: 1.1 www.sharemation.com
Connection: close

&lt;html&gt;&lt;title&gt;Error 401&lt;/title&gt;&lt;body&gt;
Error: 401
&lt;BR&gt;&lt;H1&gt;Forbidden&lt;/H1&gt;&lt;BR&gt;That action is not authorized.  Please ensure that you are authenticated.&lt;BR&gt;
&lt;p&gt;&lt;p&gt;&lt;/p&gt;&lt;/p&gt;
&lt;/body&gt;&lt;/html&gt;


==== Request ===================================================================
OPTIONS /maxdunn/ HTTP/1.1
Content-Length: 0
Accept: */*
Host: www.sharemation.com:80
Connection: Keep-Alive
User-Agent: Xythos Client 4.2 (build 109)
Authorization: Digest username=&quot;maxdunn&quot;, realm=&quot;www.sharemation.com&quot;, nonce=&quot;4ecc229d12691ff7a46a739dade6c7d9&quot;, uri=&quot;/maxdunn/&quot;, nc=00000001, cnonce=&quot;CA8778645DEC0902&quot;, qop=&quot;auth&quot;, response=&quot;c2c37f8bc9569de1d952f1618575e2bf&quot;



==== Reply ============================= reply time 62 ms ======================
HTTP/1.1 200 OK
Date: Tue, 21 Nov 2006 20:09:11 GMT
Server: Apache-Coyote/1.1
Set-Cookie: XythosSessionID1=[B@368648--740444047; Expires=Wed, 22-Nov-2006 20:09:11 GMT; Path=/
DAV: 1,2, access-control, ticket, version-control
MS-Author-Via: DAV
Allow: OPTIONS, PROPFIND, PROPPATCH, LOCK, UNLOCK, DELETE, GET, HEAD, MOVE, COPY, ACL, SEARCH
DASL: &lt;DAV:basicsearch&gt;
Accept-Ranges: bytes
Xythos-WFS-Version: Xythos WebFile Server 5.0.24.1
Content-Type: text/html; charset=UTF-8
Content-Length: 0
Via: 1.1 www.sharemation.com
Connection: close



==== Request ===================================================================
PROPFIND /maxdunn/ HTTP/1.1
Content-Type: text/xml
Content-Length: 99
Accept: */*
Host: www.sharemation.com:80
Connection: Keep-Alive
User-Agent: Xythos Client 4.2 (build 109)
Cookie: XythosSessionID1=[B@368648--740444047
Depth: 0
Authorization: Digest username=&quot;maxdunn&quot;, realm=&quot;www.sharemation.com&quot;, nonce=&quot;4ecc229d12691ff7a46a739dade6c7d9&quot;, uri=&quot;/maxdunn/&quot;, nc=00000002, cnonce=&quot;CA8778645DEC0902&quot;, qop=&quot;auth&quot;, response=&quot;8fa22aab312db0f8329df4b748ec1ac9&quot;

&lt;?xml version=&quot;1.0&quot; ?&gt;
&lt;propfind xmlns=&quot;DAV:&quot;&gt;
 &lt;prop&gt;
  &lt;displayname/&gt;
 &lt;/prop&gt;
&lt;/propfind&gt;


==== Reply ============================= reply time 62 ms ======================
HTTP/1.1 207 Multi-Status
Date: Tue, 21 Nov 2006 20:09:11 GMT
Server: Apache-Coyote/1.1
Content-Type: text/xml;charset=UTF-8
Content-Length: 490
Via: 1.1 www.sharemation.com
Connection: close

&lt;?xml version=&quot;1.0&quot; encoding=&quot;utf-8&quot; ?&gt;
&lt;D:multistatus xmlns:D=&quot;DAV:&quot; xmlns:XS=&quot;http://www.w3.org/2001/XMLSchema&quot; xmlns:XSI=&quot;http://www.w3.org/2001/XMLSchema-instance&quot; xmlns:SOAP-ENC=&quot;http://schemas.xmlsoap.org/soap/encoding/&quot;&gt;
&lt;D:response&gt;
&lt;D:href&gt;http://www.sharemation.com/maxdunn/&lt;/D:href&gt;
     &lt;D:propstat&gt;
        &lt;D:prop&gt;
&lt;D:displayname&gt;&lt;![CDATA[maxdunn]]&gt;&lt;/D:displayname&gt;
      &lt;/D:prop&gt;
       &lt;D:status&gt;HTTP/1.1 200 OK&lt;/D:status&gt;
     &lt;/D:propstat&gt;
&lt;/D:response&gt;
&lt;/D:multistatus&gt;


==== Request ===================================================================
OPTIONS /maxdunn/ HTTP/1.1
Content-Type: text/xml
Content-Length: 137
Accept: */*
Host: www.sharemation.com:80
Connection: Keep-Alive
User-Agent: Xythos Client 4.2 (build 109)
Cookie: XythosSessionID1=[B@368648--740444047
Accept-Language: en-US, en;q=0.8
Authorization: Digest username=&quot;maxdunn&quot;, realm=&quot;www.sharemation.com&quot;, nonce=&quot;4ecc229d12691ff7a46a739dade6c7d9&quot;, uri=&quot;/maxdunn/&quot;, nc=00000003, cnonce=&quot;CA8778645DEC0902&quot;, qop=&quot;auth&quot;, response=&quot;a76a7d1507f44013b9025d49bbec804f&quot;

&lt;?xml version=&quot;1.0&quot; ?&gt;
&lt;options xmlns=&quot;DAV:&quot;&gt;
  &lt;x:webuilinksquery xmlns:x=&quot;http://www.xythos.com/namespaces/StorageServer&quot;/&gt;
&lt;/options&gt;


==== Reply ============================= reply time 63 ms ======================
HTTP/1.1 200 OK
Date: Tue, 21 Nov 2006 20:09:12 GMT
Server: Apache-Coyote/1.1
DAV: 1,2, access-control, ticket, version-control
MS-Author-Via: DAV
Allow: OPTIONS, PROPFIND, PROPPATCH, LOCK, UNLOCK, DELETE, GET, HEAD, MOVE, COPY, ACL, SEARCH
DASL: &lt;DAV:basicsearch&gt;
Accept-Ranges: bytes
Xythos-WFS-Version: Xythos WebFile Server 5.0.24.1
Cache-Control: no-cache
Pragma: no-cache
Content-Type: text/xml;charset=UTF-8
Content-Length: 1029
Via: 1.1 www.sharemation.com
Connection: close

&lt;?xml version=&quot;1.0&quot; encoding=&quot;utf-8&quot; ?&gt;
&lt;D:options-response xmlns:D=&quot;DAV:&quot; xmlns:x=&quot;http://www.xythos.com/namespaces/StorageServer&quot;&gt;
&lt;x:webuilinks&gt;
&lt;x:webuilink&gt;&lt;x:id&gt;&lt;x:resourceInfoLink/&gt;&lt;/x:id&gt;
  &lt;x:webuiurl&gt;/xythoswfs/webui&lt;x:path/&gt;?action=frameset&amp;amp;subaction=infopage&amp;amp;wfc=yes&amp;amp;stk=2537D6DE3F0AA2F&lt;/x:webuiurl&gt;
  &lt;x:defaultdisplay xml:lang=&quot;en_US&quot;&gt;Manage&lt;/x:defaultdisplay&gt;
&lt;/x:webuilink&gt;
&lt;x:webuilink&gt;&lt;x:id&gt;&lt;x:accessLogViewLink/&gt;&lt;/x:id&gt;
  &lt;x:webuiurl&gt;/xythoswfs/webui&lt;x:path/&gt;?action=log&amp;amp;subaction=print&amp;amp;wfc=yes&amp;amp;stk=2537D6DE3F0AA2F&lt;/x:webuiurl&gt;
  &lt;x:appliestoresources&gt;&lt;D:resourcetype/&gt;&lt;/x:appliestoresources&gt;
  &lt;x:defaultdisplay xml:lang=&quot;en_US&quot;&gt;File Access Log&lt;/x:defaultdisplay&gt;
&lt;/x:webuilink&gt;
&lt;x:webuilink&gt;&lt;x:id&gt;&lt;x:resourceCommentsViewLink/&gt;&lt;/x:id&gt;
  &lt;x:webuiurl&gt;/xythoswfs/webui&lt;x:path/&gt;?action=details&amp;amp;subaction=printcomments&amp;amp;wfc=yes&amp;amp;stk=2537D6DE3F0AA2F&lt;/x:webuiurl&gt;
  &lt;x:defaultdisplay xml:lang=&quot;en_US&quot;&gt;Comments&lt;/x:defaultdisplay&gt;
&lt;/x:webuilink&gt;
&lt;/x:webuilinks&gt;
&lt;/D:options-response&gt;


==== Request ===================================================================
PROPFIND /maxdunn/ HTTP/1.1
Content-Type: text/xml
Content-Length: 256
Accept: */*
Host: www.sharemation.com:80
Connection: Keep-Alive
User-Agent: Xythos Client 4.2 (build 109)
Cookie: XythosSessionID1=[B@368648--740444047
Depth: 1
Translate: f
Apply-To-Redirect-Ref: T
Authorization: Digest username=&quot;maxdunn&quot;, realm=&quot;www.sharemation.com&quot;, nonce=&quot;4ecc229d12691ff7a46a739dade6c7d9&quot;, uri=&quot;/maxdunn/&quot;, nc=00000004, cnonce=&quot;CA8778645DEC0902&quot;, qop=&quot;auth&quot;, response=&quot;39dc83afdb635f67612cfe784d9ae83e&quot;

&lt;?xml version=&quot;1.0&quot; ?&gt;
&lt;propfind xmlns=&quot;DAV:&quot;&gt;
 &lt;prop&gt;
  &lt;getcontenttype/&gt;
  &lt;creationdate/&gt;
  &lt;getlastmodified/&gt;
  &lt;getcontentlength/&gt;
  &lt;resourcetype/&gt;
  &lt;lockdiscovery/&gt;
  &lt;checked-out/&gt;
  &lt;checked-in/&gt;
  &lt;reftarget/&gt; &lt;/prop&gt;
&lt;/propfind&gt;



==== Reply ============================= reply time 1984 ms ====================
HTTP/1.1 207 Multi-Status
Date: Tue, 21 Nov 2006 20:09:19 GMT
Server: Apache-Coyote/1.1
Content-Type: text/xml;charset=UTF-8
Content-Length: 1542
Via: 1.1 www.sharemation.com
Connection: close

&lt;&lt;directory listing&gt;&gt;


12:09:14 2006/11/21 Retrieving contents of E:\... OK

</pre></code>
</div>
