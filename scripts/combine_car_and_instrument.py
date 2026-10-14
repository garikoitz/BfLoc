"""Build the `object1` stimulus folder for the tempread design.

Picks 40 random images from stimuli/car and 40 from stimuli/instrument,
shuffles them together and copies them as object1-1.jpg .. object1-80.jpg
(same approach as combine_body_and_limb.ipynb). A fixed seed makes the
selection reproducible, and stimuli/object1_mapping.csv records
new name -> original name.

Usage (from anywhere):  python scripts/combine_car_and_instrument.py
"""
import csv
import os
import random
import shutil

SEED = 20261014
N_PER_SOURCE = 40

basedir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "stimuli")

# Define input folders
car_folder = os.path.join(basedir, "car")
instrument_folder = os.path.join(basedir, "instrument")

# Define output folder
object1_folder = os.path.join(basedir, "object1")
mapping_csv = os.path.join(basedir, "object1_mapping.csv")

rng = random.Random(SEED)

# Get list of images
car_images = sorted(f for f in os.listdir(car_folder) if f.endswith('.jpg'))
instrument_images = sorted(f for f in os.listdir(instrument_folder) if f.endswith('.jpg'))

# Randomly select 40 images from each and shuffle them together
object1_list = rng.sample(car_images, N_PER_SOURCE) + rng.sample(instrument_images, N_PER_SOURCE)
rng.shuffle(object1_list)

# Start from an empty output folder so reruns don't leave stale files
if os.path.isdir(object1_folder):
    shutil.rmtree(object1_folder)
os.makedirs(object1_folder)

# Copy and rename images, writing the mapping as we go
with open(mapping_csv, "w", newline="") as fid:
    writer = csv.writer(fid)
    writer.writerow(["new_name", "original_name"])
    for idx, img in enumerate(object1_list, start=1):
        src_folder = car_folder if img.startswith("car-") else instrument_folder
        new_name = f"object1-{idx}.jpg"
        shutil.copy(os.path.join(src_folder, img), os.path.join(object1_folder, new_name))
        writer.writerow([new_name, img])

print(f"Wrote {len(object1_list)} images to {object1_folder} and mapping to {mapping_csv}")
