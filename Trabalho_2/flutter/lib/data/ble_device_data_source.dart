import '../models/device.dart';
import 'device_data_source.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleDeviceDataSource implements DeviceDataSource {
  @override
  Stream<List<Device>> getDevices() {
    // 1. Inicia o scan
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    // 2. Usa yield* (ou return do stream convertido)
    return FlutterBluePlus.scanResults.map((results) {
      return results.map((r) {
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
    if (device.nativeDevice == null) return;

    final d = device.nativeDevice!;
    
    // Garante conexão
    await d.connect(autoConnect: false).catchError((e) => print(e));
    
    List<BluetoothService> services = await d.discoverServices();

    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.uuid.toString().toLowerCase() == sensor.toLowerCase()) {
          await characteristic.setNotifyValue(true);
          
          yield* characteristic.onValueReceived.map((value) {
            return value.isNotEmpty ? value[0] : 0;
          });
          return; // Sai da função após encontrar a característica certa
        }
      }
    }
  }
}