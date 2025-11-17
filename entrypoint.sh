#!/bin/bash
set -e

# firmware names are provided via environment variables, specify the old/new
if [[ -z "$OLD_FW" || -z "$NEW_FW" ]]; then
    echo "[!] You must set OLD_FW and NEW_FW environment variables."
    echo "    Example: docker run -e OLD_FW=old.bin -e NEW_FW=new.bin ..."
    exit 1
fi

# construct the full paths to the firmware files
OLD_PATH="/bins/$OLD_FW"
NEW_PATH="/bins/$NEW_FW"

# directory where binwalk will write the extracted firmware
OUTDIR=/outputs/extractions
mkdir -p "$OUTDIR"

# extract old firmware
if [[ -f "$OLD_PATH" ]]; then
    echo "[*] Extracting OLD firmware: $OLD_FW"
    # use binwalk to extract recursively, suppress stdout, but leave stderr visible
    binwalk -eM --directory="$OUTDIR/$OLD_FW" "$OLD_PATH" > /dev/null 2>&1
else
    echo "[!] Old firmware file not found: $OLD_PATH"
    exit 1
fi

# extract new firmware
if [[ -f "$NEW_PATH" ]]; then
    echo "[*] Extracting NEW firmware: $NEW_FW"
    # use binwalk to extract recursively, suppress stdout, but leave stderr visible
    binwalk -eM --directory="$OUTDIR/$NEW_FW" "$NEW_PATH" > /dev/null 2>&1
else
    echo "[!] New firmware file not found: $NEW_PATH"
    exit 1
fi

# find the squashfs root within each extracted firmware sample
OLD_ROOT=$(find "$OUTDIR/$OLD_FW" -type d \( -name squashfs-root -o -name cpio-root \) | head -n 1)
NEW_ROOT=$(find "$OUTDIR/$NEW_FW" -type d \( -name squashfs-root -o -name cpio-root \) | head -n 1)
if [[ -z "$OLD_ROOT" || -z "$NEW_ROOT" ]]; then
    echo "[!] Could not find squashfs-root in one of the firmwares!"
    exit 1
fi

# run recursive diff and only report differing files, comparing the old to new
echo "[*] Comparing filesystem trees..."
DIFF_OUT=/outputs/firmware_diff_flat.json

diff -qr --no-dereference "$OLD_ROOT" "$NEW_ROOT" 2>&1 | awk -v old="$OLD_ROOT" -v new="$NEW_ROOT" '
BEGIN {
    print "["    # start the JSON array
    first=1      # tracks whether or not to print commas
}
{
    if ($1 == "Files" && $5 == "differ") {
        # case 1: if files are present in both, but contents differ
        if (!first) print ","
        print "  {\"status\":\"modified\", \"old\":\"" $2 "\", \"new\":\"" $4 "\"}"
        first=0
    }
    else if ($1 == "Only" && $2 == "in") {
        # case 2: file or directory exists only in old or new
        dir=$3
        file=$4
        gsub(":", "", dir)

        if (!first) print ","
        if (index(dir, old) == 1) {
            print "  {\"status\":\"removed\", \"path\":\"" dir "/" file "\"}"
        } else if (index(dir, new) == 1) {
            print "  {\"status\":\"added\", \"path\":\"" dir "/" file "\"}"
        } else {
            print "  {\"status\":\"unknown\", \"path\":\"" dir "/" file "\"}"
        }
        first=0
    }
    else if ($0 ~ /No such file or directory$/) {
        # case 3: diff reports a missing file explicitly
        missing=$2
        gsub(":", "", missing)
        if (!first) print ","
        if (index($0, old) > 0) {
            print "  {\"status\":\"removed\", \"path\":\"" missing "\"}"
        } else if (index($0, new) > 0) {
            print "  {\"status\":\"added\", \"path\":\"" missing "\"}"
        } else {
            print "  {\"status\":\"unknown\", \"path\":\"" missing "\"}"
        }
        first=0
    }
}
END {
    print "]" # close the JSON array
}' > "$DIFF_OUT"

echo "[+] Flat JSON diff written to $DIFF_OUT"

# build hierarchical tree JSON from flat JSON
python3 - <<'PYCODE'
import json
from pathlib import Path

flat_file = "/outputs/firmware_diff_flat.json"
tree_file = "/outputs/firmware_diff_tree.json"

def insert_path(tree, path):
    parts = Path(path).parts
    node = tree
    for p in parts[:-1]:  # walk through dirs only
        node = node.setdefault(p, {})
    # final part is the file
    node.setdefault("files", []).append(parts[-1])

# load the flat JSON
with open(flat_file) as f:
    entries = json.load(f)

# initialize tree structure
tree = {"modified": {}, "added": {}, "removed": {}}

# place paths into the tree by category
for entry in entries:
    status = entry["status"]
    if status == "modified":
        insert_path(tree["modified"], entry["old"].lstrip("/"))
        insert_path(tree["modified"], entry["new"].lstrip("/"))
    elif status == "added":
        insert_path(tree["added"], entry["path"].lstrip("/"))
    elif status == "removed":
        insert_path(tree["removed"], entry["path"].lstrip("/"))

# save hierarchical JSON
with open(tree_file, "w") as f:
    json.dump(tree, f, indent=2)

print("[+] Tree-style JSON diff written to", tree_file)
PYCODE
