#include <Wire.h>

#define SDA_PIN 8
#define SCL_PIN 9

void setup() {
  Serial.begin(115200);
  Wire.begin(SDA_PIN, SCL_PIN);
  Serial.println("I2C Scanner");
}

void loop() {
  byte error, address;
  int nDevices = 0;

  for(address = 1; address < 127; address++ ) {
    Wire.beginTransmission(address);
    error = Wire.endTransmission();
    if (error == 0) {
      Serial.print("I2C device found at 0x");
      if(address<16) Serial.print("0");
      Serial.println(address,HEX);
      nDevices++;
    }
  }
  if(nDevices == 0) Serial.println("No I2C devices found");
  else Serial.println("Done");
  delay(5000);
}
