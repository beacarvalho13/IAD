#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <Adafruit_BMP280.h>

// UUIDs para o serviço e característica
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Definição de pinos SPI para o XIAO ESP32-C3
#define BMP_SCK  8  // D8
#define BMP_MISO 9  // D9
#define BMP_MOSI 10 // D10
#define BMP_CS   2  // D2

Adafruit_BMP280 bme(BMP_CS, BMP_MOSI, BMP_MISO, BMP_SCK);
BLECharacteristic *pCharacteristic;

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      // Alterado para aceitar o formato String do Arduino
      String value = pCharacteristic->getValue().c_str(); 

      if (value.length() > 0) {
        Serial.println("*********");
        Serial.print("Novo valor recebido: ");
        Serial.println(value);
        Serial.println("*********");
      }
    }
};

void setup() {
  Serial.begin(115200);
  delay(2000); // Tempo para estabilizar o Serial no C3

  // --- Inicialização BLE ---
  BLEDevice::init("XIAO_C3_Sensor");
  BLEServer *pServer = BLEDevice::createServer();
  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ |
                      BLECharacteristic::PROPERTY_WRITE |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );

  pCharacteristic->setCallbacks(new MyCallbacks());
  pCharacteristic->setValue("XIAO C3 Pronto");
  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->start();

  Serial.println("Bluetooth ativo!");

  // --- Inicialização BMP280 ---
  Serial.println("A iniciar BMP280...");
  
  // Forçar o modo SPI (alguns módulos precisam que o CS seja declarado explicitamente como OUTPUT)
  pinMode(BMP_CS, OUTPUT);
  digitalWrite(BMP_CS, HIGH);
  delay(100);
  if (!bme.begin()) {  
    Serial.println("Erro: BMP280 não encontrado!");
    while (1) delay(100);
  }
  Serial.println("BMP280 detetado!");
  }

void loop() {
  float temp = bme.readTemperature();
  Serial.print("Temp: ");
  Serial.println(temp);
  if (isnan(temp)) {
    Serial.println("Erro ao ler o sensor!");
  } else {
    char btsign[10];
    dtostrf(temp, 1, 2, btsign);
    
    pCharacteristic->setValue(btsign);
    pCharacteristic->notify(); 
    
    Serial.print("Enviado para o Bluetooth: ");
    Serial.println(btsign);
  }

  delay(2000);
}
