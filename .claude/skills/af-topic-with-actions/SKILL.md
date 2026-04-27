---
name: af-topic-with-actions
description: "Create or modify an Agentforce topic with actions in a .agent file, generating the appropriate backing logic (Flow, Apex, or Prompt Template) and wiring it up. TRIGGER when: user asks to create a new topic and specifies one or more actions; user says they want to modify an existing topic by adding an action. DO NOT TRIGGER when: user only asks about existing topics with no action changes; general agent design questions; deployment, publishing, or testing tasks."
license: Apache-2.0
metadata:
  version: "0.1.0"
  last_updated: "2026-04-27"
---

# af-topic-with-actions Skill

## What This Skill Is For

This skill handles one focused task: adding a topic with actions to a `.agent` file, or adding an action to an existing topic, and ensuring the backing logic file (Flow XML, Apex class, or Prompt Template) exists and is wired correctly.

**⚠️ CRITICAL:** Agent Script is NOT AppleScript, JavaScript, Python, or any language you have been trained on. All syntax rules below are authoritative and must be followed exactly.

---

## Rules That Always Apply

1. **Always `--json`.** Include `--json` as the FIRST flag on EVERY `sf` CLI command.
2. **Verify target org.** Before any org interaction run `sf config get target-org --json`.
3. **Read before editing.** Always read the full `.agent` file before modifying it.
4. **Validate after every change.** Run `sf agent validate authoring-bundle --json --api-name <DeveloperName>` after every edit. Fix all errors before proceeding.
5. **One stub at a time.** When generating backing logic stubs, deploy each one individually and fix any deploy errors before generating the next.

---

## Task: Create a New Topic With Actions

### Required Steps

1. **Identify the target `.agent` file.**
   - Read `sfdx-project.json` to find the default package directory.
   - Find `.agent` files under `<package_dir>/main/default/aiAuthoringBundles/`.
   - If multiple bundles exist, ask the user which agent to modify.
   - Read the full `.agent` file before making any changes.

2. **Clarify the action backing type.**
   For each action the user wants to add, determine the backing type:
   - **Flow** — standard Salesforce data operations (CRUD, approvals, screen flows).
   - **Apex** — complex calculations, integrations, custom logic.
   - **Prompt Template** — AI-generated responses, generative text.

   If the user has not specified, ask. Default to **Flow** for simple data operations.

3. **Check whether the backing logic already exists.**
   - For `flow://` targets: `find force-app -name "*.flow-meta.xml" | grep -i <FlowName>`
   - For `apex://` targets: `find force-app -name "*.cls" | grep -i <ClassName>`
   - For `prompt://` targets: `find force-app -name "*.promptTemplate-meta.xml" | grep -i <TemplateName>`
   - Also check the org: `sf data query --json -q "SELECT DeveloperName FROM Flow WHERE DeveloperName = '<name>' LIMIT 1"` (for flows).

4. **Write the topic block in the `.agent` file.**

   Insert after the last existing `topic` block (never inside another block). Use 4-space indentation throughout. Follow this exact structure:

   ```agentscript
   topic <topic_name>:
       description: "<what this topic handles — used by LLM for routing>"

       reasoning:
           instructions: ->
               | <Instruction telling the LLM when and how to use the action.>
                 Always name the specific output fields the LLM must include in its response.
                 Include: "Do NOT call the action again — you have the result."
                 Include: "Do NOT use the show_command tool. Always compose your response as direct text."

           actions:
               <invocation_name>: @actions.<action_name>
                   description: "<when the LLM should call this>"
                   with <input_name> = ...
                   set @variables.<var> = @outputs.<output_name>
                   available when <gate_condition>

       actions:
           <action_name>:
               description: "<what the action does>"
               target: "<type>://<DeveloperName>"
               inputs:
                   <input_name>: <type>
                       description: "<description>"
                       is_required: True
               outputs:
                   <output_name>: <type>
                       description: "<description>"
   ```

   **Naming rules** (apply to topic names, action names, variable names):
   - Only letters, numbers, underscores. Start with a letter. No trailing underscore. No `__`.
   - `snake_case` strongly recommended.

   **Target format by type:**
   - Flow: `"flow://<FlowDeveloperName>"`
   - Apex: `"apex://<ClassName>"`
   - Prompt Template: `"generatePromptResponse://<TemplateDeveloperName>"`

   **Prompt Template I/O special rules:**
   - Input names must use `"Input:<fieldApiName>"` quoted prefix.
   - Output is always `promptResponse: string`.
   - Invocation uses quoted input name: `with "Input:<field>" = ...`

   **Action loop prevention (required):**
   - Always add `available when` gating on reasoning actions that could fire repeatedly.
   - Always include post-action instructions explicitly telling the LLM not to call the action again.
   - Name specific output fields in the instructions (never say "present the results").

