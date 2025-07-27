Agent Hints
===========

We are iteratively improving "./whitepaper.md". You can see what's changed since the last iteration using `git diff HEAD`.

Introduction
============

The authors of this document are Hannah Stone and Michael Greenly.

Our goal is to create business whitepaper outlining our desired approach to building an internal developer platform.

External Docs
=============

* read @docs/terms.md                - Dictionary of acronyms and definitions.
* read @docs/the-org.md              - Information about the org's structure and people.
* read @docs/proposed-solution.md    - Overview of the proposed PSA solution.
* read @docs/word-whitepaper.md      - The first whitepaper draft.
* read @docs/miro-whitepaper.md      - The second whitepaper draft.

History
=======

The orgs currently has no real unified developer portal experience. Instead if facilities this work through JIRA where teams are required to submit many tickets to the many different platform teams; compute, storage, messaging, networking, etc... to create a new app.  This often takes 3-7 weeks to provision an application.

The org has made multiple attempts in recent years to modernize its offering through large re-org big bang style initiatives that have failed. There are some Sr. Directors that have began to believe buying a solution from an external vendor is the correct path.  Hannah and I think that this is a failure path for a number of reasons, including;
  * The orgs current structure does not lend it's self to a modern IDP structure.  The components of the IDP would live under the pervue of at least 7 Sr. Directors all reporting to the same Sr. Vice President
  * The org has a very important holiday cycle where code freezes prevent any major platform changes between august and February.  This makes any kind of big-bing change super difficult.  All existing resources need to remain focused on keeping the existing platform running in that freeze period so they tend to resist changes to support any new effort meant to replace them, intentionally or not.


Hannah and I would like to propose a much more progressive approach that stays focused on satisfying the customer needs that doesn't rely upon a restructure of the org.  Keeping that customers for us are internal developer teams.

The core idea of our orchestration solution is that we use a centralized Github repo to coordinate the offerings of all the platforms teams.  Each team would define it's offering in a Json document.  This document would both indicate what questions have to be answered by the customer to request it and how that request gets forwarded to the specific platform team offering it.  The orchestration solution provides a uniform interface to the developer portal to present the catalog of offerings to customers.  The same JSON document provides the necessary information for the orchestration software to dispatch the request to the correct platform team.

Constraints
===========
  * Do not use individual names in the end product.
  * You can use Michael Greenly and Hannah Stone for attribution.
  * Do NOT use the name Humanitec.
  * Do NOT use the term re-org.
  * Do NOT use the term big-bang.
  * DO focus on the context that's changed since the last iteration.
  * DO include citations to the sources of data.

Actions
=======
  * increment the numeric value in the ./COUNT file by +1
  * read the current version of ./whitepaper.md and ./hints.md
  * Analyze all the provided context and synthesize it into a a new professionally structure whitepaper.
  * write that paper to ./whitepaper.md
  * proceed to the end of the task without asking for permission to read, write or delete files in the project directory. 

