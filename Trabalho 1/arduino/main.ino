int inputPin = A0;
int val;

void setup() {
  Serial.begin(9600);
  pinMode(inputPin, INPUT);
}

void loop() {

  if (Serial.available() > 0){

    String command = Serial.readStringUntil('\n');
    command.trim();

    if (command == "MEASURE"){

      val = analogRead(inputPin);
      Serial.println(val);
    }

    else {

      Serial.print("ERROR");

    }
  }
}
