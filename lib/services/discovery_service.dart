import 'package:bonsoir/bonsoir.dart';
import 'dart:io';

class DiscoveryService {
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  
  final String type = '_freqtalk._tcp';
  final List<String> nearbyNodes = [];

  Future<void> start(String deviceName, int port) async {
    // 1. Broadcast ourselves
    BonsoirService service = BonsoirService(
      name: deviceName,
      type: type,
      port: port,
      attributes: {'version': '1.0'},
    );

    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.ready;
    await _broadcast!.start();

    // 2. Discover others
    _discovery = BonsoirDiscovery(type: type);
    await _discovery!.ready;
    
    _discovery!.eventStream!.listen((event) {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved ||
          event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
        if (event.service != null && !nearbyNodes.contains(event.service!.name)) {
          nearbyNodes.add(event.service!.name);
          print("Discovered Node: ${event.service!.name}");
        }
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
        nearbyNodes.remove(event.service?.name);
      }
    });

    await _discovery!.start();
  }

  void stop() {
    _broadcast?.stop();
    _discovery?.stop();
  }
}
