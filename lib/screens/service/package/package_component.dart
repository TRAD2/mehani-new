import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/package_data_model.dart';
import 'package:booking_system_flutter/screens/service/package/package_detail_screen.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/cached_image_widget.dart';
import '../../../component/view_all_label_component.dart';

class PackageComponent extends StatefulWidget {
  final List<BookingPackage> servicePackage;
  final Function(BookingPackage?) callBack;

  PackageComponent({required this.servicePackage, required this.callBack});

  @override
  _PackageComponentState createState() => _PackageComponentState();
}

class _PackageComponentState extends State<PackageComponent> {
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
    if (widget.servicePackage.isEmpty) return Offstage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ViewAllLabel(
          label: language.frequentlyBoughtTogether,
          list: [],
          onTap: () {
            //
          },
        ),
        AnimatedListView(
          listAnimationType: ListAnimationType.FadeIn,
          fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
          shrinkWrap: true,
          itemCount: widget.servicePackage.length,
          padding: EdgeInsets.zero,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (_, i) {
            BookingPackage data = widget.servicePackage[i];

            return Container(
              width: context.width(),
              padding: EdgeInsets.all(16),
              decoration: boxDecorationWithRoundedCorners(
                borderRadius: radius(),
                backgroundColor: context.cardColor,
                border: appStore.isDarkMode ? Border.all(color: context.dividerColor) : null,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CachedImageWidget(
                        url: data.imageAttachments.validate().isNotEmpty ? data.imageAttachments!.first.validate() : "",
                        height: 60,
                        fit: BoxFit.cover,
                        radius: defaultRadius,
                      ),
                      16.width,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Marquee(
                                directionMarguee: DirectionMarguee.oneDirection,
                                child: Text(data.name.validate(), style: boldTextStyle()),
                              ),
                              2.height,
                              Row(
                                children: [
                                  PriceWidget(
                                    price: data.price.validate(),
                                    hourlyTextColor: Colors.white,
                                    size: 12,
                                  ),
                                  4.width,
                                  if (data.isPackageDiscountApplied)
                                    PriceWidget(
                                      price: data.originalPrice,
                                      hourlyTextColor: Colors.white,
                                      size: 12,
                                      isBoldText: false,
                                      isLineThroughEnabled: true,
                                    ),
                                ],
                              ),
                            ],
                          ),
                          if (data.endDate.validate().isNotEmpty)
                            Text(
                              '${language.endOn}: ${formatDate(data.endDate.validate())}',
                              style: boldTextStyle(color: Colors.green, size: 12),
                            ).paddingTop(2),
                        ],
                      ).expand(),
                    ],
                  ),
                  16.height,
                  AppButton(
                    width: context.width(),
                    child: Text(
                      language.buy,
                      style: boldTextStyle(color: context.primaryColor),
                    ),
                    color: context.scaffoldBackgroundColor,
                    onTap: () async {
                      PackageDetailScreen(packageData: data, isFromServiceDetail: true, callBack: widget.callBack).launch(context);
                    },
                  ),
                ],
              ),
            );
          },
        )
      ],
    ).paddingSymmetric(horizontal: 16);
  }
}
