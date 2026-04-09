---
name: working-with-adhd-dendritic
description: "How to work effectively with a user who has ADHD/OCD and prefers dendritic, organic growth architecture."
---

# Working with ADHD and Dendritic Patterns

How to work effectively with a user who has ADHD/OCD and prefers dendritic, organic growth architecture.

## Triggers

Use this skill when:
- User shows signs of decision paralysis or perfectionism
- Planning scope is getting too large
- User mentions feeling overwhelmed or stuck
- Working on Nix/dendritic architecture
- User wants to "start small" or experiment

## Core Principles

### 1. Break the Paralysis Loop
- Offer ONE concrete next step, not a menu of options
- Validate scope explicitly: "This is just X, not Y or Z"
- Use approval gates: present, confirm, then proceed
- Celebrate small completions to build momentum

### 2. Keep Scope Minimal
- One branch at a time
- One question at a time
- One decision at a time
- If something feels big, make it smaller

### 3. Use the Dendritic Mindset
- Each piece is self-contained
- Growth is organic — new branches when needed
- Deletion is fine — branches don't affect the trunk
- No upfront commitment to the whole tree

### 4. Reduce Cognitive Load
- Show, don't just tell (use browser companion for visuals when helpful)
- Be explicit about what is IN and OUT of scope
- Use abbreviations over aliases (user prefers seeing full commands)
- Prefer defaults; make choices for user when appropriate

## ADHD-Friendly Tooling Preferences

User values tools that reduce decision fatigue:
- **Starship prompt**: Shows only what matters (git branch, dirty state)
- **Zoxide (z)**: Fuzzy directory jumping, no path memorization
- **Fish abbreviations**: Expand on space, see full command
- **Direnv**: Auto-activate environments, remove "did I remember?" friction
- **Nix**: Reproducibility removes "why is this broken now?" anxiety

## Warning Signs to Watch For

- User asking "what about X?" repeatedly (scope creep anxiety)
- Long pauses or "I don't know" responses (paralysis)
- Rewriting the same thing multiple times (perfectionism loop)
- Wanting to plan everything before starting (big design up front)

## Recovery Moves

If user seems stuck:
1. Acknowledge: "This feels like it's getting big"
2. Reframe: "What's the smallest thing that would give you value?"
3. Offer concrete default: "How about we just do X and stop there?"
4. Explicit approval: "Does that feel small enough to start?"

## Project Context

- **hbohlen-systems**: Nix-based personal infrastructure
- **Pattern**: Dendritic cells with flake-parts
- **First branch**: devShell with fish, starship, zoxide, pi
- **Future branches**: home-manager, pi-custom, hermes-skills, system-config

## Questions to Ask

When scoping work:
- "What should the first branch be?"
- "What's the smallest version of this that would work?"
- "What can we leave out and add later?"
- "Does this feel small enough to finish in one sitting?"

When user seems uncertain:
- "What feels uncertain here?"
- "What's the worst case if we try this?"
- "What would make this feel safe to start?"
