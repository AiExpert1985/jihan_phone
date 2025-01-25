import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/forms/form_filed_decoration.dart';
import 'package:tablets/src/common/forms/form_validation.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';

class FormDatePickerField extends StatelessWidget {
  const FormDatePickerField({
    this.initialValue,
    required this.onChangedFn,
    required this.name,
    this.label,
    this.isRequired = true,
    this.hideBorders = false,
    this.isReadOnly = false,
    super.key,
  });
  final String? label; // label displayed on the field (can be shown in Arabic)
  final DateTime? initialValue;
  final String name; // Widget needs it, not used by me
  final bool hideBorders; // hide borders in decoration, used if the field in sub list
  final bool isRequired; // if isRequired = false, then the field will not be validated
  final bool isReadOnly;
  final void Function(DateTime?) onChangedFn;

  @override
  Widget build(BuildContext context) {
    return FormBuilderDateTimePicker(
      transitionBuilder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: itemsColor, // *
              cancelButtonStyle:
                  ButtonStyle(foregroundColor: WidgetStatePropertyAll(Colors.white)), // *
              confirmButtonStyle:
                  ButtonStyle(foregroundColor: WidgetStatePropertyAll(Colors.white)), // *
              yearStyle: TextStyle(color: Colors.white), // *
              weekdayStyle: TextStyle(color: Colors.white), // *
              dayStyle: TextStyle(color: Colors.white), // *
              dayForegroundColor: WidgetStatePropertyAll(Colors.white), // *
              headerForegroundColor: Colors.white, // *
              yearForegroundColor: WidgetStatePropertyAll(Colors.white), // *
              dividerColor: Colors.white, // *
              rangeSelectionOverlayColor: WidgetStatePropertyAll(Colors.white),
              todayForegroundColor: WidgetStatePropertyAll(Colors.white), // *
            ),
          ),
          child: child ?? Container(color: itemsColor),
        );
      },
      enabled: !isReadOnly,
      decoration: formFieldDecoration(label: label, hideBorders: hideBorders),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14, color: Colors.white),
      name: name,
      initialValue: initialValue,
      // fieldHintText: S.of(context).date_picker_hint,
      inputType: InputType.date,
      onChanged: onChangedFn,
      validator: (value) => _validateDate(value, context),
    );
  }

  String? _validateDate(DateTime? value, BuildContext context) {
    return isRequired
        ? validateDatePicker(value, S.of(context).input_validation_error_message_for_date)
        : null;
  }
}
