#define BUTTON_PIN 2

void setup() {
  Serial.begin(115200);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
}

void loop() {
  int state = digitalRead(BUTTON_PIN);

  if (state == LOW) {
    Serial.println("BUTTON PRESSED");
  } else {
    Serial.println("not pressed");
  }

  delay(200);
}