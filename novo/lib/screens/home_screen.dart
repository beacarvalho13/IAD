import 'dart:async';
import 'package:flutter/material.dart';
import 'package:meu_projeto/data/device_data_source.dart';
import 'package:meu_projeto/models/app_mode.dart';
import 'package:meu_projeto/services/message_bus.dart';
import 'package:meu_projeto/services/morse_decoder_service.dart';
import 'package:meu_projeto/services/words_decoder_service.dart';
import '../models/device.dart';
import '../widgets/device_card.dart';
import '../data/fake_device_data_source.dart';
import '../data/ble_device_data_source.dart';
import 'writer_screen.dart';
import 'reader_screen.dart';
import 'words_writer_screen.dart';
import 'words_reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CommunicationMode currentMode = CommunicationMode.morse;

  List<Device> devices = [];
  bool isScanning = false;
  Device? connectedDevice;

  final DeviceDataSource fakedataSource = FakeDeviceDataSource();
  final DeviceDataSource bleDataSource = BleDeviceDataSource();

  List<Device> _bleDevices = [];
  List<Device> _fakeDevices = [];

  StreamSubscription<List<Device>>? _bleSub;
  StreamSubscription<List<Device>>? _fakeSub;

  // ---------------- SCAN ----------------

  void startScan() {
    setState(() {
      isScanning = true;
      devices = [];
      _bleDevices = [];
      _fakeDevices = [];
    });

    _bleSub?.cancel();
    _fakeSub?.cancel();

    _bleSub = bleDataSource.getDevices().listen((found) {
      _bleDevices = found;
      _updateDevices();
    });

    _fakeSub = fakedataSource.getDevices().listen((found) {
      _fakeDevices = found;
      _updateDevices();
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => isScanning = false);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: _buildScanResults(),
      ),
    );
  }

  void _updateDevices() {
    final Map<String, Device> all = {};

    for (var d in _fakeDevices) all[d.id] = d;
    for (var d in _bleDevices) all[d.id] = d;

    setState(() {
      devices = all.values.toList();
    });
  }

  // ---------------- DEVICE SELECT ----------------

  void selectDevice(Device device) {
    setState(() {
      connectedDevice = device;
    });

    Navigator.pop(context);

    final resolvedDevice = _resolveFakeDevice(device);
    final dataSource =
        resolvedDevice.nativeDevice == null ? fakedataSource : bleDataSource;

    // 🔥 ONLY LINE YOU NEED FOR EVERYTHING TO WORK
    if (appMode.value == CommunicationMode.morse) {
      GlobalMorseService().initDecoder(resolvedDevice, dataSource);
      GlobalMorseService().clearMessage();
    } else {
      WordsDecoderService().initDecoder(resolvedDevice, dataSource);
      WordsDecoderService().clearMessage();
    }
  }

  // ---------------- FAKE DEVICE ----------------

  Device _resolveFakeDevice(Device selected) {
    final isFake = selected.nativeDevice == null;

    if (!isFake) return selected;

    if (appMode.value == CommunicationMode.morse) {
      return Device(
        name: "Fake Sensor A",
        id: "FAKE_01",
        rssi: -40,
        nativeDevice: null,
      );
    } else {
      return Device(
        name: "Fake Sensor B",
        id: "FAKE_02",
        rssi: -60,
        nativeDevice: null,
      );
    }
  }

  // ---------------- MODE SWITCH ----------------

  void switchMode(CommunicationMode mode) {
    GlobalMorseService().dispose();
    WordsDecoderService().dispose();

    MessageBus.updateMessage("");
    MessageBus.updateCurrentPath("");

    appMode.value = mode;

    setState(() {});
  }

  // ---------------- NAVIGATION ----------------

  void openWriter(Device device) {
    final resolved = _resolveFakeDevice(device);

    if (appMode.value == CommunicationMode.morse) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WriterScreen(deviceId: resolved.id),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WordsWriterScreen(deviceId: resolved.id),
        ),
      );
    }
  }

  void openReader(Device device) {
    final resolved = _resolveFakeDevice(device);

    if (appMode.value == CommunicationMode.morse) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReaderScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WordsReaderScreen(),
        ),
      );
    }
  }

  // ---------------- CLEANUP ----------------

  @override
  void dispose() {
    _bleSub?.cancel();
    _fakeSub?.cancel();
    super.dispose();
  }

  // ---------------- UI ----------------

  Widget _buildScanResults() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "Searching for Devices",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (isScanning) const LinearProgressIndicator(),
          const SizedBox(height: 10),
          Expanded(
            child: devices.isEmpty
                ? const Center(child: Text("No devices found yet..."))
                : ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return DeviceCard(
                        device: device,
                        onTap: () => selectDevice(device),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Talky Buddy",
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome!",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // STATUS CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    connectedDevice == null
                        ? Icons.bluetooth_disabled
                        : Icons.bluetooth_connected,
                    size: 40,
                    color: connectedDevice == null
                        ? Colors.grey
                        : colors.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    connectedDevice == null
                        ? "No device connected"
                        : "Connected to: ${connectedDevice!.name}",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isScanning ? null : startScan,
        label: Text(isScanning ? "Scanning..." : "Search Devices"),
        icon: const Icon(Icons.search),
      ),
    );
  }
}