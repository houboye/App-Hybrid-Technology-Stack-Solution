# Hybrid App Cross-Stack Protocol

## Overview

This protocol defines how Native (iOS/Android), React Native, Flutter, and WebView modules communicate and navigate between each other.

## Routing

All navigation uses URL-scheme format: `app://{stack}/{page}?{params}`

Each tech stack calls into the native Router (the only layer that knows how to instantiate containers for each stack). The native Router resolves the URL and pushes the appropriate ViewController/Activity.

## Communication

All inter-stack communication flows through the native EventBus singleton. Each tech stack has a bridge adapter that:
1. Forwards outgoing messages from its runtime to the native EventBus
2. Receives incoming messages from the native EventBus and delivers them to its runtime

### Message Types
- **request**: Expects a response (has `callbackId`)
- **response**: Reply to a request (echoes `callbackId`)
- **notification**: One-way message to a specific target
- **broadcast**: One-way message to all stacks (target = "*")

See `message-schema.json` for the full JSON schema.
See `route-registry.json` for all registered routes.
