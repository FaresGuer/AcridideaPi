import paho.mqtt.client as mqtt
import os
import psycopg
import mysql.connector
from datetime import datetime
import time

# ─── Config ───────────────────────────────────────────────
MQTT_BROKER          = "broker.hivemq.com"
MQTT_PORT            = 1883
DEFAULT_CONTAINER_ID = 8

# ⚠️ Neon PostgreSQL connection string (cloud)
DATABASE_URL = "postgresql://neondb_owner:npg_ib5XlIOF2uxf@ep-restless-violet-anmpow2v.c-6.us-east-1.aws.neon.tech/locust_farm?sslmode=require"
THRESHOLD_CACHE_SECONDS = 30
DB_WRITE_MIN_INTERVAL_SECONDS = 0.5

# ⚠️ For testing on PC with local MySQL
# When deploying to Raspberry Pi, change host to "localhost"
# and user/password to "locust"/"locust123"
# Backwards-compatible DB_CONFIG (from old gateway)
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
_db_conn = None
_threshold_cache = {}
_last_db_write_ts = 0.0

# ─── Database ─────────────────────────────────────────────
def get_db():
    """Reuse one PostgreSQL connection to avoid TLS handshake on every message."""
    global _db_conn
    if _db_conn is None or _db_conn.closed:
        _db_conn = psycopg.connect(DATABASE_URL)
    return _db_conn


def get_mysql_conn():
    """Return a new MySQL connection using mysql-connector (matches old gateway style)."""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        print(f"[MySQL] Connection failed: {e}")
        return None


def _get_default_thresholds():
    return {
        "target_temperature": 25.0,
        "target_temperature_min": 20.0,
        "target_humidity": 60.0,
        "target_humidity_min": 40.0,
        "target_light_level": 75.0,
        "target_light_level_min": 30.0,
        "target_gas_level": 2000.0,
        "target_gas_level_min": 0.0,
    }

def fetch_thresholds(container_id):
    """Try to read thresholds from local MySQL first (fast). Fall back to Postgres, then defaults."""
    cached = _threshold_cache.get(container_id)
    now_ts = time.time()
    if cached and now_ts - cached["ts"] < THRESHOLD_CACHE_SECONDS:
        return cached["data"]

    # 1) Try MySQL local (use dictionary cursor as in the original gateway)
    try:
        mysql_conn = get_mysql_conn()
        if mysql_conn:
            cur = mysql_conn.cursor(dictionary=True)
            cur.execute(
                """
                SELECT target_temperature, target_temperature_min,
                       target_humidity,    target_humidity_min,
                       target_light_level, target_light_level_min,
                       target_gas_level,   target_gas_level_min
                FROM container_data
                WHERE container_id = %s
                """,
                (container_id,)
            )
            row = cur.fetchone()
            try:
                cur.close()
            except Exception:
                pass
            try:
                mysql_conn.close()
            except Exception:
                pass

            if row and any(v is not None for v in row.values()):
                # row is a dict, map keys to expected names (keep numeric types)
                values = {
                    "target_temperature":     row.get("target_temperature"),
                    "target_temperature_min": row.get("target_temperature_min"),
                    "target_humidity":        row.get("target_humidity"),
                    "target_humidity_min":    row.get("target_humidity_min"),
                    "target_light_level":     row.get("target_light_level"),
                    "target_light_level_min": row.get("target_light_level_min"),
                    "target_gas_level":       row.get("target_gas_level"),
                    "target_gas_level_min":   row.get("target_gas_level_min")
                }
                _threshold_cache[container_id] = {"ts": now_ts, "data": values}
                return values
    except Exception as e:
        print(f"[MySQL] Failed to fetch thresholds: {e}")

    # 2) Fallback to Postgres (Neon)
    try:
        db = get_db()
        with db.cursor() as cur:
            cur.execute("""
                SELECT target_temperature, target_temperature_min,
                       target_humidity,    target_humidity_min,
                       target_light_level, target_light_level_min,
                       target_gas_level,   target_gas_level_min
                FROM container_data
                WHERE container_id = %s
            """, (container_id,))
            row = cur.fetchone()

        if row:
            values = {
                "target_temperature":     row[0],
                "target_temperature_min": row[1],
                "target_humidity":        row[2],
                "target_humidity_min":    row[3],
                "target_light_level":     row[4],
                "target_light_level_min": row[5],
                "target_gas_level":       row[6],
                "target_gas_level_min":   row[7]
            }
        else:
            values = _get_default_thresholds()

        _threshold_cache[container_id] = {"ts": now_ts, "data": values}
        return values
    except Exception as e:
        print(f"[DB] Failed to fetch thresholds from Postgres: {e}")
        return _get_default_thresholds()

def update_db(temp, hum, lux_percent, gas, heater, fan, light, humidifier, container_id):
    global _last_db_write_ts
    now_ts = time.time()
    if now_ts - _last_db_write_ts < DB_WRITE_MIN_INTERVAL_SECONDS:
        return

    try:
        db = get_db()
        with db.cursor() as cur:
            heater_status = bool(heater)
            fan_status = bool(fan)
            light_status = bool(light)
            humidifier_status = bool(humidifier)

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
                heater_status, fan_status, light_status, humidifier_status,
                datetime.now(),
                container_id
            ))

        db.commit()
        _last_db_write_ts = now_ts
        print(f"[DB] Updated container_data for container {container_id}")
    except Exception as e:
        print(f"[DB] Error: {e}")

    # Also write to local MySQL (best-effort). Keep Postgres as primary but mirror to MySQL.
    try:
        mysql_conn = get_mysql_conn()
        if not mysql_conn:
            return
        cur = mysql_conn.cursor()
        cur.execute(
            """
            UPDATE container_data
            SET temperature = %s,
                humidity = %s,
                light_level = %s,
                gas_level = %s,
                heater_status = %s,
                fan_status = %s,
                light_status = %s,
                humidifier_status = %s,
                last_updated = %s
            WHERE container_id = %s
            """,
            (
                temp, hum, lux_percent, gas,
                heater_status, fan_status, light_status, humidifier_status,
                datetime.now(), container_id
            ),
        )
        mysql_conn.commit()
        try:
            cur.close()
        except Exception:
            pass
        try:
            mysql_conn.close()
        except Exception:
            pass
        print(f"[MySQL] Mirrored container_data for container {container_id}")
    except Exception as e:
        print(f"[MySQL] Error writing mirror: {e}")

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


def on_disconnect(client, userdata, *args):
    # Accept any callback signature (paho can call with varying args)
    try:
        print(f"[MQTT] Disconnected — userdata={userdata} args={args}")
    except Exception:
        print("[MQTT] Disconnected (failed to format args)")


# ─── Main ─────────────────────────────────────────────────
def main():
    # Use a unique client_id to avoid collisions with other clients
    client_id = f"Gateway-{os.getpid()}"
    try:
        client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id=client_id)
    except AttributeError:
        client = mqtt.Client(client_id=client_id)
    client.on_connect = on_connect
    client.on_message = on_message
    client.on_disconnect = on_disconnect

    print(f"[GW] Connecting to {MQTT_BROKER}...")
    client.connect(MQTT_BROKER, MQTT_PORT, keepalive=60)
    client.loop_forever()

if __name__ == "__main__":
    main()