"""
locust_detector.py — runs on PC / Raspberry Pi
────────────────────────────────────────────────
- Pulls frames from ESP32-CAM MJPEG stream
- Runs YOLOv8 locust detection on each frame
- Gender is assigned randomly 50/50
- Boxes persist for N frames after detection (no flickering)
- Publishes count via MQTT every N seconds

MQTT publishes:
  camera/count   → "12"
  camera/males   → "7"
  camera/females → "5"
  camera/status  → "online" / "offline"

Usage:
  python locust_detector.py --model "path/to/last.pt" --stream http://192.168.x.x/stream --show
"""

import cv2
import time
import random
import argparse
import numpy as np
import paho.mqtt.client as mqtt
from ultralytics import YOLO
from datetime import datetime

# ─── Config ───────────────────────────────────────────────
MQTT_BROKER    = "broker.hivemq.com"
MQTT_PORT      = 1883
CONF_THRESH    = 0.50
PUBLISH_EVERY  = 5      # seconds between MQTT publishes
MIN_SIZE       = 30     # min px for valid detection
BOX_PERSIST    = 8      # frames to keep a box alive after detection disappears
IOU_THRESHOLD  = 0.35   # how much overlap to consider same locust

# ─── Tracked boxes ────────────────────────────────────────
# Each entry: [x1, y1, x2, y2, gender, ttl]
# ttl = frames remaining before box disappears
tracked = []

# ─── IOU helper ───────────────────────────────────────────
def iou(a, b):
    ax1, ay1, ax2, ay2 = a
    bx1, by1, bx2, by2 = b
    ix1 = max(ax1, bx1); iy1 = max(ay1, by1)
    ix2 = min(ax2, bx2); iy2 = min(ay2, by2)
    iw = max(0, ix2 - ix1); ih = max(0, iy2 - iy1)
    inter = iw * ih
    area_a = (ax2-ax1) * (ay2-ay1)
    area_b = (bx2-bx1) * (by2-by1)
    union = area_a + area_b - inter
    return inter / union if union > 0 else 0

# ─── Validity check ───────────────────────────────────────
def is_valid(roi):
    if roi.size == 0: return False
    h, w = roi.shape[:2]
    if h < MIN_SIZE or w < MIN_SIZE: return False
    ar = h / w
    if ar < 0.3 or ar > 2.5: return False
    return True

# ─── Update tracker ───────────────────────────────────────
def update_tracker(detections):
    """
    detections: list of (x1, y1, x2, y2)
    Matches new detections to existing tracked boxes via IOU.
    Unmatched tracked boxes lose 1 TTL.
    New detections get a fresh box with random gender.
    """
    global tracked

    matched_tracked = set()
    matched_det     = set()

    # Match detections to existing tracks
    for di, det in enumerate(detections):
        best_iou   = IOU_THRESHOLD
        best_track = -1
        for ti, track in enumerate(tracked):
            score = iou(det, track[:4])
            if score > best_iou:
                best_iou   = score
                best_track = ti
        if best_track >= 0:
            # Update position, reset TTL
            tracked[best_track][0] = det[0]
            tracked[best_track][1] = det[1]
            tracked[best_track][2] = det[2]
            tracked[best_track][3] = det[3]
            tracked[best_track][5] = BOX_PERSIST
            matched_tracked.add(best_track)
            matched_det.add(di)

    # New detections that didn't match any existing track
    for di, det in enumerate(detections):
        if di not in matched_det:
            gender = "Male" if random.random() < 0.5 else "Female"
            tracked.append([det[0], det[1], det[2], det[3], gender, BOX_PERSIST])

    # Decay TTL for unmatched tracks, remove dead ones
    new_tracked = []
    for ti, track in enumerate(tracked):
        if ti not in matched_tracked:
            track[5] -= 1
        if track[5] > 0:
            new_tracked.append(track)
    tracked = new_tracked

# ─── Process one frame ────────────────────────────────────
def process_frame(frame, model):
    global tracked

    h_img, w_img = frame.shape[:2]

    # Run YOLO
    results = model.predict(source=frame, conf=CONF_THRESH, verbose=False)

    # Collect valid detections
    detections = []
    for r in results:
        if r.boxes is None: continue
        for box in r.boxes.xyxy.cpu().numpy():
            x1, y1, x2, y2 = map(int, box)
            x1, y1 = max(0, x1), max(0, y1)
            x2, y2 = min(w_img, x2), min(h_img, y2)
            roi = frame[y1:y2, x1:x2]
            if is_valid(roi):
                detections.append((x1, y1, x2, y2))

    # Update persistent tracker
    update_tracker(detections)

    # Count from tracker
    total   = len(tracked)
    males   = sum(1 for t in tracked if t[4] == "Male")
    females = sum(1 for t in tracked if t[4] == "Female")

    # Draw tracked boxes
    for track in tracked:
        x1, y1, x2, y2, gender, ttl = track
        color = (255, 255, 0) if gender == "Male" else (255, 0, 255)

        # Fade box slightly when TTL is low (coasting)
        alpha = min(1.0, ttl / BOX_PERSIST)
        c = tuple(int(ch * alpha) for ch in color)

        cv2.rectangle(frame, (x1, y1), (x2, y2), c, 2)
        label = f"{gender}"
        cv2.putText(frame, label, (x1, y1 - 5),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.45, c, 1)

    # HUD
    cv2.putText(frame, f"Locusts: {total}  M:{males} F:{females}",
                (10, 24), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
    cv2.putText(frame, datetime.now().strftime("%H:%M:%S"),
                (w_img - 70, 24), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (200, 200, 200), 1)

    return frame, total, males, females

# ─── MQTT ─────────────────────────────────────────────────
def make_mqtt():
    c = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id="LocustDetector")
    c.connect(MQTT_BROKER, MQTT_PORT, keepalive=60)
    c.loop_start()
    return c

# ─── Main ─────────────────────────────────────────────────
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--stream", required=True,  help="ESP32-CAM stream URL")
    ap.add_argument("--model",  required=True,  help="Path to last.pt YOLO weights")
    ap.add_argument("--show",   action="store_true", help="Show OpenCV window")
    args = ap.parse_args()

    print(f"[DET] Loading model: {args.model}")
    model = YOLO(args.model)
    print("[DET] Model loaded")

    print("[DET] Connecting MQTT...")
    mqttc = make_mqtt()
    mqttc.publish("camera/status", "online")
    print("[DET] MQTT connected")

    print(f"[DET] Opening stream: {args.stream}")
    cap = cv2.VideoCapture(args.stream)
    if not cap.isOpened():
        print("[DET] ERROR: Cannot open stream. Check ESP32-CAM IP.")
        return

    last_publish = 0

    print("[DET] Running. Press Q to quit.")
    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                print("[DET] Frame grab failed, retrying...")
                time.sleep(1)
                cap = cv2.VideoCapture(args.stream)
                continue

            annotated, total, males, females = process_frame(frame, model)

            # Publish every N seconds
            now = time.time()
            if now - last_publish >= PUBLISH_EVERY:
                mqttc.publish("camera/count",   str(total))
                mqttc.publish("camera/males",   str(males))
                mqttc.publish("camera/females", str(females))
                print(f"[DET] Published → total:{total} males:{males} females:{females}")
                last_publish = now

            if args.show:
                cv2.imshow("Locust Detection", annotated)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break

    except KeyboardInterrupt:
        print("\n[DET] Stopped.")
    finally:
        cap.release()
        mqttc.publish("camera/status", "offline")
        mqttc.loop_stop()
        if args.show:
            cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
