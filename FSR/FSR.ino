#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

// Main code for the pressure sensor FSR project, which reads the pressure and sends BLE signals based on the duration of the press

#define DEVICE_NAME "TALKY_BUDDY!!!"

BLEAdvertising *pAdvertising;
const int fsrPin = A2;
int threshold = 50;
bool isPressing = false;
unsigned long pressStartTime = 0;
uint8_t globalCounter = 0; 

// Function to broadcast BLE signal with a specific value
void sendSignal(uint8_t s) {
  globalCounter++; 
  if (globalCounter > 250) globalCounter = 1;

  uint8_t msd[4]; 
  msd[0] = 0xFF; 
  msd[1] = 0xFF; 
  msd[2] = globalCounter; 
  msd[3] = s;

  BLEAdvertisementData advData;
  advData.setFlags(0x06); 
  advData.setManufacturerData(String((char*)msd, 4));

  BLEAdvertisementData scanResponse;
  scanResponse.setName(DEVICE_NAME);

  pAdvertising->stop();
  pAdvertising->setAdvertisementData(advData);
  pAdvertising->setScanResponseData(scanResponse);
  pAdvertising->start();
  
  Serial.print("Sinal: "); Serial.print(s);
  Serial.print(" | ID: "); Serial.println(globalCounter);
}

void setup() {
  Serial.begin(115200);
  pinMode(fsrPin, INPUT);

  BLEDevice::init(DEVICE_NAME);
  pAdvertising = BLEDevice::getAdvertising();
  
  sendSignal(0);
}

// Loop to read button state and determine signal type based on press duration
void loop() {
  int value = analogRead(fsrPin);
  Serial.print("Value: ");
  Serial.println(value);
  unsigned long currentTime = millis();
  
  static unsigned long lastSignalTime = 0;
  static int estadoTimeout = 0; 

  // Press
  if (value > threshold && !isPressing) {
    isPressing = true;
    pressStartTime = currentTime;
    estadoTimeout = 0; // Getting data
  }

  // Release
  if (value <= threshold && isPressing) {
    isPressing = false;
    unsigned long duration = currentTime - pressStartTime;
    uint8_t signal = 0;

    if (duration >= 200 && duration < 1000) signal = 1; // Dot
    else if (duration >= 1500) signal = 2; // Dash

    if (signal > 0) {
      sendSignal(signal);
      delay(100);
      lastSignalTime = millis(); 
      estadoTimeout = 1; // Waiting for end of character
    }
  }

  if (!isPressing && estadoTimeout > 0) {
    unsigned long inactivityDuration = currentTime - lastSignalTime;

    if (estadoTimeout == 1) {
      if (currentTime > lastSignalTime && inactivityDuration >= 3000) { 
        sendSignal(3); // End of character
        estadoTimeout = 2; // Waiting for end of word
      }
    }
    
    else if (estadoTimeout == 2) {
      if (currentTime > lastSignalTime && inactivityDuration >= 7000) {
        sendSignal(4); // End of word
        estadoTimeout = 0; // Reading data
      }
    }
  }

  delay(10);
}
