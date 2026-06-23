const fs = require('fs');
const tracePath = 'c:/Users/Ramrao Biradar/Desktop/Project/MyProject/ITSM/ITSMProject/.sfdx/agents/ITSM_Assistant/sessions/d05b8831-d4cf-4057-9715-826bc8bf2bdf/traces/839856f7-626a-4643-b85a-0bec6739a93e.json';
const t = JSON.parse(fs.readFileSync(tracePath, 'utf8'));
t.plan.forEach(s => {
    console.log("-------------------------------");
    console.log("Step type:", s.type);
    if (s.type === 'TransitionStep') {
        console.log("Transition:", s.data.from, "->", s.data.to);
    } else if (s.type === 'FunctionStep') {
        console.log("Function Call:", s.data.function, "Output:", JSON.stringify(s.data.output));
    } else if (s.type === 'NodeEntryStateStep') {
        console.log("Entering Node:", s.data.agent_name || s.data.node_name);
    } else if (s.type === 'LLMStep') {
        console.log("LLM response:", JSON.stringify(s.response_messages, null, 2));
    } else if (s.type === 'PlannerResponseStep') {
        console.log("Response:", s.message);
    }
});
