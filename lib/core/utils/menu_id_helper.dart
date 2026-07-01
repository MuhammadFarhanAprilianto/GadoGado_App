import '../../data/models/order_model.dart';

class MenuIdHelper {
  /// Maps category name to its corresponding letter code (A, B, C, D)
  static String getCategoryLetter(String category) {
    switch (category) {
      case 'Makanan Utama':
        return 'A';
      case 'Drinks':
        return 'B';
      case 'Snack':
        return 'C';
      case 'Others':
      default:
        return 'D';
    }
  }

  /// Converts a menu name to camelCase alphanumeric-only format
  static String cleanMenuName(String name) {
    final words = name.split(RegExp(r'\s+'));
    final capitalized = words.map((w) {
      if (w.isEmpty) return '';
      final cleanWord = w.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      if (cleanWord.isEmpty) return '';
      return cleanWord[0].toUpperCase() + cleanWord.substring(1);
    }).join('');
    return capitalized;
  }

  /// Maps ServiceType enum to its corresponding digit code (1, 2, 3, 4)
  static int getServiceTypeCode(ServiceType serviceType) {
    switch (serviceType) {
      case ServiceType.dineIn:
        return 1;
      case ServiceType.takeAway:
        return 2;
      case ServiceType.rsvp:
        return 3;
      case ServiceType.delivery:
        return 4;
    }
  }

  /// Applies the ServiceType code to a dynamic menu ID (replaces the '0' suffix with service type digit)
  static String applyServiceTypeToMenuId(String idMenu, ServiceType serviceType) {
    final regex = RegExp(r'^(#?[A-D])(\d+)(\d)(_.*)$');
    final match = regex.firstMatch(idMenu);
    if (match != null) {
      final prefix = match.group(1);
      final index = match.group(2);
      final suffix = match.group(4);
      final serviceCode = getServiceTypeCode(serviceType);
      return '$prefix$index$serviceCode$suffix';
    }
    return idMenu;
  }

  /// Normalizes a dynamic menu ID (replaces the service type digit with '0')
  static String normalizeMenuId(String idMenu) {
    final regex = RegExp(r'^(#?[A-D])(\d+)(\d)(_.*)$');
    final match = regex.firstMatch(idMenu);
    if (match != null) {
      final prefix = match.group(1);
      final index = match.group(2);
      final suffix = match.group(4);
      return '$prefix${index}0$suffix';
    }
    return idMenu;
  }
}
