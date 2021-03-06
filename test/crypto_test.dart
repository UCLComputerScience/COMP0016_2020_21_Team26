import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge_me/crypto.dart';
import 'package:pointycastle/pointycastle.dart';

// These are the components of a private key generated by OpenSSL.
// (And also therefore represents a public key.)

final publicExponent = BigInt.parse('65537');
final privateExponent = BigInt.parse(
    '77ccb34adb62353aa5aa7c00b606e4'
    '5594c7af0d70cff33496e6922affdd'
    'a38e59cfcb6d0e2ab3f58ee7555718'
    '6982a43121245c50ce4b63494b754d'
    '849a235d1b672fab2ad3b4bc1f79ff'
    '767debff681f4e380c73d8c06b6bb1'
    '6a4def6028da07d8113008d2236792'
    '40149c1018a5e4ddfdc2913a41c40e'
    '137ecf218f0ee06dde4158df6c68a5'
    'ab463679ec54f83f6cf72945bb1512'
    '947ceed48f550570693cd4ef96e692'
    '2df059291841dc39623154e4dff87c'
    'd586d742ebc1f439ebd194960c19b3'
    '3975f5f04d5382db5cd3151ee50cf3'
    'be90928aac135f34d4cd49a720979f'
    '2ff19cfc966d578dc6385af1320908'
    '9e35e70727a42d878d48dfb60ea068'
    '01',
    radix: 16);
final modulus = BigInt.parse(
    '00cfa99f4e6d4ac1af5ce122a2a09b'
    '511ed4525ca9a794572231cd5c18d2'
    'aa54268cd34ad6e59e4b677b287039'
    'f1eb9963b208988565ccd6d7bafb1d'
    '87457eea992e127e02ff0470581b3b'
    'e731b57b293226b81d3701e080bb81'
    '39758a852212cfafbc9139eb6e42e8'
    'daacf3bb58a6c55f7898c23dbb027a'
    'f61589b6c44b4c0c8d5592ba453de3'
    'e6152eb0face44b12440177803aab2'
    '0337aea118f3d7d3c70b9dac550a7d'
    '881c06ac8ecad2bd65d4697be94d00'
    'fef19ab475a735bba526aa0194aa2c'
    '286718de9625473564846c7adde54c'
    '6037c3a039e5fbfff28c1df6d7db56'
    'db57236b6032017eb3c376afa27cd6'
    '28f4bd8682ab4013f1b3924cf320b0'
    'afa9',
    radix: 16);
final p = BigInt.parse(
    '00f66ebd592c0099087791feb3271f'
    'bd9e1e604547ecb671caea4f5d06c4'
    '5ee84d3613a5943338384cee7429bc'
    '641121e4e926fdaf065652fb21f9f4'
    'b6b6cb85719d89d3da9ea18c37a6c4'
    'd7eafcaffc6f6eafb5e3060fa77db4'
    '47758f699b90b8585999b67d738238'
    '5005cddd162f2637a3751c9f35beb3'
    '92144bbfa2efecc551',
    radix: 16);
final q = BigInt.parse(
    '00d7b98d8bf0772aae2a45718628e9'
    '8eae9a94ad58f27e00650bb6a482b3'
    '489ef2012ae3683dacdcbbf94602ad'
    '2fb55708b65690d25ebab4d4f61666'
    'a5d9da5d88c5e44fde6d223cb752fa'
    '40c4060ae4f77708f0c8fa2f053246'
    '69a0215bcdd3ac7d16c66560eef700'
    '386bd2d96abd5035854b695de37fb7'
    '659da5ccea0a430ed9',
    radix: 16);
const publicPEM =
'-----BEGIN RSA PUBLIC KEY-----\n'
'MIIBCgKCAQEAz6mfTm1Kwa9c4SKioJtRHtRSXKmnlFciMc1cGNKqVCaM00rW5Z5L'
'Z3socDnx65ljsgiYhWXM1te6+x2HRX7qmS4SfgL/BHBYGzvnMbV7KTImuB03AeCA'
'u4E5dYqFIhLPr7yROetuQujarPO7WKbFX3iYwj27Anr2FYm2xEtMDI1VkrpFPePm'
'FS6w+s5EsSRAF3gDqrIDN66hGPPX08cLnaxVCn2IHAasjsrSvWXUaXvpTQD+8Zq0'
'dac1u6UmqgGUqiwoZxjeliVHNWSEbHrd5UxgN8OgOeX7//KMHfbX21bbVyNrYDIB'
'frPDdq+ifNYo9L2GgqtAE/GzkkzzILCvqQIDAQAB'
'\n-----END RSA PUBLIC KEY-----';

final publicKey = RSAPublicKey(modulus, publicExponent);
final privateKey = RSAPrivateKey(modulus, privateExponent, p, q);

void main() {
  test('correctly encodes PKCS#1 public key to PEM', () {
    final encoded = encodePublicKeyInPem(publicKey);
    expect(encoded, publicPEM);
  });

  test('decoding our encoded public key gets back the original', () {
    final encoded = encodePublicKeyInPem(publicKey);
    expect(RSAKeyParser().parse(encoded) as RSAPublicKey, publicKey);
  });

  test('decoding our encoded private key gets back the original', () {
    final encoded = encodePrivateKeyInPem(privateKey);
    expect(RSAKeyParser().parse(encoded) as RSAPrivateKey, privateKey);
  });

  test('decrypting an encrypted messages gets the original message', () {
    final encrypter = Encrypter(RSA(publicKey: publicKey,
            privateKey: privateKey));

    final message = "confidentialMessage";
    final ciphertext64 = encrypter.encrypt(message).base64;

    expect(encrypter.decrypt64(ciphertext64), message);
  });
}
