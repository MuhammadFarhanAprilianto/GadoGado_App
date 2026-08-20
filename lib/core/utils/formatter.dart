extension DoubleFormatting on double {
  String toCleanString() {
    if (this == toInt()) {
      return toInt().toString();
    }
    // Limit to 3 decimal places
    String formatted = toStringAsFixed(3);
    
    // Trim trailing zeros
    if (formatted.contains('.')) {
      while (formatted.endsWith('0')) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
      if (formatted.endsWith('.')) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
    }
    
    // Replace dot with comma for Indonesian standard decimal separator
    return formatted.replaceAll('.', ',');
  }
}
