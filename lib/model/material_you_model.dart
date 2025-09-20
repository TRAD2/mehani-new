import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// هذه الدالة كانت تعتمد على إعدادات النظام وAndroid 12
/// الآن تم تعديلها لتثبيت اللون الأساسي دائمًا
Future<Color> getMaterialYouData() async {
  // تجاهل إعدادات النظام وMaterial You
  primaryColor = defaultPrimaryColor;

  return primaryColor;
}
