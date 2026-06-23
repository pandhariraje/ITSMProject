const fs = require('fs');
const tracePath = 'c:/Users/Ramrao Biradar/Desktop/Project/MyProject/ITSM/ITSMProject/.sfdx/agents/ITSM_Assistant/sessions/9c48605c-9719-4e57-a34f-9a620dc5d63c/traces/c5d95d21-e21a-4ad6-989c-54cef1c132e5.json';
const t = JSON.parse(fs.readFileSync(tracePath, 'utf8'));
t.plan.forEach(s => {
    if (s.type === 'LLMStep') {
        console.log("Enabled Tools:");
        console.log(JSON.stringify(s.tools_sent, null, 2));
        console.log("LLM Response Messages:");
        console.log(JSON.stringify(s.response_messages, null, 2));
    }
});
