# Play Store release checklist

## Package configuration
- The Android release uses `com.toongapp` for `namespace` and `applicationId`, so register that package in the Google Play Console and Firebase.
- Firebase integration still points to an older ID, so download a fresh `google-services.json` after you add `com.toongapp` to your Firebase project and drop it into `android/app/`.

## Versioning
- Keep `version: x.y.z+code` in `pubspec.yaml` in sync with the Play Store entry; `x.y.z` is `versionName` and `code` is `versionCode`.
- Increment the build number (`+code`) every time you upload a new release artifact.

## Signing setup
- Generate a private keystore (for example with `keytool -genkey -v -keystore android/app/keystore.jks -alias toonga_release -keyalg RSA -keysize 2048 -validity 10000`).
- Copy `key.properties.template` to `key.properties` in the project root, fill in your keystore path/alias/passwords, and keep the file and `.jks` out of version control.
- Gradle now loads `key.properties` to sign the `release` build type automatically.

## Building the bundle
- Run `flutter pub get` (needed once after dependency changes).
- Clean any old artifacts with `flutter clean`.
- Produce the release artifact with `flutter build appbundle --release`.
- The generated `.aab` appears under `build/app/outputs/bundle/release/app-release.aab`.

## Publishing steps
- Upload the signed bundle to the Play Console, target the `production` track (or `internal` for testing) and follow the guided release flow.
- Enable Google Play App Signing if you haven’t already; the console will then pick up the signing key you registered.
- Fill out the Play Store listing (description, screenshots, content rating, privacy policy, etc.) before promoting the release.

## Validation
- Use the Play Console internal testing track to install and sanity-check the release on a device before promoting it to production.
- Double-check runtime permissions/notifications, especially for the `POST_NOTIFICATIONS`, camera, and location permissions declared in `android/app/src/main/AndroidManifest.xml`.
