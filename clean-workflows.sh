#!/bin/bash
# Clean n8n workflow JSON files for public sharing
# Removes credential IDs/names, Slack channel IDs, Error Workflow references

for file in workflows/*.json; do
  echo "Cleaning $file..."
  
  python3 -c "
import json, sys

with open('$file', 'r') as f:
    data = json.load(f)

def clean_node(node):
    # Remove credential references
    if 'credentials' in node:
        for cred_type, cred_data in node['credentials'].items():
            if isinstance(cred_data, dict):
                cred_data['id'] = ''
                cred_data['name'] = ''
    # Clean Slack channel IDs
    if node.get('type') == 'n8n-nodes-base.slack':
        params = node.get('parameters', {})
        if 'channel' in params:
            params['channel'] = ''
    return node

# Clean workflow-level settings
if isinstance(data, list):
    wf = data[0] if data else data
else:
    wf = data

# Remove error workflow reference
settings = wf.get('settings', {})
if 'errorWorkflow' in settings:
    del settings['errorWorkflow']

# Clean each node
for node in wf.get('nodes', []):
    clean_node(node)

with open('$file', 'w') as f:
    json.dump(wf if not isinstance(data, list) else data, f, indent=2, ensure_ascii=False)
"
  
  echo "Done: $file"
done

echo ""
echo "All workflows cleaned. Review the files before committing."
