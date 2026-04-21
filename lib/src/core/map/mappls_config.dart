import 'package:mappls_gl/mappls_gl.dart';

class MapplsConfig {
  const MapplsConfig._();

  static const String restApiKey = String.fromEnvironment(
    'MAPPLS_REST_API_KEY',
    defaultValue: '19a8340043af8d929ed5661bc4e2dcf4',
  );

  static const String atlasClientId = String.fromEnvironment(
    'MAPPLS_CLIENT_ID',
    defaultValue: '96dHZVzsAuvgbkeidIFGxUZyAHDTzyP6c6wPTZn0d_IRHridX4xFACf6CV0d-ZVUMQtz8s3hhC_9SKsxFV2_cA==',
  );

  static const String atlasClientSecret = String.fromEnvironment(
    'MAPPLS_CLIENT_SECRET',
    defaultValue: 'lrFxI-iSEg80B8p98KeWRM-brweGUfSafyw_1C3v_8kWIKRqOVV3KuFP5GtaHj_TgUF7CvpCNX2PMcTRnwP4lqTrB3-DTKWd',
  );

  static Future<void> initialize() async {
    await MapplsAccountManager.setMapSDKKey(restApiKey);
    await MapplsAccountManager.setRestAPIKey(restApiKey);
    await MapplsAccountManager.setAtlasClientId(atlasClientId);
    await MapplsAccountManager.setAtlasClientSecret(atlasClientSecret);
  }
}
