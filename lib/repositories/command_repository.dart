import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/validators/validation.dart';
import '../services/reward_service.dart';
import '../models/service_quotation.dart';

abstract interface class CommandRepository {
  Future<void> send(
    String name,
    Map<String, dynamic> data,
  );
}

typedef ServiceEligibility = bool Function(
  Map<String, dynamic> provider,
  dynamic category,
);

class FirestoreCommandRepository implements CommandRepository {
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  final List<String> categories;

  final ServiceEligibility offersService;
  final ServiceEligibility availableForService;

  FirestoreCommandRepository({
    required this.db,
    required this.auth,
    required List<String> categories,
    required this.offersService,
    required this.availableForService,
  }) : categories = List.unmodifiable(categories);

  @override
  Future<void> send(
    String name,
    Map<String, dynamic> data,
  ) async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in first.');
    }

    final userId = user.uid;

    final memberRef = db.collection('members').doc(userId);

    final providerRef = db.collection('providers').doc(userId);

    switch (name) {
      case 'register':
        {
          final displayName = validatedText(
            data['name'],
            80,
            'Enter a valid display name.',
          );

          final role = data['role'];

          if (role != 'customer' && role != 'provider') {
            throw Exception('Select a valid account type.');
          }

          await db.runTransaction((transaction) async {
            final member = await transaction.get(memberRef);

            if (!member.exists) {
              transaction.set(memberRef, {
                'name': displayName,
                'role': role,
              });
            }
          });

          return;
        }

      case 'profile':
        {
          final member = await memberRef.get();
          final profile = member.data();

          if (profile == null || profile['role'] != 'provider') {
            throw Exception(
              'A provider account is required.',
            );
          }

          final category = data['category'];

          if (!categories.contains(category)) {
            throw Exception(
              'Select a valid service category.',
            );
          }

          final area = validatedText(
            data['area'],
            80,
            'Enter a valid service area.',
          );

          final price = validatedNumber(
            data['price'],
            1,
            100000000,
            'Enter a valid starting rate.',
          );

          final years = validatedNumber(
            data['years'],
            0,
            80,
            'Enter valid years of experience.',
          );

          final lat = validatedNumber(
            data['lat'],
            -90,
            90,
            'Enter a valid latitude.',
          );

          final lng = validatedNumber(
            data['lng'],
            -180,
            180,
            'Enter a valid longitude.',
          );

          final profileData = <String, dynamic>{
            'name': profile['name'],
            'category': category,
            'area': area,
            'price': price,
            'years': years,
            'available': data['available'] == true,
            'lat': coarseCoordinate(lat),
            'lng': coarseCoordinate(lng),
          };

          await db.runTransaction((transaction) async {
            final existing = await transaction.get(providerRef);

            if (existing.exists) {
              transaction.update(
                providerRef,
                profileData,
              );
            } else {
              transaction.set(providerRef, {
                ...profileData,
                'points': 0,
                'jobs': 0,
                'stars': 0,
                'ontime': 0,
                'quick': 0,
                'verified': 0,
                'level': 'Bronze',
                'fee': 10,
                'visibility': 0,
              });
            }
          });

          return;
        }

      case 'location':
        {
          final area = validatedText(
            data['area'],
            80,
            'Enter a valid service area.',
          );

          final lat = validatedNumber(
            data['lat'],
            -90,
            90,
            'Enter a valid latitude.',
          );

          final lng = validatedNumber(
            data['lng'],
            -180,
            180,
            'Enter a valid longitude.',
          );

          await db.runTransaction((transaction) async {
            final memberSnapshot = await transaction.get(memberRef);
            final providerSnapshot = await transaction.get(providerRef);

            final member = memberSnapshot.data();

            if (member == null || member['role'] != 'provider') {
              throw Exception('A provider account is required.');
            }

            if (!providerSnapshot.exists) {
              throw Exception('Create your service profile first.');
            }

            transaction.update(providerRef, {
              'area': area,
              'lat': coarseCoordinate(lat),
              'lng': coarseCoordinate(lng),
            });
          });

          return;
        }

      case 'post':
        {
          final member = await memberRef.get();
          final profile = member.data();

          if (profile == null || profile['role'] != 'customer') {
            throw Exception(
              'A customer account is required.',
            );
          }

          final category = data['category'];

          if (!categories.contains(category)) {
            throw Exception(
              'Select a valid service category.',
            );
          }

          final title = validatedText(
            data['title'],
            100,
            'Enter a valid task title.',
          );

          final description = validatedText(
            data['description'],
            500,
            'Enter a valid description.',
          );

          final area = validatedText(
            data['area'],
            80,
            'Enter a valid service area.',
          );

          final budget = validatedNumber(
            data['budget'],
            1,
            100000000,
            'Enter a valid budget.',
          );

          final lat = validatedNumber(
            data['lat'],
            -90,
            90,
            'Enter a valid latitude.',
          );

          final lng = validatedNumber(
            data['lng'],
            -180,
            180,
            'Enter a valid longitude.',
          );

          final requestImage = validatedImage(data['photo']);

          final jobId = validatedJobId(data['jobId']);
          final jobRef = db.collection('jobs').doc(jobId);

          final privateContactRef =
              db.collection('privateContacts').doc(userId);

          final jobContactRef = jobRef.collection('contacts').doc(userId);

          await db.runTransaction((transaction) async {
            final contactSnapshot = await transaction.get(privateContactRef);

            final phone = savedContactPhone(
              contactSnapshot.data(),
            );

            transaction.set(jobContactRef, {
              'phone': phone,
            });

            if (requestImage != null) {
              transaction.set(
                jobRef.collection('images').doc('request'),
                {'bytes': requestImage},
              );
            }

            transaction.set(
              jobRef.collection('locations').doc('exact'),
              {
                'lat': lat,
                'lng': lng,
              },
            );

            transaction.set(jobRef, {
              'owner': userId,
              'name': profile['name'],
              'category': category,
              'title': title,
              'description': description,
              'area': area,
              'budget': budget,
              'lat': coarseCoordinate(lat),
              'lng': coarseCoordinate(lng),
              'emergency': category == 'Mechanic' && data['emergency'] == true,
              'photo':
                  requestImage == null ? '' : '${jobRef.path}/images/request',
              'status': 'open',
              'assigned': '',
              'created': DateTime.now().millisecondsSinceEpoch,
            });
          });

          return;
        }

      case 'quote':
        {
          final jobId = validatedJobId(data['jobId']);
          final jobRef = db.collection('jobs').doc(jobId);

          final quoteRef = jobRef.collection('quotes').doc(userId);

          final privateContactRef =
              db.collection('privateContacts').doc(userId);

          final jobContactRef = jobRef.collection('contacts').doc(userId);

          final amount = validatedNumber(
            data['amount'],
            1,
            100000000,
            'Enter a valid quotation amount.',
          );

          final hours = validatedNumber(
            data['hours'],
            1,
            720,
            'Enter a valid completion time.',
          );

          final note = validatedText(
            data['note'],
            500,
            'Describe what is included in your quotation.',
          );

          await db.runTransaction((transaction) async {
            final memberSnapshot = await transaction.get(memberRef);

            final providerSnapshot = await transaction.get(providerRef);

            final jobSnapshot = await transaction.get(jobRef);

            final quoteSnapshot = await transaction.get(quoteRef);

            final member = memberSnapshot.data();
            final provider = providerSnapshot.data();
            final job = jobSnapshot.data();

            if (member == null || member['role'] != 'provider') {
              throw Exception(
                'A provider account is required.',
              );
            }

            if (provider == null) {
              throw Exception(
                'Create your service profile first.',
              );
            }

            if (job == null || job['status'] != 'open') {
              throw Exception(
                'This request is no longer available.',
              );
            }

            if (job['owner'] == userId) {
              throw Exception(
                'You cannot quote for your own request.',
              );
            }

            if (!offersService(provider, job['category'])) {
              throw Exception(
                'This request does not match your service category.',
              );
            }

            if (!availableForService(provider, job['category'])) {
              throw Exception(
                'Enable your availability before submitting a quotation.',
              );
            }

            final contactSnapshot = await transaction.get(privateContactRef);

            final phone = savedContactPhone(
              contactSnapshot.data(),
            );

            transaction.set(jobContactRef, {
              'phone': phone,
            });

            if (quoteSnapshot.exists) {
              transaction.update(quoteRef, {
                'updatedAt': DateTime.now().millisecondsSinceEpoch,
                'amount': amount,
                'hours': hours,
                'note': note,
              });
            } else {
              transaction.set(quoteRef, {
                'provider': userId,
                'name': member['name'],
                'amount': amount,
                'hours': hours,
                'note': note,
                'created': DateTime.now().millisecondsSinceEpoch,
              });
            }
          });

          return;
        }

      case 'accept':
        {
          final jobId = validatedJobId(data['jobId']);

          final providerId = validatedJobId(data['provider']);

          final jobRef = db.collection('jobs').doc(jobId);

          final quoteRef = jobRef.collection('quotes').doc(providerId);

          await db.runTransaction((transaction) async {
            final memberSnapshot = await transaction.get(memberRef);

            final jobSnapshot = await transaction.get(jobRef);

            final quoteSnapshot = await transaction.get(quoteRef);

            final member = memberSnapshot.data();
            final job = jobSnapshot.data();
            final quote = quoteSnapshot.data();

            if (member == null || member['role'] != 'customer') {
              throw Exception(
                'A customer account is required.',
              );
            }

            if (job == null || job['owner'] != userId) {
              throw Exception(
                'Service request unavailable.',
              );
            }

            if (job['status'] != 'open' || job['assigned'] != '') {
              throw Exception(
                'This request has already been booked.',
              );
            }

            if (quote == null ||
                quote['provider'] != providerId ||
                providerId == userId) {
              throw Exception('Quotation not found.');
            }

            if (!ServiceQuotation.matchesConfirmation(
              quote,
              data['confirmedQuotation'],
            )) {
              throw Exception(
                'This quotation has changed. '
                'Review the latest quotation before accepting.',
              );
            }

            final quotation = ServiceQuotation.fromMap(quote);

            final amount = quotation.amount;

            final now = DateTime.now().millisecondsSinceEpoch;

            final due = quotation.completionDeadline(now);

            final quick = quotation.isQuickResponse(job['created'] as num);

            transaction.update(jobRef, {
              'status': 'booked',
              'bookedAt': now,
              'assigned': providerId,
              'providerName': quotation.providerName,
              'amount': amount,
              'due': due,
              'quick': quick,
            });
          });

          return;
        }

      case 'start':
        {
          final jobId = validatedJobId(data['jobId']);
          final jobRef = db.collection('jobs').doc(jobId);

          await db.runTransaction((transaction) async {
            final memberSnapshot = await transaction.get(memberRef);

            final jobSnapshot = await transaction.get(jobRef);

            final member = memberSnapshot.data();
            final job = jobSnapshot.data();

            if (member == null || member['role'] != 'provider') {
              throw Exception(
                'A provider account is required.',
              );
            }

            if (job == null) {
              throw Exception(
                'Service request not found.',
              );
            }

            if (job['assigned'] != userId) {
              throw Exception(
                'This job is not assigned to you.',
              );
            }

            if (job['status'] != 'booked') {
              throw Exception(
                'This job cannot be started.',
              );
            }

            transaction.update(jobRef, {
              'status': 'in progress',
              'startedAt': DateTime.now().millisecondsSinceEpoch,
            });
          });

          return;
        }

      case 'finish':
        {
          final jobId = validatedJobId(data['jobId']);
          final jobRef = db.collection('jobs').doc(jobId);

          final summary = validatedText(
            data['summary'],
            500,
            'Describe the completed work.',
          );

          final resultImage = validatedImage(data['result']);

          await db.runTransaction((transaction) async {
            final memberSnapshot = await transaction.get(memberRef);

            final jobSnapshot = await transaction.get(jobRef);

            final member = memberSnapshot.data();
            final job = jobSnapshot.data();

            if (member == null || member['role'] != 'provider') {
              throw Exception(
                'A provider account is required.',
              );
            }

            if (job == null) {
              throw Exception(
                'Service request not found.',
              );
            }

            if (job['assigned'] != userId) {
              throw Exception(
                'This job is not assigned to you.',
              );
            }

            if (job['status'] != 'in progress') {
              throw Exception(
                'Start the job before submitting completed work.',
              );
            }

            if (resultImage != null) {
              transaction.set(
                jobRef.collection('images').doc('result'),
                {'bytes': resultImage},
              );
            }

            transaction.update(jobRef, {
              'status': 'awaiting review',
              'summary': summary,
              'result':
                  resultImage == null ? '' : '${jobRef.path}/images/result',
              'finished': DateTime.now().millisecondsSinceEpoch,
            });
          });

          return;
        }

      case 'review':
        {
          final jobId = validatedJobId(data['jobId']);
          final jobRef = db.collection('jobs').doc(jobId);

          final stars = validatedNumber(
            data['stars'],
            1,
            5,
            'Select a rating between 1 and 5.',
          );

          if (stars != stars.round()) {
            throw Exception(
              'Select a whole-number rating.',
            );
          }

          final rating = stars.toInt();

          final feedback = validatedText(
            data['feedback'],
            500,
            'Enter your feedback.',
          );

          await db.runTransaction((transaction) async {
            final memberSnapshot = await transaction.get(memberRef);

            final jobSnapshot = await transaction.get(jobRef);

            final member = memberSnapshot.data();
            final job = jobSnapshot.data();

            if (member == null || member['role'] != 'customer') {
              throw Exception(
                'A customer account is required.',
              );
            }

            if (job == null || job['owner'] != userId) {
              throw Exception(
                'Service request unavailable.',
              );
            }

            if (job['status'] != 'awaiting review') {
              throw Exception(
                'This job cannot be reviewed.',
              );
            }

            final providerId = validatedJobId(job['assigned']);

            final assignedProviderRef =
                db.collection('providers').doc(providerId);

            final workRef = assignedProviderRef.collection('work').doc(jobId);

            final providerSnapshot = await transaction.get(assignedProviderRef);

            final provider = providerSnapshot.data();

            if (provider == null) {
              throw Exception(
                'Provider profile not found.',
              );
            }

            final onTime = (job['finished'] as num) <= (job['due'] as num);

            final quick = job['quick'] == true;

            const rewardService = RewardService();

            final reward = rewardService.calculatePoints(
              rating: rating,
              onTime: onTime,
              quickResponse: quick,
            );

            final points = (provider['points'] as num).toInt() + reward;

            final completedJobs = (provider['jobs'] as num).toInt() + 1;

            final totalStars = (provider['stars'] as num).toInt() + rating;

            final onTimeJobs =
                (provider['ontime'] as num).toInt() + (onTime ? 1 : 0);

            final quickJobs =
                (provider['quick'] as num).toInt() + (quick ? 1 : 0);

            final rank = rewardService.rankForPoints(points);

            final level = rank.label;
            final fee = rank.feePercent;
            final visibility = rank.visibility;
            final examples = List<Map<String, dynamic>>.from(
              (provider['examples'] as List? ?? []).map(
                (entry) => Map<String, dynamic>.from(entry as Map),
              ),
            );

            if (examples.length < 30) {
              examples.add({
                'budget': job['budget'],
                'stars': rating,
              });
            }

            final previousFee = provider['fee'] as num;

            final serviceCharge = rewardService.calculateServiceCharge(
              amount: job['amount'] as num,
              feePercent: previousFee,
            );

            final resultPath = '${jobRef.path}/images/result';

            final portfolioConsent =
                data['consent'] == true && job['result'] == resultPath;

            transaction.update(jobRef, {
              'status': 'completed',
              'reviewedAt': DateTime.now().millisecondsSinceEpoch,
              'portfolioConsent': portfolioConsent,
              'stars': rating,
              'feedback': feedback,
              'feePercent': previousFee,
              'serviceCharge': serviceCharge,
            });

            transaction.update(assignedProviderRef, {
              'points': points,
              'jobs': completedJobs,
              'stars': totalStars,
              'ontime': onTimeJobs,
              'quick': quickJobs,
              'level': level,
              'fee': fee,
              'visibility': visibility,
              'lastReviewedJob': jobId,
              'examples': examples,
            });

            transaction.set(workRef, {
              'title': job['title'],
              'feedback': feedback,
              'stars': rating,
              'summary': job['summary'],
              'result': portfolioConsent ? resultPath : '',
              'created': DateTime.now().millisecondsSinceEpoch,
            });
          });

          return;
        }

      default:
        throw Exception('Unsupported service operation.');
    }
  }
}
