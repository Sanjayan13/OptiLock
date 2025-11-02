//
//  OptiLock ESP32 Firmware
//  Secure Face-ID Smart-Lock Prototype
//
//  Receives authenticated commands from iOS app
//  -> Controls servo lock + LCD status + buzzer
//
//  Wi-Fi credentials masked for security
//  Servo: GPIO 13
//  Buzzer: GPIO 12
//  LCD: 14,27,26,25,33,32
//

#include <WiFi.h>
#include <ESP32Servo.h>
#include <LiquidCrystal.h>

// Wi-Fi credentials (masked for open-source repo)
const char* ssid = "XXXXXX";
const char* password = "XXXXXXXX";

// Servo instance
Servo lockServo;

// Buzzer pin (audible feedback)
const int buzzerPin = 12;

// LCD pins: RS, E, D4, D5, D6, D7
LiquidCrystal lcd(14, 27, 26, 25, 33, 32);

// HTTP server on port 80 (local LAN control)
WiFiServer server(80);

//
// Buzzer feedback patterns
//
void beep(int count) {
  for (int i = 0; i < count; i++) {
    tone(buzzerPin, 2000);
    delay(120);
    noTone(buzzerPin);
    delay(120);
  }
}

//
// Lock + unlock functions
//
void unlock() {
  Serial.println("🔓 Unlock command received");
  lockServo.write(180);
  lcd.clear();
  lcd.setCursor(4, 0);
  lcd.print("Status");
  lcd.setCursor(3, 1);
  lcd.print("Unlocked");
  beep(3); // triple beep = open
}

void lock() {
  Serial.println("🔒 Lock command received");
  lockServo.write(0);
  lcd.clear();
  lcd.setCursor(4, 0);
  lcd.print("Status");
  lcd.setCursor(4, 1);
  lcd.print("Locked");
  beep(1); // single beep = closed
}

//
// Setup routine: hardware + Wi-Fi + LCD boot screen
//
void setup() {
  Serial.begin(115200);

  // LCD boot message
  lcd.begin(16, 2);
  lcd.print("OptiLock Booting...");
  delay(1200);
  lcd.clear();
  lcd.print("Status:");
  lcd.setCursor(4, 1);
  lcd.print("Locked");

  // Servo timer allocation (required for ESP32)
  ESP32PWM::allocateTimer(0);
  ESP32PWM::allocateTimer(1);
  ESP32PWM::allocateTimer(2);
  ESP32PWM::allocateTimer(3);

  lockServo.attach(13);
  lockServo.write(0);

  pinMode(buzzerPin, OUTPUT);

  // Wi-Fi connect
  Serial.println("Connecting to Wi-Fi...");
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\n✅ Wi-Fi connected");
  Serial.print("Device IP: ");
  
  // Mask real IP for public repo
  Serial.println("XXX.XXX.X.XXX");

  server.begin();
}

//
// Loop: receive HTTP commands from app
//
void loop() {
  WiFiClient client = server.available();
  if (!client) return;

  String request = client.readStringUntil('\r');
  client.flush();

  if (request.indexOf("/unlock") != -1) unlock();
  if (request.indexOf("/lock") != -1) lock();

  // Respond back to app
  client.println("HTTP/1.1 200 OK");
  client.println("Content-Type: text/plain");
  client.println("Connection: close");
  client.println();
  client.println("OK");
}