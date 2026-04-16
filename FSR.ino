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
  
  mData += (char)0xFF;   //identifier
  mData += (char)s;   //signal

  BLEAdvertisementData advData;
  advData.setName(DEVICE_NAME);
  advData.setManufacturerData(mData);

  pAdvertising->stop(); 
  pAdvertising->setAdvertisementData(advData);
  pAdvertising->start(); 
  
  Serial.print("Signal: ");
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

  //press the button
  if (value > threshold && !isPressing) {
    isPressing = true;
    pressStartTime = currentTime;
    estadoTimeout = 0;   //getting data
  }

  //release the button
  if (value <= threshold && isPressing) {
    isPressing = false;
    unsigned long duration = currentTime - pressStartTime;
    uint8_t signal = 0;

    if (duration >= 50 && duration < 1000) signal = 1;   //dot
    else if (duration >= 1000) signal = 2;   //dash

    if (signal > 0) {
      sendSignal(signal);
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
