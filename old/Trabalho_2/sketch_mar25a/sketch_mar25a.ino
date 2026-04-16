#include <Arduino.h>

// No XIAO ESP32-C3, o pino D8 corresponde ao GPIO 8
const int pinTeste = 2; 

void setup() {
  Serial.begin(115200);
  
  // Configura o pino como saída
  pinMode(pinTeste, OUTPUT);
  
  // Força o pino para HIGH
  digitalWrite(pinTeste, HIGH);
  
  Serial.println("Pino D8 definido como HIGH (3.3V)");
}

void loop() {
  // Mantém em HIGH continuamente
  digitalWrite(pinTeste, HIGH);
  delay(1000);
}
