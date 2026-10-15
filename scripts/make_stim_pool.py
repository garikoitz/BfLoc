"""Choose the fixed 80-image stimulus pool for each tempread category.

For every category folder with more than POOL_SIZE images, picks POOL_SIZE
of them at random with a fixed seed; folders with POOL_SIZE or fewer images
use all of them. Writes stimuli/stim_pool_80.csv (category,image), which
votclocSequence.m reads so every participant sees the same images.

Rerun this whenever images are added to or deleted from these folders:
    python scripts/make_stim_pool.py
"""
import csv
import os
import random
import re

SEED = 20261015
POOL_SIZE = 80
CATEGORIES = ["ES_RW1", "face1", "hand", "ES_FF1", "ES_SC1", "instrument", "dessert", "bodylimb1"]

basedir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "stimuli")
pool_csv = os.path.join(basedir, f"stim_pool_{POOL_SIZE}.csv")

rng = random.Random(SEED)

with open(pool_csv, "w", newline="") as fid:
    writer = csv.writer(fid)
    writer.writerow(["category", "image"])
    for cat in CATEGORIES:
        pattern = re.compile(rf"^{re.escape(cat)}-(\d+)\.jpg$")
        images = sorted((f for f in os.listdir(os.path.join(basedir, cat)) if pattern.match(f)),
                        key=lambda f: int(pattern.match(f).group(1)))
        if len(images) > POOL_SIZE:
            images = sorted(rng.sample(images, POOL_SIZE), key=lambda f: int(pattern.match(f).group(1)))
        for img in images:
            writer.writerow([cat, img])
        print(f"{cat}: {len(images)} images")

print(f"Wrote {pool_csv}")
