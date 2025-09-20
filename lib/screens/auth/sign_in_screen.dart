

import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/base_scaffold_body.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/auth/forgot_password_screen.dart';
import 'package:booking_system_flutter/screens/auth/otp_login_screen.dart';
import 'package:booking_system_flutter/screens/auth/sign_up_screen.dart';
import 'package:booking_system_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:country_picker/country_picker.dart';

import '../../network/rest_apis.dart';
import '../../utils/app_configuration.dart';

class SignInScreen extends StatefulWidget {
  final bool? isFromDashboard;
  final bool? isFromServiceBooking;
  final bool returnExpected;

  SignInScreen({this.isFromDashboard, this.isFromServiceBooking, this.returnExpected = false});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController emailCont = TextEditingController();
  TextEditingController passwordCont = TextEditingController();

  FocusNode emailFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();

  bool isRemember = true;

  Country selectedCountry = defaultCountry();

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    isRemember = getBoolAsync(IS_REMEMBERED);
    if (isRemember) {
      // emailCont.text = getStringAsync(USER_EMAIL);
      //asswordCont.text = getStringAsync(USER_PASSWORD);
    }

    /// For Demo Purpose
    if (await isIqonicProduct) {
      emailCont.text = DEFAULT_EMAIL;
      passwordCont.text = DEFAULT_PASS;
    }
  }

  //region Methods

  void _handleLogin() {
    hideKeyboard(context);
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      _handleLoginUsers();
    }
  }

  void _handleLoginUsers() async {
    hideKeyboard(context);

    String rawPhone = emailCont.text.trim(); // الحقل اللي يدخل المستخدم: مثلا "791234567"

// إزالة الصفر الأول إذا كان موجود
    if (rawPhone.startsWith('0')) {
      rawPhone = rawPhone.substring(1);
    }



    String countryCodeOnly = selectedCountry.phoneCode; // مثلا "962"
    String phoneWithCountry = '$countryCodeOnly$rawPhone'; // "962791234567"
    String fakeEmail = '$phoneWithCountry@mail.com'; // "962791234567@mail.com"
    String password = passwordCont.text.trim();

    appStore.setLoading(true);

    // محاولة 1: تجربة تسجيل الدخول باستخدام email الوهمي (اللي استخدمناه عند التسجيل)
    Map<String, dynamic> requestEmail = {
      'email': fakeEmail,
      'password': password,
      'login_type': LOGIN_TYPE_USER,
    };

    try {
      final loginResponse = await loginUser(requestEmail, isSocialLogin: false);

      // ناجح
      await saveUserData(loginResponse.userData!);
      await setValue(USER_PASSWORD, password);
      //await setValue(IS_REMEMBERED, isRemember);
      await appStore.setLoginType(LOGIN_TYPE_USER);
      authService.verifyFirebaseUser();
      TextInput.finishAutofillContext();
      onLoginSuccessRedirection();
      return;
    } catch (e) {
      // فشلت المحاولة بالأيميل — سنحاول بصيغة username (بدون كود الدولة) كـ fallback
      log('Login with fake email failed: $e');
    }

    // محاولة 2: تجربة تسجيل الدخول باستخدام username (كمخزن في الـ admin غالبًا بدون +)
    Map<String, dynamic> requestUsername = {
      'username': rawPhone, // "791234567" — لأن admin عندك يخزن بالشكل ده
      'password': password,
      'login_type': LOGIN_TYPE_USER,
    };

    try {
      final loginResponse = await loginUser(requestUsername, isSocialLogin: false);

      // ناجح
      await saveUserData(loginResponse.userData!);
      await setValue(USER_PASSWORD, password);
      // await setValue(IS_REMEMBERED, isRemember);
      await appStore.setLoginType(LOGIN_TYPE_USER);
      authService.verifyFirebaseUser();
      TextInput.finishAutofillContext();
      onLoginSuccessRedirection();
      return;
    } catch (e) {
      // كلا المحاولتين فشلتا — نُظهر الخطأ النهائي
      appStore.setLoading(false);
      log('Login with username fallback failed: $e');
      toast(e.toString());
    }
  }


  void googleSignIn() async {
    if(!appStore.isLoading){
      appStore.setLoading(true);
      await authService.signInWithGoogle(context).then((googleUser) async {
        String firstName = '';
        String lastName = '';
        if (googleUser.displayName.validate().split(' ').length >= 1) firstName = googleUser.displayName.splitBefore(' ');
        if (googleUser.displayName.validate().split(' ').length >= 2) lastName = googleUser.displayName.splitAfter(' ');

        Map<String, dynamic> request = {
          'first_name': firstName,
          'last_name': lastName,
          'email': googleUser.email,
          'username': googleUser.email.splitBefore('@').replaceAll('.', '').toLowerCase(),
          // 'password': passwordCont.text.trim(),
          'social_image': googleUser.photoURL,
          'login_type': LOGIN_TYPE_GOOGLE,
        };
        var loginResponse = await loginUser(request, isSocialLogin: true);

        loginResponse.userData!.profileImage = googleUser.photoURL.validate();

        await saveUserData(loginResponse.userData!);
        appStore.setLoginType(LOGIN_TYPE_GOOGLE);

        authService.verifyFirebaseUser();

        onLoginSuccessRedirection();
        appStore.setLoading(false);
      }).catchError((e) {
        appStore.setLoading(false);
        log(e.toString());
        toast(e.toString());
      });
    }
  }

  void appleSign() async {
    if(!appStore.isLoading){
      appStore.setLoading(true);

      await authService.appleSignIn().then((req) async {
        await loginUser(req, isSocialLogin: true).then((value) async {
          await saveUserData(value.userData!);
          appStore.setLoginType(LOGIN_TYPE_APPLE);

          appStore.setLoading(false);
          authService.verifyFirebaseUser();

          onLoginSuccessRedirection();
        }).catchError((e) {
          appStore.setLoading(false);
          log(e.toString());
          throw e;
        });
      }).catchError((e) {
        appStore.setLoading(false);
        toast(e.toString());
      });
    }
  }

  void otpSignIn() async {
    hideKeyboard(context);

    OTPLoginScreen().launch(context);
  }

  void onLoginSuccessRedirection() {
    afterBuildCreated(() {
      appStore.setLoading(false);
      if (widget.isFromServiceBooking.validate() || widget.isFromDashboard.validate() || widget.returnExpected.validate()) {
        if (widget.isFromDashboard.validate()) {
          push(DashboardScreen(redirectToBooking: true), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
        } else {
          finish(context, true);
        }
      } else {
        DashboardScreen().launch(context, isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
      }
    });
  }

//endregion

//region Widgets
  Widget _buildTopWidget() {
    return Container(
      child: Column(
        children: [
          Text("${language.lblLoginTitle}!", style: boldTextStyle(size: 20)).center(),
          16.height,
          Text(language.lblLoginSubTitle, style: primaryTextStyle(size: 14), textAlign: TextAlign.center).center().paddingSymmetric(horizontal: 32),
          32.height,
        ],
      ),
    );
  }

  Widget _buildRememberWidget() {
    return Column(
      children: [
        8.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RoundedCheckBox(
              borderColor: context.primaryColor,
              checkedColor: context.primaryColor,
              isChecked: false, // سيظهر غير مفعل افتراضيًا
              text: language.rememberMe,
              textStyle: secondaryTextStyle(),
              size: 20,
              onTap: (value) {
                // مجرد تفاعل بصري، لا تحفظ أي شيء
              },
            ),
            TextButton(
              onPressed: () {
                hideKeyboard(context);
                OTPLoginScreen().launch(context);
              },
              child: Text(
                language.forgotPassword,
                style: boldTextStyle(color: primaryColor, fontStyle: FontStyle.italic),
                textAlign: TextAlign.right,
              ),
            ).flexible(),
          ],
        ),
        24.height,
        AppButton(
          text: language.signIn,
          color: primaryColor,
          textColor: Colors.white,
          width: context.width() - context.navigationBarHeight,
          onTap: () {
            _handleLogin();
          },
        ),
        16.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(language.doNotHaveAccount, style: secondaryTextStyle()),
            TextButton(
              onPressed: () {
                hideKeyboard(context);
                OTPLoginScreen().launch(context);
              },
              child: Text(
                language.signUp,
                style: boldTextStyle(
                  color: primaryColor,
                  decoration: TextDecoration.underline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        /*
        TextButton(
          onPressed: () {
            if (isAndroid) {
              if (getStringAsync(PROVIDER_PLAY_STORE_URL).isNotEmpty) {
                launchUrl(Uri.parse(getStringAsync(PROVIDER_PLAY_STORE_URL)), mode: LaunchMode.externalApplication);
              } else {
                launchUrl(Uri.parse('${getSocialMediaLink(LinkProvider.PLAY_STORE)}$PROVIDER_PACKAGE_NAME'), mode: LaunchMode.externalApplication);
              }
            } else if (isIOS) {
              if (getStringAsync(PROVIDER_APPSTORE_URL).isNotEmpty) {
                commonLaunchUrl(getStringAsync(PROVIDER_APPSTORE_URL));
              } else {
                commonLaunchUrl(IOS_LINK_FOR_PARTNER);
              }
            }
          },
          child: Text(language.lblRegisterAsPartner, style: boldTextStyle(color: primaryColor)),
        )
        */
      ],
    );
  }

  Widget _buildSocialWidget() {
    if (appConfigurationStore.socialLoginStatus) {
      return Column(
        children: [
          20.height,
          if ((appConfigurationStore.googleLoginStatus || appConfigurationStore.otpLoginStatus) || (isIOS && appConfigurationStore.appleLoginStatus))
            Row(
              children: [
                Divider(color: context.dividerColor, thickness: 2).expand(),
                16.width,
                Text(language.lblOrContinueWith, style: secondaryTextStyle()),
                16.width,
                Divider(color: context.dividerColor, thickness: 2).expand(),
              ],
            ),
          24.height,
          if (appConfigurationStore.googleLoginStatus)
            AppButton(
              text: '',
              color: context.cardColor,
              padding: EdgeInsets.all(8),
              textStyle: boldTextStyle(),
              width: context.width() - context.navigationBarHeight,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: boxDecorationWithRoundedCorners(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      boxShape: BoxShape.circle,
                    ),
                    child: GoogleLogoWidget(size: 16),
                  ),
                  Text(language.lblSignInWithGoogle, style: boldTextStyle(size: 12), textAlign: TextAlign.center).expand(),
                ],
              ),
              onTap: googleSignIn,
            ),
          if (appConfigurationStore.googleLoginStatus) 16.height,
          if (appConfigurationStore.otpLoginStatus)
            AppButton(
              text: '',
              color: context.cardColor,
              padding: EdgeInsets.all(8),
              textStyle: boldTextStyle(),
              width: context.width() - context.navigationBarHeight,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: boxDecorationWithRoundedCorners(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      boxShape: BoxShape.circle,
                    ),
                    child: ic_calling.iconImage(size: 18, color: primaryColor).paddingAll(4),
                  ),
                  Text(language.lblSignInWithOTP, style: boldTextStyle(size: 12), textAlign: TextAlign.center).expand(),
                ],
              ),
              onTap: otpSignIn,
            ),
          if (appConfigurationStore.otpLoginStatus) 16.height,
          if (isIOS)
            if (appConfigurationStore.appleLoginStatus)
              AppButton(
                text: '',
                color: context.cardColor,
                padding: EdgeInsets.all(8),
                textStyle: boldTextStyle(),
                width: context.width() - context.navigationBarHeight,
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: boxDecorationWithRoundedCorners(
                        backgroundColor: primaryColor.withOpacity(0.1),
                        boxShape: BoxShape.circle,
                      ),
                      child: Icon(Icons.apple),
                    ),
                    Text(language.lblSignInWithApple, style: boldTextStyle(size: 12), textAlign: TextAlign.center).expand(),
                  ],
                ),
                onTap: appleSign,
              ),
        ],
      );
    } else {
      return Offstage();
    }
  }

