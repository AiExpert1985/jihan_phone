import 'package:flutter/material.dart';
import 'package:tablets/generated/l10n.dart';
import 'package:tablets/src/common/values/gaps.dart';

double iconFontSize = 18;
double iconSize = 30;

class ApproveIcon extends StatelessWidget {
  const ApproveIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(
        Icons.check,
        color: Colors.green,
        size: iconSize,
      ),
      VerticalGap.s,
      Text(S.of(context).approve, style: TextStyle(color: Colors.white, fontSize: iconFontSize))
    ]);
  }
}

class SaveInvoice extends StatelessWidget {
  const SaveInvoice({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(
        Icons.check,
        color: Colors.green,
        size: iconSize,
      ),
      VerticalGap.s,
      Text('حفظ القائمة', style: TextStyle(color: Colors.white, fontSize: iconFontSize))
    ]);
  }
}

class AddItem extends StatelessWidget {
  const AddItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(
        Icons.add,
        color: Colors.green,
        size: iconSize,
      ),
      VerticalGap.s,
      Text('اضافة مادة', style: TextStyle(color: Colors.white, fontSize: iconFontSize)),
    ]);
  }
}

class MainMenuIcon extends StatelessWidget {
  const MainMenuIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(
        Icons.menu,
        color: Colors.white,
        size: iconSize,
      ),
      HorizontalGap.s,
      Text(S.of(context).main_menu,
          style: TextStyle(
            color: Colors.white,
            fontSize: iconFontSize,
          ))
    ]);
  }
}

class HomeReturnIcon extends StatelessWidget {
  const HomeReturnIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(
        Icons.home,
        color: Colors.red,
        size: iconSize,
      ),
      HorizontalGap.s,
      Text(
        S.of(context).home_page,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: iconFontSize),
      )
    ]);
  }
}

class NavigationBackButton extends StatelessWidget {
  const NavigationBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(
        S.of(context).back,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: iconFontSize),
      ),
      HorizontalGap.s,
      Icon(
        Icons.arrow_forward_ios_outlined,
        color: Colors.white,
        size: iconSize,
      )
    ]);
  }
}

class SaveIcon extends StatelessWidget {
  const SaveIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(
        Icons.check,
        color: Colors.green,
        size: iconSize,
      ),
      VerticalGap.s,
      Text(
        S.of(context).save,
        style: TextStyle(fontSize: iconFontSize),
      )
    ]);
  }
}

class CancelIcon extends StatelessWidget {
  const CancelIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(
        Icons.close,
        color: Colors.red,
        size: iconSize,
      ),
      VerticalGap.s,
      Text(S.of(context).cancel, style: TextStyle(color: Colors.white, fontSize: iconFontSize)),
    ]);
  }
}

class DeleteIcon extends StatelessWidget {
  const DeleteIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.delete,
          color: Colors.red,
          size: iconSize,
        ),
        VerticalGap.s,
        Text(S.of(context).delete, style: TextStyle(fontSize: iconFontSize)),
      ],
    );
  }
}

class AddIcon extends StatelessWidget {
  const AddIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.add,
          color: Colors.white,
          size: iconSize,
        ),
        VerticalGap.s,
        Text(S.of(context).add, style: TextStyle(fontSize: iconFontSize)),
      ],
    );
  }
}

class SearchIcon extends StatelessWidget {
  const SearchIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.search,
          color: Colors.red,
          size: iconSize,
        ),
        VerticalGap.s,
        Text(S.of(context).search, style: TextStyle(fontSize: iconFontSize)),
      ],
    );
  }
}

class ReportsIcon extends StatelessWidget {
  const ReportsIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.report,
          color: Colors.red,
          size: iconSize,
        ),
        VerticalGap.s,
        Text(S.of(context).reports, style: TextStyle(fontSize: iconFontSize)),
      ],
    );
  }
}

class AddImageIcon extends StatelessWidget {
  const AddImageIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.image,
          size: iconSize,
        ),
        VerticalGap.s,
        Text(S.of(context).add, style: TextStyle(fontSize: iconFontSize)),
      ],
    );
  }
}

class NewIemIcon extends StatelessWidget {
  const NewIemIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.add,
          color: Colors.green,
          size: iconSize,
        ),
        VerticalGap.s,
        Text(S.of(context).new_item, style: TextStyle(fontSize: iconFontSize)),
      ],
    );
  }
}

class EditIcon extends StatelessWidget {
  const EditIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.edit_document,
          color: Colors.orangeAccent,
          size: iconSize,
        ),
        VerticalGap.s,
        Text(S.of(context).edit, style: TextStyle(fontSize: iconFontSize)),
      ],
    );
  }
}

class PrintIcon extends StatelessWidget {
  const PrintIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Image.asset(
        //   'assets/icons/buttons/print.png',
        //   width: 25,
        //   height: 22,
        // ),
        Icon(
          Icons.print,
          size: iconSize,
        ),
        VerticalGap.s,
        Text(S.of(context).print, style: TextStyle(fontSize: iconFontSize)),
      ],
    );
  }
}

class PrintedIcon extends StatelessWidget {
  const PrintedIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      color: Colors.green[900],
      child: Column(children: [
        // Image.asset(
        //   'assets/icons/buttons/print.png',
        //   width: 25,
        //   height: 22,
        // ),
        Icon(
          Icons.print,
          color: Colors.white,
          size: iconSize,
        ),
        VerticalGap.s,

        Text(
          S.of(context).printed,
          style: TextStyle(color: Colors.white, fontSize: iconFontSize),
        )
      ]),
    );
  }
}

class ShareIcon extends StatelessWidget {
  const ShareIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.share,
          color: Colors.blue,
          size: iconSize,
        ),
        VerticalGap.s,
        Text(S.of(context).share, style: TextStyle(fontSize: iconFontSize)),
      ],
    );
  }
}

class GoNextIcon extends StatelessWidget {
  const GoNextIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.navigate_next,
          color: Colors.green,
          size: iconSize,
        ),
        VerticalGap.s,
        Text(S.of(context).next, style: TextStyle(fontSize: iconFontSize)),
      ],
    );
  }
}

class GoPreviousIcon extends StatelessWidget {
  const GoPreviousIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.navigate_before,
          color: Colors.green,
          size: iconSize,
        ),
        VerticalGap.s,
        Text(S.of(context).previous, style: TextStyle(fontSize: iconFontSize)),
      ],
    );
  }
}

class GoFirstIcon extends StatelessWidget {
  const GoFirstIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.first_page,
          color: Colors.green,
          size: iconSize,
        ),
        VerticalGap.s,
        Text(S.of(context).first, style: TextStyle(fontSize: iconFontSize)),
      ],
    );
  }
}

class GoLastIcon extends StatelessWidget {
  const GoLastIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.last_page,
          color: Colors.green,
          size: iconSize,
        ),
        VerticalGap.s,
        Text(S.of(context).last, style: TextStyle(fontSize: iconFontSize)),
      ],
    );
  }
}

class LocaleAwareLogoutIcon extends StatelessWidget {
  const LocaleAwareLogoutIcon({super.key});

  @override
  Widget build(BuildContext context) {
    Locale currentLocale = Localizations.localeOf(context);
    // for arabic, we flip the direction
    if (currentLocale.languageCode == 'ar') {
      // for arabic,
      return Transform.flip(
        flipX: true,
        child: Icon(
          Icons.logout,
          color: Colors.white,
          size: iconSize,
        ),
      );
    }
    return const Icon(Icons.logout);
  }
}
