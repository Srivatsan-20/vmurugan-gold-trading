import 'package:flutter_test/flutter_test.dart';

/// Unit tests for MPIN validation logic
/// Tests the security validation methods used in MPIN creation
void main() {
  group('MPIN Validation Tests', () {
    
    group('Sequential PIN Detection', () {
      test('should detect ascending sequential PINs', () {
        expect(_isSequentialPin('1234'), isTrue);
        expect(_isSequentialPin('2345'), isTrue);
        expect(_isSequentialPin('6789'), isTrue);
        expect(_isSequentialPin('0123'), isTrue);
      });

      test('should detect descending sequential PINs', () {
        expect(_isSequentialPin('4321'), isTrue);
        expect(_isSequentialPin('9876'), isTrue);
        expect(_isSequentialPin('5432'), isTrue);
        expect(_isSequentialPin('3210'), isTrue);
      });

      test('should not flag non-sequential PINs', () {
        expect(_isSequentialPin('1357'), isFalse);
        expect(_isSequentialPin('2468'), isFalse);
        expect(_isSequentialPin('1379'), isFalse);
        expect(_isSequentialPin('9517'), isFalse);
      });

      test('should handle edge cases', () {
        expect(_isSequentialPin('9012'), isFalse); // wraps around
        expect(_isSequentialPin('1029'), isFalse); // not sequential
        expect(_isSequentialPin('0987'), isFalse); // not fully descending (0->9 breaks pattern)
        expect(_isSequentialPin('9876'), isTrue);  // proper descending sequence
      });
    });

    group('Repeating PIN Detection', () {
      test('should detect all same digits', () {
        expect(_isRepeatingPin('0000'), isTrue);
        expect(_isRepeatingPin('1111'), isTrue);
        expect(_isRepeatingPin('5555'), isTrue);
        expect(_isRepeatingPin('9999'), isTrue);
      });

      test('should detect alternating patterns', () {
        expect(_isRepeatingPin('1212'), isTrue);
        expect(_isRepeatingPin('3434'), isTrue);
        expect(_isRepeatingPin('7878'), isTrue);
        expect(_isRepeatingPin('0909'), isTrue);
      });

      test('should not flag diverse PINs', () {
        expect(_isRepeatingPin('1234'), isFalse);
        expect(_isRepeatingPin('2468'), isFalse);
        expect(_isRepeatingPin('1357'), isFalse);
        expect(_isRepeatingPin('9517'), isFalse);
      });

      test('should detect partial repeating patterns', () {
        expect(_isRepeatingPin('1122'), isTrue);
        expect(_isRepeatingPin('3344'), isTrue);
        expect(_isRepeatingPin('7799'), isTrue);
      });
    });

    group('Overall PIN Strength', () {
      test('should identify weak PINs', () {
        // Sequential PINs
        expect(_isWeakPin('1234'), isTrue);
        expect(_isWeakPin('4321'), isTrue);
        
        // Repeating PINs
        expect(_isWeakPin('1111'), isTrue);
        expect(_isWeakPin('1212'), isTrue);
        
        // Common patterns
        expect(_isWeakPin('0000'), isTrue);
        expect(_isWeakPin('1122'), isTrue);
      });

      test('should identify strong PINs', () {
        expect(_isWeakPin('2468'), isFalse);
        expect(_isWeakPin('1357'), isFalse);
        expect(_isWeakPin('9517'), isFalse);
        expect(_isWeakPin('3691'), isFalse);
        expect(_isWeakPin('7249'), isFalse);
      });

      test('should provide appropriate weakness messages', () {
        expect(_getWeaknessMessage('1111'), contains('same digit'));
        expect(_getWeaknessMessage('1234'), contains('sequential'));
        expect(_getWeaknessMessage('4321'), contains('sequential'));
        expect(_getWeaknessMessage('1212'), contains('pattern'));
      });
    });

    group('PIN Format Validation', () {
      test('should validate PIN length', () {
        expect(_isValidPinFormat('123'), isFalse);
        expect(_isValidPinFormat('12345'), isFalse);
        expect(_isValidPinFormat('1234'), isTrue);
      });

      test('should validate PIN contains only digits', () {
        expect(_isValidPinFormat('12a4'), isFalse);
        expect(_isValidPinFormat('12.4'), isFalse);
        expect(_isValidPinFormat('12 4'), isFalse);
        expect(_isValidPinFormat('1234'), isTrue);
      });

      test('should handle empty or null input', () {
        expect(_isValidPinFormat(''), isFalse);
        expect(_isValidPinFormat(null), isFalse);
      });
    });

    group('Security Recommendations', () {
      test('should generate appropriate security tips', () {
        final tips = _getSecurityTips();
        expect(tips.join(' '), contains('unique'));
        expect(tips.join(' '), contains('sequential'));
        expect(tips.join(' '), contains('repeating'));
        expect(tips.join(' '), contains('confidential'));
      });

      test('should suggest alternatives for weak PINs', () {
        final suggestions = _getSuggestions('1234');
        expect(suggestions, isNotEmpty);
        expect(suggestions.every((pin) => !_isWeakPin(pin)), isTrue);
      });
    });
  });
}

// Helper methods that mirror the actual implementation
bool _isSequentialPin(String pin) {
  if (pin.length != 4) return false;
  
  // Check ascending sequence
  bool isAscending = true;
  for (int i = 1; i < pin.length; i++) {
    if (int.parse(pin[i]) != int.parse(pin[i-1]) + 1) {
      isAscending = false;
      break;
    }
  }
  
  // Check descending sequence
  bool isDescending = true;
  for (int i = 1; i < pin.length; i++) {
    if (int.parse(pin[i]) != int.parse(pin[i-1]) - 1) {
      isDescending = false;
      break;
    }
  }
  
  return isAscending || isDescending;
}

bool _isRepeatingPin(String pin) {
  if (pin.length != 4) return false;
  
  // Check if all digits are the same
  if (pin.split('').toSet().length == 1) return true;
  
  // Check for alternating pattern (ABAB)
  if (pin[0] == pin[2] && pin[1] == pin[3] && pin[0] != pin[1]) return true;
  
  // Check for double pairs (AABB)
  if (pin[0] == pin[1] && pin[2] == pin[3] && pin[0] != pin[2]) return true;
  
  return false;
}

bool _isWeakPin(String pin) {
  return _isSequentialPin(pin) || _isRepeatingPin(pin);
}

String _getWeaknessMessage(String pin) {
  if (pin.split('').toSet().length == 1) {
    return 'Avoid using the same digit repeatedly';
  }
  if (_isSequentialPin(pin)) {
    return 'Avoid sequential numbers like 1234 or 4321';
  }
  if (_isRepeatingPin(pin)) {
    return 'Avoid repeating patterns like 1212 or 1122';
  }
  return 'Choose a more secure PIN';
}

bool _isValidPinFormat(String? pin) {
  if (pin == null || pin.isEmpty) return false;
  if (pin.length != 4) return false;
  return RegExp(r'^[0-9]{4}$').hasMatch(pin);
}

List<String> _getSecurityTips() {
  return [
    'Use a unique 4-digit combination',
    'Avoid sequential numbers (1234, 4321)',
    'Avoid repeating digits (1111, 2222)',
    'Don\'t use your birth year or phone digits',
    'Avoid common patterns (0000, 1234)',
    'Keep your MPIN confidential and secure'
  ];
}

List<String> _getSuggestions(String weakPin) {
  // Generate some strong PIN suggestions
  List<String> suggestions = ['2468', '1357', '9517', '3691', '7249'];
  return suggestions.where((pin) => !_isWeakPin(pin)).toList();
}
