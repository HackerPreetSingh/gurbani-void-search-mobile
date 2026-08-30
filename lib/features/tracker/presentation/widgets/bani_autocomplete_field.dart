import 'package:flutter/material.dart';

class BaniAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> options;
  final Function(String) onSelected;

  const BaniAutocompleteField({
    super.key,
    required this.controller,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (textEditingValue) {
        return options.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          decoration: const InputDecoration(
            hintText: 'Search or enter custom name...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250, maxWidth: 400),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
