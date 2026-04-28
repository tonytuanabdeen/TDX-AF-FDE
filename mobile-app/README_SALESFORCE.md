# Salesforce Integration Setup

This guide explains how to connect the FDE Bank app to a Salesforce org. The app uses the **OAuth 2.0 Client Credentials flow** for both the REST API (Contact data) and the Agentforce Agent API (mortgage chat).

---

## Prerequisites

- Agentforce must be enabled in your org with at least one activated agent.
- The agent type cannot be "Agentforce (Default)".
- A dedicated API-only user account (System Administrator or a profile with at least **API Only** access).

---

## 1. Create the External Client App

The app requires an **External Client App** (not the legacy Connected App) to access the Agentforce Agent API.

1. In Setup, search for **External Client Apps** and open **External Client Apps Manager**.
2. Click **New External Client App**.
3. Fill in **App Name** (e.g. `FDE Bank Mobile`) and **Contact Email**.
4. Under **OAuth Settings**, enable OAuth and configure the following:

### OAuth Scopes (required)

| Scope label | API name |
|-------------|----------|
| Manage user data via APIs | `api` |
| Perform requests at any time | `refresh_token, offline_access` |
| Access chatbot services | `chatbot_api` |
| Access the Salesforce API Platform | `sfap_api` |

### OAuth Options

| Setting | Value |
|---------|-------|
| Enable Client Credentials Flow | **On** |
| JWT-based access tokens for named users | **On** |
| Require secret for Web Server Flow | **Off** |
| Require secret for Refresh Token Flow | **Off** |
| Require PKCE extension | **Off** |

5. Save the app.

### Configure the Policy tab

1. Open the app, go to the **Policy** tab, and click **Edit**.
2. Under **Client Credentials Flow**, set **Run As (Username)** to the API-only user created in the prerequisites.
3. Save.

### Copy credentials

1. Open the app, go to the **Settings** tab.
2. Expand **OAuth Settings** and click **Consumer Key and Secret**.
3. Copy both values — you will need them in the next step.

> **My Domain URL**: Use the value from **Setup → My Domain** (format: `yourorg.my.salesforce.com`). Do **not** use the `lightning.force.com` URL shown in the browser.

---

## 2. Find the Agent ID

1. Open the agent in **Agent Builder**.
2. The Agent ID is the 18-character Salesforce ID in the URL, or visible in the agent's detail page.
3. It follows the format `0XxoB000000xxxxx`.

---

## 3. Configure `salesforce_config.dart`

Edit `lib/core/services/salesforce/salesforce_config.dart`:

```dart
abstract class SalesforceConfig {
  static const String instanceUrl = 'https://yourorg.my.salesforce.com';
  static const String apiVersion  = 'v65.0';

  // OAuth 2.0 Client Credentials (from External Client App)
  static const String clientId     = 'YOUR_CONSUMER_KEY';
  static const String clientSecret = 'YOUR_CONSUMER_SECRET';

  // Agentforce
  static const String agentId         = 'YOUR_AGENT_ID';
  static const String agentApiBaseUrl = 'https://api.salesforce.com/einstein/ai-agent/v1';
}
```

> For sandbox/test orgs, use `https://test.api.salesforce.com/einstein/ai-agent/v1` as the `agentApiBaseUrl`.

---

## 4. (Recommended) Use a `.env` file instead of hardcoding credentials

`flutter_dotenv` is already in `pubspec.yaml`. To avoid committing secrets:

1. Create `app/.env`:
   ```
   SF_INSTANCE_URL=https://yourorg.my.salesforce.com
   SF_CLIENT_ID=YOUR_CONSUMER_KEY
   SF_CLIENT_SECRET=YOUR_CONSUMER_SECRET
   SF_AGENT_ID=YOUR_AGENT_ID
   ```
2. In `pubspec.yaml`, uncomment:
   ```yaml
   flutter:
     assets:
       - .env
   ```
3. In `main.dart`, load it before `runApp`:
   ```dart
   await dotenv.load(fileName: '.env');
   ```
4. Update `SalesforceConfig` to read from `dotenv.env`:
   ```dart
   static String get instanceUrl  => dotenv.env['SF_INSTANCE_URL']  ?? '';
   static String get clientId     => dotenv.env['SF_CLIENT_ID']     ?? '';
   static String get clientSecret => dotenv.env['SF_CLIENT_SECRET'] ?? '';
   static String get agentId      => dotenv.env['SF_AGENT_ID']      ?? '';
   ```
5. Add `.env` to `.gitignore` — **never commit credentials**.

---

## 5. Contact ID

The app reads the Salesforce Contact ID from `SharedPreferences` (key: `AppConstants.sfContactIdKey`). Set it once after login or pre-seed it for development. The Profile screen handles these states:

| State | Shown when |
|-------|-----------|
| Loading spinner | `contactProvider` is fetching |
| Error + Retry | Network or Salesforce error |
| No-contact view | Contact ID is null/empty in prefs |
| Contact card | Data loaded successfully |

---

## 6. Custom Fields

The `ContactModel` maps standard fields (`FirstName`, `LastName`, `Email`, `Phone`) plus the custom `Current_Balance__c` field. If that field doesn't exist in your org, the balance row will simply not appear.

The `Loan_Application__c` object and its fields must be deployed to the org before the mortgage chat feature can create loan applications. Deploy the SFDC metadata from the `sfdc/` directory:

```bash
cd sfdc
sf project deploy start
```
