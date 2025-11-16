# Custom Agents for CubeSolver

This directory contains specialized GitHub Copilot agents tailored to the CubeSolver project's needs. Each agent is an expert in a specific domain and can be invoked to help with tasks in their area of expertise.

## Available Agents

### 1. SwiftUI & iOS Expert (`swiftui-expert.agent.md`)
**Name**: `swiftui-ios-expert`

**Expertise**:
- SwiftUI view development and best practices
- iOS/iPadOS/macOS/watchOS platform-specific features
- Glassmorphic design system implementation
- MVVM architecture in SwiftUI
- Apple frameworks (AVFoundation, Vision, Core ML, ARKit, RealityKit)
- Performance optimization for SwiftUI
- Platform-specific adaptations

**Use for**:
- Creating or modifying SwiftUI views
- Implementing glassmorphic UI components
- Platform-specific UI requirements
- View performance optimization
- Integrating Apple frameworks
- MVVM pattern implementation

### 2. Algorithm & Core Logic Expert (`algorithm-expert.agent.md`)
**Name**: `algorithm-expert`

**Expertise**:
- Rubik's Cube solving algorithms (Kociemba, CFOP, Roux)
- Data structures and algorithm optimization
- Cube state representation and validation
- Move notation and transformations
- Performance optimization and profiling
- Swift concurrency and async/await patterns

**Use for**:
- Implementing new solving algorithms
- Optimizing existing algorithms
- Adding cube validation logic
- Working with move notation
- Performance improvements
- Core business logic in CubeCore module

### 3. Accessibility Expert (`accessibility-expert.agent.md`)
**Name**: `accessibility-expert`

**Expertise**:
- VoiceOver and screen reader support
- Dynamic Type and text scaling
- Color contrast and visual accessibility
- Keyboard navigation (macOS)
- Motor accessibility features
- WCAG compliance
- Assistive technology compatibility

**Use for**:
- Making UI accessible
- Implementing VoiceOver support
- Supporting Dynamic Type
- Ensuring color contrast compliance
- Keyboard navigation implementation
- Testing with assistive technologies
- Accessibility audits and improvements

### 4. Testing Specialist (`my-agent.agent.md`)
**Name**: `test-specialist`

**Expertise**:
- XCTest framework and Swift testing
- Unit testing for all modules
- Integration testing
- UI testing with XCTest
- Performance testing and benchmarking
- Test organization and best practices
- Code coverage analysis

**Use for**:
- Writing unit tests
- Improving test coverage
- Creating integration tests
- UI test automation
- Performance benchmarking
- Test code review
- Identifying testing gaps

### 5. Documentation Expert (`documentation-expert.agent.md`)
**Name**: `documentation-expert`

**Expertise**:
- Swift API documentation
- README and user guides
- Technical writing
- Code comments and inline documentation
- Changelog maintenance
- Tutorial and example creation
- GitHub Pages documentation

**Use for**:
- Writing API documentation
- Updating README files
- Creating user guides
- Writing code comments
- Maintaining CHANGELOG
- Creating tutorials
- Documentation review

### 6. DevOps Expert (`devops-agent.md`)
**Name**: `devops-expert`

**Expertise**:
- GitHub Actions CI/CD pipelines
- Build automation
- Deployment strategies
- Infrastructure as code
- Security scanning
- Dependency management
- Release management

**Use for**:
- Creating/modifying GitHub Actions workflows
- CI/CD pipeline optimization
- Build configuration
- Security improvements
- Deployment automation
- Release processes

## How to Use These Agents

### In GitHub Copilot Chat
When working on a task that matches an agent's expertise, you can reference them in your conversation with GitHub Copilot. The agents are automatically available based on the files in this directory.

### Agent Selection Guidelines

**Choose SwiftUI Expert when**:
- Creating new views or UI components
- Working on glassmorphic design elements
- Implementing platform-specific features
- Optimizing view performance

**Choose Algorithm Expert when**:
- Implementing solving algorithms
- Working on core business logic
- Optimizing performance-critical code
- Adding validation logic

**Choose Accessibility Expert when**:
- Adding VoiceOver support
- Implementing Dynamic Type
- Ensuring WCAG compliance
- Making features accessible

**Choose Testing Specialist when**:
- Writing or improving tests
- Increasing code coverage
- Creating UI tests
- Performance benchmarking

**Choose Documentation Expert when**:
- Writing documentation
- Updating README or guides
- Creating API documentation
- Maintaining changelog

**Choose DevOps Expert when**:
- Modifying CI/CD workflows
- Improving build processes
- Implementing security scans
- Managing releases

## Agent Configuration Format

Each agent file follows this format:

```markdown
---
name: agent-name
description: Brief description of agent expertise
---

# Agent Title

Detailed instructions for the agent including:
- Primary responsibilities
- Behavior guidelines
- Output rules
- Common tasks
- When to use this agent
```

## Creating New Agents

To create a new specialized agent for the project:

1. Create a new `.agent.md` file in this directory
2. Follow the YAML frontmatter format with `name` and `description`
3. Provide comprehensive instructions about the agent's role
4. Include specific guidance for the CubeSolver project
5. Update this README to list the new agent

## Project-Specific Context

All agents are configured with specific knowledge about CubeSolver:

- **Architecture**: Modular Swift Package structure (CubeCore, CubeUI, CubeScanner, CubeAR)
- **Platforms**: iOS 17+, iPadOS 17+, macOS 14+, watchOS 10+
- **Framework**: SwiftUI with MVVM pattern
- **Design**: Glassmorphic Mac-style UI
- **Testing**: XCTest with comprehensive test coverage
- **CI/CD**: GitHub Actions workflows

## Best Practices

1. **Use the right agent**: Match the task to the agent's expertise
2. **Provide context**: Give agents relevant information about what you're working on
3. **Be specific**: Clearly state what you want the agent to do
4. **Review output**: Agents provide suggestions; always review and test their recommendations
5. **Combine expertise**: Complex tasks may benefit from multiple agents (e.g., SwiftUI + Accessibility)

## Maintenance

This directory should be kept up-to-date with:
- New agents as project needs evolve
- Updates to existing agents based on new patterns or practices
- Removal of agents that are no longer needed
- This README documenting all available agents

## Questions or Issues?

If you have questions about which agent to use or suggestions for new agents, please open an issue in the repository.
