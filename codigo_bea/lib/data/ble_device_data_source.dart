import '../models/device.dart';
import 'device_data_source.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

class BleDeviceDataSource implements DeviceDataSource {
  int _ultimoSinalProcessado = -1;

  @override
  Stream<List<Device>> getDevices() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    
    return FlutterBluePlus.scanResults.map((results) {
      return results.map((r) {
        return Device(
          id: r.device.remoteId.str,
          name: r.device.platformName.isEmpty ? "Unknown" : r.device.platformName,
          rssi: r.rssi,
          nativeDevice: r.device,
        );
      }).toList();
    });
  }

  @override
Stream<int> getSensorValue(Device device, String sensor) async* {
  await FlutterBluePlus.stopScan();
  final controller = StreamController<int>();
  int _ultimoIdLocal = -1;

  final subscription = FlutterBluePlus.onScanResults.listen((results) {
    for (ScanResult r in results) {
      // 1. Procuramos pelo nome que definiste no Arduino
      if (r.advertisementData.advName == "TALKY_BUDDY!!!") {
        
        final mData = r.advertisementData.manufacturerData;
        if (mData.isEmpty) continue;

        // Pegamos nos bytes de qualquer chave (Company ID) que o Arduino enviou
        final bytes = mData.values.first;

        if (bytes.length >= 2) {
          int idSeq = bytes[0]; 
          int sinal = bytes[1];

          if (idSeq != _ultimoIdLocal) {
            _ultimoIdLocal = idSeq;
            if (sinal >= 1 && sinal <= 4) {
              print(">>> SINAL CAPTADO: $sinal (ID: $idSeq)");
              controller.add(sinal);
            }
          }
        }
      }
    }
  });

  // CONFIGURAÇÃO DE ALTA AGRESSIVIDADE PARA O SCAN
  await FlutterBluePlus.startScan(
    androidUsesFineLocation: true,
    androidScanMode: AndroidScanMode.lowLatency, // Máxima velocidade
    continuousUpdates: true, 
  );

  try {
    yield* controller.stream;
  } finally {
    subscription.cancel();
    controller.close();
    await FlutterBluePlus.stopScan();
  }
}
}