Agent Hints
===========

We are iteratively improving "docs/psa-spec.md". You can see what's changed since the laster iteration by usiing `git diff HEAD`.

Constraints
===========
  * Do not use individual names in the end product.
  * Do NOT use the name Humanitec.
  * Do NOT use the term re-org.
  * Do NOT use the term big-bang.
  * DO NOT read or modify any files unless explicitly asked to.

External Docs
=============

* read @docs/terms.md                - Dictionary of acronyms and definitions.
* read @docs/the-org.md              - Information about the org's structure and people.
* read @dcos/psa-gaps-gemini.md      - previous
* read @whitepaper-gemini.md         - Current version of the white paper.

Overview
========


The core idea of our orchestration solution is that we use a centralized Github repo to coordinate the offerings of all the platforms teams.  Each team would define it's offering in a Json document.  This document would both indicate what questions have to be answered by the customer to request it and how that request gets forwarded to the specific platform team offering it.  The orchestration solution provides a uniform interface to the developer portal to present the catalog of offerings to customers.  The same JSON document provides the necessary information for the orchestration software to dispatch the request to the correct platform team.



Actions
=======

  * Analyize all information currently in context.
  * Review all given constraints.
  * Suggest what you consider is the next most important iterative change to @docs/psa-spec.md
