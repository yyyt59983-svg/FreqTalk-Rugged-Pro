import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../services/audio_manager.dart';
import '../services/webrtc_service.dart';
import '../services/udp_service.dart';
import '../services/discovery_service.dart';
import 'dart:io';
import 'dart:async';
import 'styles.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AudioManager _audio = AudioManager();
  final WebRTCService _webRTC = WebRTCService();
  final UDPService _udp = UDPService();
  final DiscoveryService _discovery = DiscoveryService();
  
  String frequency = "144.000";
  bool isOnline = true;
  bool isScanning = false;
  Timer? scanTimer;
  String deviceName = Platform.isAndroid ? "ANDROID-TAC" : "WINDOWS-TAC";

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  void _initServices() async {
    await _audio.init();
    await _discovery.start(deviceName, 45455);
    
    if (isOnline) {
      await _webRTC.connect(frequency);
    } else {
      await _udp.start(frequency);
    }
    
    // Periodically refresh UI for discovered nodes
    Timer.periodic(Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {});
        // If scanning and we find someone, stop scanning
        if (isScanning && _discovery.nearbyNodes.isNotEmpty) {
          _toggleScan();
        }
      }
    });
  }

  void _toggleScan() {
    setState(() {
      isScanning = !isScanning;
      if (isScanning) {
        scanTimer = Timer.periodic(Duration(milliseconds: 200), (timer) {
          setState(() {
            double freq = double.parse(frequency) + 0.025;
            if (freq > 146.000) freq = 144.000;
            frequency = freq.toStringAsFixed(3);
          });
        });
      } else {
        scanTimer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TacticalTheme.background,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TacticalTheme.accent.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildNearbyNodes(),
                  const SizedBox(height: 30),
                  _buildFrequencySelector(),
                  const Spacer(),
                  _buildStatusIndicator(),
                  const SizedBox(height: 40),
                  _buildPTTButton(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("FREQ-TALK", style: TacticalTheme.headline),
            Text("TACTICAL NET v1.0", style: TacticalTheme.mono.copyWith(fontSize: 12)),
          ],
        ),
        Row(
          children: [
            Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    if (_audio.isPowered) {
                      _audio.powerOff();
                    } else {
                      bool success = await _audio.powerOn();
                      if (success) _initServices();
                    }
                    setState(() {});
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _audio.isPowered ? TacticalTheme.accent : Colors.grey[800],
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Icon(Icons.power_settings_new, color: Colors.white, size: 20),
                  ),
                ),
                Text("PWR", style: TacticalTheme.mono.copyWith(fontSize: 8)),
              ],
            ),
            const SizedBox(width: 15),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: TacticalTheme.glassDecoration,
              child: Row(
                children: [
                  Icon(isOnline ? Icons.public : Icons.router, color: TacticalTheme.accent, size: 16),
                  SizedBox(width: 8),
                  Text(isOnline ? "ONLINE" : "OFFLINE", style: TacticalTheme.mono.copyWith(fontSize: 10)),
                ],
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildNearbyNodes() {
    return FadeInLeft(
      child: Container(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _discovery.nearbyNodes.length,
          itemBuilder: (context, index) {
            return Container(
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: TacticalTheme.glassDecoration.copyWith(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Row(
                  children: [
                    Icon(Icons.radar, color: TacticalTheme.accent, size: 14),
                    SizedBox(width: 8),
                    Text(_discovery.nearbyNodes[index], style: TacticalTheme.mono.copyWith(fontSize: 10)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return FadeInDown(
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: TacticalTheme.glassDecoration,
        child: Column(
          children: [
            Text("CURRENT FREQUENCY", style: TacticalTheme.mono.copyWith(color: Colors.white60)),
            const SizedBox(height: 12),
            Text(frequency, style: TacticalTheme.headline.copyWith(
              fontSize: 48, 
              letterSpacing: 4,
              color: isScanning ? TacticalTheme.accent.withOpacity(0.5) : Colors.white,
            )),
            if (isScanning) 
              FadeIn(
                child: Text("SCANNING...", style: TacticalTheme.mono.copyWith(fontSize: 10, color: TacticalTheme.accent)),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSmallButton(Icons.remove, () {
                  setState(() {
                    double freq = double.parse(frequency) - 0.025;
                    frequency = freq.toStringAsFixed(3);
                  });
                }),
                const SizedBox(width: 20),
                _buildSmallButton(isScanning ? Icons.stop : Icons.radar, _toggleScan),
                const SizedBox(width: 20),
                _buildSmallButton(Icons.add, () {
                  setState(() {
                    double freq = double.parse(frequency) + 0.025;
                    frequency = freq.toStringAsFixed(3);
                  });
                }),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSmallButton(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: TacticalTheme.accent),
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.05),
        padding: EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return StreamBuilder<PTTState>(
      stream: _audio.stateStream,
      initialData: PTTState.idle,
      builder: (context, snapshot) {
        final state = snapshot.data;
        String text = "READY TO TRANSMIT";
        Color color = TacticalTheme.accent;

        if (state == PTTState.transmitting) {
          text = "TRANSMITTING...";
          color = TacticalTheme.alert;
        } else if (state == PTTState.receiving) {
          text = "RECEIVING AUDIO";
          color = Colors.blue;
        }

        return FadeIn(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Pulse(
                infinite: state != PTTState.idle,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
              ),
              const SizedBox(width: 12),
              Text(text, style: TacticalTheme.mono.copyWith(color: color)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPTTButton() {
    return GestureDetector(
      onLongPressStart: (_) async {
        if (!_audio.isPowered) return;
        final stream = await _audio.startTransmitting();
        if (stream != null) {
          if (isOnline) {
            _webRTC.setPtt(true);
          } else {
            _udp.broadcastPTT(true);
            // In offline mode, send the raw bytes over UDP
            stream.listen((chunk) {
              if (_audio.state == PTTState.transmitting) {
                _udp.sendAudioChunk(chunk);
              }
            });
          }
        }
      },
      onLongPressEnd: (_) {
        if (!_audio.isPowered) return;
        _audio.stopTransmitting();
        if (isOnline) _webRTC.setPtt(false);
        else _udp.broadcastPTT(false);
      },
      child: StreamBuilder<PTTState>(
        stream: _audio.stateStream,
        initialData: PTTState.idle,
        builder: (context, snapshot) {
          final isTransmitting = snapshot.data == PTTState.transmitting;
          
          return AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTransmitting ? TacticalTheme.alert : TacticalTheme.surface,
              border: Border.all(
                color: isTransmitting ? Colors.white : TacticalTheme.accent,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: isTransmitting ? TacticalTheme.alert.withOpacity(0.5) : TacticalTheme.accent.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isTransmitting ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 60,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "PTT",
                    style: TacticalTheme.headline.copyWith(fontSize: 20),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
