# AR-IRL

Connect iOS ARKit to a Particle Microcontroller for Immersive AR Prototypes


## Get Up and Running

### Box Circuit

![Circuit Diagram](https://raw.githubusercontent.com/istrategylabs/ar-irl/master/images/ar-irl-circuit_fritzing.png)

Parts List:

* [Particle Photon Microcontroller](https://docs.particle.io/guide/getting-started/intro/photon/)
* [Relay Switch](https://www.amazon.com/gp/product/B00VRUAHLE/ref=oh_aui_detailpage_o03_s00?ie=UTF8&psc=1)
* [Electromagnet](https://www.amazon.com/gp/product/B01N3387AA/ref=oh_aui_detailpage_o03_s00?ie=UTF8&psc=1)
* [Roller Switch](https://www.amazon.com/WINOMO-Micro-Switch-Roller-Action/dp/B01HHPD22S/ref=sr_1_7?ie=UTF8&qid=1526401363&sr=8-7&keywords=roller+switch)
* 220 Ω Resistor (or any resistance)
* 12 V Power Supply
* Micro USB Cable

### Firmware

The firmware is stored in the particle-firmware folder. There are two options for uploading it to the photon:

* **Particle Web IDE**: Copy and paste the code into the [Web IDE](https://build.particle.io/build/new), where you can also compile it and flash it to your device wirelessly.
* **Offline Editor**: Open the code in the editor of your choice. (We used the [Arduino IDE](https://www.arduino.cc/en/Main/Software)). Then use the [Particle CLI](https://docs.particle.io/guide/tools-and-features/cli/photon/) to flash it to your device either wirelessly or via USB.

### iOS App

Open the .xcworkspace in [Xcode](https://developer.apple.com/xcode/). You'll need an Apple developer account and an iOS device running iOS 11 or later (Neither Particle Setup nor ARKit run in the simulator).

You may need to install the [CocoaPods](https://cocoapods.org/) dependency. 

Helpful Docs for getting started with the Particle iOS SDK:

* [Building a Mobile App with Particle](https://docs.particle.io/guide/how-to-build-a-product/mobile-app/)
* [Installing the Particle iOS SDK](https://docs.particle.io/reference/ios/#installation)
* [Setting up the Bridging Header](https://community.particle.io/t/mobile-sdk-building-the-bridge-from-swift-to-objective-c/12020)


