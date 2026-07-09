import subprocess

ids = [
    "0X9Bi0000000frBKAQ", # v1
    "0X9Bi0000000fw1KAA", # v2
    "0X9Bi0000000fxdKAA", # v3
    "0X9Bi0000000fzFKAQ", # v4
    "0X9Bi0000000g0rKAA", # v5
    "0X9Bi0000000g45KAA", # v6
    "0X9Bi0000000gC9KAI", # v7
    "0X9Bi0000000gDlKAI", # v8
    "0X9Bi0000000gFNKAY", # v9
    "0X9Bi0000000gGzKAI", # v10
]

for record_id in ids:
    print(f"Deleting BotVersion {record_id}...")
    cmd = f'sf data delete record --sobject BotVersion --record-id {record_id} --json'
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    print(res.stdout)
    if res.returncode != 0:
        print(f"Failed to delete {record_id}: {res.stderr}")
