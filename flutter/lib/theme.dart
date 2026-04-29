import 'package:flutter/material.dart';

const greige   = Color(0xFFC4B9A8);
const wineDark = Color(0xFF722F37);
const wineMid  = Color(0xFF947080);

final appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: greige,
  colorScheme: ColorScheme.light(
    surface: greige,
    primary: wineDark,
  ),
);
