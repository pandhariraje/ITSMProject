# Smart Incident Agent Specification

## Overview
The **Smart Incident Agent** is an autonomous AI agent built on Salesforce Agentforce for streamlined IT incident creation using custom LWC screens.

## Workflow Execution Steps
1. **Welcome**: Greets the user with `"Hello! I'm ITSM Copilot. I'll help you create a new Incident."`
2. **Launch Screen Action**: Executes `SmartIncidentShowFormAction` to present the custom `smartIncidentCreationForm` LWC component.
3. **Process Response**: Upon submission, outputs `Incident Id`, `Incident Number`, `Subject`, `Status`, and `Priority` and displays confirmation.
4. **Offer Next Actions**: Offers options: Update this Incident, Check Incident Status, Create Another Incident, End Conversation.
5. **Cancel Handling**: Handles user cancellation gracefully without creating records.
6. **Error Handling**: Displays user-friendly error messages while hiding technical Apex exceptions.

## Target Apex Classes
- `SmartIncidentController.cls`
- `SmartIncidentFormWrapper.cls`
- `SmartIncidentCreateAction.cls`
- `SmartIncidentShowFormAction.cls`
