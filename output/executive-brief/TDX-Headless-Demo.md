# TDX Highlights: Salesforce Headless 360 Demo

**Executive Brief | FDE Bank — Lending & Mortgage Application**

---

## 1. Introduction: What is Headless 360?

Salesforce **Headless 360** is a new architecture paradigm announced at TDX that decouples Agentforce capabilities from the Salesforce UI layer. It enables organisations to embed autonomous AI agents into any custom channel — native mobile apps, third-party portals, IoT devices, or partner systems — while keeping Salesforce as the single source of truth for customer data, business logic, and compliance.

### Why it matters

| Traditional Approach | Headless 360 Approach |
|---|---|
| Agents bound to Salesforce Messaging, Service Cloud chat, or Experience Cloud | Agents accessible via REST API from any frontend |
| Customer data locked behind Salesforce UI screens | Customer 360 data served headlessly to any client |
| Limited to Salesforce-rendered UX | Full creative control over brand experience |

**Key enabler:** The **Agentforce Agent API** (`/einstein/ai-agent/v1`) — a stateful, session-based REST endpoint that allows external applications to create agent sessions, send messages, and receive autonomous responses.

---

## 2. Agent Architecture Overview

The demo is powered by the **Loan Assistant** — a multi-agent orchestration bundle deployed as a `GenAiPlannerBundle` using the `Atlas__ConcurrentMultiAgentOrchestration` planner type.

### Agent Topology

```
                    +------------------+
                    |   Agent Router   |  (start_agent)
                    +--------+---------+
                             |
          +------------------+------------------+
          |                  |                  |
  +-------v------+  +-------v------+  +--------v--------+
  | Loan Request |  |  Escalation  |  |    Off Topic    |
  | (subagent)   |  |  (subagent)  |  |   (subagent)    |
  +--------------+  +--------------+  +-----------------+
                                               |
                                      +--------v--------+
                                      | Ambiguous Qn    |
                                      | (subagent)      |
                                      +-----------------+
```

### Topics & Responsibilities

| Topic | Role |
|-------|------|
| **Agent Router** | Entry point. Routes user intent to the correct subagent. |
| **Loan Request** | End-to-end loan onboarding: identity verification, financial data collection (work situation, income, property cost, loan amount, duration), and submission via Apex. |
| **Escalation** | Transfers conversation to a live human agent on explicit request. |
| **Off Topic** | Redirects off-topic queries without revealing system internals. |
| **Ambiguous Question** | Asks the user to clarify vague requests. |

### Actions (Apex-backed)

| Action | Description | Target |
|--------|-------------|--------|
| `get_contact_info` | Retrieves first name, last name, and account ID for the authenticated user from their Contact record. | `apex://GetContactInfo` |
| `create_loan_application` | Creates a `Loan_Application__c` record and five `Loan_QA__c` child records from collected onboarding data. | `apex://CreateLoanApplication` |

### State Management

The agent maintains session-scoped variables (`salesforceContactId`, `contact_first_name`, `contact_last_name`, `loan_application_id`, etc.) enabling stateful, multi-turn conversations without requiring the mobile app to manage context.

---

## 3. Custom Lending Mortgage Mobile App

The **FDE Bank** mobile application is a Flutter-based native app (`sdk >=3.3.0`) purpose-built to demonstrate a real-world headless banking experience.

### Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Navigation | GoRouter |
| HTTP | Dart `http` package |
| Auth | OAuth 2.0 Client Credentials via External Client App |
| Agent Comms | Agentforce Agent API (REST, session-based) |
| Security | `flutter_dotenv` for secrets, PKCE-capable |

### App Structure

```
lib/
  core/
    services/salesforce/        # Auth, HTTP client, config
    providers/                  # Contact ID, shared prefs
    router/                     # GoRouter definitions
  features/
    home/                       # Dashboard & transactions
    accounts/                   # Account overview
    payments/                   # Payment flows
    profile/                    # Salesforce Contact display
    mortgage/                   # Wizard + AI Chat
      screens/
        mortgage_wizard_screen  # Form-based wizard (10 steps)
        mortgage_chat_screen    # Conversational AI agent
      services/
        agent_service           # Agentforce session lifecycle
      providers/
        chat_provider           # Chat state management
        mortgage_provider       # Wizard state management
      models/
        agent_session           # Session metadata
        chat_message            # Message model
        mortgage_application    # Application data
        mortgage_question       # Question definitions
```

### Salesforce Integration Points

1. **OAuth 2.0 Client Credentials Flow** — External Client App with scopes: `api`, `refresh_token`, `chatbot_api`, `sfap_api`
2. **Contact API** — Standard REST API fetches customer profile data
3. **Agentforce Agent API** — Creates sessions, sends/receives messages, manages lifecycle
4. **Session Variables** — Passes `salesforceContactId` at session creation for identity resolution

---

## 4. Key Learnings from TDX

### Technical Insights

1. **External Client Apps replace Connected Apps** for Agentforce API access — they support the required `chatbot_api` scope and JWT-based token issuance.

2. **Session-based architecture** — The Agent API is stateful. Each session maintains its own variable state and conversation history, enabling multi-turn interactions without client-side context management.

3. **Streaming support** — The API supports `featureSupport: 'Streaming'` with text chunk types, enabling real-time typing indicators in the mobile UI.

4. **Agent Script DSL** — The `.agent` file format provides a declarative, version-controllable way to define agent behaviour including topic routing, action bindings, state updates, and guardrails — all deployable as metadata.

