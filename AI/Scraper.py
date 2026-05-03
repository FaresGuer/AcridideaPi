import os
import requests
import time
from PIL import Image
from io import BytesIO
from tqdm import tqdm
from pyinaturalist import get_observations

# ─── Config ───────────────────────────────────────────────
OUTPUT_DIR = "dataset/raw"
CLASSES    = ["male_cricket", "female_cricket", "dead_cricket"]

# iNaturalist taxon ID for crickets (Gryllidae family)
CRICKET_TAXON_ID = 52884

MIN_SIZE   = (100, 100)   # discard images smaller than this
MAX_IMAGES = 300          # per class target
REQUEST_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
}

# ─── Setup folders ────────────────────────────────────────
for cls in CLASSES:
    os.makedirs(f"{OUTPUT_DIR}/{cls}", exist_ok=True)
os.makedirs("dataset/labeled", exist_ok=True)

# ─── Helpers ──────────────────────────────────────────────
def download_image(url, save_path):
    try:
        response = requests.get(url, timeout=10, headers=REQUEST_HEADERS)
        response.raise_for_status()
        img = Image.open(BytesIO(response.content)).convert("RGB")
        if img.size[0] < MIN_SIZE[0] or img.size[1] < MIN_SIZE[1]:
            return False
        img.save(save_path)
        return True
    except Exception as e:
        print(f"  Failed: {url} — {e}")
        return False

def sanitize(text):
    return text.replace(" ", "_").replace("/", "_")

def is_cricket_observation(observation):
    taxon = observation.get("taxon") or {}
    taxon_id = taxon.get("id")
    ancestor_ids = taxon.get("ancestor_ids") or []
    iconic = taxon.get("iconic_taxon_name")
    # Defensive filter: keep only insect observations in Gryllidae lineage.
    return iconic == "Insecta" and (
        taxon_id == CRICKET_TAXON_ID or CRICKET_TAXON_ID in ancestor_ids
    )

# ─── iNaturalist scraper ───────────────────────────────────
# iNaturalist has observation quality controls and species verification
# so images are much more reliable than Google
def scrape_inaturalist(label, query_term, count=200):
    print(f"\n[iNaturalist] Scraping '{query_term}' → {label}")
    saved = 0
    page  = 1
    use_query = True

    while saved < count:
        params = {
            "taxon_id": CRICKET_TAXON_ID,
            "quality_grade": "research",  # verified observations only
            "photos": True,
            "per_page": 50,
            "page": page,
        }
        if use_query and query_term:
            params["q"] = query_term
        obs = get_observations(**params)

        results = obs.get("results", [])
        if not results:
            if page == 1 and use_query:
                # Fallback: query terms are often too restrictive for this endpoint.
                print("  No results with query filter; retrying taxon-only...")
                use_query = False
                continue
            print(f"  No more results at page {page}")
            break

        for obs in tqdm(results, desc=f"Page {page}"):
            if saved >= count:
                break
            if not is_cricket_observation(obs):
                continue
            photos = obs.get("photos", [])
            for photo in photos:
                url = photo.get("url", "").replace("square", "large")
                if not url:
                    continue
                path = f"{OUTPUT_DIR}/{label}/{sanitize(label)}_{saved:04d}.jpg"
                if download_image(url, path):
                    saved += 1
                    break  # one image per observation
            time.sleep(0.2)  # be polite to the API

        page += 1
        time.sleep(1)

    print(f"  Saved {saved} images for '{label}'")
    return saved

# ─── Web image scraper (supplement iNaturalist) ───────────
# Used to supplement when iNaturalist doesn't have enough
def scrape_web_images(label, query, count=100):
    print(f"\n[Web] Scraping '{query}' → {label}")
    try:
        from ddgs import DDGS
    except Exception:
        try:
            from duckduckgo_search import DDGS
        except Exception as e:
            print(f"  Skipping web scrape: {e}")
            return 0

    saved = 0
    attempts = 0
    while saved < count and attempts < 4:
        attempts += 1
        try:
            with DDGS() as ddgs:
                for result in ddgs.images(query, max_results=count * 2):
                    if saved >= count:
                        break
                    url = result.get("image")
                    if not url:
                        continue
                    dst = f"{OUTPUT_DIR}/{label}/{sanitize(label)}_web_{saved:04d}.jpg"
                    if download_image(url, dst):
                        saved += 1
                    time.sleep(0.15)
            if saved > 0:
                break
        except Exception as e:
            if "Ratelimit" in str(e):
                wait_seconds = attempts * 6
                print(f"  Rate limited, retrying in {wait_seconds}s...")
                time.sleep(wait_seconds)
                continue
            print(f"  Web search failed: {e}")
            break

    print(f"  Saved {saved} images for '{label}'")
    return saved

# ─── Deduplication ────────────────────────────────────────
# Remove duplicate images using file size as a quick filter
def deduplicate(label):
    print(f"\n[Dedup] Cleaning {label}...")
    folder  = f"{OUTPUT_DIR}/{label}"
    seen    = set()
    removed = 0

    for fname in os.listdir(folder):
        path = f"{folder}/{fname}"
        size = os.path.getsize(path)
        if size in seen:
            os.remove(path)
            removed += 1
        else:
            seen.add(size)

    print(f"  Removed {removed} duplicates")

# ─── Main ─────────────────────────────────────────────────
def main():
    print("=" * 50)
    print("Cricket Dataset Scraper")
    print("=" * 50)

    # iNaturalist queries — these terms help filter by sex
    # dead crickets need a different approach since iNat
    # doesn't have a death tag — we use Bing for those
    inaturalist_queries = [
        ("male_cricket",   "male cricket gryllus"),
        ("female_cricket", "female cricket gryllus ovipositor"),
    ]

    web_queries = [
        ("male_cricket",   "male cricket insect close up"),
        ("female_cricket", "female cricket insect ovipositor close up"),
        ("dead_cricket",   "dead cricket insect"),
    ]

    # Scrape iNaturalist first (higher quality)
    for label, query in inaturalist_queries:
        scrape_inaturalist(label, query, count=200)

    # Supplement with web image search
    for label, query in web_queries:
        scrape_web_images(label, query, count=100)
        time.sleep(3)

    # Deduplicate
    for cls in CLASSES:
        deduplicate(cls)

    # Final count
    print("\n" + "=" * 50)
    print("Dataset summary:")
    for cls in CLASSES:
        folder = f"{OUTPUT_DIR}/{cls}"
        count  = len(os.listdir(folder))
        print(f"  {cls}: {count} images")
    print("=" * 50)
    print("\nNext step: upload dataset/raw to Roboflow for labeling")
    print("https://roboflow.com")

if __name__ == "__main__":
    main()