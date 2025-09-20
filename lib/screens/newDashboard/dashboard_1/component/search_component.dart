import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../main.dart';
import '../../../../model/service_data_model.dart';
import '../../../../utils/common.dart';
import '../../../../utils/images.dart';
import '../../../service/search_service_screen.dart';

class SearchComponent extends StatefulWidget {
  final List<ServiceData>? featuredList;

  SearchComponent({this.featuredList});

  @override
  State<SearchComponent> createState() => _SearchComponentState();
}

class _SearchComponentState extends State<SearchComponent> {
  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      return Container(
        height: 50,
        width: context.width(),
        decoration: boxDecorationDefault(color: context.cardColor),
        child: AppTextField(
          textFieldType: TextFieldType.NAME,
          readOnly: true,
          onTap: () {
            SearchServiceScreen(featuredList: widget.featuredList).launch(context);
          },
          decoration: inputDecoration(
            context,
            hintText: language.eGCleaningPlumberPest,
            prefixIcon: Image.asset(
              ic_search,
              width: 10,
              height: 10,
              color: context.iconColor,
            ).paddingAll(14),
          ),
        ),
      );
    });
  }
}
