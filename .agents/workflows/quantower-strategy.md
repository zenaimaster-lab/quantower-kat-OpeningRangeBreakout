---
name: quantower-strategy
description: Standardize metadata, compile, hot-deploy, and synchronize C# Quantower strategies.
---

# Workflow: Quantower Strategy DevOps & Standards

This workflow automates and standardizes the hot-deployment, validation, and metadata recording of C# strategies for the Quantower Platform.

## Instructions

Whenever this command is run, execute the following steps sequentially:

1. **Verify Metadata settings**:
   - Check if `[Category("0. METADATA & SYSTEM INFO")]` is implemented in the primary C# strategy file.
   - Supplement or update the strategy version, adapter reference version (e.g. `v1.145.17`), compilation datetime (e.g. `2026-05-27 09:17:06`), and brief strategy description.
   - Always bump the `STRATEGY_VERSION` constant.

2. **Compile the Strategy**:
   - Navigate to the strategy project directory.
   - Run: `dotnet build -c Release`
   - Ensure the build completes with 0 errors.

3. **Hot-Deploy to Quantower**:
   - Locate the compiled `.dll` and `.pdb` files in `bin\Release\net8.0-windows\`.
   - Copy them to the Quantower scripts folder using:
     ```powershell
     Copy-Item -Path "bin\Release\net8.0-windows\KatOpeningRangeBreakout.dll", "bin\Release\net8.0-windows\KatOpeningRangeBreakout.pdb" -Destination "C:\Quantower\Settings\Scripts\Strategies\" -Force
     ```

4. **Synchronize Codebase**:
   - Stage all local modifications: `git add .`
   - Create a conventional commit: `git commit -m "feat: [detailed change summary]"`
   - Push to master branch: `git push origin master`

Follow the global skill `quantower-strategy-standards` for details.
