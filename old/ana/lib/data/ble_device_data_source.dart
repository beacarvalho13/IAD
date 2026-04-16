import '../models/device.dart';
import 'device_data_source.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

class BleDeviceDataSource implements DeviceDataSource {
  StreamSubscription<List<ScanResult>>? _sub;

  @override
  Stream<List<Device>> getDevices() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    return FlutterBluePlus.scanResults.map((results) {
      return results.map((r) {
        return Device(
          id: r.device.remoteId.str,
          name: r.device.platformName.isEmpty
              ? "Arduino Beacon"
              : r.device.platformName,
          rssi: r.rssi,
          nativeDevice: null,
        );
      }).toList();
    });
  }

  // ❗ IMPORTANT: ONLY raw signal emitter
  void listenToBeacon(Function(int signal) onSignal) {
    FlutterBluePlus.stopScan();
    FlutterBluePlus.startScan(timeout: null);

    _sub?.cancel();

    _sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final data = r.advertisementData.manufacturerData;

        if (data.isNotEmpty) {
          final bytes = data.values.first;

          if (bytes.length >= 2) {
            onSignal(bytes[1]); // raw signal ONLY
          }
        }
      }
    });
  }

  void dispose() {
    _sub?.cancel();
    FlutterBluePlus.stopScan();
  }

  @override
  Stream<int> getSensorValue(Device device, String sensor) {
    throw UnimplementedError(
      "Not used anymore for beacon mode"
    );
  }
}