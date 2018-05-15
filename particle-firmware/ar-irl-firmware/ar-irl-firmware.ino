#define RELAY_PIN 6
#define BUTTON_PIN 10 //A0
bool closed = true;

STARTUP(WiFi.selectAntenna(ANT_AUTO));

void setup() {
    Particle.function("lock", lockBox);
    Particle.function("unlock", unlockBox);
    Particle.variable("closed", closed);
    pinMode(BUTTON_PIN, INPUT);
    pinMode(RELAY_PIN, OUTPUT);
    digitalWrite(RELAY_PIN, LOW);
}

void loop() {
  checkButton();
}

void checkButton() {
  if(digitalRead(BUTTON_PIN)){
    // if button read is high, button is pressed, so box is closed
    closed = true;
  } else {
    closed = false;
  }
}

int lockBox(String extra) {
  digitalWrite(RELAY_PIN, LOW);
  return 0;
}

int unlockBox(String extra) {
  digitalWrite(RELAY_PIN, HIGH);
  return 1;
}

