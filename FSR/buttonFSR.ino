#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

#define DEVICE_NAME "TALKY_BUDDY!!!"

BLEAdvertising *pAdvertising;

const int buttonPin = 2;
int threshold = 1000;

bool isPressing = false;
unsigned long pressStartTime = 0;

uint8_t globalCounter = 0; // Coloca isto no topo do código

static unsigned long lastSignalTime = 0;
static int estadoTimeout = 0; 

void sendSignal(uint8_t s) {
  globalCounter++; // ISTO É VITAL: Muda o ID a cada envio
  if (globalCounter > 250) globalCounter = 1;

  uint8_t msd[4]; 
  msd[0] = 0xFF; // Company ID Byte 1
  msd[1] = 0xFF; // Company ID Byte 2
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

  pinMode(buttonPin, INPUT_PULLUP);

  BLEDevice::init(DEVICE_NAME);
  pAdvertising = BLEDevice::getAdvertising();
  
  sendSignal(0);
}

void loop() {
  int value = analogRead(fsrPin);
  unsigned long currentTime = millis();

  //press the button
  if (value == LOW && !isPressing) {
    isPressing = true;
    pressStartTime = currentTime;
    estadoTimeout = 0;   //getting data
  }

  //release the button
  if (value == HIGH && isPressing) {
    isPressing = false;
    unsigned long duration = currentTime - pressStartTime;
    uint8_t signal = 0;

    if (duration >= 200 && duration < 1000) signal = 1;   //dot
    else if (duration >= 1500) signal = 2;   //dash

    if (signal > 0) {
      sendSignal(signal);
      delay(100);
      lastSignalTime = millis(); 
      estadoTimeout = 1;   //waiting for end of character
    }
  }

  if (!isPressing && estadoTimeout > 0) {
    unsigned long inactivityDuration = currentTime - lastSignalTime;

    if (estadoTimeout == 1) {
      if (currentTime > lastSignalTime && inactivityDuration >= 3000) { 
        sendSignal(3);   //end of character
        estadoTimeout = 2;   //waiting for end of word
      }
    }
    
    else if (estadoTimeout == 2) {
      if (currentTime > lastSignalTime && inactivityDuration >= 7000) {
        sendSignal(4);   //end of word
        estadoTimeout = 0;   //reading data
      }
    }
  }

  delay(10);
}
