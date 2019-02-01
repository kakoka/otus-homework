[vagrant@centralServer ~]$ curl -I 192.168.254.1
HTTP/1.1 200 OK
Server: nginx/1.12.2
Date: Thu, 31 Jan 2019 13:29:58 GMT
Content-Type: text/html
Content-Length: 3700
Last-Modified: Tue, 06 Mar 2018 09:26:21 GMT
Connection: keep-alive
ETag: "5a9e5ebd-e74"
Accept-Ranges: bytes

[vagrant@centralServer ~]$ curl -I 192.168.0.2
curl: (7) Failed connect to 192.168.0.2:80; Connection refused

[vagrant@centralServer ~]$ curl -I 192.168.0.2:8080
HTTP/1.1 200 OK
Server: nginx/1.12.2
Date: Thu, 31 Jan 2019 13:30:46 GMT
Content-Type: text/html
Content-Length: 3700
Last-Modified: Tue, 06 Mar 2018 09:26:21 GMT
Connection: keep-alive
ETag: "5a9e5ebd-e74"
Accept-Ranges: bytes

[vagrant@centralServer ~]$ sudo tail /var/log/nginx/access.log
192.168.254.1 - - [31/Jan/2019:13:29:58 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.29.0" "-"
192.168.0.2 - - [31/Jan/2019:13:30:46 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.29.0" "-"
