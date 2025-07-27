**A vision for a Connected Platform that is scalable and sustainable  ** 

   
   
Intro    
. A platform that empowers teams to move fast and make smart, sustainable decisions from day one to day done. Getting this right requires understanding how engineers experience the platform, end to end, and identifying the highest-leverage friction points to address first. As a leading technology retailer with a strong ecommerce presence, Best Buy obsesses over the customer journey, from search to cart to checkout, because we know that friction equals lost conversion. Platform engineering should be no different. The same principles that drive great customer experience (clear information architecture, curated workflows, guided decisions) should guide our platform as well.    
   
This paper synthesizes internal learnings, industry trends and frameworks like Humanitec to propose a path forward that should be considered for our engineers and our strategy. It’s a structure for alignment, iteration and meaningful conversation, grounded in work we’re already doing:    
 

* Ongoing Platform Solutions work which makes it easier to request (and eventually provision) commonly needed architecture. Platform solutions aren't just technical building blocks; they're reusable and guided experiences. Designing them well requires collaboration across platform engineering teams, security, architecture and product.   
* Real operational pain like ticket driven workflows, inconsistent guidance, typos in simple requests causing days of back and forth and long lead times.    
* Industry frameworks like Humanitic's reference architecture which offers valuable patterns but must be adapted to our reality.   
* Industry data and principles that show the clear correlation between internal platforms, golden paths and high-performing engineering teams.    
   

This isn’t about chasing tools or mimicking vendors. It’s about building a sustainable foundation tailored to our Best Buy context. A foundation that reduces cognitive load, scales responsibly and improves the experience for engineering teams.    
   
**Platform Vision**   
   
**A Connected Platform That Scales Responsibly **   
   
Our platform vision is simple and ambitious. Build a connected platform that empowers teams to move fast and make smart, sustainable decisions from day one to day done.    
   
We believe a well-designed internal platform does three things  

1. Abstracts complexity where it doesn’t add value    
2. Standardizes common needs through reusable solutions    
3. Empowers teams to self-serve with appropriate guardrails 

   
This vision is grounded in experience and data. Ops teams executed over 7k IIPs last year. That is 7k manual touch points. Today, provisioning a new app can take weeks. Key store inputs are often a holdup and are inconsistently entered. Teams frequently encounter manual steps that are fragmented across the platform teams (messaging for messaging, DB for DB, etc), unclear instructions and delays. These aren’t edge cases but clear signals that highlight where the platform needs to mature.    
   
**The Platform Must Serve Engineers with Real Solutions, Not Just Tools**   
** **   
At the heart of our strategy is the idea that a platform isn’t just a pile of tools. A platform is an experience. And like any good experience, it should:    
 

* Minimize the number of decisions teams must make to get started    
* Automate repetitive steps    
* Align with how teams actually work, not how we wish they did  

   
This is where the Platform Solutions work comes in. A platform solution is \[definition\].    
   
Each solution includes:  

* A codified architecture pattern    
* A streamlined request experience    
* Clear documentation and guardrails   
* A foundation for automation and iteration  

   
Platform solutions are a way to abstract away choices that don’t need to be made repeatedly, ensuring consistency and accelerating delivery.    
   
**Data We’re Seeing So Far ** 

* Since rolling out the new process for compute offerings, we’ve seen an increase from 51% to 80% of new apps using our preferred compute offerings    
* 3 platform solutions adopted thus far and there could be different reasons for that: visibility, and assumption that teams want/need composable arch patterns vs individual components    
   

**Looking Ahead **   
   
Our next step is to evolve from defining these solutions to automating them and to validate which ones deliver the most value. That means understanding:    
 

* What are the most frequent and painful requests?    
* Where is the opportunity to reduce confusion?    
* How can we track and measure adoption and success?    
   

This is the start of a longer journey toward a mature internal developer platform. A platform that scales with us not just in size but in quality and experience.    
   
Need to tie in how this strategy/vision aligns with business goals in the next year?   
Is there any data around cost savings or time to market that we can quantify?    
What assumptions are we making?    
How will we track adoption and success in a meaningful way?    
How does the vision consider teams and an org with truly varying levels of maturity?    
What bets are we making?    
   
   
**Platform Solution Automation **   
   
