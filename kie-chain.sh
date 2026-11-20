#!/bin/bash
# kie-chain.sh — Lane B chain via Kie.ai Seedance v1 Lite i2v (720p, 5s/clip)
# Same contract as fal-chain.sh: clip1 starts from the Agnes opening keyframe;
# every next clip starts from the literal last frame of the previous clip.
# Kie needs public URLs -> uses Kie's file-base64-upload for each start image.
# Requires KIE_API_KEY in env. Mechanical lane — no model.
set -e -o pipefail
DIR="$(cd "$(dirname "$0")" && pwd)/kieassets"
mkdir -p "$DIR"
MODEL="bytedance/v1-lite-image-to-video"

declare -a NAMES=(cap1 cap2 cap3 cap4 cap5)
declare -a PROMPTS=(
"slow cinematic camera drift forward through a vast dark void of scattered glowing cyan and violet data fragments, particles subtly beginning to align and drift toward the center, smooth continuous motion, no cuts"
"continue the exact same camera drift, now accelerating into a converging tunnel of cyan and violet light particles rushing toward a single distant point, smooth continuous motion, no cuts, do not change the colour grade"
"continue the exact same camera drift, the tunnel of light collapses into a single brilliant glowing portal core with concentric rings of cyan and violet energy, smooth continuous motion, no cuts, do not change the colour grade"
"continue the exact same camera drift, the glowing portal core expands and opens outward revealing a vast organized grid of glowing cyan and violet nodes and connecting lines, smooth continuous motion, no cuts, do not change the colour grade"
"continue the exact same camera drift, the network of glowing nodes resolves and settles into a calm symmetrical dark navy scene with a single elegant glowing portal emblem centered, camera coming to rest, smooth continuous motion, no cuts, do not change the colour grade"
)

START_IMG="$(dirname "$DIR")/assets/cap1-start.png"
PREV_LAST=""

upload_img () { # $1 local path -> echoes public URL
  python3 - "$1" <<'PY'
import base64,json,sys,os
p = sys.argv[1]
b = base64.b64encode(open(p,'rb').read()).decode()
payload = {"base64Data": f"data:image/png;base64,{b}", "uploadPath":"images/sitefilm",
           "fileName": os.path.basename(p)}
open('/tmp/kie-up.json','w').write(json.dumps(payload))
PY
  curl -sS -X POST "https://kieai.redpandaai.co/api/file-base64-upload" \
    -H "Authorization: Bearer $KIE_API_KEY" -H "Content-Type: application/json" \
    -d @/tmp/kie-up.json | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['downloadUrl'])"
}

for i in 0 1 2 3 4; do
  NAME="${NAMES[$i]}"; PROMPT="${PROMPTS[$i]}"
  if [ "$i" -eq 0 ]; then IMG="$START_IMG"; else IMG="$DIR/${NAMES[$((i-1))]}-last.png"; fi
  [ -r "$IMG" ] || { echo "[$NAME] start image missing: $IMG"; exit 1; }

  echo "[$NAME] uploading start image..."
  IMG_URL=$(upload_img "$IMG")
  [ -n "$IMG_URL" ] || { echo "[$NAME] upload failed"; exit 1; }

  python3 - "$MODEL" "$PROMPT" "$IMG_URL" <<'PY'
import json,sys
model, prompt, url = sys.argv[1:4]
payload = {"model": model, "input": {"prompt": prompt, "image_url": url,
           "duration":"5", "resolution":"720p", "camera_fixed": False}}
open('/tmp/kie-task.json','w').write(json.dumps(payload))
PY

  TID=""
  for a in 1 2 3; do
    RESP=$(curl -sS -X POST "https://api.kie.ai/api/v1/jobs/createTask" \
      -H "Authorization: Bearer $KIE_API_KEY" -H "Content-Type: application/json" \
      -d @/tmp/kie-task.json)
    TID=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print((d.get('data') or {}).get('taskId',''))" 2>/dev/null)
    [ -n "$TID" ] && break
    echo "[$NAME] create retry $a — $(echo "$RESP" | head -c 200)"; sleep 10
  done
  [ -n "$TID" ] || { echo "[$NAME] FAILED to create task"; exit 1; }
  echo "[$NAME] task $TID — polling..."

  URL=""
  for a in $(seq 1 90); do
    REC=$(curl -sS "https://api.kie.ai/api/v1/jobs/recordInfo?taskId=$TID" -H "Authorization: Bearer $KIE_API_KEY")
    STATE=$(echo "$REC" | python3 -c "import sys,json; d=json.load(sys.stdin); print((d.get('data') or {}).get('state',''))" 2>/dev/null)
    if [ "$STATE" = "success" ]; then
      URL=$(echo "$REC" | python3 -c "
import sys,json
d=json.load(sys.stdin)['data']
res=d.get('resultJson') or ''
try:
  rj=json.loads(res) if isinstance(res,str) else res
  urls=(rj.get('resultUrls') or rj.get('result_urls') or [])
  print(urls[0] if urls else '')
except Exception: print('')")
      break
    elif [ "$STATE" = "fail" ]; then
      echo "[$NAME] FAILED server-side:"; echo "$REC" | head -c 400; exit 1
    fi
    sleep 8
  done
  [ -n "$URL" ] || { echo "[$NAME] timed out or no result url"; echo "$REC" | head -c 400; exit 1; }

  curl -fsSL -o "$DIR/$NAME.mp4" "$URL"
  ffmpeg -y -v error -i "$DIR/$NAME.mp4" -vf "select=eq(n\,0)" -frames:v 1 -update 1 -q:v 1 "$DIR/$NAME-first.png"
  ffmpeg -y -v error -sseof -0.05 -i "$DIR/$NAME.mp4" -update 1 -q:v 1 "$DIR/$NAME-last.png"
  echo "[$NAME] downloaded: $(ffprobe -v error -select_streams v -show_entries stream=width,height,nb_frames -of csv=p=0 "$DIR/$NAME.mp4")"

  if [ -n "$PREV_LAST" ]; then
    SSIM=$( (ffmpeg -i "$PREV_LAST" -i "$DIR/$NAME-first.png" -lavfi "scale2ref[a][b];[a][b]ssim" -f null - 2>&1 || true) | grep -o 'All:[0-9.]*' | cut -d: -f2)
    ffmpeg -y -v error -i "$PREV_LAST" -i "$DIR/$NAME-first.png" -filter_complex "[1][0]scale2ref[b][a];[a][b]hstack" "$DIR/$NAME-junction-compare.jpg" || true
    echo "[$NAME] JUNCTION SSIM vs prev-last: ${SSIM:-n/a}  (compare: $NAME-junction-compare.jpg)"
  fi
  PREV_LAST="$DIR/$NAME-last.png"
done

set -a; :; set +a
echo "credits left: $(curl -sS 'https://api.kie.ai/api/v1/chat/credit' -H "Authorization: Bearer $KIE_API_KEY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data'))")"
echo "CHAIN DONE"
