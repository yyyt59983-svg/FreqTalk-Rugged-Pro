import 'dart:io';
import 'dart:typed_data';
import 'audio_manager.dart';

class UDPService {
  RawDatagramSocket? _socket;
  final int port = 45455;
  final String multicastAddress = '224.0.0.1'; // Local network multicast
  
  String? _currentFrequency;

  Future<void> start(String frequency) async {
    _currentFrequency = frequency;
    
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port, reuseAddress: true);
    _socket!.multicastLoopback = false;
    _socket!.joinMulticast(InternetAddress(multicastAddress));

    _socket!.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? dg = _socket!.receive();
        if (dg != null) {
          _processIncomingPacket(dg.data);
        }
      }
    });
  }

  void _processIncomingPacket(Uint8List data) {
    // Packet structure: [Freq(4)] [Type(1)] [Audio...]
    // Type 1: PTT State Change, Type 2: Audio Chunk
    if (data.length < 5) return;

    int type = data[4];
    if (type == 1) {
      // PTT State Change
      bool talking = data.length > 5 && data[5] == 1;
      if (talking) {
        AudioManager().startReceiving();
      } else {
        AudioManager().stopReceiving();
      }
    } else if (type == 2) {
      // Audio Chunk
      if (AudioManager().state == PTTState.receiving) {
        AudioManager().playAudioChunk(data.sublist(5));
      }
    }
  }

  void broadcastPTT(bool talking) {
    if (_socket == null) return;
    List<int> packet = [1, 2, 3, 4, 1, talking ? 1 : 0];
    _socket!.send(Uint8List.fromList(packet), InternetAddress(multicastAddress), port);
  }

  void sendAudioChunk(Uint8List chunk) {
    if (_socket == null) return;
    List<int> header = [1, 2, 3, 4, 2]; // Type 2 = Audio
    _socket!.send(Uint8List.fromList([...header, ...chunk]), InternetAddress(multicastAddress), port);
  }

  void dispose() {
    _socket?.close();
  }
}
