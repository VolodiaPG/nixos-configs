---
name: plain-user-text
description: Use whenever you write prose a human will read, in any project. This covers the final answer or any chat reply, README and other docs, code comments, docstrings, commit messages, PR descriptions, error and log messages, and release notes. Loads the simple-english skill so the text stays plain and unambiguous.
---

# Plain user-facing text

Before you write prose for a human reader, invoke the `simple-english:simple-english` skill (from the simple-english plugin) with the Skill tool. Follow it for the final text.

Scope: only text meant for a person. Never rewrite code, identifiers, commands, paths, or quoted errors.

Precedence: explicit user instructions about tone, language, or format win over this skill. A terse-mode setting (for example caveman) still sets the length of chat replies. `simple-english` then sets the wording of what is left.
