import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:myhealthtrackr/pages/food_product_details_page.dart';
import 'package:myhealthtrackr/pages/food_search_page.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/food_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key, this.initialMealType, this.logDate});

  static const routeName = '/scan-food';
  final String? initialMealType;
  final DateTime? logDate;

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  static const _cameraPermissionKey = 'camera_permission_granted';

  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean8,
      BarcodeFormat.ean13,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );
  final FoodService _foodService = const FoodService();

  _CameraAccessState _cameraAccessState = _CameraAccessState.prompt;
  bool _isHandlingBarcode = false;
  bool _isTorchOn = false;
  String? _cameraErrorMessage;
  String? _lastScannedBarcode;

  @override
  void initState() {
    super.initState();
    _restoreCameraAccessState();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _restoreCameraAccessState() async {
    final preferences = await SharedPreferences.getInstance();
    final hadGrantedAccess = preferences.getBool(_cameraPermissionKey) ?? false;

    if (!mounted || !hadGrantedAccess) return;

    await _requestCameraAccess(showPromptState: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController,
            errorBuilder: (context, error) => _buildScannerErrorState(error),
            onDetect: _handleBarcodeCapture,
          ),
          _buildScannerOverlay(context),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context),
                  const Spacer(),
                  _buildInstructionCard(),
                ],
              ),
            ),
          ),
          if (_isHandlingBarcode)
            Container(
              color: AppColours.overlayDark,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColours.primary),
                  const SizedBox(height: 18),
                  Text(
                    'Looking up food details...',
                    style: AppTextStyles.body.copyWith(
                      color: AppColours.onDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _requestCameraAccess({bool showPromptState = true}) async {
    if (_cameraAccessState == _CameraAccessState.requesting ||
        _isHandlingBarcode) {
      return;
    }

    if (showPromptState) {
      setState(() {
        _cameraAccessState = _CameraAccessState.requesting;
        _cameraErrorMessage = null;
      });
    } else {
      setState(() {
        _cameraErrorMessage = null;
      });
    }

    try {
      await _scannerController.start();
      await _storeCameraPermissionGranted(true);
      if (!mounted) return;

      setState(() {
        _cameraAccessState = _scannerController.value.hasCameraPermission
            ? _CameraAccessState.granted
            : _CameraAccessState.denied;
      });
    } on MobileScannerException catch (error) {
      await _storeCameraPermissionGranted(false);
      if (!mounted) return;

      setState(() {
        _cameraAccessState =
            error.errorCode == MobileScannerErrorCode.permissionDenied
            ? _CameraAccessState.denied
            : _CameraAccessState.error;
        _cameraErrorMessage = _messageForScannerError(error);
      });
    } catch (_) {
      await _storeCameraPermissionGranted(false);
      if (!mounted) return;

      setState(() {
        _cameraAccessState = _CameraAccessState.error;
        _cameraErrorMessage =
            'We could not start the camera right now. Please try again.';
      });
    }
  }

  Future<void> _storeCameraPermissionGranted(bool isGranted) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_cameraPermissionKey, isGranted);
  }

  Future<void> _handleBarcodeCapture(BarcodeCapture capture) async {
    if (_cameraAccessState != _CameraAccessState.granted ||
        _isHandlingBarcode) {
      return;
    }

    final barcode = capture.barcodes
        .map((entry) => entry.rawValue?.trim())
        .whereType<String>()
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');

    if (barcode.isEmpty) return;

    setState(() {
      _isHandlingBarcode = true;
      _lastScannedBarcode = barcode;
    });

    await _scannerController.stop();

    try {
      final product = await _foodService.lookupFoodByBarcode(barcode);
      if (!mounted) return;
      await _openProductDetails(product);
    } on ApiFailure catch (error) {
      if (!mounted) return;
      await _showErrorSheet(error.message);
    } catch (_) {
      if (!mounted) return;
      await _showErrorSheet(
        'Something went wrong while looking up that barcode.',
      );
    } finally {
      if (mounted) {
        setState(() => _isHandlingBarcode = false);
      }
    }
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        _buildTopButton(
          icon: AppIcons.arrowBackRounded,
          onTap: () => Navigator.of(context).pop(),
        ),
        const Spacer(),
        _buildTopButton(
          icon: _isTorchOn ? AppIcons.flashOnRounded : AppIcons.flashOffRounded,
          onTap: _cameraAccessState != _CameraAccessState.granted
              ? null
              : () async {
                  await _scannerController.toggleTorch();
                  if (!mounted) return;
                  setState(() => _isTorchOn = !_isTorchOn);
                },
        ),
      ],
    );
  }

  Widget _buildTopButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColours.secondary.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColours.borderLight),
        ),
        child: Icon(
          icon,
          color: onTap == null ? AppColours.textSubtle : AppColours.onDark,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    final barcode = _lastScannedBarcode;
    final isPermissionPending = _cameraAccessState == _CameraAccessState.prompt;
    final isPermissionDenied = _cameraAccessState == _CameraAccessState.denied;
    final isPermissionError = _cameraAccessState == _CameraAccessState.error;
    final isRequesting = _cameraAccessState == _CameraAccessState.requesting;
    final hasAccess = _cameraAccessState == _CameraAccessState.granted;

    final title = switch (_cameraAccessState) {
      _CameraAccessState.prompt => 'Allow camera access',
      _CameraAccessState.requesting => 'Requesting camera access',
      _CameraAccessState.granted => 'Scan a product barcode',
      _CameraAccessState.denied => 'Camera access is needed',
      _CameraAccessState.error => 'We could not open the camera',
    };

    final message = switch (_cameraAccessState) {
      _CameraAccessState.prompt =>
        'To scan barcodes of food items, MyHealthTrackr needs permission to use your device camera.',
      _CameraAccessState.requesting =>
        'Please respond to the system permission prompt to continue.',
      _CameraAccessState.granted =>
        'Point your camera at the barcode of a food item and we’ll look it up automatically for you.',
      _CameraAccessState.denied =>
        _cameraErrorMessage ??
            'Camera access was denied. Please allow access to continue scanning food barcodes.',
      _CameraAccessState.error =>
        _cameraErrorMessage ??
            'We could not start the camera right now. Please try again.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColours.panelBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColours.shadowHeavy,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.title.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColours.textMuted,
              fontSize: 16,
            ),
          ),
          if (hasAccess && barcode != null) ...[
            const SizedBox(height: 14),
            Text(
              'Last scan: $barcode',
              style: AppTextStyles.label.copyWith(
                color: AppColours.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (!hasAccess) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isRequesting ? null : _requestCameraAccess,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColours.primary,
                  foregroundColor: AppColours.onDark,
                  disabledBackgroundColor: AppColours.primary.withValues(
                    alpha: 0.45,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isPermissionPending
                      ? 'Allow camera access'
                      : isPermissionDenied || isPermissionError
                      ? 'Try again'
                      : 'Waiting for permission',
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 18),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isHandlingBarcode ? null : _openManualSearch,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColours.onDark,
                side: const BorderSide(color: AppColours.borderLight),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(AppIcons.searchRounded),
              label: const Text('Search manually'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Container(
            color: AppColours.overlayDark.withValues(
              alpha: _cameraAccessState == _CameraAccessState.granted
                  ? 0.34
                  : 0.56,
            ),
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColours.primary, width: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openProductDetails(FoodProduct product) async {
    final selectedMealType = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (context) => FoodProductDetailsPage(
          product: product,
          initialMealType: widget.initialMealType,
          logDate: widget.logDate,
        ),
      ),
    );

    if (!mounted) return;
    if (selectedMealType != null && selectedMealType.trim().isNotEmpty) {
      Navigator.of(context).pop(selectedMealType);
      return;
    }
    await _scannerController.start();
  }

  Future<void> _openManualSearch() async {
    final navigator = Navigator.of(context);

    if (_cameraAccessState == _CameraAccessState.granted) {
      await _scannerController.stop();
    }

    final selection = await navigator.push<FoodSearchSelection>(
      MaterialPageRoute<FoodSearchSelection>(
        builder: (context) =>
            FoodSearchPage(initialMealType: widget.initialMealType),
      ),
    );

    if (!mounted) return;

    if (selection?.product != null) {
      await _openProductDetails(selection!.product!);
      return;
    }

    if (selection?.openBarcodeScanner == true) {
      await _scannerController.start();
      return;
    }

    if (_cameraAccessState == _CameraAccessState.granted) {
      await _scannerController.start();
    }
  }

  Future<void> _showErrorSheet(String message) async {
    final shouldScanAgain = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColours.secondary,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We could not match that barcode',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: AppTextStyles.bodyMuted.copyWith(
                    color: AppColours.textMuted,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColours.onDark,
                          side: const BorderSide(color: AppColours.borderLight),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Try again'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColours.primary,
                          foregroundColor: AppColours.onDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    if (shouldScanAgain == true) {
      await _scannerController.start();
    }
  }

  Widget _buildScannerErrorState(MobileScannerException error) {
    if (_cameraAccessState == _CameraAccessState.requesting) {
      return const SizedBox.shrink();
    }

    final isPermissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    final message = _cameraErrorMessage ?? _messageForScannerError(error);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColours.secondary.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColours.panelBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPermissionDenied
                  ? 'Camera permission required'
                  : 'Camera unavailable',
              style: AppTextStyles.title.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: AppTextStyles.bodyMuted.copyWith(
                color: AppColours.textMuted,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _messageForScannerError(MobileScannerException error) {
    return switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Camera access was denied. Please allow camera access when prompted so you can scan barcodes.',
      MobileScannerErrorCode.unsupported =>
        'This device does not support camera scanning.',
      _ => 'We could not start the camera right now. Please try again.',
    };
  }
}

enum _CameraAccessState { prompt, requesting, granted, denied, error }
