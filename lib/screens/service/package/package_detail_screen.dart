import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/package_data_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/base_scaffold_widget.dart';

class PackageDetailScreen extends StatefulWidget {
  final BookingPackage packageData;
  final bool? isFromServiceDetail;
  final Function(BookingPackage?)? callBack;

  PackageDetailScreen({required this.packageData, this.isFromServiceDetail = false, this.callBack});

  @override
  _PackageDetailScreenState createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: widget.packageData.name.validate(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: boxDecorationWithRoundedCorners(borderRadius: radiusOnly(topLeft: defaultRadius, topRight: defaultRadius), backgroundColor: context.cardColor),
              child: AnimatedScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        language.packageDescription,
                        style: boldTextStyle(size: LABEL_TEXT_SIZE),
                      ),
                      8.height,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          4.height,
                          widget.packageData.description.validate().isNotEmpty
                              ? ReadMoreText(
                                  widget.packageData.description.validate(),
                                  style: primaryTextStyle(size: 12),
                                  textAlign: TextAlign.justify,
                                  colorClickableText: context.primaryColor,
                                )
                              : Text(language.lblNotDescription, style: secondaryTextStyle()),
                        ],
                      ),
                      16.height,
                      Text(language.packagePrice, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                      8.height,
                      Row(
                        children: [
                          PriceWidget(price: widget.packageData.price.validate()),
                          4.width,
                          if (widget.packageData.isPackageDiscountApplied)
                            PriceWidget(
                              price: widget.packageData.originalPrice,
                              hourlyTextColor: Colors.white,
                              size: 12,
                              isBoldText: false,
                              isLineThroughEnabled: true,
                            ),
                        ],
                      ),
                      Divider(height: 30),
                      Text(language.getTheseServiceWithThisPackage, style: secondaryTextStyle()),
                      8.height,
                      if (widget.packageData.serviceList != null)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: widget.packageData.serviceList!.length,
                          itemBuilder: (_, i) {
                            ServiceData data = widget.packageData.serviceList![i];
                            return Container(
                              width: context.width(),
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              margin: EdgeInsets.symmetric(vertical: 8),
                              decoration: boxDecorationWithRoundedCorners(
                                borderRadius: radius(),
                                backgroundColor: context.scaffoldBackgroundColor,
                                border: appStore.isDarkMode ? Border.all(color: context.dividerColor) : null,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CachedImageWidget(
                                    url: data.attachments!.isNotEmpty ? data.attachments!.first : "",
                                    height: 70,
                                    width: 70,
                                    fit: BoxFit.cover,
                                    radius: 8,
                                  ),
                                  16.width,
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Marquee(child: Text(data.name.validate(), style: boldTextStyle(size: LABEL_TEXT_SIZE))),
                                      4.height,
                                      if (data.subCategoryName.validate().isNotEmpty)
                                        Marquee(
                                          child: Row(
                                            children: [
                                              Text('${data.categoryName}', style: boldTextStyle(size: 12, color: textSecondaryColorGlobal)),
                                              Text('  >  ', style: boldTextStyle(size: 14, color: textSecondaryColorGlobal)),
                                              Text('${data.subCategoryName}', style: boldTextStyle(size: 12, color: context.primaryColor)),
                                            ],
                                          ),
                                        )
                                      else
                                        Text('${data.categoryName}', style: boldTextStyle(size: 12, color: context.primaryColor)),
                                      4.height,
                                      PriceWidget(
                                        price: data.price.validate(),
                                        hourlyTextColor: Colors.white,
                                        size: 14,
                                      ),
                                    ],
                                  ).expand()
                                ],
                              ),
                            ).onTap(() {
                              ServiceDetailScreen(serviceId: data.id.validate()).launch(context);
                            });
                          },
                        )
                    ],
                  ),
                ],
              ),
            ),
          ),
          AppButton(
            onTap: () {
              widget.callBack?.call(widget.packageData);
            },
            color: context.primaryColor,
            child: Text(language.lblBookNow, style: boldTextStyle(color: white)),
            width: context.width(),
            textColor: Colors.white,
          ).paddingSymmetric(horizontal: 16.0, vertical: 10.0)
        ],
      ),
    );
  }
}
