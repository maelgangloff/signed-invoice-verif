import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class QRViewReader extends StatefulWidget {
  const QRViewReader({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => QRViewReaderState();
}

class QRViewReaderState extends State<QRViewReader> {
  QRViewController? controller;
  ECPublicKey publicKey = ECPublicKey('-----BEGIN PUBLIC KEY----- MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEgBW6ULaGUzdOXCY+BgX9CDl6vytP18GtHlmHAHiHDOF8+R1X/lcxhJuKbo0+kYyilq6Mam0f68WyTSQKbZm5lg== -----END PUBLIC KEY-----');
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: _buildQrView(context)
            ),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  const Text('Please present a digital signature stamp'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () async {
                              FilePickerResult? result = await FilePicker.platform.pickFiles(
                                allowMultiple: false,
                                allowCompression: false,
                                allowedExtensions: ['pem', 'pub', 'key'],
                                dialogTitle: 'Load a public key file',
                                type: FileType.custom,
                                withData: true,
                                withReadStream: false
                              );
                              if(result == null) return;
                              PlatformFile file = result.files.first;
                              Uint8List? data = file.bytes;
                              if(data == null) return;
                              setState(() {
                                publicKey = ECPublicKey(String.fromCharCodes(data));
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              primary: Colors.red
                            ),
                            child: FutureBuilder(
                              future: controller?.getCameraInfo(),
                              builder: (context, snapshot) {
                                return const Text('Load key');
                              },
                            )),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () async {
                              await controller?.toggleFlash();
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              primary: Colors.grey
                            ),
                            child: FutureBuilder(
                              future: controller?.getFlashStatus(),
                              builder: (context, snapshot) {
                                return const Text('Flash');
                              },
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    double scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      controller.pauseCamera();
      try {
        final JWT jwt = JWT.verify(scanData.code ?? '', publicKey);
        final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
        _showInformation(context, 'Valid invoice scanned!', '''Signed by: ${jwt.header?['kid'] ?? 'no kid'}
From : ${jwt.issuer}
To : ${jwt.subject}
Reference: ${jwt.payload['ref']}
Issue date: ${dateFormatter.format(DateTime.fromMillisecondsSinceEpoch(jwt.payload['iat'] * 1000))}
Due date: ${dateFormatter.format(DateTime.fromMillisecondsSinceEpoch(jwt.payload['dueDate'] * 1000))}
Amount: ${jwt.payload['curr']} ${jwt.payload['amt'].toStringAsFixed(2)}
Quantity: ${jwt.payload['qty']}
Number of line: ${jwt.payload['line']}
Status: ${jwt.payload['pay'] == false ? 'Unpaid' : "Paid/${jwt.payload['pay']}"}
''');
      } on JWTInvalidError {
        _showInformation(context, 'Error', 'This is not a valid invoice');
      } on JWTExpiredError {
        _showInformation(context, 'Error', 'This document has expired');
      } catch (e) {
        _showInformation(context, 'Error', 'This is not a signed document');
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to scan without camera access permission.')));
    }
  }

  void _showInformation(BuildContext context, String title, String content) {
    showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('OK'),
            onPressed: () {
              controller!.resumeCamera();
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}