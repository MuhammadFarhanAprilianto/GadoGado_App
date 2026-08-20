class AppConstants {
  static const String appName = 'Warung Mpo Lemez';
  
  // Roles
  static const String roleCustomer = 'pelanggan';
  static const String roleAdmin = 'admin';
  static const String roleOwner = 'owner';

  // Authentication Codes for Registration
  static const String codeAdminRegister = 'ADMIN123';
  static const String codeOwnerRegister = 'OWNER123';

  // Categories
  static const List<String> categories = ['All', 'Makanan Utama', 'Drinks', 'Snack', 'Others'];
  
  // Storage Keys
  static const String keyUserRole = 'user_role';
  static const String keyIsLoggedIn = 'is_logged_in';
}
