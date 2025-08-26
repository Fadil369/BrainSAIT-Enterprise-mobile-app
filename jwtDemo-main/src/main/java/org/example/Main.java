package org.example;


import com.auth0.jwt.JWT;
import com.auth0.jwt.JWTCreator;
import com.auth0.jwt.algorithms.Algorithm;
import org.bouncycastle.asn1.x509.SubjectPublicKeyInfo;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.bouncycastle.openssl.PEMKeyPair;
import org.bouncycastle.openssl.PEMParser;
import org.bouncycastle.openssl.jcajce.JcaPEMKeyConverter;
import org.bouncycastle.util.io.pem.PemReader;
import org.springframework.core.io.ClassPathResource;

import java.io.InputStream;
import java.io.InputStreamReader;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.Security;
import java.security.interfaces.ECPrivateKey;
import java.security.interfaces.ECPublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.time.Instant;
import java.util.Date;
import java.util.Map;


public class Main {

    /**
     * This method reads private key PEM file from classPath resource and converts into ECPrivateKey
     * @param filename of private key PEM located in app resources
     * @return generated private key from security provider
     */
    private static ECPrivateKey getECPrivateKey(String filename) throws Exception {

        InputStream inputStream = new ClassPathResource(filename).getInputStream();
        PemReader pemReader = new PemReader(new InputStreamReader(inputStream));

        PEMParser pemParser = new PEMParser(pemReader);
        Object obj = pemParser.readObject();
        KeyPair kp = new JcaPEMKeyConverter().getKeyPair((PEMKeyPair) obj);

        return (ECPrivateKey) kp.getPrivate();
    }

    /**
     * This method reads public key PEM file from classPath resource and converts into ECPublicKey
     * @param filename of public key PEM located in app resources
     * @return generated public key from security provider
     */
    private static ECPublicKey getECPublicKey(String filename) throws Exception {

        InputStream inputStream = new ClassPathResource(filename).getInputStream();
        PemReader pemReader = new PemReader(new InputStreamReader(inputStream));

        PEMParser pemParser = new PEMParser(pemReader);
        Object obj = pemParser.readObject();

        SubjectPublicKeyInfo subjectPublicKeyInfo = (SubjectPublicKeyInfo) obj;
        X509EncodedKeySpec encodedKeySpec = new X509EncodedKeySpec(subjectPublicKeyInfo.getEncoded());
        KeyFactory keyFactory = KeyFactory.getInstance("EC");

        return (ECPublicKey) keyFactory.generatePublic(encodedKeySpec);
    }

    /**
     * This method creates JWT Builder with JWT claims. For more details, visit
     * https://developer.apple.com/documentation/proximityreader/generating-reader-tokens-for-the-verifier-api
     * @return JWT Builder with required claims
     */
    private static JWTCreator.Builder getJwtBuilder() {

        // Set algorithm to ES256, and type to Json Web Token (JWT)
        Map<String, Object> headerClaims = Map.of("alg", "ES256", "typ", "JWT");

        return JWT.create()
                .withIssuedAt(Date.from(Instant.now()))  // Token creation time in Epoch
                .withAudience("apple-identityservices-v1")  // Audience is set to apple-identityservices-v1
                .withExpiresAt(Date.from(Instant.now().plusSeconds(300)))  // Expiry no later than 5 minutes of iat
                .withKeyId("ABCDEFGHIJ")  // Represents your server's signing key you onboarded to Apple Business Register
                .withIssuer("KLMNOPQRST")  // Brand ID you obtain from Apple Business Register
                .withSubject("UVWXYZ1234")  // Reader instance identifier obtained from your app
                .withHeader(headerClaims);
    }

    public static void main(String[] args) throws Exception {

        Security.addProvider(new BouncyCastleProvider());

        ECPrivateKey sk = getECPrivateKey("private-key.pem");
        ECPublicKey pk = getECPublicKey("public-key.pem");

        JWTCreator.Builder jwtBuilder = getJwtBuilder();

        // Sign JWT
        String result = jwtBuilder.sign(Algorithm.ECDSA256(null, sk));
        System.out.println("JWT Signed Successfully: " + result);

        // Verify JWT
        JWT.require(Algorithm.ECDSA256(pk, null)).build().verify(result);
        System.out.println("JWT Verified Successfully: " + result);
    }
}
