import 'package:flutter/material.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:floating/floating.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatefulWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final floating = Floating();
  CameraController? _controller;
  bool isPiPEnabled = false; // State variable for PiP mode attempt

  // Floating window ke liye state variables
  Offset floatingWindowPosition = Offset(100, 100); // Shuruati position
  double floatingWindowWidth = 200; // Shuruati width
  double floatingWindowHeight = 150; // Shuruati height

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.cameras.isNotEmpty) {
      _controller =
          CameraController(widget.cameras[0], ResolutionPreset.medium);
      _controller!.initialize().then((_) {
        if (mounted) {
          setState(() {});
        }
      }).catchError((e) {
        print('Error initializing camera: $e');
      });
    } else {
      print('No cameras found on this device.');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    super.didChangeAppLifecycleState(lifecycleState);
    if (lifecycleState == AppLifecycleState.resumed) {
      setState(() {
        isPiPEnabled = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> enablePiP() async {
    await floating.enable(aspectRatio: const Rational(4, 3));
    setState(() {
      isPiPEnabled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: <Widget>[
            // Camera Preview
            _controller != null && _controller!.value.isInitialized
                ? SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: CameraPreview(_controller!),
                  )
                : const Center(
                    child: Text("Loading Camera...", key: Key('loadingCamera')),
                  ),

            // Floating Window
          ],
        ),
        floatingActionButton: !isPiPEnabled
            ? FutureBuilder<bool>(
                future: floating.isPipAvailable,
                initialData: false,
                builder: (context, snapshot) {
                  return snapshot.data == true
                      ? FloatingActionButton.extended(
                          onPressed: enablePiP,
                          label: const Text('Enable PiP'),
                          icon: const Icon(Icons.picture_in_picture),
                        )
                      : const SizedBox();
                },
              )
            : null,
      ),
    );
  }
}
