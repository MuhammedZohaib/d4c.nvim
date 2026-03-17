# Environment Variables for AI Features

Add to your ~/.zshrc or ~/.bashrc:

```bash
# Avante AI (Claude — recommended)
export ANTHROPIC_API_KEY="sk-ant-..."

# Avante AI (OpenAI — optional)
export OPENAI_API_KEY="sk-..."

# GitHub Copilot (if using copilot.lua)
# Run :Copilot auth inside Neovim after enabling
```

To switch AI provider in Avante, edit:
~/.config/nvim/lua/plugins/ai.lua → change `provider = "claude"` to `"openai"`
