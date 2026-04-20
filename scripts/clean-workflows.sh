#!/bin/bash
# Scrub n8n workflow JSON files for public sharing.
# Clears credential IDs/names, Slack channel selectors (incl. __rl resource locators),
# errorWorkflow references, and forces active=false.
#
# Usage: ./scripts/clean-workflows.sh

set -e

cd "$(dirname "$0")/.."

for file in workflows/*.json; do
  echo "Cleaning $file..."

  python3 - "$file" <<'PY'
import json, sys

path = sys.argv[1]
with open(path) as f:
    data = json.load(f)

wf = data[0] if isinstance(data, list) else data

wf["active"] = False

settings = wf.get("settings", {})
settings.pop("errorWorkflow", None)

for node in wf.get("nodes", []):
    for cred in (node.get("credentials") or {}).values():
        if isinstance(cred, dict):
            cred["id"] = ""
            cred["name"] = ""
    if node.get("type") == "n8n-nodes-base.slack":
        params = node.setdefault("parameters", {})
        for key in ("channel", "channelId"):
            val = params.get(key)
            if isinstance(val, dict):
                val["value"] = ""
                val["cachedResultName"] = ""
            elif isinstance(val, str):
                params[key] = ""

with open(path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY

  echo "Done: $file"
done

echo ""
echo "All workflows cleaned. Review the files before committing."
