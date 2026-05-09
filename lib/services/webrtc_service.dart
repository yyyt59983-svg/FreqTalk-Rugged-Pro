import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'audio_manager.dart';

class WebRTCService {
  IO.Socket? _socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  
  final String serverUrl = "http://YOUR_SERVER_IP:3000"; // Update with real IP
  String? _currentFrequency;

  // Configuration for WebRTC
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ]
  };

  Future<void> connect(String frequency) async {
    _currentFrequency = frequency;
    
    _socket = IO.io(serverUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .build());

    _socket!.onConnect((_) {
      print('Connected to Signaling Server');
      _socket!.emit('join-frequency', frequency);
    });

    _socket!.on('signal', (data) async {
      var signal = data['signal'];
      var from = data['from'];

      if (signal['type'] == 'offer') {
        await _handleOffer(signal, from);
      } else if (signal['type'] == 'answer') {
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(signal['sdp'], signal['type'])
        );
      } else if (signal['type'] == 'candidate') {
        await _peerConnection?.addCandidate(
          RTCIceCandidate(signal['candidate'], signal['sdpMid'], signal['sdpMLineIndex'])
        );
      }
    });

    _socket!.on('remote-ptt-start', (data) {
      AudioManager().startReceiving();
    });

    _socket!.on('remote-ptt-stop', (data) {
      AudioManager().stopReceiving();
    });

    await _initLocalStream();
  }

  Future<void> _initLocalStream() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    // Initially mute the stream for PTT
    _localStream!.getAudioTracks()[0].enabled = false;
  }

  Future<void> setPtt(bool talking) async {
    if (_localStream != null) {
      _localStream!.getAudioTracks()[0].enabled = talking;
      
      if (talking) {
        _socket?.emit('ptt-start', _currentFrequency);
      } else {
        _socket?.emit('ptt-stop', _currentFrequency);
      }
    }
  }

  Future<void> _handleOffer(dynamic offer, String from) async {
    _peerConnection = await createPeerConnection(_iceServers);
    
    _peerConnection!.onIceCandidate = (candidate) {
      _socket?.emit('signal', {
        'to': from,
        'signal': {
          'type': 'candidate',
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        }
      });
    };

    _peerConnection!.onTrack = (event) {
      // Remote audio track received
      // In a real walkie-talkie, we'd play this track whenAudioManager says receiving
    };

    await _peerConnection!.addStream(_localStream!);
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type'])
    );

    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _socket?.emit('signal', {
      'to': from,
      'signal': {
        'type': 'answer',
        'sdp': answer.sdp,
      }
    });
  }

  void dispose() {
    _localStream?.dispose();
    _peerConnection?.dispose();
    _socket?.disconnect();
  }
}
