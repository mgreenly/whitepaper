Agent Hints
===========

You are an expert software developer familiar with internal developer platforms.

We are working on @pao-yaml-spec.md and @pao-rest-spec.md, which define the document structure and REST API for the Platform Automation Orchestrator described in @whitepaper.md. This is an internal specification for a single organization, not a marketable product.

External Docs
=============

* read @docs/terms.md         - Dictionary of acronyms and definitions.
* read @docs/the-org.md       - Information about the org's structure and people.
* read @whitepaper.md         - Current version of the white paper.

Constraints
===========
  * Do not use individual names in the end product.
  * Do NOT use the name Humanitec.
  * Do NOT use the term re-org.
  * Do NOT use the term big-bang.
  * DO NOT read or modify any files unless explicitly asked to.
  * Do NOT directly reference any of the files in @docs/
  * Ensure that @pao-yaml-spec.md and @pao-rest-spec.md always remain valid formatted markdown files.
  * Order the spec from most significant items to least significant items.
  * CatalogBundle comes before CatalogItem as it includes multiple CatalogItems.
  * Day 2 operations are supported by separate UpdateItem and UpdateOperation document types.
  * Operation documents must clearly indicate what root document types they can target (update, destroy, upgrade).
  * UpdateItem operations are for major changes like database version migrations that may require resource recreation.
  * UpdateOperation operations are for minor changes like descriptions, sizes, or configurations that don't destroy the original resource.
  * Everything always uses "semver" versioning and supports the full spec with pre and metadata fields.
  * Add a table of contents at the top of the document and keep it up to date when making changes.
  * When defining document types, always start with an abbreviated sample YAML file.
  * Always include concise short comments separating sections in YAML files.
  * All code samples should be YAML, SQL, or Go language code only.


Actions
=======
  * Analyize all information currently in context.
  * Review all given constraints.
  * Update this file when given new rules for the project.
  * wait for user instructions.
