#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

#define DEVICE_NAME "TALKY_BUDDY"

BLEAdvertising *pAdvertising;
const int fsrPin = A2;
int threshold = 1000;
bool isPressing = false;
unsigned long pressStartTime = 0;

void sendSignal(uint8_t s) {
  String mData = "";
  
  // Adicionamos dois bytes: 
  // 1. Um identificador (0xFF)
  // 2. O teu sinal (s)
  mData += (char)0xFF; 
  mData += (char)s;    

  BLEAdvertisementData advData;
  advData.setName(DEVICE_NAME);
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
  
  sendSignal(0);
}

void loop() {
  int value = analogRead(fsrPin);
  unsigned long currentTime = millis();
  
  static unsigned long lastSignalTime = 0;
  static int estadoTimeout = 0; 

  // 1. PRESSIONAR
  if (value > threshold && !isPressing) {
    isPressing = true;
    pressStartTime = currentTime;
    estadoTimeout = 0; 
  }

  // 2. SOLTAR
  if (value <= threshold && isPressing) {
    isPressing = false;
    unsigned long duration = currentTime - pressStartTime;
    uint8_t signal = 0;

    if (duration >= 50 && duration < 1000) signal = 1;
    else if (duration >= 1000) signal = 2;

    if (signal > 0) {
      sendSignal(signal);
      // Forçamos o lastSignalTime a ser o AGORA absoluto
      lastSignalTime = millis(); 
      estadoTimeout = 1;         
    }
  }

  // 3. GESTÃO DE TIMEOUTS (Com proteção contra disparos fantasmas)
  if (!isPressing && estadoTimeout > 0) {
    unsigned long inactivityDuration = currentTime - lastSignalTime;

    // SINAL 3
    if (estadoTimeout == 1) {
      // Se a diferença for negativa ou louca (devido ao reset do rádio), ignoramos
      if (currentTime > lastSignalTime && inactivityDuration >= 3000) { 
        sendSignal(3);
        estadoTimeout = 2; 
      }
    }
    // SINAL 4
    else if (estadoTimeout == 2) {
      if (currentTime > lastSignalTime && inactivityDuration >= 7000) {
        sendSignal(4);
        estadoTimeout = 0; 
      }
    }
  }

  delay(10); // Reduzi para 10ms para dar mais precisão ao loop
}
