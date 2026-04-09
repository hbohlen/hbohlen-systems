## ADDED Requirements

### Requirement: Skill authoring template
A template file SHALL exist at `.agents/templates/SKILL-template.md` that provides a scaffold for creating new skills. The template SHALL include the canonical frontmatter schema with placeholder values and recommended sections for skill content.

#### Scenario: Creating a new skill from template
- **WHEN** a developer copies `.agents/templates/SKILL-template.md` to a new skill directory
- **THEN** the template SHALL contain placeholder frontmatter with all required and optional fields documented
- **AND** the template SHALL include section headings for `Overview`, `When to Use`, `Steps` or `Pattern`, `Examples`, and `Guardrails`

### Requirement: Migration map inventory
An inventory file SHALL exist at `.agents/inventories/migration-map.md` that documents the source and destination of every skill migrated during this change. For each skill, it SHALL record the original location, canonical location, adapter location(s), and disposition (promoted, merged, or left in backup).

#### Scenario: Auditing migration completeness
- **WHEN** a developer needs to verify all skills have been accounted for
- **THEN** the migration map SHALL list every skill from `.opencode/skills/`, `.pi/skills/`, and `backups/hermes-personalization/skills/`
- **AND** each entry SHALL have a clear destination or archival decision recorded