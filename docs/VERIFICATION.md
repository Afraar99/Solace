# Verification

Official Solace APKs on [GitHub Releases](https://github.com/Afraar99/Solace/releases) are signed with the Solace release keystore (not Google Play App Signing).

Verify with [apksigner](https://developer.android.com/studio/command-line/apksigner.html#options-verify):

```sh
apksigner verify --print-certs --verbose Solace-1.2.0-arm64-v8a.apk
```

Fingerprints for the official release signing certificate:

```text
dn: CN=Solace, OU=Mobile, O=Mohamed Afraar, L=Colombo, ST=Western, C=LK
SHA-256 digest: 15b1517d9f72e2c159fd3d38a6f56e123e41300df664cfdab32a8399ea16b902
SHA-1 digest: 47e9acb05411e302a4afa8985cf316a1cf9d107e
MD5 digest: 24ebc29679dad79a221a276ab9f643cf
```

Only install APKs whose certificate matches these digests (or that you built and signed yourself).
