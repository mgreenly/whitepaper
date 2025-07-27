Introduction
============

I am Mike a sr. engineering manager, my partner is Hannah a sr. product manager.  We work for a major U.S. big box, home appliance, and electronics focused retailer which I'll refer to as the "org" from here out.  Our team, "Pipelines & Orchestration", is responsible for building the orchestration layer of an Internal Developer Platform (IDP).

Our goal here is to create business whitepaper to sell our desired approach to this task.

First we'll provide a bunch of relevant information, then provide specific instructions for generating documents.

The Org and the People
======================

The relevant organization structure and leaders
  * Mike, Sr. Engineering Manager for the "Pipelines & Orchestration" team, reports to Stephanie.
  * Hannah, Sr. Product Manager, for the "Pipelines & Orchestration" team, reports to Tina.
  * Stephanie, Engineering Director, reports to Gerry.
  * Gerry, Sr. Engineering Director, reports to Adam.
  * Tina, Sr. Product Directory, reports to Adam.
  * Adam, Sr. Vice President, reports to Neil.
  * Neil, the Chief Technology Officer.
  * Michelle, Director, reports to Tanmay.
  * Tanmay, Sr. Director, reports to Adam.
  * Jason, Director, reports to Gerry.
  * Ivan, Associate Director, reports to Jason.
  * Dhoda, Sr. Engineering Manager, reports to Jason.
  * Anil, Engineering Manager, reprots to Gerry
  * JJJJ, Engineering Manager, reports to Gerry
  * Pete, engineering Manasger of Observability, reports to ????
  * Aurtiro, Associate Director of the Networking teaam, reports to ???
  * Hendricks, Sr. Director of ???, reports to ??? 



The orgs currently has no real IDP.  Instead if facilities this work through JIRA where teams are required to submit many tickets to the many different platform teams; compute, storage, messaging, networking, etc... to create a new app.  This often takes 3-7 weeks to provision an application.

The org has made multiple attempts in recent years to modernize its offering through large re-org big bang style initiatives that have failed. There are some Sr. Directors that have began to believe buying a solution from an external vendor is the correct path.  Hannah and I think that this is a failure path for a number of reasons, including;
  * The orgs current structure does not lend it's self to a modern IDP structure.  The components of the IDP would live under the pervue of at least 7 Sr. Directors all reporting to the same Sr. Vice President
  * The org has a very important holiday cycle where code freezes prevent any major paltform changes between august and february.  This makes any kind of big-bing change super difficult.  All existing resources need to remain focused on keeping the existing platform running in that freeze period so they tend to resist changes to support any new effort meant to replace them, intentionally or not.


Hannah and I would like to propose a much more progressive approach that stays focused on satisfying the customer needs that doesn't rely opn a restrucutre of the org.  Keeping that customers for us are internal developer teams.

The core idea of our orchestration solution is that we use a centrailized github repo to coordinate the offerings of all the platforms teams.  Each team would define it's offering in a JSON document.  This document would both indicate what questions have to be answered by the customer to request it and how that request gets forwarded to the spcific platform team offering it.  The orchestration solution provides a uniform interface to the developer portal to present the catalog of offerings to customers.  The same JSON document provides the necessary information for the orchestration software to dispatch the request to the correct platform team.


The ./docs folder containers two eary draft documents.  Read these.
  * read ./docs/word-whitepaper.md - this document came first and is older
  * read ./docs/miro-whitepaper.md - this document cam later and is a bit more refined.

In the draft documents there is a comparison carefully engineer the customer experience but don't do that at all for our engineers.  This is a power point.  It needs to be used with impactful timing in the final document.


Actions
=======
  * delete ./whitepaper.md and ./hinst.md
  * Synthesize all of the information above to generate profesionally structured business whitepaper in the file ./whitepaper.md.
  * Provide suggestions about what missing information would provide necessary context to improve the document in ./hints.md

Constraints
===========
  * Never use the names of individuals except Hannah and I for attribution.
  * Never use the name Humanitec.
  * Never use the term re-org.
  * Never use the term big-bang.
