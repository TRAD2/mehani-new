import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_1/shimmer/dashboard_shimmer_1.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/empty_error_state_widget.dart';
import '../../../component/loader_widget.dart';
import '../../../model/dashboard_model.dart';
import '../../../model/category_model.dart';
import '../../../network/rest_apis.dart';
import '../../../utils/constant.dart';
import '../../dashboard/component/category_component.dart';
import 'component/booking_confirmed_component_1.dart';
import 'component/feature_services_dashboard_component_1.dart';
import 'component/job_request_dashboard_component_1.dart';
import 'component/search_component.dart';
import 'component/service_list_dashboard_component_1.dart';
import 'component/slider_dashboard_component_1.dart';

class DashboardFragment1 extends StatefulWidget {
  @override
  _DashboardFragment1State createState() => _DashboardFragment1State();
}

class _DashboardFragment1State extends State<DashboardFragment1> {
  Future<DashboardResponse>? future;

  // --------- new state for fetching all categories ----------
  List<CategoryData> fullCategoryList = [];
  int catPage = 1;
  bool catLastPage = false;
  bool isFetchingCategories = false;
  // ---------------------------------------------------------

  @override
  void initState() {
    super.initState();
    init();

    // fetch all categories (paginated) to show on dashboard
    fetchAllCategories();

    setStatusBarColorChange();

    LiveStream().on(LIVESTREAM_UPDATE_DASHBOARD, (p0) {
      init();
      appStore.setLoading(true);

      // re-fetch categories on dashboard update
      fetchAllCategories();

      setState(() {});
    });
  }

  void init() async {
    future = userDashboard(isCurrentLocation: appStore.isCurrentLocation, lat: getDoubleAsync(LATITUDE), long: getDoubleAsync(LONGITUDE));
    setStatusBarColorChange();
    setState(() {});
  }

  // Fetch all categories by paginating through getCategoryListWithPagination
  Future<void> fetchAllCategories() async {
    if (isFetchingCategories) return;
    try {
      isFetchingCategories = true;
      catPage = 1;
      catLastPage = false;
      fullCategoryList.clear();

      while (!catLastPage) {
        // getCategoryListWithPagination appends to categoryList when provided
        await getCategoryListWithPagination(catPage, categoryList: fullCategoryList, lastPageCallBack: (val) {
          catLastPage = val;
        });
        catPage++;
      }
    } catch (e) {
      // ignore errors silently, fallback to dashboard categories
      log(e);
    } finally {
      isFetchingCategories = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> setStatusBarColorChange() async {
    setStatusBarColor(
      statusBarIconBrightness: appStore.isDarkMode
          ? Brightness.light
          : await isNetworkAvailable()
          ? Brightness.light
          : Brightness.dark,
      transparentColor,
      delayInMilliSeconds: 800,
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
    LiveStream().dispose(LIVESTREAM_UPDATE_DASHBOARD);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SnapHelperWidget<DashboardResponse>(
            initialData: cachedDashboardResponse,
            future: future,
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                imageWidget: ErrorStateWidget(),
                retryText: language.reload,
                onRetry: () {
                  appStore.setLoading(true);
                  init();

                  // also re-fetch categories on retry
                  fetchAllCategories();

                  setState(() {});
                },
              );
            },
            loadingWidget: DashboardShimmer1(),
            onSuccess: (snap) {
              return Observer(builder: (context) {
                return AnimatedScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  listAnimationType: ListAnimationType.FadeIn,
                  fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                  onSwipeRefresh: () async {
                    appStore.setLoading(true);

                    setValue(LAST_APP_CONFIGURATION_SYNCED_TIME, 0);
                    init();

                    // refresh categories as well
                    await fetchAllCategories();

                    setState(() {});

                    return await 2.seconds.delay;
                  },
                  children: [
                    // السلايدر في الأعلى
                    SliderDashboardComponent1(
                      sliderList: snap.slider.validate(),
                      featuredList: snap.featuredServices.validate(),
                      callback: () async {
                        appStore.setLoading(true);
                        init();
                        // refresh categories too
                        await fetchAllCategories();
                        setState(() {});
                      },
                    ),

                    // حقل البحث أسفل السلايدر مباشرة
                    Container(
                      padding: EdgeInsets.all(16),
                      color: context.scaffoldBackgroundColor,
                      child: SearchComponent(featuredList: snap.featuredServices.validate()),
                    ),

                    // باقي المكونات
                    BookingConfirmedComponent1(upcomingConfirmedBooking: snap.upcomingData),
                    16.height,

                    // use fullCategoryList when available, otherwise fallback to dashboard 'snap.category'
                    CategoryComponent(
                      categoryList: fullCategoryList.isNotEmpty ? fullCategoryList : snap.category.validate(),
                      isNewDashboard: true,
                    ),

                    16.height,
                    ServiceListDashboardComponent1(serviceList: snap.service.validate()),
                    16.height,
                    FeatureServicesDashboardComponent1(serviceList: snap.featuredServices.validate()),
                    16.height,
                    if (appConfigurationStore.jobRequestStatus) NewJobRequestDashboardComponent1()
                  ],
                );
              });
            },
          ),
          Observer(builder: (context) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}