// This #include statement was automatically added by the Particle IDE.
//#include <neopixel.h>


//bool state = false;
#define RELAY_PIN 6
#define BUTTON_PIN 10 //A0
bool closed = true;
//#define LED_PIN 6
//#define NUM_LED 24
//#define PIX_TYPE WS2812B

STARTUP(WiFi.selectAntenna(ANT_AUTO));
//Adafruit_NeoPixel square = Adafruit_NeoPixel(NUM_LED, LED_PIN, PIX_TYPE);

void setup() {
//    square.begin();
//    colorFill(square.Color(0,0,0));
//    square.show();
//    Particle.function("lights", switchLight);
//    Particle.function("lightsOn", turnOnLight);
//    Particle.function("lightsOff", turnOffLight);
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

//int switchLight(String extra){
//  if (state) {
//    colorFill(square.Color(0,0,50));
//    state = false;
//    return 1;
//  }
//  else {
//    colorFill(square.Color(0,0,0));
//    state = true;
//    return 0;
//  }
//}
//
//int turnOffLight(String extra) {
//  colorFill(square.Color(0,0,0));
//  state = true;
//  return 0;
//}
//
//int turnOnLight(String extra) {
//  colorFill(square.Color(0,0,50));
//  state = false;
//  return 1;
//}
//
//void colorFill(uint32_t c) {
//  for(int i=0; i<NUM_LED; i++) {
//    square.setPixelColor(i, c);
//  }
//  square.show();
//}

