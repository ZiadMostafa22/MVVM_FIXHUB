import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;
  static FirebaseAnalytics get analytics => FirebaseAnalytics.instance;
  static FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp();
    
    // Configure Firestore settings
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
  }

  // Collection references
  static CollectionReference get usersCollection => 
      firestore.collection('users');
  static CollectionReference get carsCollection => 
      firestore.collection('cars');
  static CollectionReference get bookingsCollection => 
      firestore.collection('bookings');
  static CollectionReference get invoicesCollection => 
      firestore.collection('invoices');
  static CollectionReference get techniciansCollection => 
      firestore.collection('technicians');
  static CollectionReference get servicesCollection => 
      firestore.collection('services');
  static CollectionReference get reviewsCollection => 
      firestore.collection('reviews');

  static CollectionReference get chatbotConversationsCollection => 
      firestore.collection('chatbot_conversations');
}
