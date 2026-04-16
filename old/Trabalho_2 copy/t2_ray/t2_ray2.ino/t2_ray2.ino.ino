#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BMP280.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// Pinos I2C para o XIAO ESP32-C3
#define SDA_PIN 8
#define SCL_PIN 9

Adafruit_BMP280 bmp;
BLECharacteristic *pCharacteristic;
bool deviceConnected = false;

// UUIDs Únicos (Podes gerar os teus, mas estes funcionam)
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Callback para saber se o telemóvel ligou ou desligou
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) { deviceConnected = true; };
    void onDisconnect(BLEServer* pServer) { 
      deviceConnected = false;
      BLEDevice::startAdvertising(); // Reinicia o sinal para nova ligação
    }
};

void setup() {
  Serial.begin(115200);
  Wire.begin(SDA_PIN, SCL_PIN);

  // 1. Inicializar BMP280
  if (!bmp.begin(0x76)) {
    Serial.println("BMP280 não encontrado!");
    while (1);
  }

  // 2. Configurar BLE
  BLEDevice::init("XIAO_ESP32_C3_BMP"); // Nome que aparece no telemóvel
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_NOTIFY 
                    );
  pCharacteristic->addDescriptor(new BLE2902());
  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  BLEDevice::startAdvertising();
  Serial.println("Bluetooth ativo! À espera de ligação...");
}

void loop() {
  bmp.takeForcedMeasurement();
  float temp = bmp.readTemperature();
  float pres = bmp.readPressure() / 100.0F;

  // Criar uma string com os dados para enviar
  String dataString = "T:" + String(temp, 2) + " P:" + String(pres, 1);
  
  if (deviceConnected) {
    pCharacteristic->setValue(dataString.c_str());
    pCharacteristic->notify(); // Envia os dados para a App
    Serial.println("Enviado via BLE: " + dataString);
  }

  Serial.println("Serial: " + dataString);
  delay(1000); 
}
