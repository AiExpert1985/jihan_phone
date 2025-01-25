import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/classes/db_cache.dart';
import 'package:tablets/src/common/forms/form_filed_decoration.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';

/// same as DropDownWithSearchForm but without expanded
class DropDownWithSearch extends ConsumerWidget {
  const DropDownWithSearch(
      {required this.onChangedFn,
      this.label,
      this.isRequired = true,
      this.hideBorders = false,
      required this.dbCache,
      this.initialValue,
      this.isReadOnly = false,
      super.key});

  final DbCache dbCache; // used to bring items (from database) shown in the list
  final String? initialValue; // must contains 'name' property
  final String? label; // label shown on the cell
  final bool hideBorders; // hide borders in decoration, used if the field in sub list
  final bool isRequired; // if isRequired = false, then the field will not be validated
  final bool isReadOnly;
  final void Function(Map<String, dynamic>) onChangedFn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownSearch<Map<String, dynamic>>(
      mode: Mode.form,
      enabled: !isReadOnly,
      decoratorProps: DropDownDecoratorProps(
        baseStyle: const TextStyle(fontSize: 14, color: Colors.white),
        textAlign: TextAlign.center,
        decoration: formFieldDecoration(label: label, hideBorders: hideBorders),
      ),
      selectedItem: initialValue != null ? {'name': initialValue} : null,
      items: (filter, t) => dbCache.getSearchableList(filterKey: 'name', filterValue: filter),
      compareFn: (i, s) => i == s,
      popupProps: PopupProps.dialog(
        title: label != null
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  label!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              )
            : null,
        dialogProps: DialogProps(
          backgroundColor: itemsColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        fit: FlexFit.tight,
        showSearchBox: true,
        itemBuilder: popUpItem,
        searchFieldProps: TextFieldProps(
          autofocus: true,
          textAlign: TextAlign.center,
          decoration: formFieldDecoration(),
        ),
      ),
      itemAsString: (item) {
        return item['name'];
      },
      onChanged: (item) {
        if (item == null) return;
        onChangedFn(item);
      },
    );
  }
}

Widget popUpItem(
    BuildContext context, Map<String, dynamic> item, bool isDisabled, bool isSelected) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 8),
    decoration: !isSelected
        ? null
        : BoxDecoration(
            border: Border.all(color: Theme.of(context).primaryColor),
            borderRadius: BorderRadius.circular(5),
            color: Colors.white,
          ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      child: ListTile(
        selected: isSelected,
        title: Text(item['name'], style: const TextStyle(fontSize: 14, color: Colors.white)),
        // subtitle: Text(item.code.toString()),
        leading: CircleAvatar(
          // radius: 70,
          backgroundColor: Colors.white,
          foregroundImage:
              CachedNetworkImageProvider(item['imageUrls'][item['imageUrls'].length - 1]),
        ),
      ),
    ),
  );
}
