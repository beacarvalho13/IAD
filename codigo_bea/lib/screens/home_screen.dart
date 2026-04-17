import 'dart:async';
import 'package:flutter/material.dart';
import 'package:meu_projeto/models/app_mode.dart';
import 'package:meu_projeto/services/message_bus.dart';
import 'package:meu_projeto/services/morse_decoder_service.dart';
import 'package:meu_projeto/services/words_decoder_service.dart';
import '../models/device.dart';
import '../widgets/device_card.dart';
import 'writer_screen.dart'; // Importa o novo ecrã
import 'reader_screen.dart'; // Importa o novo ecrã
import '../data/fake_device_data_source.dart';
import '../data/ble_device_data_source.dart';
import '../data/device_data_source.dart';
import 'words_writer_screen.dart';
import 'words_reader_screen.dart';

// Home screen of the app, allowing users to scan for devices, select communication mode (Morse or Words) and navigate to writer/reader screens based on the selected device and mode

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CommunicationMode currentMode = CommunicationMode.morse;
  List<Device> devices = [];
  bool isScanning = false;
  Device? connectedDevice; // Saves the selected device to show its name and pass it to the next screens

  final DeviceDataSource fakedataSource = FakeDeviceDataSource();
  final DeviceDataSource bleDataSource = BleDeviceDataSource();// Data sources for real BLE devices and fake devices for testing

  StreamSubscription<List<Device>>? _bleSub;
  StreamSubscription<List<Device>>? _fakeSub;

  List<Device> _bleDevices = [];
  List<Device> _fakeDevices = [];// Temporary lists to hold devices from each source before merging them

  void Function(VoidCallback fn)? _modalSetState;

  // Scanning
  void startScan() {// Starts scanning for devices, shows a loading indicator and opens a bottom sheet with the results
    setState(() {
      isScanning = true;
      _bleDevices = [];
      _fakeDevices = [];
      devices = [];
    });

    _bleSub?.cancel();
    _fakeSub?.cancel();// Cancel any previous subscriptions to avoid duplicates if the user scans multiple times

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

    showModalBottomSheet(// Opens a bottom sheet to show the scanning results, allowing the user to select a device
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Save this setter so we can trigger rebuilds
            _modalSetState = setModalState;

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: _buildScanResults(),
            );
          },
        );
      },
    );
  }

  void _updateDevices() {// Merges all devices from both sources (real and fake) into a single list
    final Map<String, Device> all = {};

    for (var d in _fakeDevices) { all[d.id] = d; }
    for (var d in _bleDevices) { all[d.id] = d; }
    
    setState(() {
      devices = all.values.toList();
    });

     if (_modalSetState != null) {
      _modalSetState!(() {});// Trigger a rebuild of the modal to show new devices as they are found
    }

  }

  // Navigation
  
  void selectDevice(Device device) {
    setState(() {
      connectedDevice = device;
    });
    Navigator.pop(context); // Closes the bottomsheet after selecting a device
  }

    Device _resolveFakeDevice(Device selected) {
      final isFake = selected.nativeDevice == null;

      if (!isFake) return selected;

      if (appMode.value == CommunicationMode.morse) {
        return Device(
          name: "Fake Sensso or A",
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
    }// Since the fake devices are just placeholders, we need to give them a known ID and name when selected

     void switchMode(CommunicationMode mode) {
      // Stop everything cleanly first
      GlobalMorseService().dispose();
      WordsDecoderService().dispose();

      // Reset shared UI state
      MessageBus.updateMessage("");
      MessageBus.updateCurrentPath("");

      // Update global mode
      appMode.value = mode;

      setState(() {});
    }

  void openWriter(Device device) {// Opens the writer screen based on the selected mode, passing the selected device to it
    final resolveDevice = _resolveFakeDevice(device);
    final dataSource = resolveDevice.nativeDevice == null ? fakedataSource : bleDataSource;

    WordsDecoderService().dispose();
    GlobalMorseService().dispose();

    MessageBus.updateMessage("");
    MessageBus.updateCurrentPath("");// Clears any previous message state before opening the new screen

    if (appMode.value == CommunicationMode.morse) {
      GlobalMorseService().initDecoder(resolveDevice, dataSource);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WriterScreen(deviceId: resolveDevice.id),
        ),
      );
    } else {
      WordsDecoderService().initDecoder(resolveDevice, dataSource);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WordsWriterScreen(
            deviceId: resolveDevice.id,
          ),
        ),
      );
    }
  }


  void openReader(Device device) {// Opens the reader screen based on the selected mode, passing the selected device to it
    final resolveDevice = _resolveFakeDevice(device);
    final dataSource = resolveDevice.nativeDevice == null ? fakedataSource : bleDataSource;

    WordsDecoderService().dispose();
    GlobalMorseService().dispose();

    MessageBus.updateMessage("");
    MessageBus.updateCurrentPath("");// Clears any previous message state before opening the new screen
    
    if (appMode.value == CommunicationMode.morse) {
      GlobalMorseService().initDecoder(resolveDevice, dataSource);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReaderScreen(),
        ),
      );
      
    } else {

      WordsDecoderService().initDecoder(resolveDevice, dataSource);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WordsReaderScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    _fakeSub?.cancel();
    super.dispose();
  }

  // UI components
  Widget _buildScanResults() {// Building of the main UI
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text("Searching for Devices", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),// Header of the scanning box
          const SizedBox(height: 10),
          if (isScanning) const LinearProgressIndicator(),// Shows a loading indicator while scanning
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

    return Scaffold(// Main layout of the home screen, showing connection status, mode selection and navigation to writer/reader screens
      appBar: AppBar(
        title: Text("Talky Buddy", style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Welcome!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Status card showing if a device is connected and its name, or prompting to connect if not
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  Icon(
                    connectedDevice == null ? Icons.bluetooth_disabled : Icons.bluetooth_connected,
                    size: 40,
                    color: connectedDevice == null ? Colors.grey : colors.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    connectedDevice == null ? "No device connected" : "Connected to: ${connectedDevice!.name}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Center(// Toggle buttons to switch between Morse and Words mode, updating the global app accordingly
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(12),
                isSelected: [
                  appMode.value == CommunicationMode.morse,
                  appMode.value == CommunicationMode.words,// The toggle state is determined by the global app mode
                ],
                onPressed: (index) {
                  switchMode(
                  appMode.value = index == 0
                      ? CommunicationMode.morse
                      : CommunicationMode.words,
                  );
                },
                children: const [// Communication mode list, only appears when a device is connected
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("Morse"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("Words"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text("Modes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),


            Opacity(
              opacity: connectedDevice == null ? 0.5 : 1.0,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.edit, color: colors.primary),
                      title: const Text("Writer Mode"),
                      subtitle: const Text("Morse Binary Tree Guide"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: connectedDevice == null ? null : () => openWriter(connectedDevice!),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.visibility, color: colors.primary),
                      title: const Text("Reader Mode"),
                      subtitle: const Text("View incoming messages"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: connectedDevice == null ? null : () => openReader(connectedDevice!),
                    ),
                  ],
                ),
              ),
            ),
            
            if (connectedDevice == null)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(child: Text("Connect to a device to unlock modes", style: TextStyle(color: Colors.grey))),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isScanning ? null : startScan,
        label: Text(isScanning ? "Scanning..." : "Search Devices"),
        icon: Icon(isScanning ? Icons.sync : Icons.search),
      ),
    );
  }
}