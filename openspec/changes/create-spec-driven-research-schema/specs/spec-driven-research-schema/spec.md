## ADDED Requirements

### Requirement: Schema defines artifact pipeline
The spec-driven-research schema SHALL define an artifact pipeline with the following artifacts in order: exploration, proposal, spec-validation, research, specs, design, tasks.

#### Scenario: Create new change with schema
- **WHEN** `openspec new change "my-change" --schema spec-driven-research` is run
- **THEN** a new change is created with all 7 artifact types defined

### Requirement: Artifacts have correct dependencies
Each artifact in the schema SHALL declare its dependencies correctly.

#### Scenario: Exploration has no dependencies
- **WHEN** the schema is loaded
- **THEN** exploration artifact has empty `requires` array

#### Scenario: Research requires proposal and spec-validation
- **WHEN** the schema is loaded
- **THEN** research artifact requires both proposal and spec-validation

### Requirement: Apply requires tasks
The schema SHALL mark tasks as required for apply readiness.

#### Scenario: Check apply readiness
- **WHEN** `openspec status` is run
- **THEN** `applyRequires` includes "tasks" artifact

### Requirement: Schema is valid YAML
The schema configuration SHALL be valid YAML that passes schema validation.

#### Scenario: Validate schema
- **WHEN** schema YAML is parsed
- **THEN** no parse errors occur