The platform solution automation addresses the problem of platform teams either lacking or not exposing automation that other platform teams can interact with. The solution proposed below is the lubrication required to deliver integrated automation. If as a group, we want to deliver new services within minutes of a request we need to have automation that outside parties can engage with and that we can use between our own teams. This proposal supports all currently understood requirements and completely decouples the requester from the provider freeing both parties to implement the design at their own pace. 

* This approach is extremely low effort and cost effective   
* The biggest value isn't *how* we're storing things with this approach, it's that Git becomes the shared space where the coordination happens   
* This approach positions us to stay loosely coupled technically but tightly aligned in execution   
* We get transparency, visibility, async collab and traceability which are all difficult things to do well in an org this size   
* This approach gives us the cross-team interaction point without needing every team to stand up new tooling or processes. They can work the way they already work just plugged into a shared flow.   
* The git interface isn't the point, the nexus is. The simplicity here is what unlocks it to work across the many silos. 

\[INSERT DIAGRAM OF PLATFORM SOLUTION AUTOMATION\]    
   
**Alignment with Humanitec’s Reference Architecture **   
   
Humanitec’s reference architecture offers a clear, well-structured mental model for designing an Internal Developer Platform (IDP). While we don’t adopt their framework wholesale, several of its key principles align closely with our current strategy and ongoing platform efforts.    
   
**Key Areas of Alignment **   
 

1. **Logical Architecture: Planes of the IDP ** 

Humanitech defines give “planes” to structure a developer platform  

| Plane  | Description  | Our BBY Alignment  |
| :---- | :---- | :---- |
| Developer Control Plane  | Developer Portal, Git repos,   | Backstage is our central developer portal. We need to use it to surface platform solutions and provide consistent access points.   |
| Integration and Delivery Plane  | CI pipelines, container registries, orchestrator   | We integrate pipelines into the platform experience and we’re exploring orchestration patterns to automate infrastructure provisioning.   |
| Security and Compliance Plane  | Secrets management, policy enforcement  |   |
| Monitoring and Logging Plane  | Observability tools for infra and apps  |   |
| Resource Plane  | Underlying infrastructure   | We use Terraform…  |

   
I agree with Humanitec that these layers are composable, not prescriptive, and should be designed for adaptability.    
   
**Where We Diverge from Humanitec and Why That Matters**   
   
While Humanitec’s reference architecture offers a helpful blueprint, we may intentionally choose to diverge in a few key areas. These differences are not deviations rather they are deliberate adaptations to our organization’s needs, engineering landscape and platform maturity.    
   
**Focus on Platform Solutions not just resource abstraction **   
   
Humanitec emphasizes resource level orchestration treating infrastructure provisioning as an orchestrator driven outcome tied to workload specs. The approach with platform solutions starts higher up the stack delivering opinionated architecture patterns and the experience around them. Like what components are included, what the request flow looks like and what parts are automated and how. This allows us to abstract complexity not just from provisioning but from decision making and standardization.    
   
The Humanitec approach is powerful, but it assumes that teams are comfortable writing spec files (like Score), that everything is modular and interoperable and that developers understand enough infrastructure context to describe their app dependencies accurately. We have learned through the platform solutions work and IIP process that teams struggle with submitting requests accurately so we must first start with positioning the org to request and describe their needs successfully.    
   
The platform solutions don’t ask developers to describe individual infrastructure needs in low level specs. That is abstracted that away by saying “Pick this solution and we’ll handle the downstream infrastructure needs for you”.    
I believe this model currently works well for platform teams who are early in the standardization journey (like us) while Humanitec’s model may work better for mature platform organizations.    
   
**We should consider real-world usability over theoretical completeness **   
   
Humanitec’s planes are conceptually elegant, but many implementations assume a greenfield environment or a very mature DevOps culture.    
   
We’re building with  

