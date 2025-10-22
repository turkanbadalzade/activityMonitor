import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service that polls macOS for time since the last user input.
class InactivityService {
  static const MethodChannel _channel = MethodChannel('com.example.inactivity/detector');
  final StreamController<Duration> _controller = StreamController<Duration>.broadcast();
  Timer? _timer;

  Stream<Duration> get idleStream => _controller.stream;

  void start({Duration interval = const Duration(seconds: 1)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      try {
        final int? ms = await _channel.invokeMethod<int>('getIdleTimeMs');
        if (ms != null && !_controller.isClosed) {
          _controller.add(Duration(milliseconds: ms));
        }
      } catch (e) {
        // Optionally handle errors here or emit Duration.zero
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: SafeArea(child: InactivityView()),
      ),
    );
  }
}

class InactivityView extends StatefulWidget {
  const InactivityView({super.key});

  @override
  State<InactivityView> createState() => _InactivityViewState();
}

class _InactivityViewState extends State<InactivityView> {
  late final InactivityService _inactivity;

  @override
  void initState() {
    super.initState();
    _inactivity = InactivityService()..start();
  }

  @override
  void dispose() {
    _inactivity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StreamBuilder<Duration>(
        stream: _inactivity.idleStream,
        builder: (context, snapshot) {
          final d = snapshot.data ?? Duration.zero;
          final secs = d.inSeconds;
          return Text('Idle: ${secs}s', style: const TextStyle(fontSize: 24));
        },
      ),
    );
  }
}