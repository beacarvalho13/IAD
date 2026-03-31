#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;

const int fsrPin = A0;

// UUIDs únicos para o serviço e característica (podes manter estes)
#define SERVICE_UUID           "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_TX "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
    };
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      // Reinicia o advertising para permitir nova conexão
      pServer->getAdvertising()->start();
    }
};

void setup() {
  Serial.begin(115200);

  // Inicializa o dispositivo BLE
  BLEDevice::init("XIAO_Ball_Sensor"); // Nome que aparecerá no Bluetooth

  // Cria o Servidor BLE
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Cria o Serviço BLE
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Cria a Característica para envio de dados (TX)
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID_TX,
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
  
  pCharacteristic->addDescriptor(new BLE2902());

  pService->start();

  // Começa a transmitir a presença do Bluetooth
  pServer->getAdvertising()->start();
  Serial.println("Aguardando conexão Bluetooth...");
}

void loop() {
  int value = analogRead(fsrPin);

  if (deviceConnected) {
    // Envia o valor como bytes (Low byte e High byte)
    pCharacteristic->setValue((uint8_t*)&value, 2); 
    pCharacteristic->notify();
    
    Serial.print("Enviado valor real: ");
    Serial.println(value);
  }
  delay(300);
}
