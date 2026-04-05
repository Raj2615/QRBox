class AppStrings {
  AppStrings._();

  static const String appName = 'QRBox';
  static const String appTagline = 'Smart Inventory for Your Boxes';

  // Auth
  static const String login = 'Log In';
  static const String register = 'Create Account';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String forgotPassword = 'Forgot Password?';
  static const String orContinueWith = 'Or continue with';
  static const String signInWithGoogle = 'Sign in with Google';
  static const String noAccount = "Don't have an account?";
  static const String hasAccount = 'Already have an account?';

  // Dashboard
  static const String dashboard = 'Dashboard';
  static const String totalBoxes = 'Total Boxes';
  static const String totalItems = 'Total Items';
  static const String recentBoxes = 'Recent Boxes';
  static const String quickActions = 'Quick Actions';

  // Box
  static const String myBoxes = 'My Boxes';
  static const String addBox = 'Add Box';
  static const String editBox = 'Edit Box';
  static const String deleteBox = 'Delete Box';
  static const String boxName = 'Box Name';
  static const String boxLocation = 'Location';
  static const String boxPin = 'PIN';
  static const String boxDescription = 'Description';

  // Items
  static const String addItem = 'Add Item';
  static const String editItem = 'Edit Item';
  static const String deleteItem = 'Delete Item';
  static const String itemName = 'Item Name';
  static const String quantity = 'Quantity';
  static const String description = 'Description';

  // QR
  static const String generateQR = 'Generate QR Codes';
  static const String scanQR = 'Scan QR Code';
  static const String numberOfCodes = 'Number of QR Codes';
  static const String generatePDF = 'Generate PDF';
  static const String downloadPDF = 'Download PDF';

  // Search
  static const String search = 'Search';
  static const String searchItems = 'Search items across all boxes...';
  static const String noResults = 'No results found';

  // Web viewer base URL
  static const String baseUrl = 'https://qrbox-cbcbb.web.app';
  static const String boxUrlPrefix = '/box/';

  // Errors
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorInvalidEmail = 'Please enter a valid email address.';
  static const String errorWeakPassword = 'Password must be at least 6 characters.';
  static const String errorPasswordMismatch = 'Passwords do not match.';
}