5. **Register any new variables** needed by the topic's actions in the top-level `variables:` block.
   - Mutable variables MUST have a default value: `my_var: mutable string = ""`
   - Linked variables MUST have a `source:`, NO default value.
   - Boolean defaults are `True` / `False` (capitalized — NEVER `true`/`false`).
   - Do not add variables already declared.

6. **Validate compilation.**
   ```bash
   sf agent validate authoring-bundle --json --api-name <DeveloperName>
   ```
   If it fails, diagnose and fix before proceeding. Common errors:
   - Consecutive underscores `__` in names → rename.
   - Missing `outputs:` block on action with `inputs:` → add `outputs:` even if empty placeholders.
   - Lowercase boolean → capitalize.

7. **Generate backing logic if it does not exist.**

   **For `flow://` targets** — create a Flow XML stub at
   `force-app/main/default/flows/<FlowDeveloperName>.flow-meta.xml`:

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <Flow xmlns="http://soap.sforce.com/2006/04/metadata">
       <apiVersion>62.0</apiVersion>
       <description>Autolaunched flow backing the <action_name> agent action.</description>
       <label><Flow Label></label>
       <variables>
           <!-- One <variables> block per input -->
           <name><inputName></name>
           <dataType>String</dataType>
           <isCollection>false</isCollection>
           <isInput>true</isInput>
           <isOutput>false</isOutput>
       </variables>
       <!-- One <variables> block per output -->
       <variables>
           <name><outputName></name>
           <dataType>String</dataType>
           <isCollection>false</isCollection>
           <isInput>false</isInput>
           <isOutput>true</isOutput>
       </variables>
       <start>
           <locationX>50</locationX>
           <locationY>50</locationY>
       </start>
       <status>Active</status>
       <processType>AutoLaunchedFlow</processType>
   </Flow>
   ```

   **Element ordering in Flow XML is critical.** Always group elements of the same type together in this order:
   `apiVersion` → `description` → `label` → `variables` → `assignments` → `decisions` → `recordLookups` → `recordCreates` → `recordUpdates` → `start` → `status` → `processType`

   **For `apex://` targets** — create an Apex class stub at
   `force-app/main/default/classes/<ClassName>.cls` and `<ClassName>.cls-meta.xml`:

   ```apex
   public with sharing class <ClassName> {

       public class Request {
           @InvocableVariable(label='<Label>' description='<desc>' required=true)
           public <ApexType> <inputName>;
       }

       public class Response {
           @InvocableVariable(label='<Label>' description='<desc>')
           public <ApexType> <outputName>;
       }

       @InvocableMethod(label='<Label>' description='<desc>')
       public static List<Response> execute(List<Request> requests) {
           List<Response> results = new List<Response>();
           for (Request req : requests) {
               Response res = new Response();
               // TODO: implement logic
               // Return realistic-looking data — NOT 'TODO' strings.
               // Example: res.<outputName> = '<plausible value based on input>';
               results.add(res);
           }
           return results;
       }
   }
   ```

   Agent Script type → Apex type mapping:
   | Agent Script | Apex |
   |---|---|
   | `string` | `String` |
   | `number` | `Decimal` |
   | `boolean` | `Boolean` |
   | `date` | `Date` |
   | `id` | `Id` |
   | `object` | `SObject` |
   | `list[string]` | `List<String>` |

   **I/O name matching is case-sensitive.** The `@InvocableVariable` field names must exactly match the `inputs:` / `outputs:` names in the `.agent` file.

   **One `@InvocableMethod` per class.** If multiple actions are needed, create separate classes.

   Stub data quality: stubs MUST return realistic-looking data, not empty strings or `'TODO'`. Use input values and field names to derive plausible values.

   Also create the metadata file `<ClassName>.cls-meta.xml`:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
       <apiVersion>62.0</apiVersion>
       <status>Active</status>
   </ApexClass>
   ```

   **For `prompt://` / `generatePromptResponse://` targets** — create the prompt template metadata. Prompt Templates require setup in the org (Einstein generative features). Ask the user if they have an existing template or need one created, and follow the org's Einstein feature configuration.

