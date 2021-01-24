import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:pointycastle/pointycastle.dart';

// General Idea:
// 1. Generate RSA key pair
// 2. Store key pair as string using PEM format.
// 3. When user adds friends, store their public key (with PEM format)

// These were helpful:
// https://medium.com/flutter-community/asymmetric-key-generation-in-flutter-ad2b912f3309
// https://github.com/bcgit/pc-dart/blob/master/tutorials/rsa.md

/// generates and stores an RSA key pair for this user
setupCrypto() async { // may need to use Isolate if this reduces performance
  final keyPair = _generateRSAKeyPair(_getSecureRandom());
  // TODO
}

AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _generateRSAKeyPair(
    SecureRandom secureRandom,
    {int bitLength = 2048}) {
  final publicExponent = BigInt.parse('65537');

  // setup generator
  final keyGen = RSAKeyGenerator()
    ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(publicExponent, bitLength, 64),
        secureRandom));

  final pair = keyGen.generateKeyPair();

  // Cast the generated key pair into the RSA key types
  final myPublic = pair.publicKey as RSAPublicKey;
  final myPrivate = pair.privateKey as RSAPrivateKey;

  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(myPublic, myPrivate);
}

/// get secure source of randomness, using dart's math library to get seed
SecureRandom _getSecureRandom() {
  final secureRandom = FortunaRandom();

  final seedSource = Random.secure();
  final seeds = <int>[];
  for (int i = 0; i < 32; i++) {
    seeds.add(seedSource.nextInt(255));
  }
  secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

  return secureRandom;
}

String _encodePrivateKeyInPem(RSAPrivateKey key) {
  final asn = ASN1Sequence();
  // TODO
  final base64Data = base64.encode(asn.encodedBytes);
  return '-----BEGIN PRIVATE KEY-----\n$base64Data\n-----END PRIVATE KEY-----';
}

/// encodes RSA public key into PKCS#1 format
String _encodePublicKeyInPem(RSAPublicKey key) {
  final asn = ASN1Sequence();

  asn.add(ASN1Integer(key.modulus));
  asn.add(ASN1Integer(key.exponent));

  final base64Data = base64.encode(asn.encodedBytes);
  return '-----BEGIN PUBLIC KEY-----\n$base64Data\n-----END PUBLIC KEY-----';
}
