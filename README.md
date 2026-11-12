# Servora
Group 50 · SE303.3 Mobile Application Development · NSBM Green University

Servora helps a customer choose a local professional. A provider can quote, complete work and earn a performance level. The Android client uses Flutter and the shared backend uses Firebase. Open docs/ten-days.md for the team schedule and docs/team-work-allocation.md for member assignments and branch names. The independent browser walkthrough in dist/ uses sample data on one browser.

## Run the Android app
1. Install Flutter stable with Dart 3.6 or newer, Android Studio, Android SDK, Python 3, Node.js 22, Firebase CLI and FlutterFire CLI. Run `flutter doctor`, resolve Android toolchain issues and start an emulator or connect a phone.
2. From this repository run `python scripts/android_setup.py` (use python3 on Linux/macOS). This generates the Android runner with package lk.group50.servora, adds permissions and installs Flutter dependencies. Commit the generated Android runner and pubspec.lock as a team.
3. In the team's Firebase project enable Email/Password sign-in, create a Cloud Firestore database in Native mode and create the default Storage bucket. Deploying Cloud Functions and using Storage may require the team project to have billing enabled. Choose the team project before deploying.
4. Run `firebase login`, then `flutterfire configure --project=YOUR_PROJECT_ID --platforms=android`. Choose the generated Android package. Confirm android/app/google-services.json exists and that FlutterFire configured the Google services Gradle plugin. Android reads the default Firebase configuration at startup. If FlutterFire offers to replace firebase.json, retain the repository's firestore, storage and functions entries.
5. Run `npm --prefix functions install`, then `firebase deploy --project YOUR_PROJECT_ID --only functions,firestore:rules,storage`. Commit the generated functions/package-lock.json.
6. Run `flutter analyze`, `flutter run` and repeat on a second device or emulator. Use separate email accounts for the customer and provider. Run `flutter build apk --debug` for a demo APK. A working network is required.
7. Providers first save a service profile with a matching category and availability. Customers can use GPS or type the same town and coordinates. For GPS testing on an emulator, set a location in Extended Controls. Notifications require a Google Play-enabled device/emulator and permission. Tap Enable job notifications again after a token change. The demo stores one active token per account.

## Reproduce the assessed flow
Create two providers in one category with different rates, experience and coordinates. Set each to available. A customer posts a task, opens it from My jobs, changes ranking priorities and compares two professionals. Both providers submit a quote. The customer chooses one. The assigned provider starts and submits the work result. The customer confirms, rates and explicitly permits any result image for the portfolio. Reopen both accounts to verify history, portfolio and benefits. Repeat with Emergency mechanic, declining GPS and entering coordinates manually. Rotate the device and test invalid amounts, unavailable providers and a second acceptance from another device.

## Repository handoff
From the extracted repository with GitHub CLI authenticated under the intended owner, run:
```sh
gh auth login
gh repo create servora --private --source=. --remote=github --push
```
Invite the other five members and all evaluators, or set the visibility agreed by the group. Verify evaluator access independently. Each member clones the GitHub repository under their own account, creates a feature branch and opens pull requests with their own commits. The starter commit is AI-assisted setup. Document each student's actual work, GitHub username and evidence in the report.

## Implementation map
- lib/main.dart contains the Flutter screens, device integrations and content-based recommendation.
- functions/index.js validates roles and state in Firestore transactions. functions/workflow.js defines transitions, points and benefits. Run node --test functions/workflow.test.js.
- firestore.rules and storage.rules control direct client access. Only the backend writes job state, quotes, completed work and points.
- docs/design.md defines the data model, ranking and checks. docs/ten-days.md maps the proposal to a ten-day integration and assessment plan.
