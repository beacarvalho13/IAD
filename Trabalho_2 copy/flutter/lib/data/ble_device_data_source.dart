import '../models/device.dart';
import 'device_data_source.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleDeviceDataSource implements DeviceDataSource {
  @override
  Stream<List<Device>> getDevices() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    return FlutterBluePlus.scanResults.map((List<ScanResult> results) {
      return results.map((ScanResult r) {
        return Device(
          id: r.device.remoteId.str,
          name: r.device.platformName.isEmpty ? "Unknown Device" : r.device.platformName,
          rssi: r.rssi,
          nativeDevice: r.device,
        );
      }).toList();
    });
  }

  @override
  Stream<int> getSensorValue(Device device, String sensor) async* {
    
    if (device.nativeDevice == null) {
      yield 0; // or fake value if you want
      return;
    }

    final d = device.nativeDevice!;

    try {
      await d.connect(autoConnect: false);
    } catch (e) {
      // already connected or failed → ignore
      print("Connect error: $e");
    }

    
        List<BluetoothService> services;
    try {
      services = await d.discoverServices();
    } catch (e) {
      print("Discover error: $e");
      return;
    }

    for (var service in services) {
      print("Service: ${service.uuid}");

      // ⚠️ This comparison is probably wrong (see note below)
      if (service.uuid.toString().toLowerCase() == sensor.toLowerCase()) {

        for (var characteristic in service.characteristics) {
          await characteristic.setNotifyValue(true);

          yield* characteristic.lastValueStream.map((value) {
            return value.isNotEmpty ? value[0] : 0;
          });
        }
      }
    }
  }
}