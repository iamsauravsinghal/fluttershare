import 'package:flutter/material.dart';

header(BuildContext context,
    {bool isAppHeader = false, String title, bool hasBackButton = true}) {
  return AppBar(
    automaticallyImplyLeading: hasBackButton,
    title: Text(
      isAppHeader ? 'PixShare' : title,
      style: TextStyle(
        color: Colors.white,
        fontFamily: isAppHeader ? "Signatra" : "",
        fontSize: isAppHeader ? 50.0 : 22.0,
      ),
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
  );
}
