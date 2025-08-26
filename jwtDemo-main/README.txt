
JWT Signing demo using bouncycastle and auth0 libraries

Steps to Generate ECDSA Key Pair:

1. Generate Private Key. Do not share your private key.
> openssl ecparam -name prime256v1 -genkey -noout -out private-key.pem

2. Generate Public Key. This is the public key you will share with Apple Business Register.
> openssl ec -in private-key.pem -pubout -out public-key.pem


Proximity Reader Documentation

Generating reader tokens for the Verifier API:
https://developer.apple.com/documentation/proximityreader/generating-reader-tokens-for-the-verifier-api
