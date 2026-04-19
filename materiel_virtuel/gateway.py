import paho.mqtt.client as mqtt
import mysql.connector
from datetime import datetime

# ─── Config ───────────────────────────────────────────────
MQTT_BROKER          = "broker.hivemq.com"
MQTT_PORT            = 1883
DEFAULT_CONTAINER_ID = 8

# ⚠️ For testing on PC with local MySQL
# When deploying to Raspberry Pi, change host to "localhost"
# and user/password to "locust"/"locust123"
# DB_CONFIG = {
#     "host":     "localhost",
#     "user":     "locust",
#     "password": "locust123",
#     "database": "locust_farm"
# } 
# rasberry pi config
DB_CONFIG = {
    "host":     "localhost",
    "user":     "root",
    "password": "",
    "database": "locust_farm"
}
# Topics — sensors ESP publishes
TOPIC_TEMP      = "sensors/temperature"
TOPIC_HUM       = "sensors/humidity"
TOPIC_GAS       = "sensors/gas"
TOPIC_LUX       = "sensors/luminosity"

# Topics — mobile app container selection
TOPIC_CONTAINER = "gateway/container"

# Topics — gateway publishes to actuators ESP
TOPIC_FAN        = "actuators/fan"
TOPIC_BUZZER     = "actuators/buzzer"
TOPIC_HUMIDIFIER = "actuators/humidifier"
TOPIC_LIGHT      = "actuators/light"
# TOPIC_HEATER   = "actuators/heater"

# Topics — status for TFT display
TOPIC_STATUS_SENSOR  = "status/sensor"
TOPIC_STATUS_GATEWAY = "status/gateway"
TOPIC_STATUS_ALERT   = "status/alert"

# ─── State ────────────────────────────────────────────────
container_id = DEFAULT_CONTAINER_ID
latest = {
    "temperature": None,
    "humidity":    None,
    "gas":         None,
    "light_level": None
}

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

        # Update current state
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
        print(f"[DB] Updated container_data for container {container_id}")
    except Exception as e:
        print(f"[DB] Error: {e}")
    finally:
        cur.close()
        db.close()

# ─── Decision Logic ───────────────────────────────────────
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

    lux_percent = (lux / 4095.0) * 100 if lux is not None else None

    fan        = 0
    buzzer     = 0
    heater     = 0
    light      = 0
    humidifier = 0

    if gas is not None and (gas > GAS_MAX or gas < GAS_MIN):
        print(f"[GW] ALERT: Gas out of range ({gas}) — triggering fan + buzzer")
        fan    = 1
        buzzer = 1

    elif temp is not None and (temp > TEMP_MAX or temp < TEMP_MIN):
        print(f"[GW] ALERT: Temp out of range ({temp}) — triggering fan/heater + buzzer")
        heater = 1 if temp < TEMP_MIN else 0
        fan    = 1 if temp > TEMP_MAX else 0
        buzzer = 1

    elif hum is not None and (hum > HUM_MAX or hum < HUM_MIN):
        print(f"[GW] ALERT: Humidity out of range ({hum})")
        humidifier = 1 if hum < HUM_MIN else 0
        buzzer     = 1

    elif lux_percent is not None and (lux_percent > LUX_MAX or lux_percent < LUX_MIN):
        print(f"[GW] ALERT: Light out of range ({lux_percent:.1f}%)")
        light  = 1
        buzzer = 1

    else:
        print(f"[GW] All normal — temp:{temp} hum:{hum} gas:{gas} lux:{lux_percent}")

    return fan, buzzer, heater, light, humidifier

# ─── MQTT Callbacks ───────────────────────────────────────
def on_connect(client, userdata, flags, reason_code, properties):
    if reason_code == 0:
        print("[MQTT] Gateway connected")
        for topic in [TOPIC_TEMP, TOPIC_HUM, TOPIC_GAS, TOPIC_LUX, TOPIC_CONTAINER]:
            client.subscribe(topic)
            print(f"[MQTT] Subscribed to {topic}")
        client.publish(TOPIC_STATUS_GATEWAY, "1")
        print("[GW] Published gateway status: connected")
    else:
        print(f"[MQTT] Connection failed: rc={reason_code}")

def on_message(client, userdata, msg):
    global container_id
    topic   = msg.topic
    payload = msg.payload.decode().strip()
    print(f"[MQTT] {topic}: {payload}")

    # Container selection from mobile app
    if topic == TOPIC_CONTAINER:
        try:
            container_id = int(payload)
            print(f"[GW] Container selected: {container_id}")
        except ValueError:
            print(f"[MQTT] Bad container ID: {payload}")
        return

    # Sensor data
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

    # Sensor ESP is publishing → mark as connected
    client.publish(TOPIC_STATUS_SENSOR, "1")

    temp = latest["temperature"]
    hum  = latest["humidity"]
    gas  = latest["gas"]
    lux  = latest["light_level"]

    thresholds = fetch_thresholds(container_id)
    print(f"[GW] Thresholds — temp:{thresholds['target_temperature']} hum:{thresholds['target_humidity']} gas:{thresholds['target_gas_level']} lux:{thresholds['target_light_level']}")

    fan, buzzer, heater, light, humidifier = decide(temp, hum, gas, lux, thresholds)

    # Build alert message for TFT display
    if buzzer == 1:
        if gas is not None and gas > thresholds["target_gas_level"]:
            alert_msg = f"Gas high! {int(gas)} ppm"
        elif temp is not None and temp > thresholds["target_temperature"]:
            alert_msg = f"Temp high! {temp:.1f}C"
        elif temp is not None and temp < thresholds["target_temperature_min"]:
            alert_msg = f"Temp low! {temp:.1f}C"
        elif hum is not None and hum < thresholds["target_humidity_min"]:
            alert_msg = f"Humidity low! {hum:.1f}%"
        elif hum is not None and hum > thresholds["target_humidity"]:
            alert_msg = f"Humidity high! {hum:.1f}%"
        else:
            alert_msg = "Light out of range"
        client.publish(TOPIC_STATUS_ALERT, alert_msg)
        print(f"[GW] Alert published: {alert_msg}")

    client.publish(TOPIC_FAN,        str(fan))
    client.publish(TOPIC_BUZZER,     str(buzzer))
    client.publish(TOPIC_HUMIDIFIER, str(humidifier))
    client.publish(TOPIC_LIGHT,      str(light))
    print(f"[GW] Published → fan:{fan} buzzer:{buzzer} humidifier:{humidifier} light:{light}")

    lux_percent = adc_to_percent(lux)
    update_db(temp, hum, lux_percent, gas, heater, fan, light, humidifier, container_id)

# ─── Main ─────────────────────────────────────────────────
def main():
    try:
        client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id="Gateway")
    except AttributeError:
        client = mqtt.Client(client_id="Gateway")
    client.on_connect = on_connect
    client.on_message = on_message

    print(f"[GW] Connecting to {MQTT_BROKER}...")
    client.connect(MQTT_BROKER, MQTT_PORT, keepalive=60)
    client.loop_forever()

if __name__ == "__main__":
    main()