* A mixed estate of EC2, Openshift and EKS    
* Existing AWS account structures and pipeline systems    
* Security models, tagging standards and compliance obligations    
* A variety of engineering team skill levels and preferences    
   

So while we align on the end-stage goals (self-service, reduce cognitive load) our execution at Best Buy must account for    
 

* Learning curves    
* BBY unique constraints    
* Operational guardrails    
     
   

**We are not tool-led, we are context led **   
   
Where Humanitec offers an off-the-shelf- orchestrator and developer portal our strategy is grounded in existing internal tools and processes.    
 

* We need to decide if investing in Backstage and declare that as the developer control plane with workflows tailored to how engineers already work    
* We’re building automation on our TF Pipeline foundation enabling composability without vendor lock-in    
* We…    
   

Instead of replacing entire toolchains, we need to design a platform experience that connects tools we trust, elevating what works and evolving what doesn’t.    
   
Our divergence should reflect respect for the complexity of our ecosystem, a bias toward learning and iteration and a clear strategy for evolving towards a more automated and sustainable future.    
   
Using frameworks like Humanitec as a reference point are critical steps that guide how to shape a strong strategy, but the north star should be grounded in real workflows, real users and real outcomes.    
   
**Industry Trends and Data**   
   
The challenges we’re solving internally are not unique. Across the industry, teams are grappling with increased complexity, fragmented infrastructure and growing developer cognitive load.    
Recent data on platform engineering and software team performance highlights a clear pattern. High performing teams operate differently, and they invest intentionally in internal platforms to scale their impact.    
   
**What Differentiates High-Performing Teams?**   
   
In 2023, Platform engineering researchers surveyed over 1,000 engineering teams across different industries. The data reinforces key insights.  

| Metric  | High-Top Performing Teams  | Low-Med Performing Teams  |
| :---- | :---- | :---- |
| Lead Time  | Hours to minutes  | Weeks or more  |
| Mean time to resolve  | \<1 hour  | Days+  |
| Deploy frequency  | On Demand  | Monthly, Weekly  |
| App bootstrap time  | \<2 hrs (54% of top performing)  | 1 week or more  |
| Infra Provisioning   | Self-service, via golden paths  | Manual, ops provisioning  |
| Who can Deploy to Dev/Stage?  | Any engineer  | Only senior engineers  |
| Platform Adoption  | 93% use a platform team built IDP  | Majority lack platform team or IDP  |

   
**Key Insight**: Top-performing teams invest in platform engineering and build internal platforms that reduce friction, standardize infrastructure and enable fast, safe delivery. This data should give us confidence in where we are headed while also reinforcing urgency. This opportunity is not simply just to ‘do better’, it is to be a top tier organization by treating platform engineering not as a set of tools but as a **strategic enabler of delivery performance**.    
   
Platform as a Product enables measurable business impact    
 

* Mckinsey (2020): Organizations that treat internal platforms as products (with roadmaps, metrics, and user feedback loops) see 2-3x faster time to market and significant developer productivity gains  

   
**Enabling A responsible Operating Model**   
 

One of the most critical gaps in our current operating model is the lack of visibility into cloud spend and a broader disconnect between infrastructure decisions and their financial impact. 

This isn't a problem unique to our organization, many organizations going through cloud transformations encounter the same friction where cost is considered after a decision is made, not before. If we want to unlock the full value of the cloud, this must change. Cost needs to be a strategy and not a surprise. 

 

**That means** 

* Predicting cost impacts before changes are made   
* Monitoring and adjusting based on actual changes   
* Making cost tradeoffs visible at the time decisions are being scoped 

   

**What needs to shift** 

1. Better cost visibility across domains \- biz and product teams need access to clear, and reliable cost data that maps to their environments, workloads and teams   
2. Tagging, Standards and Account structure: Cost visibility depends on good hygiene with standardized tagging, ownership metadata and a domain aligned account strategy.   
3. Shared responsibility for cloud spend: Engineering and business teams should understand the financial impact of   
* Provisioning new infra   
* running unused environments   
* Choosing EC2 VS Container workloads   
4. FinOps should be a capability: Not just a set of dashboards but a way of working.   
* Cost estimates during planning   
* Feedback loops between spend and priority setting 

   

