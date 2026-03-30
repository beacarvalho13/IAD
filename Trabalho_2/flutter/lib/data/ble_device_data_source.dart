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
    await device.nativeDevice.connect();
    List<BluetoothService> services = await device.nativeDevice.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toLowerCase()==sensor.toLowerCase()) {
        for (var characteristics in service.characteristics) {
          await characteristics.setNotifyValue(true);
          yield* characteristics.lastValueStream.map((value) {
            return value.isNotEmpty ? value[0] : 0;
          });
        }
      }
    }
  }
  
}