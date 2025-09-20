import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class ThemeSelectionDaiLog extends StatefulWidget {
  @override
  ThemeSelectionDaiLogState createState() => ThemeSelectionDaiLogState();
}

class ThemeSelectionDaiLogState extends State<ThemeSelectionDaiLog> {
  // فقط خيار الوضع الفاتح
  List<String> themeModeList = [language.appThemeLight];
  int? currentIndex = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    currentIndex = 0;
    await setValue(THEME_MODE_INDEX, THEME_MODE_LIGHT); // دائماً فاتح
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width(),
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              width: context.width(),
              decoration: boxDecorationDefault(
                color: context.primaryColor,
                borderRadius: radiusOnly(topRight: defaultRadius, topLeft: defaultRadius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(language.chooseTheme, style: boldTextStyle(color: Colors.white)).flexible(),
                  IconButton(
                    onPressed: () {
                      finish(context);
                    },
                    icon: Icon(Icons.close, color: white),
                  )
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(vertical: 16),
              itemCount: themeModeList.length,
              itemBuilder: (BuildContext context, int index) {
                return RadioListTile(
                  value: index,
                  activeColor: primaryColor,
                  groupValue: currentIndex,
                  title: Text(themeModeList[index], style: primaryTextStyle()),
                  onChanged: (dynamic val) async {
                    currentIndex = val;
                    appStore.setDarkMode(false); // دائماً الوضع الفاتح
                    defaultToastBackgroundColor = Colors.black;
                    defaultToastTextColor = Colors.white;
                    await setValue(THEME_MODE_INDEX, THEME_MODE_LIGHT); // حفظ الفاتح كخيار
                    setState(() {});
                    finish(context);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}