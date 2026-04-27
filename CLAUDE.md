# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Salesforce DX project for building an Agentforce-enabled banking application. Uses API version 66.0 with no namespace. The single package directory is `banking-app/` (standard SFDX source format).

## Commands

```bash
# Lint LWC and Aura JavaScript
npm run lint

# Run LWC Jest tests
npm test                      # all tests
npm run test:unit:watch       # watch mode
npm run test:unit:debug       # debug mode (Node inspector)
npm run test:unit:coverage    # with coverage report

# Run a single LWC test file
npx sfdx-lwc-jest -- --testPathPattern='componentName'

# Format code (Apex, XML, LWC HTML, JS, JSON, CSS, YAML)
npm run prettier
npm run prettier:verify       # check only, no writes

# Deploy metadata to default org
sf project deploy start -d banking-app

# Retrieve metadata from default org
sf project retrieve start -d banking-app

# Create scratch org from config
sf org create scratch -f config/project-scratch-def.json -a <alias>

# Run Apex tests in the org
sf apex run test --code-coverage --result-format human

# Run a single Apex test class
sf apex run test -n MyTestClassName --result-format human

# Execute anonymous Apex
sf apex run -f scripts/apex/hello.apex
```

## Architecture

- **`banking-app/`** — All Salesforce source metadata (SFDX source format: `main/default/classes/`, `main/default/lwc/`, etc.). Create this directory when adding the first metadata component.
- **`skills/`** — Claude Code skill definitions. `banking-industry-loan-process/SKILL.md` defines the end-to-end loan origination process (intake, credit evaluation, underwriting, disbursement) with compliance guardrails.
- **`config/project-scratch-def.json`** — Scratch org shape: Developer Edition, Lightning Experience enabled.
- **`scripts/`** — Developer utility scripts (anonymous Apex in `apex/`, SOQL in `soql/`).
- **`.sfdx/mcp-tools/`** — 74 MCP tools for Salesforce CLI operations (query, deploy, retrieve, run Apex/Agent tests, assign permission sets, etc.). Tool definitions live in `.sfdx/mcp-tools/tools/`.

## Pre-commit Hooks

Husky runs `lint-staged` on commit which:
1. Formats staged files with Prettier (includes Apex via `prettier-plugin-apex`)
2. Lints Aura/LWC JavaScript with ESLint
3. Runs related LWC Jest tests with `--bail --findRelatedTests --passWithNoTests`

## Key Config Details

- **`.forceignore`** — Excludes `__tests__/`, `jsconfig.json`, `.eslintrc.json`, and `package.xml` from source tracking. LWC test files are never deployed.
- **Prettier** — Uses `prettier-plugin-apex` for `.cls`/`.trigger` files and `@prettier/plugin-xml` for XML. LWC HTML uses the `lwc` parser. Trailing commas disabled.
- **ESLint** — Flat config (`eslint.config.js`). Aura uses `@salesforce/eslint-plugin-aura` (recommended + locker). LWC uses `@salesforce/eslint-config-lwc/recommended`. The `@lwc/lwc/no-unexpected-wire-adapter-usages` rule is disabled in test files.
