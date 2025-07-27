The Org
=======

We work for a major U.S. big box, home appliance, and electronics focused retailer which we'll refer to as "The Org" in these documents.

People and Org Structure
========================

Mike Greenly, Sr. Engineering Manager, of the "Pipelines & Orchestration" team, reports to Stephanie Culver.  This team provides the tooling to "developer teams" so that they can provision and deploy software.  It's a thin veneer on top of the capabilities fprovided by the 'platform teams'

Hannah Stone, Sr. Product Manager, of the "Pipelines & Orchestration" team, reports to Tina Hubbard.

Stephanie Culver, Engineering Director, of the Orchestration and Accounts team, reports to Gerry Blanck.

Gerry Blanck, Engineering Sr. Director, for Infrastructure and Data Platforms, reports to Adam Sand.

Tina Hubbard, Product Manager Director, for Infrastucture and Data Platforms, reports to Adam Sand.

Adam Sand, Sr. Vice President, for Digital, Analytics and Technology, reports to Neil Sample.

Neil Sample, the Chief Technology Officer.

Michelle Porkrzywinski, Engineering Sr., Director, of Developer & Tooling Experience, reports to Tanmay Sinha.

Tanmay Sinha, Vice President of Technology Modernization and Engineering Practices, reports to Adam Sand.

Jason Hill, Egineering Director, for Infrastucture Platforms,  reports to Gerry Blanck.

Ivan Kronkvist, Associate Associate Director, for Compute Team, reports to Jason Hill.

Narsiah Dhoda, Sr. Engineering Manager, for the Foundations Team, reports to Jason Hill.

Jim Musil, Engineering Manager, for Data Platforms, reports to Gerry Blanck

Joushua Smith, Engineering Sr. Manager, Data Store Platform, reports to Jim Musil

nil Atri, Engineering Sr. Manager,Data Transport Platform, reports to Jim Musil

Pete Krueger, engineering Director, for Observability, reports to Tanmay Sinha

Arturo E., Associate Director of the Networking teaam, reports to Mike Wang

Mike Wang, Tech Fellow, Reports to Adam Sand.

Greg Handrick, Egineering Direcotr, Identity Managment, reports to Mike Wang

Erik Carlson, Principal Architect, reports to TJ Duluka

TJ Duluka, Distinguised Architect, reports to Mike Wang


Platform Teams
==============

When we refer to Platform Teams we are always refering to these teams:

  Ivan's Compute Team
  Dhoda's Foundations Team
  Anils's Data Transport Team
  Smiths's Data Store Team
  Noah's Account Team

We sometimes refer to those teams as the "Core Platform Teams".

Sometimes when talking about "Platform Teams" we mean to include the following teams as well:

  Kruger's Obersvability Team
  Handrick's Identity Mangaement Team

Team Details
============
  The Compute Team - responsible for EC2, OpenShift, EKS, Lambda, ASGs, ELBs, ALBs
  The Foundations Team - responsible for VPCs, IAM, security groups, parameter store and secrets manager, etc...
  Data Transport Team - Responsible for Kafka, IBM MQ, Rabbit MQ, etc...
  Data Store Team - Responsible for MySQL, Aurora Postgres, MemoryDB, ValKey, Redis, etc...
  Accounts Team - Responsible for vending new accounts
  Obersvability Team - Responsbile for logging, alerting, grafana, etc.. 
  Identity Mangaement Team, responsible for user identity managment and cyberark

The "Orchestration & Pipelines" Team
===================================
  * The Orchestration & Piplines portal is known as "Stratus".
  * Stratus provides the portal through which new applications are provisioned and existing applications are deployed.
  * Stratus also provides a network proxy that allows "developer customers" to access their deployed apps from the corp network.
  * Container applications are provisioned through Stratus by "Developer Customers" directly.
  * Virtual Machine applications are provisioned through Jira tickets that are resolved by Compute Team members who use the Stratus portal to execute the work.

