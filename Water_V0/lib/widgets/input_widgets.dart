import 'package:flutter/material.dart';
import '../models/challenge.dart';

class InputWidget extends StatelessWidget {
  final Challenge challenge;
  final String? value;
  final Function(String) onChanged;
  final bool enabled;

  const InputWidget({
    Key? key,
    required this.challenge,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (challenge.inputType) {
      case 'text':
        return TextInputField(
          value: value,
          onChanged: onChanged,
          enabled: enabled,
        );
      case 'number':
        return NumberInputField(
          value: value,
          onChanged: onChanged,
          min: challenge.min,
          max: challenge.max,
          enabled: enabled,
        );
      case 'dropdown':
        return DropdownInputField(
          value: value,
          options: challenge.options!,
          onChanged: onChanged,
          enabled: enabled,
        );
      case 'slider':
        return SliderInputField(
          value: value,
          onChanged: onChanged,
          min: challenge.min!,
          max: challenge.max!,
          enabled: enabled,
        );
      case 'radio':
        return RadioInputField(
          value: value,
          options: challenge.options!,
          onChanged: onChanged,
          enabled: enabled,
        );
      case 'checkbox':
        return CheckboxInputField(
          value: value,
          options: challenge.options!,
          onChanged: onChanged,
          enabled: enabled,
        );
      default:
        return TextInputField(
          value: value,
          onChanged: onChanged,
          enabled: enabled,
        );
    }
  }
}

class TextInputField extends StatelessWidget {
  final String? value;
  final Function(String) onChanged;
  final bool enabled;

  const TextInputField({
    Key? key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value),
      onChanged: onChanged,
      enabled: enabled,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        hintText: 'Enter your answer',
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[200],
      ),
    );
  }
}

class NumberInputField extends StatelessWidget {
  final String? value;
  final Function(String) onChanged;
  final double? min;
  final double? max;
  final bool enabled;

  const NumberInputField({
    Key? key,
    required this.value,
    required this.onChanged,
    this.min,
    this.max,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value),
      onChanged: (val) {
        if (val.isEmpty) {
          onChanged(val);
          return;
        }
        
        final number = double.tryParse(val);
        if (number != null) {
          if (min != null && number < min!) return;
          if (max != null && number > max!) return;
          onChanged(val);
        }
      },
      enabled: enabled,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        hintText: 'Enter a number',
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[200],
        helperText: min != null && max != null ? 'Range: ${min!.toInt()} - ${max!.toInt()}' : null,
      ),
    );
  }
}

class DropdownInputField extends StatelessWidget {
  final String? value;
  final List<String> options;
  final Function(String) onChanged;
  final bool enabled;

  const DropdownInputField({
    Key? key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
        color: enabled ? Colors.white : Colors.grey[200],
      ),
      child: DropdownButton<String>(
        value: value,
        hint: const Text('Select an option'),
        isExpanded: true,
        underline: Container(),
        onChanged: enabled ? (val) {
          if (val != null) onChanged(val);
        } : null,
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
      ),
    );
  }
}

class SliderInputField extends StatefulWidget {
  final String? value;
  final Function(String) onChanged;
  final double min;
  final double max;
  final bool enabled;

  const SliderInputField({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<SliderInputField> createState() => _SliderInputFieldState();
}

class _SliderInputFieldState extends State<SliderInputField> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value != null ? double.tryParse(widget.value!) ?? widget.min : widget.min;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${widget.min.toInt()}'),
            Text('${_currentValue.toInt()}'),
            Text('${widget.max.toInt()}'),
          ],
        ),
        Slider(
          value: _currentValue,
          min: widget.min,
          max: widget.max,
          divisions: (widget.max - widget.min).toInt(),
          label: _currentValue.toInt().toString(),
          onChanged: widget.enabled ? (val) {
            setState(() {
              _currentValue = val;
            });
            widget.onChanged(val.toInt().toString());
          } : null,
        ),
      ],
    );
  }
}

class RadioInputField extends StatelessWidget {
  final String? value;
  final List<String> options;
  final Function(String) onChanged;
  final bool enabled;

  const RadioInputField({
    Key? key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        return RadioListTile<String>(
          title: Text(option),
          value: option,
          groupValue: value,
          onChanged: enabled ? (val) {
            if (val != null) onChanged(val);
          } : null,
          activeColor: Theme.of(context).colorScheme.primary,
        );
      }).toList(),
    );
  }
}

class CheckboxInputField extends StatefulWidget {
  final String? value;
  final List<String> options;
  final Function(String) onChanged;
  final bool enabled;

  const CheckboxInputField({
    Key? key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<CheckboxInputField> createState() => _CheckboxInputFieldState();
}

class _CheckboxInputFieldState extends State<CheckboxInputField> {
  late List<String> _selectedOptions;

  @override
  void initState() {
    super.initState();
    _selectedOptions = widget.value != null ? widget.value!.split(',') : [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.options.map((option) {
        return CheckboxListTile(
          title: Text(option),
          value: _selectedOptions.contains(option),
          onChanged: widget.enabled ? (val) {
            if (val == true) {
              _selectedOptions.add(option);
            } else {
              _selectedOptions.remove(option);
            }
            widget.onChanged(_selectedOptions.join(','));
            setState(() {});
          } : null,
          activeColor: Theme.of(context).colorScheme.primary,
        );
      }).toList(),
    );
  }
}

