import 'dart:async' show StreamSubscription, unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'core/validators/validation.dart';
import 'repositories/command_repository.dart';
import 'services/recommendation_service.dart';
import 'app/theme/servora_theme.dart';

part 'features/authentication/accounts.dart';
part 'app/dashboard.dart';
part 'app/customer_dashboard.dart';
part 'app/provider_dashboard.dart';
part 'features/customer/requests.dart';
part 'features/jobs/jobs.dart';
part 'features/recommendations/discovery.dart';
part 'features/portfolio/portfolio.dart';
part 'features/jobs/contacts.dart';
part 'features/notifications/notifications.dart';
part 'features/settings/settings.dart';
part 'features/authentication/security.dart';
part 'features/authentication/recovery.dart';
part 'features/settings/profile_photo.dart';
part 'features/provider/services.dart';
part 'features/jobs/timestamps.dart';
part 'features/earnings/earnings.dart';
part 'features/settings/preferences.dart';
part 'features/notifications/notification_settings.dart';
part 'features/settings/location_settings.dart';
part 'features/settings/information.dart';
part 'app/servora_app.dart';
part 'app/welcome.dart';
part 'app/branding/servora_brand.dart';
part 'core/widgets/shared_widgets.dart';
part 'core/widgets/service_icons.dart';
part 'core/widgets/hero_banner.dart';

typedef RowData = Map<String, dynamic>;

const categories = [
  'Plumbing',
  'Electrical',
  'Painting',
  'Carpentry',
  'Masonry',
  'Gardening',
  'Cleaning',
  'Mechanic',
];

const ink = Color(0xff173d39);

final db = FirebaseFirestore.instance;

String get uid => FirebaseAuth.instance.currentUser!.uid;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await appPreferences.load();

    runApp(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: appPreferences.themeMode,
        builder: (context, mode, child) {
          return Servora(themeMode: mode);
        },
      ),
    );
  } catch (e) {
    debugPrint(
      'Servora initialization failed (${e.runtimeType}).',
    );

    runApp(
      const MaterialApp(
        title: 'Servora',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 56,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Unable to start Servora',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Please check your internet connection '
                      'and restart the application.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final CommandRepository commandRepository = FirestoreCommandRepository(
  db: db,
  auth: FirebaseAuth.instance,
  categories: categories,
  offersService: (provider, category) => offersService(provider, category),
  availableForService: (provider, category) =>
      availableForService(provider, category),
);

Future<void> send(String name, RowData data) {
  return commandRepository.send(name, data);
}
