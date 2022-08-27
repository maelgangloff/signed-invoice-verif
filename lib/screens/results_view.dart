import 'package:flutter/material.dart';

class ResultsView extends StatelessWidget {
  const ResultsView({
    Key? key,
    required this.data,
    required this.state,
  }) : super(key: key);

  final Map<String, String> data;
  final DecodedState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: state.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: state.appBarBackground,
        foregroundColor: state.appBarText,
        title: Text("${state.name} invoice decoded"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border:
              TableBorder(horizontalInside: BorderSide(color: state.dividerColor ?? Colors.black)),
          children: data.entries
              .map((entry) => TableRow(children: [
                    TableCell(
                        child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )),
                    TableCell(
                        child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 0, 2),
                      child: Text(entry.value),
                    ))
                  ]))
              .toList(),
        ),
      ),
    );
  }
}

abstract class DecodedState {
  Color? appBarBackground;
  Color? appBarText;
  Color? scaffoldBackground;
  Color? dividerColor;
  String? name;
}

class Valid implements DecodedState {
  @override
  Color? appBarBackground = Colors.green.shade900;
  @override
  Color? appBarText = Colors.white;
  @override
  Color? scaffoldBackground = Colors.green.shade50;
  @override
  Color? dividerColor = Colors.green.shade200;
  @override
  String? name = "Valid";
}

class Invalid implements DecodedState {
  @override
  Color? appBarBackground = Colors.red.shade900;
  @override
  Color? appBarText = Colors.white;
  @override
  Color? scaffoldBackground = Colors.red.shade50;
  @override
  Color? dividerColor = Colors.red.shade200;
  @override
  String? name = "Invalid";
}

class Expired implements DecodedState {
  @override
  Color? appBarBackground = Colors.amber.shade900;
  @override
  Color? appBarText = Colors.white;
  @override
  Color? scaffoldBackground = Colors.amber.shade50;
  @override
  Color? dividerColor = Colors.amber.shade200;
  @override
  String? name = "Expired";
}

class Unverified implements DecodedState {
  @override
  Color? appBarBackground = Colors.white;
  @override
  Color? appBarText = Colors.black;
  @override
  Color? scaffoldBackground = Colors.white;
  @override
  Color? dividerColor = Colors.grey.shade400;
  @override
  String? name = "Unverified";
}
