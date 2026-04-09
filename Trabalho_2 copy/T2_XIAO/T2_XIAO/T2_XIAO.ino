const int fsrPin = A0;

void setup() {
  Serial.begin(115200);
  pinMode(fsrPin, INPUT);
  Serial.println("--- Teste de Sensor FSR ---");
}

void loop() {
  int value = analogRead(fsrPin);
  Serial.print("Valor lido: ");
  Serial.println(value);
  delay(100); 
}
