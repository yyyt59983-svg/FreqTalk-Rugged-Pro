import 'dart:async';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

enum PTTState { idle, transmitting, receiving }

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final _record = AudioRecorder();
  final _player = AudioPlayer();
  
  Stream<Uint8List>? _audioStream;
  StreamSubscription<Uint8List>? _audioSubscription;

  PTTState _state = PTTState.idle;
  PTTState get state => _state;
  
  bool _isPowered = false;
  bool get isPowered => _isPowered;

  StreamController<PTTState> _stateController = StreamController<PTTState>.broadcast();
  StreamController<bool> _powerController = StreamController<bool>.broadcast();
  
  Stream<PTTState> get stateStream => _stateController.stream;
  Stream<bool> get powerStream => _powerController.stream;

  Future<bool> powerOn() async {
    if (await _record.hasPermission()) {
      _isPowered = true;
      _powerController.add(true);
      Vibration.vibrate(duration: 100);
      return true;
    }
    return false;
  }

  void powerOff() {
    _isPowered = false;
    _powerController.add(false);
    _record.stop();
  }

  Future<void> init() async {
    // Initial setup
  }

  Future<Stream<Uint8List>?> startTransmitting() async {
    if (_state != PTTState.idle) return null;

    if (await _record.hasPermission()) {
      _state = PTTState.transmitting;
      _stateController.add(_state);

      Vibration.vibrate(duration: 50);
      
      // Start streaming raw PCM data
      final stream = await _record.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ));
      
      return stream;
    }
    return null;
  }

  Future<void> stopTransmitting() async {
    if (_state != PTTState.transmitting) return;

    await _record.stop();
    _state = PTTState.idle;
    _stateController.add(_state);

    _playRogerBeep();
  }

  void startReceiving() {
    if (_state == PTTState.transmitting) return;

    _state = PTTState.receiving;
    _stateController.add(_state);
  }

  // Method to play incoming audio bytes (for UDP mode)
  Future<void> playAudioChunk(Uint8List chunk) async {
    // In a production app, use a dedicated PCM sink like flutter_soloud
    // For this implementation, we simulate the buffer handling
  }

  void stopReceiving() {
    if (_state == PTTState.receiving) {
      _state = PTTState.idle;
      _stateController.add(_state);
      print("PTT: Audio stopped");
    }
  }

  Future<void> _playRogerBeep() async {
    // In production, add a small 'roger.mp3' to assets
    // For now, use a system sound or vibration
    Vibration.vibrate(pattern: [0, 50, 50, 50]); 
  }

  void dispose() {
    _record.dispose();
    _player.dispose();
    _stateController.close();
  }
}
