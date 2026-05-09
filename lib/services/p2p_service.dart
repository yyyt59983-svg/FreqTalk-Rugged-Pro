import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'dart:async';

class P2PService {
  final _p2p = FlutterP2pConnection();
  List<DiscoveredPeers> peers = [];
  WifiP2PGroupInfo? groupInfo;
  
  StreamSubscription? _peerStream;
  StreamSubscription? _connectionStream;

  Future<void> init() async {
    await _p2p.initialize();
    
    _peerStream = _p2p.streamPeers().listen((event) {
      peers = event;
      print("P2P: Discovered ${peers.length} peers");
    });

    _connectionStream = _p2p.streamWifiP2PInfo().listen((event) {
      groupInfo = event;
      print("P2P: Connection status changed: ${event.isConnected}");
    });
  }

  Future<void> discover() async {
    bool? started = await _p2p.discover();
    print("P2P: Discovery started: $started");
  }

  Future<void> stopDiscovery() async {
    await _p2p.stopDiscovery();
  }

  Future<void> connect(DiscoveredPeers peer) async {
    await _p2p.connect(peer.deviceAddress);
  }

  void dispose() {
    _peerStream?.cancel();
    _connectionStream?.cancel();
    _p2p.unregister();
  }
}
