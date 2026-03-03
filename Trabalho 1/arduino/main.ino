int hallPin = A0;
int val;
float voltage;
float tesla;

void setup() {
  Serial.begin(9600);
  pinMode(hallPin, INPUT);

  if (estado == HIGH) {
      Serial.println("Connection established");
    } else {
      Serial.println("No connection");
    }
}

void loop() {

  if (Serial.available() > 0){

    String command = Serial.readStringUntil('\n');
    command.trim();

    if (command == "MEASURE"){

      val = analogRead(hallPin);

      voltage = val * (5.0 / 1023.0);

      tesla = (voltage - 2.5)/ 0.018;

      Serial.print("Raw: ");
      Serial.print(val);
      Serial.print(" | Volts: ");
      Serial.print(voltage);
      Serial.print(" | Tesla: ");
      Serial.println(tesla);

      if (val == 0 || val == 1023) {
        Serial.print("WARNING: Pin reading extreme value (");
        Serial.print(val);
        Serial.println("). Check sensor connection.");

    }

    if (command.length() == 0) {
      Serial.println("ERROR: Empty command received.");
    }

    else {

      Serial.print("ERROR");
      Serial.println(command);

    }
  }

  delay(5000);
  }
}
