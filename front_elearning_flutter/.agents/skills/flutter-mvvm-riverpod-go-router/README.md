# Flutter MVVM Agent Skill

A structured skill package for this repository.

## Structure

- skill.md - Skill metadata and quick reference
- instruction.md - Agent execution instructions for this project
- metadata.json - Package metadata
- rules/ - Individual architecture and coding rules
  - _sections.md - Section definitions and ordering
  - _template.md - Template for new rules

## Rule Naming

Use `area-description.md` format:

- architecture-...
- data-...
- state-...
- navigation-...
- ui-...
- reliability-...

## Add A New Rule

1. Copy rules/_template.md
2. Rename with correct prefix and concise description
3. Add frontmatter fields
4. Include incorrect and correct examples
5. Add repository-specific notes
