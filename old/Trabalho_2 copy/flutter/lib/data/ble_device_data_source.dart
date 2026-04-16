import '../models/device.dart';
import 'device_data_source.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleDeviceDataSource implements DeviceDataSource {
  @override
  Stream<List<Device>> getDevices() async* {
    // Start scanning if not already scanning
    if (!(await FlutterBluePlus.isScanning.first)) {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    }

    // Emit results as they arrive
    await for (final results in FlutterBluePlus.scanResults) {
      List<Device> bleDevices = results.map((r) {
        return Device(
          id: r.device.remoteId.str,
          name: r.device.platformName.isEmpty ? "Unknown Device" : r.device.platformName,
          rssi: r.rssi,
          nativeDevice: r.device,
        );
      }).toList();

      yield bleDevices;
    }
  }

  @override
  Stream<int> getSensorValue(Device device, String sensor) async* {
    if (device.nativeDevice == null) {
      yield 0; // fallback for fake devices
      return;
    }

    final d = device.nativeDevice!;

    try {
      await d.connect(autoConnect: false);
    } catch (e) {
      // already connected or failed
      print("BLE connect error: $e");
    }

    List<BluetoothService> services = [];
    try {
      services = await d.discoverServices();
    } catch (e) {
      print("BLE discover error: $e");
      return;
    }

    for (var service in services) {
      for (var characteristic in service.characteristics) {
        try {
          await characteristic.setNotifyValue(true);
          yield* characteristic.lastValueStream.map((value) => value.isNotEmpty ? value[0] : 0);
        } catch (e) {
          print("Characteristic error: $e");
        }
      }
    }
  }
}