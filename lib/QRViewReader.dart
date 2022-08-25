import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class QRViewReader extends StatefulWidget {
  const QRViewReader({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => QRViewReaderState();
}

class QRViewReaderState extends State<QRViewReader> {
  QRViewController? controller;
  ECPublicKey? publicKey;
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
          Expanded(flex: 5, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  const Text('Present a digital signature stamp'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () async {
                              FilePickerResult? result =
                                  await FilePicker.platform.pickFiles(
                                      allowMultiple: false,
                                      allowCompression: false,
                                      allowedExtensions: ['pem', 'pub', 'key'],
                                      dialogTitle: 'Load a public key file',
                                      type: FileType.custom,
                                      withData: true,
                                      withReadStream: false);
                              if (result == null) return;
                              PlatformFile file = result.files.first;
                              Uint8List? data = file.bytes;
                              if (data == null) return;
                              setState(() {
                                publicKey =
                                    ECPublicKey(String.fromCharCodes(data));
                              });
                            },
                            onLongPress: (() => publicKey = null),
                            style:
                                ElevatedButton.styleFrom(primary: Colors.white),
                            child: Icon(
                                publicKey == null
                                    ? Icons.key_off_rounded
                                    : Icons.key_rounded,
                                color: publicKey == null
                                    ? Colors.orange
                                    : Colors.green,
                                size: 30)),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () async {
                              await controller?.toggleFlash();
                              setState(() {});
                            },
                            style:
                                ElevatedButton.styleFrom(primary: Colors.white),
                            child: FutureBuilder(
                              future: controller?.getFlashStatus(),
                              builder: (context, snapshot) {
                                return Icon(
                                    snapshot.data == false
                                        ? Icons.flash_off_rounded
                                        : Icons.flash_on_rounded,
                                    color: Colors.brown,
                                    size: 30);
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
    double scanArea = (MediaQuery.of(context).size.width < 300 ||
            MediaQuery.of(context).size.height < 300)
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
        ECPublicKey? key = publicKey;
        if (key != null) {
          final JWT jwt = JWT.verify(scanData.code ?? '', key);
          _showInvoiceInformation(
              context,
              'Valid signature!',
              jwt.header?['kid'],
              jwt.issuer,
              jwt.subject,
              jwt.payload['ref'],
              DateTime.fromMillisecondsSinceEpoch(jwt.payload['iat'] * 1000),
              DateTime.fromMillisecondsSinceEpoch(
                  jwt.payload['dueDate'] * 1000),
              jwt.payload['curr'],
              jwt.payload['amt'],
              jwt.payload['qty'],
              jwt.payload['line'],
              jwt.payload['pay']);
        } else {
          final jwt = JwtDecoder.decode(scanData.code ?? '');
          _showInvoiceInformation(
              context,
              'Unable to authenticate',
              'No kid',
              jwt['iss'],
              jwt['sub'],
              jwt['ref'],
              DateTime.fromMillisecondsSinceEpoch(jwt['iat'] * 1000),
              DateTime.fromMillisecondsSinceEpoch(jwt['dueDate'] * 1000),
              jwt['curr'],
              jwt['amt'],
              jwt['qty'],
              jwt['line'],
              jwt['pay']);
        }
      } catch (e) {
        _showInformation(context, 'Error', e.toString());
      }
    });
    controller.pauseCamera();
    controller.resumeCamera();
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Unable to scan without camera access permission')));
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

  void _showInvoiceInformation(
      BuildContext context,
      String title,
      String? kid,
      String? issuer,
      String? subject,
      String? reference,
      DateTime? issueDate,
      DateTime? dueDate,
      String? currency,
      double? amount,
      int? quantity,
      int? line,
      dynamic pay) {
    final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
    _showInformation(context, title, '''Signed by: ${kid ?? 'no kid'}
From : $issuer
To : $subject
Reference: $reference
Issue date: ${issueDate != null ? dateFormatter.format(issueDate) : "N/A"}
Due date: ${dueDate != null ? dateFormatter.format(dueDate) : "N/A"}
Amount: $currency ${amount != null ? amount.toStringAsFixed(2) : "N/A"}
Quantity: $quantity
Number of line: $line
Status: ${pay == false ? 'Unpaid' : "Paid/$pay"}
''');
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
