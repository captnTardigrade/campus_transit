import 'package:flutter/material.dart';

class ErrorButton extends StatelessWidget {
  const ErrorButton(
      {super.key,
      required this.callBack,
      required this.error,
      required this.buttonText});

  final String error;
  final VoidCallback callBack;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(error),
          ElevatedButton(
            onPressed: callBack,
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
