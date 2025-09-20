import 'dart:convert';

import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/base_scaffold_body.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/auth/sign_up_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../network/rest_apis.dart';
import '../../utils/configs.dart';
import '../../utils/constant.dart';
import '../dashboard/dashboard_screen.dart';

class OTPLoginScreen extends StatefulWidget {
  const OTPLoginScreen({Key? key}) : super(key: key);

  @override
  State<OTPLoginScreen> createState() => _OTPLoginScreenState();
}

class _OTPLoginScreenState extends State<OTPLoginScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController numberController = TextEditingController();
  late FocusNode _mobileNumberFocus;

  Country selectedCountry = defaultCountry();

  String otpCode = '';
  String verificationId = '';

  ValueNotifier _valueNotifier = ValueNotifier(true);

  bool isCodeSent = false;
  bool isOtpError = false;
  List<TextEditingController> otpControllers = [];
  List<FocusNode> otpFocusNodes = [];

  @override
  void initState() {
    super.initState();

    // تهيئة FocusNodes
    _mobileNumberFocus = FocusNode();

    // تهيئة قوائم OTP
    for (int i = 0; i < OTP_TEXT_FIELD_LENGTH; i++) {
      otpControllers.add(TextEditingController());
      otpFocusNodes.add(FocusNode());
    }

    afterBuildCreated(() => init());
  }

  Future<void> init() async {
    appStore.setLoading(false);
  }

  @override
  void dispose() {
    // التخلص من جميع FocusNodes لتجنب تسرب الذاكرة
    _mobileNumberFocus.dispose();

    for (var node in otpFocusNodes) {
      node.dispose();
    }

    for (var controller in otpControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  //region Methods
  Future<void> changeCountry() async {
    showCountryPicker(
      context: context,
      countryListTheme: CountryListThemeData(
        textStyle: secondaryTextStyle(color: textSecondaryColorGlobal),
        searchTextStyle: primaryTextStyle(),
        inputDecoration: InputDecoration(
          labelText: language.search,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withOpacity(0.2),
            ),
          ),
        ),
      ),
      showPhoneCode: true,
      onSelect: (Country country) {
        selectedCountry = country;
        log(jsonEncode(selectedCountry.toJson()));
        setState(() {});
      },
    );
  }

  Future<void> sendOTP() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      hideKeyboard(context);

      appStore.setLoading(true);

      toast(language.sendingOTP);

      try {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: "+${selectedCountry.phoneCode}${numberController.text.trim()}",
          verificationCompleted: (PhoneAuthCredential credential) async {
            toast(language.verified);

            if (isAndroid) {
              await FirebaseAuth.instance.signInWithCredential(credential);
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            appStore.setLoading(false);
            if (e.code == 'invalid-phone-number') {
              toast(language.theEnteredCodeIsInvalidPleaseTryAgain, print: true);
            } else {
              toast(e.toString(), print: true);
            }
          },
          codeSent: (String _verificationId, int? resendToken) async {
            toast(language.otpCodeIsSentToYourMobileNumber);

            appStore.setLoading(false);

            verificationId = _verificationId;

            if (verificationId.isNotEmpty) {
              isCodeSent = true;
              isOtpError = false; // إعادة تعيين حالة الخطأ
              setState(() {});

              // التركيز التلقائي على أول حقل OTP بعد ظهوره (الحقل الأول من اليسار)
              Future.delayed(Duration(milliseconds: 100), () {
                if (mounted && otpFocusNodes.isNotEmpty) {
                  FocusScope.of(context).requestFocus(otpFocusNodes[0]);
                }
              });
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            //FirebaseAuth.instance.signOut();
            //isCodeSent = false;
            //setState(() {});
            this.verificationId = verificationId;
          },
        );
      } on Exception catch (e) {
        log(e);
        appStore.setLoading(false);

        toast(e.toString(), print: true);
      }
    }
  }

  void _handleOtpChange(int index, String value) {
    // إخفاء رسالة الخطأ عند بدء التعديل
    if (isOtpError) {
      setState(() {
        isOtpError = false;
      });
    }

    if (value.length == 1 && index < OTP_TEXT_FIELD_LENGTH - 1) {
      // الانتقال إلى الحقل التالي (من اليسار إلى اليمين)
      FocusScope.of(context).requestFocus(otpFocusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      // الرجوع إلى الحقل السابق عند الحذف
      FocusScope.of(context).requestFocus(otpFocusNodes[index - 1]);
    }

    // تحديث رمز OTP الكامل
    otpCode = '';
    for (int i = 0; i < OTP_TEXT_FIELD_LENGTH; i++) {
      otpCode += otpControllers[i].text;
    }

    // إذا تم ملء جميع الحقول، تقديم OTP تلقائياً
    if (otpCode.length == OTP_TEXT_FIELD_LENGTH) {
      submitOtp();
    }
  }

  // دالة جديدة للتعامل مع الحذف بشكل صحيح
  void _handleOtpKey(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent) {
      final logicalKey = event.logicalKey;

      // إذا كانت الزر المضغوط هو Backspace
      if (logicalKey == LogicalKeyboardKey.backspace) {
        // إذا كان الحقل الحالي فارغاً، انتقل إلى الحقل السابق
        if (otpControllers[index].text.isEmpty && index > 0) {
          FocusScope.of(context).requestFocus(otpFocusNodes[index - 1]);
        }
        // إذا كان الحقل يحتوي على نص، امسحه ولكن ابقَ في نفس الحقل
        else if (otpControllers[index].text.isNotEmpty) {
          otpControllers[index].clear();

          // تحديث رمز OTP الكامل
          otpCode = '';
          for (int i = 0; i < OTP_TEXT_FIELD_LENGTH; i++) {
            otpCode += otpControllers[i].text;
          }
        }
      }
    }
  }

  // دالة لمسح جميع حقول OTP
  void _clearAllOtpFields() {
    for (int i = 0; i < OTP_TEXT_FIELD_LENGTH; i++) {
      otpControllers[i].clear();
    }
    otpCode = '';

    // إعادة التركيز إلى الحقل الأول
    if (mounted && otpFocusNodes.isNotEmpty) {
      FocusScope.of(context).requestFocus(otpFocusNodes[0]);
    }
  }

  Future<void> submitOtp() async {
    log(otpCode);
    if (otpCode.validate().isNotEmpty) {
      if (otpCode.validate().length >= OTP_TEXT_FIELD_LENGTH) {
        hideKeyboard(context);
        appStore.setLoading(true);

        try {
          PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: otpCode);
          UserCredential credentials = await FirebaseAuth.instance.signInWithCredential(credential);

          Map<String, dynamic> request = {
            'username': numberController.text.trim(),
            'password': numberController.text.trim(),
            'login_type': LOGIN_TYPE_OTP,
            "uid": credentials.user!.uid.validate(),
          };

          try {
            await loginUser(request, isSocialLogin: true).then((loginResponse) async {
              if (loginResponse.isUserExist.validate(value: true)) {
                await saveUserData(loginResponse.userData!);
                await appStore.setLoginType(LOGIN_TYPE_OTP);
                DashboardScreen().launch(context, isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
              } else {
                appStore.setLoading(false);
                finish(context);

                SignUpScreen(
                  isOTPLogin: true,
                  phoneNumber: numberController.text.trim(),
                  countryCode: selectedCountry.countryCode,
                  uid: credentials.user!.uid.validate(),
                  tokenForOTPCredentials: credential.token,
                ).launch(context);
              }
            }).catchError((e) {
              finish(context);
              toast(e.toString());
              appStore.setLoading(false);
            });
          } catch (e) {
            appStore.setLoading(false);
            toast(e.toString(), print: true);
          }
        } on FirebaseAuthException catch (e) {
          appStore.setLoading(false);
          if (e.code.toString() == 'invalid-verification-code') {
            setState(() {
              isOtpError = true;
            });
            // مسح جميع الحقول عند الخطأ
            _clearAllOtpFields();
            toast(language.theEnteredCodeIsInvalidPleaseTryAgain, print: true);
          } else {
            toast(e.message.toString(), print: true);
          }
        } on Exception catch (e) {
          appStore.setLoading(false);
          toast(e.toString(), print: true);
        }
      } else {
        toast(language.pleaseEnterValidOTP);
      }
    } else {
      toast(language.pleaseEnterValidOTP);
    }
  }

  // endregion

  Widget _buildOTPInputField() {
    return Column(
      children: [
        Text("أدخل الرمز المرسل إلى رقمك", style: primaryTextStyle()),
        16.height,
        Directionality(
          textDirection: TextDirection.ltr, // إجبار اتجاه الحقول إلى اليسار لليمين
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(OTP_TEXT_FIELD_LENGTH, (index) {
              return SizedBox(
                width: 45,
                height: 45,
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (event) => _handleOtpKey(event, index),
                  child: TextField(
                    controller: otpControllers[index],
                    focusNode: otpFocusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: primaryTextStyle(),
                    textDirection: TextDirection.ltr, // إجبار اتجاه النص أيضاً
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(defaultRadius),
                        borderSide: BorderSide(
                          color: isOtpError ? Colors.red : Colors.grey,
                          width: isOtpError ? 2.0 : 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(defaultRadius),
                        borderSide: BorderSide(
                          color: isOtpError ? Colors.red : Colors.grey,
                          width: isOtpError ? 2.0 : 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(defaultRadius),
                        borderSide: BorderSide(
                          color: isOtpError ? Colors.red : primaryColor,
                          width: isOtpError ? 2.0 : 1.0,
                        ),
                      ),
                      filled: true,
                      fillColor: context.cardColor,
                    ),
                    onChanged: (value) => _handleOtpChange(index, value),
                  ),
                ),
              );
            }),
          ),
        ),
        if (isOtpError) ...[
          8.height,
          Text(
            "الرمز الذي أدخلته غير صحيح. يرجى المحاولة مرة أخرى.",
            style: secondaryTextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
        16.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("", style: secondaryTextStyle()),
            4.width,
            Text("", style: secondaryTextStyle(color: primaryColor)).onTap(() {
              sendOTP();
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildMainWidget() {
    if (isCodeSent) {
      return Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            32.height,
            _buildOTPInputField(),
            30.height,
            AppButton(
              onTap: () {
                submitOtp();
              },
              text: language.confirm,
              color: primaryColor,
              textColor: Colors.white,
              width: context.width(),
            ),
          ],
        ),
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Form(
            key: formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Country code ...
                Container(
                  height: 48.0,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Center(
                    child: Text(
                      "+${selectedCountry.phoneCode}",
                      style: primaryTextStyle(size: 12),
                    ),
                  ),
                ).onTap(() {
                  changeCountry();
                }),
                10.width,
                // Mobile number text field...
                AppTextField(
                  controller: numberController,
                  focus: _mobileNumberFocus,
                  textFieldType: TextFieldType.PHONE,
                  decoration: inputDecoration(context).copyWith(
                    hintText: '${language.lblExample}: ${selectedCountry.example}',
                    hintStyle: secondaryTextStyle(),
                  ),
                  autoFocus: true,
                  onFieldSubmitted: (s) {
                    sendOTP();
                  },
                ).expand(),
              ],
            ),
          ),
          30.height,
          AppButton(
            onTap: () {
              sendOTP();
            },
            text: language.btnSendOtp,
            color: primaryColor,
            textColor: Colors.white,
            width: context.width(),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(isCodeSent ? language.confirmOTP : language.lblEnterPhnNumber, style: boldTextStyle(size: APP_BAR_TEXT_SIZE)),
          elevation: 0,
          backgroundColor: context.scaffoldBackgroundColor,
          leading: Navigator.of(context).canPop() ? BackWidget(iconColor: context.iconColor) : null,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(statusBarIconBrightness: appStore.isDarkMode ? Brightness.light : Brightness.dark, statusBarColor: context.scaffoldBackgroundColor),
        ),
        body: Body(
          child: Container(
            padding: EdgeInsets.all(16),
            child: _buildMainWidget(),
          ),
        ),
      ),
    );
  }
}