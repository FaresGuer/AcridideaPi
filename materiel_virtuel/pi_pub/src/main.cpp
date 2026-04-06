#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>


#define DHTPIN 4 
#define potentiometerPin 35
#define gasPin 34

DHT dht(DHTPIN, DHT22);
WiFiClient espClient;
PubSubClient client(espClient);

float temp = 0;
float hum = 0;
int sensorValue;

const int redPin = 14;
const int greenPin = 27;
const int bluePin = 26;

#define MAX_TEMP_THRESHOLD     28.0
#define MIN_TEMP_THRESHOLD     20.0 
#define MAX_HUMIDITY_THRESHOLD     70.0
#define MIN_HUMIDITY_THRESHOLD     30.0 
#define MAX_LUX_THRESHOLD      2000
#define MIN_LUX_THRESHOLD      1000
#define MAX_GAS_THRESHOLD      1500 
#define MIN_GAS_THRESHOLD      1000
const char* ssid     = "Wokwi-GUEST";
const char* password = "";
const char* mqtt_server = "broker.hivemq.com";

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
    if (client.connect("SensorsNode")) {
      Serial.println("connected");
    } else {
      Serial.print("failed, rc=");
      Serial.println(client.state());
      delay(2000);
    }
  }
}
void setup() {
  Serial.begin(115200);
  dht.begin();
  connectWiFi();
  client.setServer(mqtt_server, 1883);
  
}

void loop() {
  if (!client.connected()) connectMQTT();
  client.loop();
  float temp = dht.readTemperature();
  float hum  = dht.readHumidity();
  int   lux  = analogRead(potentiometerPin);
  int   gas  = analogRead(gasPin);
  client.publish("sensors/temperature", String(temp).c_str());
  client.publish("sensors/luminosity",  String(lux).c_str());
  client.publish("sensors/gas",         String(gas).c_str());
  client.publish("sensors/humidity",         String(hum).c_str());
  String status = "clear";
  if (gas  > MAX_GAS_THRESHOLD || gas < MIN_GAS_THRESHOLD)  status = "gas";
  else if (temp > MAX_TEMP_THRESHOLD || temp < MIN_TEMP_THRESHOLD) status = "temp";
  else if (hum > MAX_HUMIDITY_THRESHOLD || hum < MIN_HUMIDITY_THRESHOLD) status = "humidity";
  else if (lux  > MAX_LUX_THRESHOLD || lux < MIN_LUX_THRESHOLD)  status = "lux";
  Serial.printf("Temp: %.1f | Lux: %d | Gas: %d | Humidity: %.1f \n",temp, lux, gas, hum);

  delay(2000);
}

