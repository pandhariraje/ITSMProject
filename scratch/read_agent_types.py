import os
import glob
import re

agent_files = glob.glob("force-app/**/*.agent", recursive=True)

for file in agent_files:
    if "genAiPlannerBundles" in file:
        continue
    try:
        with open(file, "r", encoding="utf-8") as f:
            content = f.read()
        match = re.search(r"agent_type:\s*\"?([^\n\"]+)\"?", content)
        label = re.search(r"agent_label:\s*\"?([^\n\"]+)\"?", content)
        if match:
            print(f"File: {os.path.basename(file)} | Label: {label.group(1) if label else 'N/A'} | Type: {match.group(1)}")
    except Exception as e:
        print(f"Error reading {file}: {e}")
