# Platform Automation Orchestrator Catalog Quiz

## Instructions
This quiz covers high-level concepts from the Platform Automation Orchestrator catalog system. Focus on understanding the core purposes and patterns rather than specific syntax details.

**10 Questions - 4 Multiple Choice Options Each**

---

## Question 1
What is the primary purpose of the Platform Automation Orchestrator catalog repository?

- A) To store source code for platform applications
- B) To define platform service offerings through schema-driven YAML documents that enable automated self-service provisioning
- C) To manage user authentication and permissions
- D) To monitor platform performance metrics

---

## Question 2
What are the two main document types in the catalog system, and what is the key difference between them?

- A) ServiceItem and ServiceGroup - one handles databases, the other handles compute
- B) PlatformItem and PlatformBundle - one is for internal use, the other for external
- C) CatalogItem and CatalogBundle - one defines individual services, the other defines composite services with multiple components
- D) ManualItem and AutomaticItem - one requires human intervention, the other is fully automated

---

## Question 3
The catalog system implements a "Progressive Enhancement" pattern. What does this mean?

- A) Services automatically become faster over time through machine learning optimization
- B) Platform teams can start with manual JIRA-based fulfillment and evolve toward full automation at their own pace
- C) The user interface progressively loads more features as users become more experienced
- D) Services are gradually migrated from on-premises to cloud infrastructure

---

## Question 4
The variable system uses four namespaces for template processing. Which namespace contains user input from request forms?

- A) `.system.*` - contains platform context and environment information
- B) `.metadata.*` - contains static catalog item metadata
- C) `.output.*` - contains computed values from previous actions
- D) `.current.*` - contains user form input values

---

## Question 5
What is the fundamental organizational principle that governs how platform teams interact with the catalog system?

- A) All teams must use the same technology stack and follow identical processes
- B) Platform teams own their catalog categories and maintain full control over their service definitions
- C) A central platform team owns all catalog items and makes changes on behalf of other teams
- D) Teams rotate ownership of catalog items quarterly to ensure knowledge sharing

---

## Question 6
According to the Reference Architecture, in which plane does the Platform Automation Orchestrator reside?

- A) Developer Control Plane
- B) Integration and Delivery Plane
- C) Security and Compliance Plane
- D) Resource Plane

---

## Question 7
What is the expected timeline improvement that PAO aims to achieve for resource provisioning?

- A) From hours to minutes
- B) From days to hours
- C) From weeks to hours (Phase 1), then hours to minutes (later phases)
- D) From months to weeks

---

## Question 8
How does the catalog system handle bundle component processing?

- A) All components are processed in parallel for maximum speed
- B) Components are processed randomly to distribute load
- C) Components are processed sequentially with dependency ordering
- D) Components are processed based on alphabetical order

---

## Question 9
What validation mechanisms ensure catalog quality and consistency?

- A) Only manual code reviews by senior architects
- B) Automated unit tests that run locally on developer machines
- C) JSON Schema compliance, naming conventions, variable syntax validation, and cross-reference validation
- D) Static analysis tools that check for security vulnerabilities

---

## Question 10
What action types are supported for fulfilling catalog item requests?

- A) Only JIRA tickets for all requests
- B) Only automated REST API calls
- C) JIRA tickets (manual) and REST API calls, Git commits, GitHub workflows (automatic)
- D) Email notifications and Slack messages