import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nudge_me/main_pages.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:random_string/random_string.dart';
import 'package:shared_preferences/shared_preferences.dart';

// General Idea:
// 1. Generate RSA key pair
// 2. Store key pair as string using PEM format.
// 3. When user adds friends, store their public key (with PEM format)

// These were helpful:
// https://medium.com/flutter-community/asymmetric-key-generation-in-flutter-ad2b912f3309
// https://github.com/bcgit/pc-dart/blob/master/tutorials/rsa.md

const RSA_PRIVATE_PEM_KEY = 'rsa_private_pem';
const RSA_PUBLIC_PEM_KEY = 'rsa_public_pem';
const USER_IDENTIFIER_KEY = 'user_identifier';
const USER_PASSWORD_KEY = 'user_password';

/// generates and stores an RSA key pair for this user
/// NOTE: may need to use Isolate if this reduces performance
Future<void> setupCrypto() async {
  // this takes a while so I use multithreading
  final keyPair = await compute<SecureRandom,
          AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>>(
      _generateRSAKeyPair, _getSecureRandom());
  // using fingerprint as identifier:
  final identifier = _getFingerprint(keyPair.publicKey);
  final password = randomAlphaNumeric(20);

  final prefs = await SharedPreferences.getInstance();
  prefs.setString(
      RSA_PRIVATE_PEM_KEY, _encodePrivateKeyInPem(keyPair.privateKey));
  prefs.setString(RSA_PUBLIC_PEM_KEY, _encodePublicKeyInPem(keyPair.publicKey));
  prefs.setString(USER_IDENTIFIER_KEY, identifier);
  prefs.setString(USER_PASSWORD_KEY, password);

  _addUserBackend(identifier, password);
}

Future<void> _addUserBackend(String identifier, String password) async {
  final body = jsonEncode({"identifier": identifier, "password": password});
  http
      .post(BASE_URL + "/user/new",
          headers: {"Content-Type": "application/json"}, body: body)
      .then((response) {
    print("Response body: ${response.body}");
    // TODO: notify user in case something went wrong
  });
}

/// encodes RSA private key into PKCS#1 format
String _encodePrivateKeyInPem(RSAPrivateKey key) {
  final asn = ASN1Sequence();

  asn.add(ASN1Integer(BigInt.zero)); // version
  asn.add(ASN1Integer(key.n)); // modulus
  asn.add(ASN1Integer(key.exponent)); // public exponent
  asn.add(ASN1Integer(key.privateExponent));
  asn.add(ASN1Integer(key.p));
  asn.add(ASN1Integer(key.q));
  asn.add(ASN1Integer(key.privateExponent % (key.p - BigInt.one))); // exp1
  asn.add(ASN1Integer(key.privateExponent % (key.q - BigInt.one))); // exp2
  asn.add(ASN1Integer(key.q.modInverse(key.p))); // coefficient

  final base64Data = base64.encode(asn.encode());
  return '-----BEGIN RSA PRIVATE KEY-----\n$base64Data\n-----END RSA PRIVATE KEY-----';
}

/// encodes RSA public key into PKCS#1 format
String _encodePublicKeyInPem(RSAPublicKey key) {
  final base64Data = base64.encode(_getPublicKeyBytes(key));
  return '-----BEGIN RSA PUBLIC KEY-----\n$base64Data\n-----END RSA PUBLIC KEY-----';
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

/// get fingerprint of a public key by hashing with sha-1 and concatenating
/// the hex values
String _getFingerprint(RSAPublicKey key) => SHA1Digest()
    .process(_getPublicKeyBytes(key))
    .map((e) => e.toRadixString(16)) // convert to hex
    .join();

/// Get the bytes used in the middle part of the PEM format.
/// Useful for generating fingerprints.
Uint8List _getPublicKeyBytes(RSAPublicKey key) {
  final asn = ASN1Sequence();

  asn.add(ASN1Integer(key.modulus));
  asn.add(ASN1Integer(key.exponent));

  return asn.encode();
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