5. **Concurrent Multi-Agent Orchestration** — The `Atlas__ConcurrentMultiAgentOrchestration` planner allows independent subagents to handle different concerns while sharing state through a central variable store.

### Architecture Decisions

- **Thin client, thick platform** — The mobile app is deliberately simple; all business logic (identity verification, data validation, record creation) lives in Salesforce Apex behind the agent.
- **Dual UX paradigm** — Offering both wizard (form) and conversational (agent) paths on the same screen lets users self-select their preferred interaction model.
- **Identity via session variables** — Passing the Contact ID at session creation eliminates the need for the agent to ask "who are you?" — it already knows.

### Gotchas & Best Practices

- Agent type **cannot** be "Agentforce (Default)" — must be a custom agent
- Use `My Domain` URL (not `lightning.force.com`) for instance configuration
- Agent ID is the 18-char Salesforce ID visible in Agent Builder URL
- Token refresh (401 handling) must be implemented client-side
- The `x-b3-sampled: 1` header enables distributed tracing for debugging

---

## 5. Demo Journey: The Evolution of Banking

The demo tells a three-chapter story of how banking experiences evolve — from analog to digital to conversational.

### Chapter 1: Traditional In-Branch (Paper-Based)

> *"Please take a seat, fill out this form, and bring it back to the counter."*

- Customer visits a physical branch
- Fills out paper-based loan application forms
- Bank officer manually enters data into systems
- Processing takes days to weeks
- No real-time feedback or status updates
- Error-prone, repetitive data entry

**Pain points:** High friction, slow turnaround, inconsistent data quality, inaccessible outside business hours.

---

### Chapter 2: Digitised Experience (Form Wizard)

> *"Answer 10 quick questions and we'll prepare your mortgage application. It takes about 3 minutes."*

The mobile app's **Mortgage Wizard** (`mortgage_wizard_screen.dart`) digitalises the paper process:

- **10-step guided wizard** with progress bar
- Structured inputs: dropdowns, currency fields, numeric entry
- Client-side validation ensures data quality
- **Review page** summarises all answers before submission
- Encrypted, secure, accessible 24/7
- Confirmation with tracking reference

**UX highlights:**
- Security badge: "Your information is encrypted and secure"
- Time estimate: "10 steps, about 3 minutes"
- No-commitment: "Review before submitting"
- Option to switch to conversational: *"Prefer to talk to someone? Chat with FrED"*

**Improvement over paper:** Speed (minutes not days), accuracy (validated inputs), accessibility (anytime, anywhere), and cost (no branch visit required).

---

### Chapter 3: Conversational Agent-Driven Experience

> *"Hi, I'm FrED, FDE Bank's AI Assistant. How can I help you?"*

The **Mortgage Chat** (`mortgage_chat_screen.dart`) powered by Agentforce represents the final evolution:

- **Natural language interaction** — no forms, no buttons, just conversation
- **Identity-aware** — agent recognises the user by name via Salesforce Contact lookup
- **Guided but flexible** — collects the same data points conversationally, one question at a time
- **Contextual** — remembers previous answers within the session
- **Autonomous submission** — creates `Loan_Application__c` and child records directly via Apex
- **Guardrailed** — off-topic redirection, ambiguity handling, escalation to human
- **Real-time** — typing indicators, streaming responses

**Agent conversation flow:**
```
1. Session created (Contact ID passed)
2. Agent calls get_contact_info → greets user by name
3. Identity confirmation ("Can you confirm you are [Name]?")
4. Sequential data collection:
   a. Work situation (constrained options)
   b. Annual net income
   c. Property purchase price
   d. Loan amount
   e. Repayment duration in months
5. Summary & confirmation prompt
6. create_loan_application → record created
7. Success message with application reference
```

**Improvement over wizard:** Lower cognitive load, natural interaction, accessibility (voice-ready), personalised experience, and the ability to handle edge cases conversationally.

---

## 6. Summary: The Headless 360 Value Proposition

```
+------------------+      +-------------------+      +---------------------+
|  Paper Forms     | ---> |  Digital Wizard   | ---> | Conversational AI   |
|  (Days)          |      |  (Minutes)        |      | (Seconds)           |
|  Branch-bound    |      |  Mobile-first     |      | Any channel         |
|  Human-processed |      |  System-processed |      | Agent-processed     |
+------------------+      +-------------------+      +---------------------+
```

| Metric | Paper | Wizard | Agentforce Headless |
|--------|-------|--------|---------------------|
| Time to apply | 2-5 days | ~3 minutes | ~2 minutes |
| Channel | In-branch only | Mobile app | Any (mobile, web, voice, IoT) |
| Processing | Manual | Automated | Autonomous |
| Personalisation | None | Limited | Context-aware, identity-resolved |
| Error handling | Callback in days | Inline validation | Conversational correction |
| Escalation | Physical queue | N/A | Instant handoff to human |

### Key Takeaway

**Headless 360 is not just about removing the UI — it's about removing the ceiling.** By decoupling Agentforce from Salesforce surfaces, organisations can deliver autonomous, personalised, compliant AI experiences on any channel while Salesforce remains the trusted backbone for data, logic, and governance.

---

*Prepared for TDX Executive Stakeholder Review*
*Demo: FDE Bank — Lending & Mortgage Application*
*Platform: Salesforce Agentforce + Flutter Mobile*
*API Version: 66.0 | Agent API: v1*
