# Agent Spec: ITSM Copilot

## Purpose & Scope

The `ITSM_Copilot` is an Agentforce assistant designed to guide users through ITSM workflows, specifically focusing on an interactive Incident Creation flow utilizing a custom Lightning Web Component screen.

## Behavioral Intent & Workflow

### Step 1 – Welcome
Displays:
> Hello! I'm ITSM Copilot. I'll help you create a new Incident.

### Step 2 – Launch Screen Action
Launches the custom `show_incident_form` Agent Action that opens the custom `itsmCopilotCreateIncidentForm` LWC screen.
The screen collects:
- Subject (Required)
- Description (Required)
- Urgency (High, Medium, Low)
- Impact (High, Medium, Low)
- Priority (Critical, High, Moderate, Low)
- Status (New, Open, In Process, Resolved, Completed, Problem Created, Closed)

### Step 3 – Process the Response
Upon clicking **Submit**, receives outputs from the action (`incidentId`, `incidentNumber`, `subject`, `status`, `priority`).
Displays confirmation message:
> Your Incident has been created successfully.
Along with Incident Number, Subject, Status, Priority.

### Step 4 – Offer Next Actions
Asks:
> What would you like to do next?
Options:
- Update this Incident
- Check Incident Status
- Create Another Incident
- End Conversation

### Step 5 – Cancel Handling
If user clicks **Cancel**:
Displays:
> Incident creation has been cancelled. No record was created.
Asks:
> Is there anything else I can help you with?

### Step 6 – Error Handling
On Apex/action error:
Displays:
> I couldn't create the Incident due to an error. Please review the information and try again.

## Subagent Map

```mermaid
%%{init: {'theme':'neutral'}}%%
graph TD
    A[start_agent agent_router] -->|Create incident, report issue, ticket request| B[incident_creation]
```

## Actions & Backing Logic

### show_incident_form (incident_creation)
- **Target:** `apex://ITSMCopilotShowIncidentFormAction`
- **Complex Data Type:** `c__itsmCopilotIncidentFormInputType`

### create_incident (incident_creation)
- **Target:** `apex://ITSMCopilotCreateIncidentAction`

## Agent Configuration

- **developer_name:** `ITSM_Copilot`
- **agent_label:** `ITSM Copilot`
- **agent_type:** `AgentforceEmployeeAgent`
