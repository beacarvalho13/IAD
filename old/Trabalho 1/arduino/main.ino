int hallPin = A0;
int val;
float voltage;
float tesla;

void setup() {
  Serial.begin(9600);
  pinMode(hallPin, INPUT);
}

void loop() {

  if (Serial.available() > 0){

    String command = Serial.readStringUntil('\n');
    command.trim();

    if (command == "MEASURE"){

      val = analogRead(hallPin);

      voltage = val * (5.0 / 1023.0);

      tesla = (voltage - 2.5)/ 0.018;

      Serial.println(tesla);
    }

    else{
      Serial.println("9999");
    }
  }
  
  delay(100);
}
