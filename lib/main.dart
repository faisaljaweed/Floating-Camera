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

  const MyApp({Key? key, required this.cameras}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final floating = Floating();
  CameraController? _controller;
  bool isPiPEnabled = false; // State variable for PiP mode attempt

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
      // When app resumes (comes back from PiP), show the button again
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
    await floating.enable(aspectRatio: Rational(10, 9));
    setState(() {
      isPiPEnabled = true; // Assume PiP mode is attempted/enabled
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _controller != null && _controller!.value.isInitialized
            ? Container(
                width: double.infinity,
                height: double.infinity,
                child: CameraPreview(_controller!),
              )
            : Center(
                child:
                    const Text("Loading Camera...", key: Key('loadingCamera')),
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