8. **Deploy backing logic to the org.**
   ```bash
   # For a Flow:
   sf project deploy start --json --metadata Flow:<FlowDeveloperName>

   # For an Apex class:
   sf project deploy start --json --metadata ApexClass:<ClassName>
   ```
   Fix any deploy errors before deploying additional stubs.

9. **Grant Apex class access in the agent's permission set** *(Apex targets only — skip for Flow/Prompt Template).*

   For every Apex class created in this task:

   a. **Locate the permission set locally.**
      ```bash
      find force-app -name "*.permissionset-meta.xml"
      ```
      Look for a file whose base name matches the agent's developer name (common convention: `<AgentDeveloperName>.permissionset-meta.xml`).

   b. **If the permission set file is not found locally, retrieve it from the org.**
      First identify the correct permission set name:
      ```bash
      sf data query --json -q "SELECT Name, Label FROM PermissionSet WHERE Name LIKE '%<AgentDeveloperName>%' LIMIT 10"
      ```
      Then retrieve it:
      ```bash
      sf project retrieve start --json --metadata PermissionSet:<PSName>
      ```
      If no permission set exists for the agent, ask the user to confirm the correct permission set name before proceeding.

   c. **Add a `<classAccesses>` entry for the Apex class** inside the permission set XML. Insert it in alphabetical order among existing `<classAccesses>` blocks (or after the last one):
      ```xml
      <classAccesses>
          <apexClass>ClassName</apexClass>
          <enabled>true</enabled>
      </classAccesses>
      ```
      Do not add a duplicate entry if the class is already listed.

   d. **Deploy the updated permission set.**
      ```bash
      sf project deploy start --json --metadata PermissionSet:<PSName>
      ```

10. **Publish the agent bundle.**
    ```bash
    sf agent publish authoring-bundle --json --api-name <DeveloperName>
    ```

---

## Task: Add an Action to an Existing Topic

### Required Steps

1. **Read the `.agent` file** in full before editing.
2. **Locate the target topic block.** Identify the exact `topic <name>:` block to modify.
3. **Determine the backing type** for the new action (Flow / Apex / Prompt Template). See Step 2 above.
4. **Check whether the backing logic exists.** See Step 3 above.
5. **Add the action definition** to the topic's `actions:` block. If the topic has no `actions:` block yet, add one after the `reasoning:` block.

   ```agentscript
   actions:
       <action_name>:
           description: "<what the action does>"
           target: "<type>://<DeveloperName>"
           inputs:
               <input_name>: <type>
                   description: "<description>"
                   is_required: True
           outputs:
               <output_name>: <type>
                   description: "<description>"
   ```

6. **Add the invocation entry** in the topic's `reasoning.actions:` block. If the block doesn't exist, add it inside `reasoning:` after `instructions:`.

   ```agentscript
   reasoning:
       ...
       actions:
           <invocation_name>: @actions.<action_name>
               description: "<when the LLM should call this>"
               with <input_name> = ...
               set @variables.<var> = @outputs.<output_name>
               available when <gate_condition>
   ```

7. **Update reasoning instructions** to reference the new action. Name the specific output fields the LLM must use. Add explicit "do not call again" and "no show_command" instructions.
8. **Add any new variables** to the top-level `variables:` block (Step 5 above).
9. **Validate, generate backing logic if missing, deploy, grant Apex class access, and publish.** Follow Steps 6–10 from "Create a New Topic With Actions."

---

## Common Mistakes to Avoid

| Mistake | Correct Approach |
|---|---|
| `else if` or nested `if` in instructions | Use compound conditions (`and`/`or`) or sequential `if` blocks |
| `transition to` in `reasoning.actions` | Use `@utils.transition to @topic.<name>` |
| `@utils.transition to` in `before_reasoning`/`after_reasoning` | Use bare `transition to` |
| Lowercase `true`/`false` | Always `True` / `False` |
| Mutable variable without default | Add `= ""` / `= 0` / `= False` |
| Linked variable with default | Remove the default; add `source:` |
| Snake_case I/O names for Apex targets | Match exact `@InvocableVariable` field names (usually camelCase) |
| Action with `inputs:` but no `outputs:` | Always add `outputs:` block (even placeholder) |
| Generic "present the results" instructions | Name specific output fields; block `show_command` |
| Prompt Template with bare input names | Use `"Input:<fieldApiName>"` quoted prefix |
| Consecutive underscores `__` in names | Rename — not allowed in any identifier |
