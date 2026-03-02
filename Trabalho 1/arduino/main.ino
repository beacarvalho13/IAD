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
      Serial.println(val);

      voltage = val * (5.0 / 1023.0);
      Serial.println(voltage);

      tesla = (voltage - 2.5)/ 0.018;
      Serial.println(tesla);

    }

    else {

      Serial.print("ERROR");

    }
  }

  delay(5000);
}
