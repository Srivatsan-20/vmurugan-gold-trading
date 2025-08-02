import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MPinInputWidget extends StatefulWidget {
  final Function(String) onMPinComplete;
  final String title;
  final String subtitle;
  final bool isConfirmation;

  const MPinInputWidget({
    super.key,
    required this.onMPinComplete,
    this.title = 'Create MPIN',
    this.subtitle = 'Enter 4-digit MPIN for secure login',
    this.isConfirmation = false,
  });

  @override
  State<MPinInputWidget> createState() => _MPinInputWidgetState();
}

class _MPinInputWidgetState extends State<MPinInputWidget> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  String _mpin = '';
  bool _isWeakPin = false;
  String? _weaknessMessage;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool _isSequentialPin(String pin) {
    if (pin.length != 4) return false;

    // Check for ascending sequence (1234, 2345, etc.)
    bool isAscending = true;
    for (int i = 1; i < pin.length; i++) {
      if (int.parse(pin[i]) != int.parse(pin[i-1]) + 1) {
        isAscending = false;
        break;
      }
    }

    // Check for descending sequence (4321, 5432, etc.)
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
    return pin.split('').toSet().length == 1; // All digits are the same
  }

  void _validatePinStrength(String pin) {
    setState(() {
      _isWeakPin = false;
      _weaknessMessage = null;

      if (_isRepeatingPin(pin)) {
        _isWeakPin = true;
        _weaknessMessage = 'Avoid using same digits (e.g., 1111)';
      } else if (_isSequentialPin(pin)) {
        _isWeakPin = true;
        _weaknessMessage = 'Avoid sequential numbers (e.g., 1234)';
      } else if (pin == '0000') {
        _isWeakPin = true;
        _weaknessMessage = 'Avoid using 0000 as MPIN';
      }
    });
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      // Move to next field if not the last one
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Unfocus when last digit is entered
        _focusNodes[index].unfocus();
      }
    } else {
      // When deleting, move to previous field
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    _updateMPin();
  }

  void _updateMPin() {
    _mpin = _controllers.map((c) => c.text).join();
    if (_mpin.length == 4) {
      _validatePinStrength(_mpin);
      // Add a small delay to show validation message before proceeding
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          widget.onMPinComplete(_mpin);
        }
      });
    } else {
      setState(() {
        _isWeakPin = false;
        _weaknessMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) => _buildMPinField(index)),
        ),
        const SizedBox(height: 16),

        // MPIN Strength Indicator
        if (_mpin.length == 4) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isWeakPin ? Colors.orange[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isWeakPin ? Colors.orange[300]! : Colors.green[300]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isWeakPin ? Icons.warning : Icons.check_circle,
                  color: _isWeakPin ? Colors.orange[700] : Colors.green[700],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _isWeakPin ? _weaknessMessage! : 'Strong MPIN ✓',
                  style: TextStyle(
                    color: _isWeakPin ? Colors.orange[700] : Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMPinField(int index) {
    bool hasValue = _controllers[index].text.isNotEmpty;
    bool isFocused = _focusNodes[index].hasFocus;

    Color borderColor = const Color(0xFFFFD700);
    if (_mpin.length == 4 && _isWeakPin) {
      borderColor = Colors.orange;
    } else if (_mpin.length == 4 && !_isWeakPin) {
      borderColor = Colors.green;
    } else if (isFocused) {
      borderColor = const Color(0xFFFFD700);
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: hasValue ? borderColor.withOpacity(0.1) : Colors.white,
      ),
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) => _onDigitChanged(index, value),
      ),
    );
  }
}