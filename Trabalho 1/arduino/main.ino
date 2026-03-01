int inputPin = A0;
int val;

void setup() {
  Serial.begin(9600);
  pinMode(inputPin, INPUT);
}

void loop() {

  val = analogRead(inputPin);

  Serial.println(val);

  delay(1000);

}
