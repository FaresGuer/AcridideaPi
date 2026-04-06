#include <WiFi.h>
#include <PubSubClient.h>
#include <ESP32Servo.h>
const char* ssid        = "Wokwi-GUEST";
const char* password    = "";
const char* mqtt_server = "broker.hivemq.com";

const int redPin   = 14;
const int greenPin = 27;
const int bluePin  = 26;
const int servoPin = 18;

#define SERVO_IDLE    0
#define SERVO_ALERT   90
Servo myServo;
WiFiClient espClient;
PubSubClient client(espClient);

void setLED(bool r, bool g, bool b) {
  digitalWrite(redPin,   r ? LOW : HIGH);  // common anode
  digitalWrite(greenPin, g ? LOW : HIGH);
  digitalWrite(bluePin,  b ? LOW : HIGH);
}

void handleStatus(String status) {
  if (status == "gas") {
    setLED(false, false, true);   // blue
    myServo.write(SERVO_ALERT);
  } else if (status == "temp") {
    setLED(true, false, false);   // red
    myServo.write(SERVO_ALERT);
  } else if (status == "lux") {
    setLED(false, true, false);   // green
    myServo.write(SERVO_ALERT);
  } else if(status == "humidity") {
    setLED(true, true, false);    // yellow
    myServo.write(SERVO_ALERT);
  } 
  else {
    setLED(false, false, false);  // off
    myServo.write(SERVO_IDLE);
  }
}

void callback(char* topic, byte* payload, unsigned int length) {
  String message;
  for (int i = 0; i < length; i++) message += (char)payload[i];

  Serial.printf("Received [%s]: %s\n", topic, message.c_str());

  if (String(topic) == "actuators/led") {
    if      (message == "red")   setLED(true,  false, false);
    else if (message == "blue")  setLED(false, false, true);
    else if (message == "green") setLED(false, true,  false);
    else if (message == "yellow") setLED(true,  true,  false);
    else                         setLED(false, false, false);
  }

  if (String(topic) == "actuators/servo") {
    if (message == "alert") myServo.write(90);
    else                    myServo.write(0);
  }
}
void connectWiFi() {
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected");
}
void connectMQTT() {
  while (!client.connected()) {
    Serial.print("Connecting to MQTT...");
    if (client.connect("ActuatorsNode")) {
      Serial.println("connected");
      client.subscribe("actuators/led");
      client.subscribe("actuators/servo");
    } else {
      Serial.print("failed, rc=");
      Serial.println(client.state());
      delay(2000);
    }
  }
}

void setup() {
  Serial.begin(115200);

  pinMode(redPin,   OUTPUT);
  pinMode(greenPin, OUTPUT);
  pinMode(bluePin,  OUTPUT);
  setLED(false, false, false);

  myServo.attach(servoPin);
  myServo.write(SERVO_IDLE);

  connectWiFi();
  client.setServer(mqtt_server, 1883);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) connectMQTT();
  client.loop();
}
