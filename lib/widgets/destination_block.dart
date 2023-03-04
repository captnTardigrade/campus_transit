import 'package:flutter/material.dart';

class DestinationBlock extends StatelessWidget {
  final String title;
  final String vehicleId;
  final int color;

  const DestinationBlock(
      {super.key,
      required this.vehicleId,
      required this.color,
      required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Container(
        width: 200,
        height: 100,
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color(color),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                vehicleId,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
