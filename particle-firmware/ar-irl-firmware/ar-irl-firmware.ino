// This #include statement was automatically added by the Particle IDE.
#include <neopixel.h>


bool state = false;
int led = D7;

void setup() {
    pinMode(led, OUTPUT);
    Particle.function("lights", switchLight);
}

void loop() {
}

int switchLight(String extra){
    if (state) {
        digitalWrite(led, HIGH);
        state = false;
        return 1;
    }
    else {
        digitalWrite(led, LOW);
        state = true;
        return 0;
    }
}
