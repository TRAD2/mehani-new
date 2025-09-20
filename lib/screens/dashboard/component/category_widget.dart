import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nb_utils/nb_utils.dart';

class CategoryWidget extends StatelessWidget {
  final CategoryData categoryData;
  final double? width;
  final bool? isFromCategory;

  CategoryWidget({required this.categoryData, this.width, this.isFromCategory});

  Widget buildDefaultComponent(BuildContext context) {
    final double cardWidth = width ?? (context.width() / 3) - 24;
    final double cardSize = cardWidth;
    final double iconSize = CATEGORY_ICON_SIZE;

    return SizedBox(
      width: cardWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // بطاقات بفئة بيضاء وظل واضح
          Container(
            width: cardSize,
            height: cardSize,
            padding: EdgeInsets.all(CATEGORY_CARD_PADDING),
            decoration: BoxDecoration(
              color: Colors.white, // خلفية بيضاء كما في صورة رقم 2
              borderRadius: BorderRadius.circular(CATEGORY_CARD_RADIUS),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: Offset(0, 4), // ظل واضح تحت البطاقة
                ),
              ],
            ),
            child: Center(
              child: categoryData.categoryImage.validate().endsWith('.svg')
                  ? SvgPicture.network(
                categoryData.categoryImage.validate(),
                height: iconSize,
                width: iconSize,
                placeholderBuilder: (context) => PlaceHolderWidget(
                  height: iconSize,
                  width: iconSize,
                  color: transparentColor,
                ),
              )
                  : CachedImageWidget(
                url: categoryData.categoryImage.validate(),
                fit: BoxFit.contain,
                width: iconSize,
                height: iconSize,
                circle: false,
                placeHolderImage: '',
              ),
            ),
          ),
          10.height,
          Text(
            '${categoryData.name.validate()}',
            style: boldTextStyle(size: 16), // خط كبير وواضح
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget categoryComponent() {
      return Observer(builder: (context) {
        return buildDefaultComponent(context);
      });
    }

    return categoryComponent();
  }
}