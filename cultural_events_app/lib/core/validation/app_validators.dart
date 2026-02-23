class AppValidators {
  static const int nameMax = 20;
  static const int titleMax = 50;
  static const int descriptionMin = 10;
  static const int descriptionMax = 500;
  static const int emailMax = 100;
  static const int passwordMin = 6;
  static const int passwordMax = 20;
  static const int categoryNameMax = 20;
  static const int locationMax = 30;
  static const int commentMax = 500;

  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );
  static final RegExp _imageExtensionRegex = RegExp(
    r'\.(jpg|jpeg|png|webp)$',
    caseSensitive: false,
  );
  static final RegExp _strongPasswordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\w\s]).+$',
  );

  static String? validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Name is required.';
    if (text.length > nameMax) return 'Name must be at most $nameMax characters.';
    return null;
  }

  static String? validateTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Title is required.';
    if (text.length > titleMax) {
      return 'Title must be at most $titleMax characters.';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Description is required.';
    if (text.length < descriptionMin) {
      return 'Description must be at least $descriptionMin characters.';
    }
    if (text.length > descriptionMax) {
      return 'Description must be at most $descriptionMax characters.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required.';
    if (text.length > emailMax) return 'Email must be at most $emailMax characters.';
    if (!_emailRegex.hasMatch(text)) return 'Enter a valid email address.';
    return null;
  }

  static String? validatePassword(String? value) {
    return validateStrongPassword(value);
  }

  static String? validateStrongPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password is required.';
    if (text.length < passwordMin) {
      return 'Password must be at least $passwordMin characters.';
    }
    if (text.length > passwordMax) {
      return 'Password must be at most $passwordMax characters.';
    }
    if (!_strongPasswordRegex.hasMatch(text)) {
      return 'Password must include upper/lowercase letters, a number, and a special character.';
    }
    return null;
  }

  static String? validateLoginPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password is required.';
    if (text.length > passwordMax) {
      return 'Password must be at most $passwordMax characters.';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    final passwordValidation = validateStrongPassword(value);
    if (passwordValidation != null) return passwordValidation;
    if (value != password) return 'Passwords do not match.';
    return null;
  }

  static String? validateCategoryName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Category name is required.';
    if (text.length > categoryNameMax) {
      return 'Category name must be at most $categoryNameMax characters.';
    }
    return null;
  }

  static String? validateLocation(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Location is required.';
    if (text.length > locationMax) {
      return 'Location must be at most $locationMax characters.';
    }
    return null;
  }

  static String? validateComment(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Comment is required.';
    if (text.length < descriptionMin) {
      return 'Comment must be at least $descriptionMin characters.';
    }
    if (text.length > commentMax) {
      return 'Comment must be at most $commentMax characters.';
    }
    return null;
  }

  static String? validatePositiveNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'This field is required.';
    final number = num.tryParse(text);
    if (number == null) return 'Enter numbers only.';
    if (number <= 0) return 'Value must be positive.';
    return null;
  }

  static String? validateUpcomingDate(DateTime value) {
    if (value.isBefore(DateTime.now())) {
      return 'Date must not be in the past.';
    }
    return null;
  }

  static String? validateImageUrl(String? value, {bool required = false}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return required ? 'Image URL is required.' : null;
    }

    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasAbsolutePath || uri.host.isEmpty) {
      return 'Enter a valid URL.';
    }
    if (!(text.startsWith('http://') || text.startsWith('https://'))) {
      return 'URL must start with http:// or https://.';
    }
    if (!_imageExtensionRegex.hasMatch(uri.path)) {
      return 'Image URL must end with .jpg, .jpeg, .png or .webp.';
    }
    return null;
  }
}
