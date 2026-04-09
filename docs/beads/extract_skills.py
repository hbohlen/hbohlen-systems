#!/usr/bin/env python3
"""
extract_skills.py - Extract skill sections from beads skill definitions markdown file.

This script reads the comprehensive skill definitions document and extracts each
individual skill into separate markdown files for use in agent skill directories.

Usage:
    python3 extract_skills.py [--input PATH] [--agents-dir PATH] [--hermes-dir PATH]

Default paths:
    Input: docs/beads/skill-definitions.md
    Agents output: .agents/skills/beads/
    Hermes output: .hermes/skills/beads/
"""

import argparse
import os
import re
import sys
from pathlib import Path

# Mapping of skill numbers to output filenames
SKILL_MAPPING = {
    1: "core.md",
    2: "dependencies.md",
    3: "sync.md",
    4: "workflows.md",
    5: "multi-agent.md",
    6: "config.md",
}


def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Extract skill sections from beads skill definitions"
    )
    parser.add_argument(
        "--input",
        default="docs/beads/skill-definitions.md",
        help="Path to skill definitions markdown file",
    )
    parser.add_argument(
        "--agents-dir",
        default=".agents/skills/beads/",
        help="Output directory for agents skill files",
    )
    parser.add_argument(
        "--hermes-dir",
        default=".hermes/skills/beads/",
        help="Output directory for hermes skill files",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be extracted without writing files",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Show detailed progress information",
    )
    return parser.parse_args()


def read_skill_definitions(input_path):
    """Read the skill definitions markdown file."""
    try:
        with open(input_path, "r", encoding="utf-8") as f:
            content = f.read()
        return content
    except FileNotFoundError:
        print(f"Error: Input file not found: {input_path}")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading file {input_path}: {e}")
        sys.exit(1)


def extract_skill_sections(content):
    """
    Extract individual skill sections from the markdown content.

    Skill sections start with "## Skill X: Title" and continue until the next
    "## Skill" or the end of the document.
    """
    # Pattern to match skill section headers
    skill_pattern = r"^## Skill (\d+): (.+?)$"

    lines = content.split("\n")
    sections = []
    current_section = None
    current_content = []
    in_skill = False

    for line in lines:
        # Check if this line starts a new skill section
        match = re.match(skill_pattern, line)
        if match:
            # If we were already in a skill, save it
            if in_skill and current_section is not None:
                sections.append(
                    {
                        "number": current_section["number"],
                        "title": current_section["title"],
                        "content": "\n".join(current_content).strip(),
                    }
                )

            # Start new skill section
            skill_num = int(match.group(1))
            skill_title = match.group(2).strip()
            current_section = {"number": skill_num, "title": skill_title}
            current_content = [line]  # Include the header line
            in_skill = True

        elif in_skill:
            # Check if we've reached the end of the skill section
            # Skill sections end with a horizontal rule (---) or next top-level header
            if (line.startswith("---") and len(line.strip()) >= 3) or (
                line.startswith("## ") and not line.startswith("## Skill")
            ):
                # End of current skill section
                if current_section is not None:
                    sections.append(
                        {
                            "number": current_section["number"],
                            "title": current_section["title"],
                            "content": "\n".join(current_content).strip(),
                        }
                    )
                in_skill = False
                current_section = None
                current_content = []
            else:
                # Continue accumulating content
                current_content.append(line)
        else:
            # Not in a skill section, skip
            continue

    # Don't forget the last skill section if we're still in one
    if in_skill and current_section is not None:
        sections.append(
            {
                "number": current_section["number"],
                "title": current_section["title"],
                "content": "\n".join(current_content).strip(),
            }
        )

    return sections


def format_skill_content(skill_data):
    """
    Format skill content for output.

    Converts the extracted skill section into a proper markdown document
    with appropriate headers and structure.
    """
    number = skill_data["number"]
    title = skill_data["title"]
    content = skill_data["content"]

    # Create a proper header (use # instead of ## for top-level in individual files)
    lines = content.split("\n")
    if lines and lines[0].startswith("## "):
        # Replace ## Skill X: Title with # Skill: Title
        lines[0] = f"# Skill: {title}"

    # Ensure the file ends with a newline
    formatted = "\n".join(lines)
    if not formatted.endswith("\n"):
        formatted += "\n"

    return formatted


def write_skill_file(
    content, output_path, skill_num, skill_title, dry_run=False, verbose=False
):
    """Write skill content to output file."""
    if dry_run:
        print(f"[DRY RUN] Would write skill {skill_num} to: {output_path}")
        return

    try:
        # Ensure directory exists
        os.makedirs(os.path.dirname(output_path), exist_ok=True)

        with open(output_path, "w", encoding="utf-8") as f:
            f.write(content)

        if verbose:
            print(f"✓ Wrote skill {skill_num}: {skill_title} to {output_path}")
    except Exception as e:
        print(f"Error writing to {output_path}: {e}")


def main():
    """Main extraction function."""
    args = parse_arguments()

    # Resolve paths relative to project root
    project_root = Path.cwd()
    input_path = project_root / args.input
    agents_dir = project_root / args.agents_dir
    hermes_dir = project_root / args.hermes_dir

    if args.verbose:
        print(f"Input file: {input_path}")
        print(f"Agents output: {agents_dir}")
        print(f"Hermes output: {hermes_dir}")

    # Read skill definitions
    content = read_skill_definitions(input_path)

    # Extract skill sections
    sections = extract_skill_sections(content)

    if args.verbose:
        print(f"Found {len(sections)} skill sections")

    # Process each skill section
    for skill_data in sections:
        skill_num = skill_data["number"]
        skill_title = skill_data["title"]

        # Get output filename from mapping
        if skill_num not in SKILL_MAPPING:
            print(f"Warning: No mapping for skill {skill_num}, skipping")
            continue

        filename = SKILL_MAPPING[skill_num]

        # Format content
        formatted_content = format_skill_content(skill_data)

        if args.verbose and not args.dry_run:
            print(f"Processing skill {skill_num}: {skill_title} -> {filename}")

        # Write to agents directory
        agents_path = agents_dir / filename
        write_skill_file(
            formatted_content,
            agents_path,
            skill_num,
            skill_title,
            args.dry_run,
            args.verbose,
        )

        # Write to hermes directory
        hermes_path = hermes_dir / filename
        write_skill_file(
            formatted_content,
            hermes_path,
            skill_num,
            skill_title,
            args.dry_run,
            args.verbose,
        )

    # Summary
    if not args.dry_run:
        print(f"\n✅ Successfully extracted {len(sections)} skills:")
        for skill_data in sections:
            skill_num = skill_data["number"]
            skill_title = skill_data["title"]
            filename = SKILL_MAPPING.get(skill_num, "unknown.md")
            print(f"  Skill {skill_num}: {skill_title} -> {filename}")
        print(f"\nFiles written to:")
        print(f"  {agents_dir}")
        print(f"  {hermes_dir}")
    else:
        print(f"\n[DRY RUN] Would extract {len(sections)} skills")


if __name__ == "__main__":
    main()
