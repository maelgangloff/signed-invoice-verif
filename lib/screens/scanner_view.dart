import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:signed_invoice_verif/screens/informations_view.dart';

import 'results_view.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ScannerViewState();
}

class ScannerViewState extends State<ScannerView> {
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
      appBar: AppBar(
        backgroundColor: Colors.amberAccent,
        title: const Text('Scan a Digital Signature Stamp'),
      ),
      body: Stack(
        children: <Widget>[
          _qrView(context),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.all(8),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Colors.white12),
                child: Row(
                  children: [
                    if (publicKey != null)
                      IconButton(
                          tooltip: "Disable verification",
                          onPressed: () {
                            setState(() {
                              publicKey = null;
                            });
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 30,
                            color: Colors.white,
                          )),
                    IconButton(
                        tooltip: "Load a public key",
                        padding: const EdgeInsets.all(8),
                        onPressed: () async {
                          try {
                            FilePickerResult? result = await FilePicker.platform
                                .pickFiles(
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
                          } on PlatformException catch (e) {
                            if (e.code ==
                                "read_external_storage_permission_denied") {
                              _showInformation(context, "Permission denied",
                                  "Please allow file system access to open a key file.");
                            } else {
                              _showInformation(
                                  context,
                                  "PlatformException",
                                  e.message ??
                                      "An unexpected exception occured");
                            }
                          } on JWTParseError {
                            _showInformation(context, "Invalid public key",
                                "The selected file does not contain a valid prime256v1 public key.");
                          } catch (e) {
                            _showInformation(context,
                                "An unexpected error occured.", e.toString());
                          }
                        },
                        icon: Icon(
                            publicKey == null
                                ? Icons.key_off_rounded
                                : Icons.key_rounded,
                            color: publicKey == null
                                ? Colors.white70
                                : Colors.white,
                            size: 30)),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Colors.white12),
                child: IconButton(
                  tooltip: "Toggle flash",
                  padding: const EdgeInsets.all(8),
                  onPressed: () async {
                    await controller!.resumeCamera();
                    await controller?.toggleFlash();
                    setState(() {});
                  },
                  icon: FutureBuilder<bool?>(
                    future: controller?.getFlashStatus(),
                    builder: (context, snapshot) {
                      return Icon(
                          snapshot.data ?? false
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          color: snapshot.data ?? false
                              ? Colors.white
                              : Colors.white70,
                          size: 30);
                    },
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Colors.white12),
                child: IconButton(
                  tooltip: "More information",
                  padding: const EdgeInsets.all(8),
                  onPressed: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: ((context) {
                      controller?.pauseCamera();
                      return const InformationsView();
                    }))).then((value) => controller?.resumeCamera());
                  },
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _qrView(BuildContext context) {
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.white,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: min(MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.width) *
              .7),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    controller.resumeCamera();
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      controller.pauseCamera();
      try {
        ECPublicKey? key = publicKey;
        if (key != null) {
          final JWT jwt = JWT.verify(scanData.code ?? '', key);
          FlutterBeep.beep(true);
          _showResults(context, Valid(), jwt);
        } else {
          final jwt = JwtDecoder.decode(scanData.code ?? '');
          FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_ABBR_ALERT);
          _showResults(context, Unverified(), jwt);
        }
      } catch (e) {
        FlutterBeep.beep(false);
        if (e is FormatException) {
          _showInformation(context, 'Invalid DSS',
              "Couldn't decode DSS, QR code does not contain a valid JWT token. This happens sometimes when the qr code isn't read properly. In that case you should try again.");
        } else if (e.toString().contains("JWTInvalidError")) {
          final jwt = JwtDecoder.decode(scanData.code ?? '');
          _showResults(context, Invalid(), jwt);
        } else if (e.toString().contains("JWTExpiredError")) {
          final jwt = JwtDecoder.decode(scanData.code ?? '');
          _showResults(context, Expired(), jwt);
        } else {
          _showInformation(context, 'Error', e.toString());
        }
      }
    });
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
            TextButton(
              child: Text(
                'OK',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary),
              ),
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

  void _showResults(BuildContext context, DecodedState state, dynamic jwt) {
    final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
    final DateTime issueDate = DateTime.fromMillisecondsSinceEpoch(
        (jwt is JWT ? jwt.payload['iat'] : jwt['iat']) * 1000);
    final DateTime dueDate = DateTime.fromMillisecondsSinceEpoch(
        (jwt is JWT ? jwt.payload['dueDate'] : jwt['dueDate']) * 1000);
    final dynamic pay = jwt is JWT ? jwt.payload['pay'] : jwt['pay'];
    final Map<String, String> data = {
      'Signed by': "${jwt is JWT ? jwt.header!['kid'] : 'no kid'}",
      'From': "${jwt is JWT ? jwt.issuer : jwt['iss']}",
      'To': "${jwt is JWT ? jwt.subject : jwt['sub']}",
      'Reference': "${jwt is JWT ? jwt.payload['ref'] : jwt['ref']}",
      'Issue date': dateFormatter.format(issueDate),
      'Due date': dateFormatter.format(dueDate),
      'Amount':
          "${jwt is JWT ? jwt.payload['curr'] : jwt['curr']} ${(jwt is JWT ? jwt.payload['amt'] : jwt['amt']).toStringAsFixed(2)}",
      'Quantity': "${jwt is JWT ? jwt.payload['qty'] : jwt['qty']}",
      'Number of line': "${jwt is JWT ? jwt.payload['line'] : jwt['line']}",
      'Status': pay == false ? 'Unpaid' : (pay == null ? "Paid" : "Paid/$pay"),
    };
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: ((context) => ResultsView(data: data, state: state)),
          ),
        )
        .then((value) => controller!.resumeCamera());
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
