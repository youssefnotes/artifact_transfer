# Certificates

1. Create directory `certs` in the APP main directory
`mkdir certs`
_Using Admin:_
2. Copy the public key certificates
`cp ./../../config/crypto-config/peerOrganizations/egyptianmuseum.org/users/Admin@egyptianmuseum.org/msp/admincerts/Admin@egyptianmuseum.org-cert.pem ./`
3. Copy the private key certificates
`cp ./../../config/crypto-config/peerOrganizations/egyptianmuseum.org/users/Admin@egyptianmuseum.org/msp/keystore/* ./`
4. Prepare newDefaultKeyValueStore
`touch EGArtAdmin`
5. Add the following content
```
{
   "name": "EGArtAdmin",
   "mspid": "EGArtMSP",
   "roles": null,
   "affiliation": "",
   "enrollmentSecret": "",
   "enrollment": {
      "signingIdentity": "",
      "identity": {
         "certificate": ""
      }
   }
}
```
6. Fill certificate field with formatted public key
`awk '{printf "%s\\n", $0}' Admin@egyptianmuseum.org-cert.pem > EGArtAdminFormatted.pem`
7. Fill signingIdentity with the name of the private key without any suffix
```
{
   "name": "EGArtAdmin",
   "mspid": "EGArtMSP",
   "roles": null,
   "affiliation": "",
   "enrollmentSecret": "",
   "enrollment": {
      "signingIdentity": "83da26b0f2cef19299ac12b977ebab8ca2417c5653d3b928384e580c6daf8a1e",
      "identity": {
         "certificate": "-----BEGIN CERTIFICATE-----\nMIICqjCCAlGgAwIBAgIUM1iHzNwseMJl58b8bnMa9AgmbX4wCgYIKoZIzj0EAwIw\naDELMAkGA1UEBhMCVVMxFzAVBgNVBAgTDk5vcnRoIENhcm9saW5hMRQwEgYDVQQK\nEwtIeXBlcmxlZGdlcjEPMA0GA1UECxMGRmFicmljMRkwFwYDVQQDExBmYWJyaWMt\nY2Etc2VydmVyMB4XDTE4MDQxNDA5MjMwMFoXDTE5MDQxNDA5MjgwMFowbDELMAkG\nA1UEBhMCVVMxFzAVBgNVBAgTDk5vcnRoIENhcm9saW5hMRQwEgYDVQQKEwtIeXBl\ncmxlZGdlcjEaMAsGA1UECxMEdXNlcjALBgNVBAsTBG9yZzExEjAQBgNVBAMTCW5v\nZGVBZG1pbjBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABLVdIIUYXFK7HfgFjlyL\nAO8HKZXqtrAh9Z7z81YTjax22Gp/RbsbzAb1vQPpoUxtKdBWCWes720rdExKBXGU\nYFCjgdQwgdEwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYE\nFNiyxqJc/LTHnUq14tzodXiLs50AMB8GA1UdIwQYMBaAFPwALtJ/8v+/E9LDLVQ7\n4EGEnwu7MBEGA1UdEQQKMAiCBnVidW50dTBeBggqAwQFBgcIAQRSeyJhdHRycyI6\neyJoZi5BZmZpbGlhdGlvbiI6Im9yZzEiLCJoZi5FbnJvbGxtZW50SUQiOiJub2Rl\nQWRtaW4iLCJoZi5UeXBlIjoidXNlciJ9fTAKBggqhkjOPQQDAgNHADBEAiAlRC6j\nBdV8vxKiSaj+5R5TBOESjaBX4gsKuzipIjq8cwIgW89emMKGZANxOdLIsPB9F4Z4\nOzumdf6ttyZIaFGVfME=\n-----END CERTIFICATE-----\n"
      }
   }
}
```
8. Copy the private key to ~/.hfc-key-store changing the suffix from *_sk* to *-priv*
`test -d ~/.hfc-key-store || mkdir ~/.hfc-key-store && cp -a 83da26b0f2cef19299ac12b977ebab8ca2417c5653d3b928384e580c6daf8a1e_sk ~/.hfc-key-store/83da26b0f2cef19299ac12b977ebab8ca2417c5653d3b928384e580c6daf8a1e-priv`