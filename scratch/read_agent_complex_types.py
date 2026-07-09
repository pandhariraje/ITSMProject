import base64

with open("force-app/main/default/genAiPlannerBundles/Help_Desk_Incident_Agent_v8/agentScript/Help_Desk_Incident_Agent_v8_definition.agent", "r") as f:
    encoded = f.read().strip()

decoded = base64.b64decode(encoded).decode('utf-8')

for line in decoded.split('\n'):
    if 'complex_data_type_name' in line:
        print(line)
