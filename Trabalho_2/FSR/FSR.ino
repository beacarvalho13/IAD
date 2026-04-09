#include <BLEDevice.h>   //start bluetooth
#include <BLEServer.h>   //connects sensor to phone
#include <BLEUtils.h>   //data formating
#include <BLE2902.h>   //notifications

//unique UUIDs
#define SERVICE_UUID "6de2eabe-59c9-4100-8703-bba2e01799d1"
#define CHARACTERISTIC_UUID_TX "e08d4a41-01eb-4fbb-bede-105ae8dbe66c"
#define CHARACTERISTIC_UUID_RX "06d32e0c-d2ed-4d0e-a0e8-5962ab983449"

BLEServer* pServer = NULL;
BLECharacteristic* pTxCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;
const int fsrPin = A0;
unsigned long pressStartTime = 0;
bool isPressing = false;
int threshold = 1000;


//just to test on serial
void sendSignal(uint8_t s) {
  pTxCharacteristic->setValue(&s, 1);
  pTxCharacteristic->notify();
  Serial.print("Signal sent: ");
  Serial.println(s);
}

class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) {
    deviceConnected = true;
    Serial.println("Device connected");
  };

  void onDisconnect(BLEServer *pServer) {
    deviceConnected = false;
    Serial.println("Device disconnected");
  }
};

class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String rxValue = pCharacteristic->getValue();

    if (rxValue.length() > 0) {
      Serial.println("*********");
      Serial.print("Received Value: ");
      Serial.println(rxValue);
      Serial.println("*********");
    }
  }
};

void setup() {
  Serial.begin(115200);
  pinMode(fsrPin, INPUT);
  
  //create the BLE Device
  BLEDevice::init("TALKY BUDDY");

  //create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  //create the BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  //create a BLE Characteristic
  pTxCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID_TX, BLECharacteristic::PROPERTY_NOTIFY);
  pTxCharacteristic->addDescriptor(new BLE2902());

  BLECharacteristic *pRxCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID_RX, BLECharacteristic::PROPERTY_WRITE);
  pRxCharacteristic->setCallbacks(new MyCallbacks());

  //start the service
  pService->start();
  pServer->getAdvertising()->addServiceUUID(SERVICE_UUID);

  //start advertising
  pServer->getAdvertising()->start();
  Serial.println("Waiting a client connection to notify...");
}

void loop() {
  int value = analogRead(fsrPin);
  unsigned long currentTime = millis();
  static unsigned long lastSignalTime = 0;
  static bool waitingForTimeout = false;
  static bool signal3Sent = false;
  static bool signal4Sent = false;
  deviceConnected = true;

  //detect pressing and timing
  if (deviceConnected) {
    Serial.print("Value:");
    Serial.println(value);
    if (value > threshold && !isPressing) {
      isPressing = true;
      pressStartTime = currentTime;
      waitingForTimeout = false;
    }

    if (value <= threshold && isPressing) {
      isPressing = false;
      unsigned long duration = currentTime - pressStartTime;
      uint8_t signal = 0;

      if (duration >= 10 && duration < 1000) {
        signal = 1;   //point
      } 
      else if (duration >= 1000) {
        signal = 2;   //dash
      }

      if (signal > 0) {
        sendSignal(signal);
        lastSignalTime = millis(); //starts counting the time after the signal
        waitingForTimeout = true;
        signal3Sent = false;
        signal4Sent = false;
      }
    }

    //waiting time between signals
    if (waitingForTimeout && !isPressing) {
      unsigned long inactivityDuration = currentTime - lastSignalTime;

      //signal end of character
      if (inactivityDuration >= 3000 && !signal3Sent) {
        sendSignal(3); //end of character
        signal3Sent = true;
        Serial.println("Timeout: End of letter (3)");
      }

      //signal end of word
      if (inactivityDuration >= 7000 && !signal4Sent) {
        sendSignal(4); //end of word
        signal4Sent = true;
        waitingForTimeout = false;
        Serial.println("Timeout: End of word (4)");
      }
    }
  }
  
  //for stability
  delay(50);
}
