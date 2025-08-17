# Platform Automation Orchestrator (PAO)

## Table of Contents

- [Overview](#overview)
- [Documentation](#documentation)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)

## Overview

The Platform Automation Orchestrator (PAO) is a central coordination system for Internal Developer Platform (IDP) services. It enables self-service provisioning through a unified catalog, streamlining service delivery and reducing provisioning times from weeks to hours.

## Documentation

### Core Documents
- [**Whitepaper**](whitepaper.md) - Executive summary and strategic vision for PAO implementation
- [**Roadmap**](roadmap.md) - Development phases and implementation timeline (8-12 months)
- [**Service Specification**](service.md) - Technical overview of the PAO REST API service
- [**Catalog Specification**](catalog.md) - Service catalog management and structure

### Agent Documentation
- [**Agent Catalog**](agent-catalog.md) - Catalog management agent specifications
- [**Agent Planner**](agent-planner.md) - Planning agent specifications  
- [**Agent Service**](agent-service.md) - Service management agent specifications

### Project Configuration
- [**CLAUDE.md**](CLAUDE.md) - Project instructions and guidance for AI agents

## Project Structure

```
/
├── README.md              # This file
├── whitepaper.md          # Strategic vision and architecture
├── roadmap.md             # Development timeline and phases
├── service.md             # PAO service specification
├── catalog.md             # Catalog management specification
├── agent-catalog.md       # Catalog agent documentation
├── agent-planner.md       # Planner agent documentation
├── agent-service.md       # Service agent documentation
├── CLAUDE.md              # AI agent project instructions
└── bin/
    └── claude             # CLI utility
```

## Getting Started

1. Begin with the [Whitepaper](whitepaper.md) to understand the strategic context and business problem
2. Review the [Roadmap](roadmap.md) for implementation phases and timeline
3. Examine the [Service Specification](service.md) for technical architecture details
4. Reference the [Catalog Specification](catalog.md) for service catalog structure
5. Consult agent documentation for specific component implementations

For development guidance and AI agent instructions, see [CLAUDE.md](CLAUDE.md).