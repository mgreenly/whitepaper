# Platform Automation Orchestrator Catalog Quiz - Answer Key

---

## Answer 1: B
**Correct Answer:** To define platform service offerings through schema-driven YAML documents that enable automated self-service provisioning

**Explanation:** The catalog repository serves as the central convergence point where platform teams define their service offerings in structured YAML documents. These documents enable developers to request resources through a self-service model, transforming the traditional multi-week manual provisioning process into an automated system.

---

## Answer 2: C
**Correct Answer:** CatalogItem and CatalogBundle - one defines individual services, the other defines composite services with multiple components

**Explanation:** CatalogItem represents individual platform services (like a database or compute instance), while CatalogBundle represents composite services that combine multiple CatalogItems with defined dependencies and sequential processing. Bundles enable complex multi-component provisioning scenarios.

---

## Answer 3: B
**Correct Answer:** Platform teams can start with manual JIRA-based fulfillment and evolve toward full automation at their own pace

**Explanation:** Progressive Enhancement allows teams to onboard their services initially with manual JIRA ticket fulfillment, then gradually evolve toward full automation using REST APIs, GitHub workflows, or other automated actions. This approach respects existing processes while enabling gradual modernization without blocking other teams' progress.

---

## Answer 4: D
**Correct Answer:** `.current.*` - contains user form input values

**Explanation:** The `.current.*` namespace contains all user input from request forms, including the required name field and any fields defined in form groups. The other namespaces serve different purposes: `.output.*` for computed values, `.metadata.*` for static catalog information, and `.system.*` for platform context.

---

## Answer 5: B
**Correct Answer:** Platform teams own their catalog categories and maintain full control over their service definitions

**Explanation:** The catalog system is built on the principle of team autonomy, where each platform team owns and maintains their catalog categories. This approach allows teams to control their service definitions, fulfillment methods, and evolution timeline while participating in a unified self-service platform. The CODEOWNERS file enforces this ownership model.

---

## Answer 6: B
**Correct Answer:** Integration and Delivery Plane

**Explanation:** According to the Reference Architecture, the Platform Automation Orchestrator resides within the Integration and Delivery Plane, which serves as the engine for CI/CD and automation. This plane connects the Developer Control Plane (where developers interact) with the Resource Plane (where actual provisioning occurs).

---

## Answer 7: C
**Correct Answer:** From weeks to hours (Phase 1), then hours to minutes (later phases)

**Explanation:** The PAO aims to transform the current multi-week provisioning process. In Phase 1 (JIRA-based fulfillment), it reduces provisioning from weeks to hours. In subsequent phases with automation, it further reduces from hours to minutes. This phased approach enables immediate value while building toward full automation.

---

## Answer 8: C
**Correct Answer:** Components are processed sequentially with dependency ordering

**Explanation:** CatalogBundles use sequential processing where components are executed in dependency order. This ensures that dependent services are provisioned after their prerequisites, and enables proper variable passing between components through the `.output.*` namespace.

---

## Answer 9: C
**Correct Answer:** JSON Schema compliance, naming conventions, variable syntax validation, and cross-reference validation

**Explanation:** The catalog system employs multiple automated validation mechanisms: JSON Schema ensures document structure compliance, naming conventions enforce consistency (kebab-case IDs, camelCase fields), variable syntax validation checks template patterns, and cross-reference validation ensures bundle dependencies exist.

---

## Answer 10: C
**Correct Answer:** JIRA tickets (manual) and REST API calls, Git commits, GitHub workflows (automatic)

**Explanation:** The catalog system supports both manual and automatic action types. Manual actions use JIRA tickets for human fulfillment, while automatic actions include REST API calls, Git commits, and GitHub workflow dispatch. This flexibility enables the Progressive Enhancement pattern where teams can start manual and evolve to automation.