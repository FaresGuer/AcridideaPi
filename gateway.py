import paho.mqtt.client as mqtt
import mysql.connector
from datetime import datetime

# ─── Config ───────────────────────────────────────────────
MQTT_BROKER  = "broker.hivemq.com"
MQTT_PORT    = 1883
DEFAULT_CONTAINER_ID = 8  # fallback container

DB_CONFIG = {
    "host":     "localhost",
    "user":     "root",
    "password": "",
    "database": "locust_farm"
}

# Topics — sensors publish
TOPIC_TEMP = "sensors/temperature"
TOPIC_HUM  = "sensors/humidity"
TOPIC_GAS  = "sensors/gas"
TOPIC_LUX  = "sensors/luminosity"

# Topics — mobile app container selection
TOPIC_CONTAINER = "gateway/container"

# Topics — gateway publishes to actuators
TOPIC_LED   = "actuators/led"
TOPIC_SERVO = "actuators/servo"

# ─── State ────────────────────────────────────────────────
container_id = DEFAULT_CONTAINER_ID  # Current container from mobile app
latest = {
    "temperature": None,
    "humidity":    None,
    "gas":         None,
    "light_level": None
}


def reset_latest_readings():
    latest["temperature"] = None
    latest["humidity"] = None
    latest["gas"] = None
    latest["light_level"] = None

# ─── Database ─────────────────────────────────────────────
def get_db():
    return mysql.connector.connect(**DB_CONFIG)

def fetch_thresholds(container_id):
    try:
        db  = get_db()
        cur = db.cursor(dictionary=True)
        cur.execute("""
            SELECT target_temperature, target_temperature_min,
                   target_humidity,    target_humidity_min,
                   target_light_level, target_light_level_min,
                   target_gas_level,   target_gas_level_min
            FROM container_data
            WHERE container_id = %s
        """, (container_id,))
        row = cur.fetchone()
        return row if row else {
            "target_temperature":     25.0,
            "target_temperature_min": 20.0,
            "target_humidity":        70.0,
            "target_humidity_min":    30.0,
            "target_light_level":     75.0,
            "target_light_level_min": 20.0,
            "target_gas_level":       1500.0,
            "target_gas_level_min":   0.0
        }
    except Exception as e:
        print(f"[DB] Failed to fetch thresholds: {e}")
        return {
            "target_temperature":     25.0,
            "target_temperature_min": 20.0,
            "target_humidity":        70.0,
            "target_humidity_min":    30.0,
            "target_light_level":     75.0,
            "target_light_level_min": 20.0,
            "target_gas_level":       1500.0,
            "target_gas_level_min":   0.0
        }
    finally:
        cur.close()
        db.close()

def update_db(temp, hum, lux_percent, gas, heater, fan, light, humidifier, container_id):
    try:
        db  = get_db()
        cur = db.cursor()
        cur.execute("""
            UPDATE container_data
            SET temperature       = %s,
                humidity          = %s,
                light_level       = %s,
                gas_level         = %s,
                heater_status     = %s,
                fan_status        = %s,
                light_status      = %s,
                humidifier_status = %s,
                last_updated      = %s
            WHERE container_id = %s
        """, (
            temp, hum, lux_percent, gas,
            heater, fan, light, humidifier,
            datetime.now(),
            container_id
        ))
        db.commit()
        print(f"[DB] Updated container {container_id}")
    except Exception as e:
        print(f"[DB] Error: {e}")
    finally:
        cur.close()
        db.close()

# ─── Decision logic ───────────────────────────────────────
def adc_to_percent(adc_value):
    return (adc_value / 4095.0) * 100

