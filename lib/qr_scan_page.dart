import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanPageContent extends StatefulWidget {
  const QrScanPageContent({super.key});

  @override
  QrScanPageContentState createState() => QrScanPageContentState();
}

class QrScanPageContentState extends State<QrScanPageContent> {
  final MobileScannerController controller = MobileScannerController();

  void _handleBarcode(BarcodeCapture barcodeCapture) {
    if (barcodeCapture.barcodes.isNotEmpty) {
      final barcode = barcodeCapture.barcodes.first;
      final String? code = barcode.displayValue;
      if (code != null) {
        ("Barcode detected: $code");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Code Scanner"),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: CameraPreviewWidget(
                  controller: controller,
                  onBarcodeDetected: _handleBarcode,
                ),
              ),
              Container(
                height: screenHeight * 0.2,
                color: Colors.white,
                alignment: Alignment.center,
                child: const Text(
                  'Align the QR code within the frame',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CameraPreviewWidget extends StatefulWidget {
  final MobileScannerController controller;
  final Function(BarcodeCapture) onBarcodeDetected;

  const CameraPreviewWidget({
    required this.controller,
    required this.onBarcodeDetected,
    super.key,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.start();
    widget.controller.barcodes.listen(widget.onBarcodeDetected);
  }

  @override
  void dispose() {
    widget.controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double centerY = screenHeight * 0.4;

    return Stack(
      children: [
        MobileScanner(
          controller: widget.controller,
        ),
        CustomPaint(
          size: Size.infinite,
          painter: _OverlayPainter(
            squareSize: 200.0,
            borderRadius: 20.0,
            borderThickness: 8.0,
            centerY: centerY,
          ),
        ),
      ],
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double squareSize;
  final double borderRadius;
  final double borderThickness;
  final double centerY;

  _OverlayPainter({
    required this.squareSize,
    required this.borderRadius,
    required this.borderThickness,
    required this.centerY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.5);

    // 화면 전체에 오버레이를 그립니다
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    // QR 코드 인식 영역을 설정
    final centerX = size.width / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: squareSize,
        height: squareSize,
      ),
      Radius.circular(borderRadius),
    );

    // QR 코드 영역을 투명하게 처리
    overlayPaint.blendMode = BlendMode.dstOut;
    canvas.drawRRect(rect, overlayPaint);
    canvas.restore();

    // 테두리 설정
    final cornerPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderThickness
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 55;
    double halfSquareSize = squareSize / 2;
    double left = centerX - halfSquareSize;
    double right = centerX + halfSquareSize;
    double top = centerY - halfSquareSize;
    double bottom = centerY + halfSquareSize;

    // 각 모서리에 경계선을 추가
    // 왼쪽 위 모서리
    Path topLeftPath = Path();
    topLeftPath.moveTo(left + cornerLength, top);
    topLeftPath.lineTo(left + borderRadius, top);
    topLeftPath.arcToPoint(
      Offset(left, top + borderRadius),
      radius: Radius.circular(borderRadius),
      clockwise: false,
    );
    topLeftPath.lineTo(left, top + cornerLength);
    canvas.drawPath(topLeftPath, cornerPaint);

    // 왼쪽 아래 모서리
    Path bottomLeftPath = Path();
    bottomLeftPath.moveTo(left + cornerLength, bottom);
    bottomLeftPath.lineTo(left + borderRadius, bottom);
    bottomLeftPath.arcToPoint(
      Offset(left, bottom - borderRadius),
      radius: Radius.circular(borderRadius),
      clockwise: true,
    );
    bottomLeftPath.lineTo(left, bottom - cornerLength);
    canvas.drawPath(bottomLeftPath, cornerPaint);

    // 오른쪽 아래 모서리
    Path bottomRightPath = Path();
    bottomRightPath.moveTo(right - cornerLength, bottom);
    bottomRightPath.lineTo(right - borderRadius, bottom);
    bottomRightPath.arcToPoint(
      Offset(right, bottom - borderRadius),
      radius: Radius.circular(borderRadius),
      clockwise: false,
    );
    bottomRightPath.lineTo(right, bottom - cornerLength);
    canvas.drawPath(bottomRightPath, cornerPaint);

    // 오른쪽 위 모서리
    Path topRightPath = Path();
    topRightPath.moveTo(right - cornerLength, top);
    topRightPath.lineTo(right - borderRadius, top);
    topRightPath.arcToPoint(
      Offset(right, top + borderRadius),
      radius: Radius.circular(borderRadius),
      clockwise: true,
    );
    topRightPath.lineTo(right, top + cornerLength);

    canvas.drawPath(topRightPath, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
