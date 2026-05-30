## Karpathy Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from Andrej Karpathy's observations (https://github.com/multica-ai/andrej-karpathy-skills).

Rules:
- **Think Before Coding**: State assumptions explicitly. If uncertain, ask. Surface tradeoffs; do not hide confusion or pick silently.
- **Simplicity First**: Write the minimum code that solves the problem. Nothing speculative, no abstractions for single-use code, no error handling for impossible scenarios. Keep it clean and short.
- **Surgical Changes**: Touch only what you must. Match existing style. Do not perform "drive-by" refactoring or formatting of adjacent code. Clean up imports/variables/functions that your changes made unused.
- **Goal-Driven Execution**: Define clear success criteria and loop until verified. For multi-step tasks, state a brief plan and verification checks.
