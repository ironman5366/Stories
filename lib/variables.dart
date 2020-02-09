import 'package:flutter/material.dart';

final theme = new ThemeData(
    primaryColor: Color(0xFFDE6B48),
    accentColor: Color(0xFF7DBBC3),
    splashColor: Color(0xFFDAEDBD),
    backgroundColor: Color(0xFFFAF0E8),
    fontFamily: "Arimo",
    cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(
                Radius.circular(8.0)
            )
        )
    )
);
