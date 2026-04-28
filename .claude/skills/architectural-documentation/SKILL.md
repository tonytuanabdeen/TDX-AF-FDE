---
name: architectural-documentation
description: >
  Provides comprehensive architectural documentation for software systems, ensuring clarity, maintainability, and alignment with organizational standards and best practices.
---

# Skill: Salesforce Schema → Entity Relationship Diagram Generator

## Purpose
Generate a comprehensive **Salesforce Entity Relationship Diagram (ERD)** by analyzing the Salesforce schema including:

- Standard Objects
- Custom Objects
- Fields
- Lookup Relationships
- Master-Detail Relationships
- Junction Objects

The skill must also produce:

1. **Entity Relationship Diagram (ERD)**
2. **Object descriptions**
3. **Field descriptions**
4. **Relationship descriptions**
5. **Documentation in Markdown**

The model must assume **Person Accounts are enabled** and must treat them as the representation of **individual customers**, rather than separate Account + Contact entities. Therefore, do not draw Account and Contact as separate entities for individuals; instead, represent them as a single entity (Person Account) with the appropriate fields.

The Generated HTML documentation must follow default claude code theme and color styles for readability and consistency. The ERD should be clear, well-labeled, and visually organized to effectively communicate the structure of the Salesforce schema.

---

# Core Principles

## 1. Salesforce Schema Understanding

When analyzing schema metadata, inspect:

- Object metadata
- Field metadata
- Relationship metadata
- Standard vs Custom objects
- Junction objects
- External Id fields
- Lookup vs Master-detail

Supported relationship types:

| Type | Description |
|-----|-------------|
| Lookup | Loose relationship between objects |
| Master-Detail | Strong relationship with cascading ownership |
| Junction Object | Many-to-many relationship implemented with two master-detail relationships |

---

# Person Account Modeling

Person Accounts represent **individual customers**.

### Modeling Rules

- `Account` with `IsPersonAccount = true` represents individuals
- Do NOT model `Contact` separately for individuals
- Contacts should only appear for **business relationships**

ERD representation: