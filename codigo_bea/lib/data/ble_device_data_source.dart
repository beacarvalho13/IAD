import '../models/device.dart';
import 'device_data_source.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

class BleDeviceDataSource implements DeviceDataSource {
  @override
  Stream<List<Device>> getDevices() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    
    return FlutterBluePlus.scanResults.map((results) {
      return results.map((r) {
        return Device(
          id: r.device.remoteId.str,
          // Alterado para usar advName
          name: r.advertisementData.advName.isEmpty ? "Unknown" : r.advertisementData.advName,
          rssi: r.rssi,
          nativeDevice: r.device,
        );
      }).toList();
    });
  }

  @override
  Stream<int> getSensorValue(Device device, String sensor) async* {
    await FlutterBluePlus.stopScan();
    // Definido como broadcast para segurança
    final controller = StreamController<int>.broadcast();
    int _ultimoIdLocal = -1;

    final subscription = FlutterBluePlus.onScanResults.listen((results) {
      for (ScanResult r in results) {
        // Certifica-te que o nome é IGUAL ao do Arduino
        if (r.advertisementData.advName == "TALKY_BUDDY!!!") {
          final mData = r.advertisementData.manufacturerData;
          if (mData.isEmpty) continue;

          final bytes = mData.values.first;

          if (bytes.length >= 2) {
            int idSeq = bytes[0]; 
            int sinal = bytes[1];
            
            print("ID: $idSeq | Sinal: $sinal");

            if (idSeq != _ultimoIdLocal) {
              _ultimoIdLocal = idSeq;
              if (sinal >= 1 && sinal <= 4) {
                print(">>> SINAL VALIDADO: $sinal");
                controller.add(sinal);
              }
            }
          }
        }
      }
    });

    await FlutterBluePlus.startScan(
      androidUsesFineLocation: true,
      androidScanMode: AndroidScanMode.lowLatency,
      continuousUpdates: true, 
    );

    try {
      yield* controller.stream;
    } finally {
      await subscription.cancel();
      await controller.close();
      await FlutterBluePlus.stopScan();
    }
  }
}