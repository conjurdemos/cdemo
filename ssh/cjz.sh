#!/bin/sh
set -e

# Implementation note: 'tee' is used as a sudo-friendly 'cat' to populate a file with the contents provided below.

sudo -n tee /etc/conjur.conf > /dev/null << EOF
account: dev
appliance_url: https://conjur/api
cert_file: /etc/conjur-dev.pem
netrc_path: /etc/conjur.identity
plugins: []
EOF

sudo -n tee /etc/conjur-dev.pem > /dev/null << EOF
-----BEGIN CERTIFICATE-----
MIIDQjCCAiqgAwIBAgIVALqX0m7HrKhD4Uk9lFlOIoNydCp7MA0GCSqGSIb3DQEB
CwUAMDsxDDAKBgNVBAoTA2RldjESMBAGA1UECxMJQ29uanVyIENBMRcwFQYDVQQD
Ew5jeWJlcmFyay5sb2NhbDAeFw0xNzExMDYyMTUzNTVaFw0yNzExMDQyMTUzNTVa
MBkxFzAVBgNVBAMMDmN5YmVyYXJrLmxvY2FsMIIBIjANBgkqhkiG9w0BAQEFAAOC
AQ8AMIIBCgKCAQEAvM4J/GIu+HH0ML3PL1bl8/BQTa7BCDDEfHD9spkFkOA145OQ
KrBqRXvNCy0DO0hNg50a1343MmN3z/kA2SQO5b6WRhO0XZAs/qJxol5vDwmuhYaj
oWfo1rfTZ4uWTq+/JsxVJlYfpgYdwZ8otJP5FWMoDjWaDRC8ERlwIVLQzDiHdgLy
aZLQA4o/jIj3Ym+PpVQs9ga9VvdTj+GJriYWPIwkJ0CW9V0fO8oQnUFeYe9qsFHM
rcSbXTR19T6TNPICl1VTTHvsgqay/xnW1XQ04cW1FCVH9Fo0FmDWmzofI4e5Cx47
gD/u83d4e4yTUicTQOapSI89dDPIwVADnTyLTQIDAQABo18wXTAOBgNVHQ8BAf8E
BAMCBaAwHQYDVR0OBBYEFNo5o+5ea0sNMlW/75VgGJCv2AcJMCwGA1UdEQQlMCOC
DmN5YmVyYXJrLmxvY2Fsgglsb2NhbGhvc3SCBmNvbmp1cjANBgkqhkiG9w0BAQsF
AAOCAQEAbOkn3UkoI0j2jglBN1Dz45ne+ujMfQgO7oCFYGwUSZhP717ZkLltO6gG
PVaeI0D4kdLZiGA2IJz4dn+q4IN5T6LhgaChnpBBJbTH5S1popBw1gjxt4YTK5Gk
MnfmRXlPKMgir/EbsyWXVRuFK7LmP20irQdDVTyutxJpH1zwuZnJnlGxPcYVk/Gz
ja+npLxBx0tdYcgI2mxLhnlSRjOdrPPfeKUdtCfr+scWKTFx3AuQP4MW+XjVxBNV
EPkvle/iYWVkbRafmQl5CIimvXsvebXQ2RA8x5Ghs6Y7XXGYRWSZSOzj91o25/aD
kpHAvc5gn9btn7Cc8fDEIMZt8Vr96A==
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIDhjCCAm6gAwIBAgIJAKICRrRs6JwDMA0GCSqGSIb3DQEBCwUAMDsxDDAKBgNV
BAoTA2RldjESMBAGA1UECxMJQ29uanVyIENBMRcwFQYDVQQDEw5jeWJlcmFyay5s
b2NhbDAeFw0xNzExMDYyMTUzNTNaFw0yNzExMDQyMTUzNTNaMDsxDDAKBgNVBAoT
A2RldjESMBAGA1UECxMJQ29uanVyIENBMRcwFQYDVQQDEw5jeWJlcmFyay5sb2Nh
bDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMpmdcR9BVxoOQLSubyz
+NI5RINhVrVKtgaE8v4R/x9xZRuZkbwCL4XjqSO0zult6fUij9dz5y1M2ggfS46M
Vx0GTOZmxI719sgPA0xmurnEdNd6AwVN0Z30NrXHwlS7O5ZSYsynDY/2h1QWs1/b
zHQiSHsvcIWyCODQA/3ERoogqvCWVS9MnXzy4C3zyyuzoym4yQ/vF1lBNd54G43h
ZhHZnB0zSQk/frdkvQiR+N9XWFDic6Fvy8ptz8N1N9e2uLBxQ1d6L8JScobqFDmC
9wWWrodedOvjJXi1XQMPxsxYhqjO52K5nc8Ejw6Y6ACIJBW0fXd+7/Z1lRoSrtN3
nPkCAwEAAaOBjDCBiTAsBgNVHREEJTAjgg5jeWJlcmFyay5sb2NhbIIJbG9jYWxo
b3N0ggZjb25qdXIwHQYDVR0OBBYEFIv5+iHhl0kcAVUNnJ+8yNkCbcFlMB8GA1Ud
IwQYMBaAFIv5+iHhl0kcAVUNnJ+8yNkCbcFlMAwGA1UdEwQFMAMBAf8wCwYDVR0P
BAQDAgHmMA0GCSqGSIb3DQEBCwUAA4IBAQCJ5ft3Ns/1EOw3Jz/lp+ZERorCbLd3
n9UpTMzJmArtNniGzek2UASrcAyfn73XUzuTdnDvy3e9vzFfjPVwUN8OqKS3tEN4
20GBHznFOkiv5eLfJNj4DXwKbscDcr1ZdaFfFGrfohXbJeTQvme1CeOUkxPLso30
z+28r+3027kwY3vtRwoEwZ1U6QcILZVmnjfVqXw03YmlCAFyBDkOnS2fvH9g0Kk5
l1Gnau81lfhyNs3IZs6BJQ785UxryEJw5ALEx+RGvs0dpt1Rd+T7g7su1kLoflaJ
zGq+0kYcz/2/lmD08iJhmDOsKztQ8GidX2ZoQMgqQ7/kNMNmFxZxVAwY
-----END CERTIFICATE-----
EOF

sudo -n touch /etc/conjur.identity
sudo -n chmod 600 /etc/conjur.identity
sudo -n tee /etc/conjur.identity > /dev/null << EOF
machine https://conjur/api/authn
        login host/foo
        password 2f0hya82dg022224e67mm3c59c1118nxdcj1qbrc7g215539jfy57dm
EOF

curl -L https://www.opscode.com/chef/install.sh | sudo -n bash
sudo -n chef-solo --recipe-url https://github.com/conjur-cookbooks/conjur/releases/download/v0.4.3/conjur-v0.4.3.tar.gz -o conjur
