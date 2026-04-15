#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

// Não precisamos de Service UUID para Beacon, mas manter o nome ajuda a filtrar no Flutter
#define DEVICE_NAME "TALKY_BUDDY"

BLEAdvertising *pAdvertising;
const int fsrPin = A2;
int threshold = 1000;
bool isPressing = false;
unsigned long pressStartTime = 0;

void sendSignal(uint8_t s) {
  // Em vez de std::string, usamos o tipo String do Arduino
  String mData = "";
  
  // Adicionamos dois bytes: 
  // 1. Um identificador (0xFF)
  // 2. O teu sinal (s)
  mData += (char)0xFF; 
  mData += (char)s;    

  BLEAdvertisementData advData;
  advData.setName(DEVICE_NAME);
  
  // Agora o tipo coincide com o que a biblioteca espera
  advData.setManufacturerData(mData);

  pAdvertising->stop(); 
  pAdvertising->setAdvertisementData(advData);
  pAdvertising->start(); 
  
  Serial.print("Beacon Signal Emitido: ");
  Serial.println(s);
}

void setup() {
  Serial.begin(115200);
  pinMode(fsrPin, INPUT);

  BLEDevice::init(DEVICE_NAME);
  pAdvertising = BLEDevice::getAdvertising();
  
  sendSignal(0); // Inicia com sinal zero
}

void loop() {
  int value = analogRead(fsrPin);
  unsigned long currentTime = millis();
  static unsigned long lastSignalTime = 0;
  static bool waitingForTimeout = false;
  static bool signal3Sent = false;
  static bool signal4Sent = false;

  if (value > threshold && !isPressing) {
    isPressing = true;
    pressStartTime = currentTime;
    waitingForTimeout = false;
  }

  if (value <= threshold && isPressing) {
    isPressing = false;
    unsigned long duration = currentTime - pressStartTime;
    uint8_t signal = 0;
    if (duration >= 50 && duration < 1000) signal = 1;
    else if (duration >= 1000) signal = 2;

    if (signal > 0) {
      sendSignal(signal);
      lastSignalTime = millis();
      waitingForTimeout = true;
      signal3Sent = false;
      signal4Sent = false;
    }
  }

  if (waitingForTimeout && !isPressing) {
    unsigned long inactivityDuration = currentTime - lastSignalTime;
    if (inactivityDuration >= 3000 && !signal3Sent) {
      sendSignal(3);
      signal3Sent = true;
    }
    if (inactivityDuration >= 7000 && !signal4Sent) {
      sendSignal(4);
      signal4Sent = true;
      waitingForTimeout = false;
    }
  }
  delay(20);
}
