class InputSanitizer {
  static String clean(String input, {int max = 120}) {
    final String trimmed = input.trim();
    final String noControl = trimmed.replaceAll(RegExp(r'[\u0000-\u001F]'), '');
    if (noControl.length <= max) {
      return noControl;
    }
    return noControl.substring(0, max);
  }

  static bool isPhoneValid(String input) {
    return RegExp(r'^[0-9+]{8,15}$').hasMatch(input.trim());
  }
}
