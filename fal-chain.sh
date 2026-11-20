#!/bin/bash
# fal-chain.sh — Lane B chain via fal.ai Seedance Lite (720p, 5s/clip)
# Chains 5 clips: clip1 starts from the Agnes opening keyframe; every next clip
# starts from the literal last frame of the previous clip. SSIM-gates junctions.
# Requires FAL_KEY in env. Mechanical lane — no model.
set -e -o pipefail
DIR="$(cd "$(dirname "$0")" && pwd)/falassets"
mkdir -p "$DIR"
ENDPOINT="fal-ai/bytedance/seedance/v1/lite/image-to-video"

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

for i in 0 1 2 3 4; do
  NAME="${NAMES[$i]}"; PROMPT="${PROMPTS[$i]}"
  if [ "$i" -eq 0 ]; then IMG="$START_IMG"; else IMG="$DIR/${NAMES[$((i-1))]}-last.png"; fi
  [ -r "$IMG" ] || { echo "[$NAME] start image missing: $IMG"; exit 1; }

  echo "[$NAME] encoding start image + submitting (Seedance Lite 720p 5s)..."
  python3 - "$IMG" "$PROMPT" <<'PY'
import base64,json,sys
img, prompt = sys.argv[1], sys.argv[2]
b = base64.b64encode(open(img,'rb').read()).decode()
payload = {"prompt": prompt, "image_url": f"data:image/png;base64,{b}",
           "aspect_ratio":"16:9", "duration":"5", "camera_fixed": False}
open('/tmp/fal-payload.json','w').write(json.dumps(payload))
PY

  RID=""
  for a in 1 2 3; do
    RESP=$(curl -sS -X POST "https://queue.fal.run/$ENDPOINT" \
      -H "Authorization: Key $FAL_KEY" -H "Content-Type: application/json" \
      -d @/tmp/fal-payload.json)
    RID=$(echo "$RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('request_id',''))" 2>/dev/null)
    [ -n "$RID" ] && break
    echo "[$NAME] submit retry $a — $(echo "$RESP" | head -c 200)"; sleep 10
  done
  [ -n "$RID" ] || { echo "[$NAME] FAILED to submit"; exit 1; }
  echo "[$NAME] request $RID — polling..."

  URL=""
  for a in $(seq 1 90); do
    ST=$(curl -sS "https://queue.fal.run/$ENDPOINT/requests/$RID/status" -H "Authorization: Key $FAL_KEY" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))" 2>/dev/null)
    if [ "$ST" = "COMPLETED" ]; then
      URL=$(curl -sS "https://queue.fal.run/$ENDPOINT/requests/$RID" -H "Authorization: Key $FAL_KEY" \
        | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('video',{}).get('url',''))" 2>/dev/null)
      break
    elif [ "$ST" = "FAILED" ] || [ "$ST" = "ERROR" ]; then
      echo "[$NAME] FAILED server-side"; curl -sS "https://queue.fal.run/$ENDPOINT/requests/$RID" -H "Authorization: Key $FAL_KEY" | head -c 400; exit 1
    fi
    sleep 8
  done
  [ -n "$URL" ] || { echo "[$NAME] timed out"; exit 1; }

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
echo "CHAIN DONE"