**Where we need to get to ** 

 

A future where cost is a known, visible input to planning, not a surprise or a constraint. 

 

We want: 

* Eng teams to have confidence they're using resources efficiently   
* Teams understand the tradeoffs of one solutions vs another   
* Leaders consider infra cost in decision making   
* The org is progressing towards proactive vs reactive 

   

**Platform Connection** 

 

The platform and platform solutions model has a key role to play in supporting this shift. 

* Predefined solutions include cost aware defaults   
* Automation includes tagging and guardrails 

   

The platform should help surface the cost signal early, clearly and in a way that influences good decision making. 

 

**Strategy Requires Leadership, not just Tools **   
   
The appeal of frameworks like Humanitec is clear. They offer structure, a common language and the promise of acceleration. But no external model, regardless how well designed, can make our strategic decisions for us. A third-party tool can certainly help execute a vision, but it can’t define our vision for us.    
   
What is needed now is not another vendor solution. We need aligned platform leadership with the courage to make hard, organization shaping decisions about how we work, how we scale, and what kind of platform experiences we are committed to delivering.    
   
**Decisions that can’t be outsourced **   
   
These are the choices that only internal leadership can and should make:  

* What does ‘preferred’ mean in our platform and who decides it?    
* What is our long-term automation strategy and where do we start?    
* How do we align investments across dev portal and pipelines, so they work as a connected system?    
* How do we balance innovation with standardization in a way that serves product teams well at best buy and protects the business?    
* How do we show developers we’re listening by reducing friction in their experience?  

   
These questions can be answered through unified platform thinking, consistent execution, and sustained leadership collaboration.    
 

If we want to build a platform that engineers trust and adopt, we need:  

* A shared vision across platform teams (networking, compute, security, CI/CD, developer experience, cost, observability)    
* Clarity around ownership, sequencing and priorities    
* A culture that embraces full cycle thinking from provisioning to observability, from request to reuse.    
* Cross functional decision making that centers the engineer experience, not in pockets but across the platform surface  

The Humanitec reference architecture can help us frame the conversation but only we can own the strategy. A cohesive platform experience will only emerge when we decide, together, how to shape it. That starts with leadership alignment, shared decision making and a willingness to take ownership of the full journey. This white paper does not claim to have all the answers, but it does reflect what is possible when platform thinking connects strategy, execution and experience.  

   
**Conclusion**   
   
Over the past year, our organization has made important strides in defining a platform strategy that works not just in theory but in practice. This white paper reflects that momentum and frames the next chapter of our journey.    
   
We’ve aligned to a vision in that **a platform that empowers teams to move fast and make smart, sustainable decisions from day one to day done.* ***   
   
We’ve taken deliberate steps to introduce platform solutions and experiences.    
   
We’ve been honest about what’s still ahead  

* Friction still exists in onboarding and provisioning    
* Platform solutions are not automated    
* We must continue learning, measuring and iterating to ensure we’re solving the right problems in the right way    
   

The industry data is clear, high performing teams don’t get there by accident. They invest in internal platforms that standardize what should be consistent, automate what should be repeatable and empower engineers to focus on value.    
   
We’re on that path and we have an opportunity right now to move faster, more intentionally and more collaboratively. This is not a call for more tools. It is a call for more connection.    
 

* Between developers and the platform    
* Between different platform teams    
* Between friction and opportunity    
* Between strategy and execution    
* Between the present and what comes next  

   
   
**Next Steps **   
   
As we continue to evolve, our focus should be on  

* Platform solutions and products that solve common problems for our org   
* Investment in automation    
* Instrumenting the experience to uncover bottlenecks and friction points    
   

The platform is not the end product. It is the engine that powers every product team at Best Buy.    
   
I feel I need more in the conclusion area in terms of next steps – what is this paper really after influencing? If nothing else, awareness that there is necessary change and a proposal for what that change may look like. But maybe need more concrete next steps.    
   
Need to add prioritization, success criteria    
More internal data    
Call out risks    
   
   
   
   
