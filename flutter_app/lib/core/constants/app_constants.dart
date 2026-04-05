class AppConstants {
  AppConstants._();

  // QR code prefix
  static const String qrPrefix = 'QRBOX';
  static const String qrIdFormat = 'QRBOX-';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String boxesCollection = 'boxes';
  static const String itemsCollection = 'items';

  // Storage paths
  static const String itemImagesPath = 'items';

  // PIN
  static const int pinLength = 4;

  // Pagination
  static const int boxesPageSize = 20;
  static const int itemsPageSize = 50;

  // QR generation
  static const int maxQRBatch = 500;
  static const int qrPerPage = 10; // 2 columns x 5 rows on A4

  // Image
  static const double maxImageWidth = 1024;
  static const double maxImageHeight = 1024;
  static const int imageQuality = 80;
}