//endregion

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    if (widget.isFromServiceBooking.validate()) {
      setStatusBarColor(Colors.transparent, statusBarIconBrightness: Brightness.dark);
    } else if (widget.isFromDashboard.validate()) {
      setStatusBarColor(Colors.transparent, statusBarIconBrightness: Brightness.light);
    } else {
      setStatusBarColor(primaryColor, statusBarIconBrightness: Brightness.light);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: Navigator.of(context).canPop() ? Container(
              margin: EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),child: BackWidget(iconColor: context.iconColor)) : null,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(statusBarIconBrightness: appStore.isDarkMode ? Brightness.light : Brightness.dark, statusBarColor: context.scaffoldBackgroundColor),
        ),
        body: Body(
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Observer(builder: (context) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    (context.height() * 0.12).toInt().height,
                    _buildTopWidget(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        ),
                        10.width,
                        AppTextField(
                          textFieldType: isAndroid ? TextFieldType.PHONE : TextFieldType.NAME,
                          controller: emailCont,
                          focus: emailFocus,
                          errorThisFieldRequired: language.requiredText,
                          nextFocus: passwordFocus,
                          isValidationRequired: false,
                          decoration: inputDecoration(context, labelText: "${language.hintContactNumberTxt}").copyWith(
                            hintText: '${language.lblExample}: ${selectedCountry.example}',
                            hintStyle: secondaryTextStyle(),
                          ),
                          maxLength: 10,
                          suffix: ic_calling.iconImage(size: 10).paddingAll(14),
                          validator: (val) {
                            if (val == null || val.isEmpty) return language.requiredText;

                            String phone = val.trim();

                            // لو الرقم يبدأ بـ0 نحذفها
                            if (phone.startsWith('0')) phone = phone.substring(1);

                            // الرقم بدون الصفر لازم يكون 9 أرقام
                            if (phone.length != 9) return "رقم الهاتف غير صحيح";

                            return null;
                          },
                        ).expand(),
                      ],
                    ),

                    16.height, // مسافة بين رقم الهاتف وكلمة السر

                    // حقل كلمة السر
                    AppTextField(
                      textFieldType: TextFieldType.PASSWORD,
                      controller: passwordCont,
                      focus: passwordFocus,
                      obscureText: true,
                      suffixPasswordVisibleWidget: ic_show.iconImage(size: 10).paddingAll(14),
                      suffixPasswordInvisibleWidget: ic_hide.iconImage(size: 10).paddingAll(14),
                      decoration: inputDecoration(context, labelText: language.hintPasswordTxt),
                      autoFillHints: [AutofillHints.password],
                      onFieldSubmitted: (s) {
                        _handleLogin();
                      },
                    ),
                    _buildRememberWidget(),
                    if (!getBoolAsync(HAS_IN_REVIEW)) _buildSocialWidget(),
                    30.height,
                  ],
                );
              }),
            ),
          ),
        ),
      ),);
  }
}