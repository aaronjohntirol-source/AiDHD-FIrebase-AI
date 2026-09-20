class InputValidation {
  static String? nameError(String value) {
    if (value.trim().length < 2) return 'Name must be at least 2 characters.';
    return null;
  }

  static String? ageError(String value) {
    final age = int.tryParse(value.trim());
    if (age == null || age < 13 || age > 120) {
      return 'You must be 13 or older to create an account.';
    }
    return null;
  }

  static String? usernameError(String value) {
    final length = value.trim().length;
    if (length < 5 || length > 20) {
      return 'Username must be 5 to 20 characters.';
    }
    return null;
  }
}
