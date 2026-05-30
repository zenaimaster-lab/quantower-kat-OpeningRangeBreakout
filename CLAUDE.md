# Quantower C# Strategy Project Rules

This file outlines the standard commands, code styles, and mandatory development/deployment workflows for this codebase. Any agent working on this repository must strictly adhere to these rules.

## MANDATORY WORKFLOW (BUILD-DEPLOY-PUSH)

Whenever you make any changes to the C# source code (`KatOpeningRangeBreakout.cs`), you **must** execute the following workflow as a single, atomic operation:

1. **Build the Project**
   - Must run the build command in the project root:
     ```powershell
     dotnet build -c Release
     ```
   - Ensure the build completes with `0 Error(s)` and `0 Warning(s)`.

2. **Deploy to Quantower**
   - Copy the compiled Release binaries from:
     `c:\Users\kieuanhtuan\Documents\all. Coding\quantower-kat-OpeningRangeBreakout\bin\Release\net8.0-windows\`
   - To the Quantower strategy scripts directory:
     `C:\Quantower\Settings\Scripts\Strategies\`
   - Copy both files:
     - `KatOpeningRangeBreakout.dll`
     - `KatOpeningRangeBreakout.pdb`
   - Use this PowerShell command to safely copy them:
     ```powershell
     Copy-Item -Path "bin\Release\net8.0-windows\KatOpeningRangeBreakout.dll", "bin\Release\net8.0-windows\KatOpeningRangeBreakout.pdb" -Destination "C:\Quantower\Settings\Scripts\Strategies\" -Force
     ```

3. **Synchronize with Git & GitHub**
   - Stage all changes, commit with a clear, descriptive message (Conventional Commits style: `feat: ...` or `fix: ...`), and push directly to remote:
     ```powershell
     git add .
     git commit -m "feat: <description of your C# strategy modifications>"
     git push origin master
     ```

---

## Technical Stack & Configuration

- **Language & Framework**: C# / .NET 8.0 Windows (`net8.0-windows`) with WPF and Windows Forms enabled.
- **Reference Library**: `TradingPlatform.BusinessLayer.dll` located at `C:\Quantower\TradingPlatform\v1.145.17\bin\TradingPlatform.BusinessLayer.dll`.
- **Target Quantower Version**: `v1.145.17`.

---

## Coding Standards & Style Guide

- **Quantower Strategy Class**: All strategy logic resides in `KatOpeningRangeBreakout.cs`.
- **Parameters**: 
  - Group settings using `[InputParameter]` headers where appropriate (e.g. `INPUT PARAMETER`).
  - Inputs should have clean names and descriptions, aligned next to their condition checkboxes.
- **Indicators**:
  - Keep EMA inputs clean. Hardcode default/important EMA periods (9, 21, 34, 250, 255) as quick-access checkbox fields rather than generic text boxes if possible.
- **Error Handling**: Use robust `try-catch` blocks for trading operations, logging detailed messages using the built-in `Log(...)` system.
- **Readability**: Ensure all original XML comments, region structures, and strategy descriptions are maintained.

---

## Mandatory Behavioral Guidelines (Karpathy Guidelines)

All development in this repository **must** strictly adhere to the Karpathy Guidelines (https://github.com/multica-ai/andrej-karpathy-skills) to reduce common AI coding mistakes:

1. **Think Before Coding**:
   - State assumptions explicitly before modifying code.
   - If a requirement or behavior is ambiguous or unclear, stop and ask the user. Do not make silent assumptions.
   - Surface tradeoffs and propose simpler approaches when possible.
2. **Simplicity First**:
   - Write the minimum amount of code required to solve the problem. Avoid speculative features, unnecessary configurability, or premature abstractions.
   - If code can be simplified or condensed significantly, refactor/rewrite it to be clean and concise.
3. **Surgical Changes**:
   - Touch only what is necessary to fulfill the request.
   - Do not perform "drive-by" refactoring or reformat adjacent code/comments/styles that are unrelated to your task. Maintain existing code styling.
   - Clean up any imports, variables, or functions that your changes made unused. Do not remove pre-existing unused elements unless asked.
4. **Goal-Driven Execution**:
   - Translate tasks into clear, verifiable success criteria (e.g. reproducing a bug with a test first, or validating exact outputs).
   - For multi-step tasks, state a clear, bite-sized step-by-step plan with verification checks for each step, and verify at each point.

