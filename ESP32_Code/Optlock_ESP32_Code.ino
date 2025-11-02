#include <WiFi.h>
#include <ESP32Servo.h>
#include <LiquidCrystal.h>

// WiFi details
const char* ssid = "Home Wifi (Main)";
const char* password = "Sanjayan";

// Servo
Servo lockServo;

// Buzzer pin
const int buzzerPin = 12;

// LCD pins: RS, E, D4, D5, D6, D7
LiquidCrystal lcd(14, 27, 26, 25, 33, 32);

WiFiServer server(80);

void beep(int count) {
  for (int i = 0; i < count; i++) {
    tone(buzzerPin, 2000);
    delay(120);
    noTone(buzzerPin);
    delay(120);
  }
}

void unlock() {
  Serial.println("Unlock command received");
  lockServo.write(180);
  lcd.clear();
  lcd.setCursor(5, 0);
  lcd.print("Status");
  lcd.setCursor(4, 1);
  lcd.print("Unlocked");
  beep(3); // three beeps
}

void lock() {
  Serial.println("Lock command received");
  lockServo.write(0);
  lcd.clear();
  lcd.setCursor(5, 0);
  lcd.print("Status");
  lcd.setCursor(5, 1);
  lcd.print("Locked");
  beep(1); // one beep
}

void setup() {
  Serial.begin(115200);

  // LCD setup
  lcd.begin(16, 2);
  lcd.print("OptiLock Booting");
  delay(1000);
  lcd.clear();
  lcd.print("Status:");
  lcd.setCursor(4, 1);
  lcd.print("Locked");

  // Servo setup
  ESP32PWM::allocateTimer(0);
  ESP32PWM::allocateTimer(1);
  ESP32PWM::allocateTimer(2);
  ESP32PWM::allocateTimer(3);

  lockServo.attach(13);
  lockServo.write(0);

  pinMode(buzzerPin, OUTPUT);

  // WiFi connect
  Serial.println("Connecting to WiFi...");
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.println("WiFi connected!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  server.begin();
}

void loop() {
  WiFiClient client = server.available();
  if (!client) return;

  String request = client.readStringUntil('\r');
  client.flush();

  if (request.indexOf("/unlock") != -1) unlock();
  if (request.indexOf("/lock") != -1) lock();

  client.println("HTTP/1.1 200 OK");
  client.println("Content-Type: text/plain");
  client.println("Connection: close");
  client.println();
  client.println("OK");
}