def decide(temp, hum, gas, lux, thresholds):
    TEMP_MAX = thresholds["target_temperature"]
    TEMP_MIN = thresholds["target_temperature_min"] or (TEMP_MAX - 5)

    HUM_MAX  = thresholds["target_humidity"]
    HUM_MIN  = thresholds["target_humidity_min"] or (HUM_MAX - 20)

    LUX_MAX  = thresholds["target_light_level"]
    LUX_MIN  = thresholds["target_light_level_min"] or 0.0

    GAS_MAX  = thresholds["target_gas_level"]
    GAS_MIN  = thresholds["target_gas_level_min"] or 0.0

    # Convert raw ADC to percent for light comparison
    lux_percent = (lux / 4095.0) * 100 if lux is not None else None

    led    = "off"
    servo  = "idle"
    heater = fan = light = humidifier = 0

    if gas is not None and (gas > GAS_MAX or gas < GAS_MIN):
        led   = "blue"
        servo = "alert"
        fan   = 1

    elif temp is not None and (temp > TEMP_MAX or temp < TEMP_MIN):
        led    = "red"
        servo  = "alert"
        heater = 1 if temp < TEMP_MIN else 0
        fan    = 1 if temp > TEMP_MAX else 0

    elif hum is not None and (hum > HUM_MAX or hum < HUM_MIN):
        led        = "yellow"
        servo      = "alert"
        humidifier = 1 if hum < HUM_MIN else 0

    elif lux_percent is not None and (lux_percent > LUX_MAX or lux_percent < LUX_MIN):
        led   = "green"
        servo = "alert"
        light = 1

    return led, servo, heater, fan, light, humidifier

# ─── MQTT callbacks ───────────────────────────────────────
def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("[MQTT] Gateway connected")
        # Subscribe to sensor topics
        for topic in [TOPIC_TEMP, TOPIC_HUM, TOPIC_GAS, TOPIC_LUX]:
            client.subscribe(topic)
            print(f"[MQTT] Subscribed to {topic}")
        # Subscribe to container selection from mobile app
        client.subscribe(TOPIC_CONTAINER)
        print(f"[MQTT] Subscribed to {TOPIC_CONTAINER}")
    else:
        print(f"[MQTT] Connection failed: {rc}")

def on_message(client, userdata, msg):
    global container_id
    topic   = msg.topic
    payload = msg.payload.decode().strip()
    print(f"[MQTT] {topic}: {payload}")

    # Handle container selection from mobile app
    if topic == TOPIC_CONTAINER:
        try:
            new_container_id = int(payload)
            if new_container_id != container_id:
                container_id = new_container_id
                print(f"[GW] Container selected: {container_id}")
            else:
                print(f"[GW] Container selected: {container_id}")
        except ValueError:
            print(f"[MQTT] Bad container ID: {payload}")
        return

    # Handle sensor data
    try:
        value = float(payload)
    except ValueError:
        print(f"[MQTT] Bad payload: {payload}")
        return

    if topic == TOPIC_TEMP:
        latest["temperature"] = value
    elif topic == TOPIC_HUM:
        latest["humidity"] = value
    elif topic == TOPIC_GAS:
        latest["gas"] = value
    elif topic == TOPIC_LUX:
        latest["light_level"] = value

    if any(v is None for v in latest.values()):
        print(f"[GW] Waiting for all sensors... {latest}")
        return

    temp = latest["temperature"]
    hum  = latest["humidity"]
    gas  = latest["gas"]
    lux  = latest["light_level"]

    # Always fetch latest thresholds from DB (app may have changed them)
    thresholds = fetch_thresholds(container_id)
    print(f"[GW] Thresholds for container {container_id} — temp:{thresholds['target_temperature']} hum:{thresholds['target_humidity']} lux:{thresholds['target_light_level']}")

    led, servo, heater, fan, light, humidifier = decide(temp, hum, gas, lux, thresholds)

    client.publish(TOPIC_LED,   led)
    client.publish(TOPIC_SERVO, servo)
    print(f"[GW] Published → led:{led} servo:{servo}")
    lux_percent = adc_to_percent(lux)
    update_db(temp, hum, lux_percent, gas, heater, fan, light, humidifier, container_id)

# ─── Main ─────────────────────────────────────────────────
def main():
    client = mqtt.Client(client_id="Gateway")
    client.on_connect = on_connect
    client.on_message = on_message

    print(f"[GW] Connecting to {MQTT_BROKER}...")
    client.connect(MQTT_BROKER, MQTT_PORT, keepalive=60)
    client.loop_forever()

if __name__ == "__main__":
    main()