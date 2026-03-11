## ADDED Requirements

### Requirement: Skill is registered with pi
The workflow-orchestrator skill SHALL be registered in pi's skill system.

#### Scenario: List skills
- **WHEN** user lists available skills
- **THEN** workflow-orchestrator appears in the list

### Requirement: Skill has SKILL.md
The skill SHALL have proper documentation in SKILL.md format.

#### Scenario: View skill help
- **WHEN** user invokes skill help
- **THEN** SKILL.md content is displayed

### Requirement: Skill can be invoked
The skill SHALL be invokable via pi's skill invocation mechanism.

#### Scenario: Invoke skill
- **WHEN** user invokes workflow-orchestrator
- **THEN** skill logic executes
