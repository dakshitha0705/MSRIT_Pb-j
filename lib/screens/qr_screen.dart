import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScreen extends StatefulWidget {
  final void Function(String code) onScanned;
  const QrScreen({super.key, required this.onScanned});
  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  bool _scanned = false;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(children: [
          MobileScanner(onDetect: (capture) {
            if (_scanned) return;
            final barcode = capture.barcodes.firstOrNull;
            final val = barcode?.rawValue;
            if (val != null) {
              _scanned = true;
              widget.onScanned(val);
              Navigator.pop(context);
            }
          }),
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context)),
                        const Text('Scan QR Code',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600)),
                      ])))),
        ]),
      );
}
