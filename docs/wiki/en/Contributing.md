# 🤝 Contributing Guide - BLACK-ICE ARCH

Thank you for your interest in contributing to BLACK-ICE ARCH! This guide will help you get started.

---

## 📋 Code of Conduct

By participating in this project, you agree to maintain a respectful and professional environment.

### Standards

✅ **Acceptable behavior**:

- Being respectful toward other contributors
- Accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy toward other members

❌ **Unacceptable behavior**:

- Offensive or discriminatory language
- Personal attacks
- Trolling or dismissive comments
- Public or private harassment

---

## 🚀 Ways to Contribute

### 1. Report Bugs

Found a bug? [Open an issue](https://github.com/panxos/BLACK-ICE_ARCH/issues/new)

**Include**:

- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable
- System information:

  ```bash
  uname -a
  hyprctl version
  pacman -Q | grep hyprland
  ```

### 2. Suggest Features

Have an idea? [Open an issue](https://github.com/panxos/BLACK-ICE_ARCH/issues/new) with the `enhancement` label.

**Include**:

- Detailed description of the feature
- Use cases
- Benefits for the community
- Possible implementation (optional)

### 3. Improve Documentation

Documentation can always be better:

- Fix typos
- Clarify confusing instructions
- Add examples
- Translate to other languages

### 4. Contribute Code

- Add new tools
- Improve existing scripts
- Optimize performance
- Add features

### 5. Create Themes

- Design new Waybar themes
- Create color schemes
- Design wallpapers

---

## 🔧 Development Environment Setup

### Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/BLACK-ICE_ARCH.git
cd BLACK-ICE_ARCH

# Add upstream
git remote add upstream https://github.com/panxos/BLACK-ICE_ARCH.git
```

### Create a Branch

```bash
# Update main
git checkout main
git pull upstream main

# Create branch for your feature
git checkout -b feature/descriptive-name
```

### Make Changes

```bash
# Edit files
nano script.sh

# Test changes
./test-script.sh

# Commit
git add .
git commit -m "feat: clear description of the change"
```

---

## 📝 Code Standards

### Bash Scripts

```bash
#!/bin/bash
#
# Script: descriptive_name.sh
# Description: Purpose of the script
# Author: Your Name
#

set -euo pipefail

# Variables in UPPER_CASE
readonly CONSTANT_VARIABLE="value"
local_variable="value"

# Functions with snake_case
function_name() {
    local param="$1"
    # Code here
}

# Logging
log_info "Informational message"
log_error "Error message"

# Error handling
if ! command; then
    log_error "Command failed"
    exit 1
fi
```

### Conventions

- **Indentation**: 4 spaces (no tabs)
- **Variable names**: `snake_case`
- **Function names**: `snake_case`
- **Constants**: `UPPER_CASE`
- **Comments**: Clear and concise
- **Error handling**: Always use `set -e` and validate inputs

### ShellCheck

All scripts must pass ShellCheck:

```bash
shellcheck script.sh
```

---

## 🧪 Testing

### Local Tests

```bash
# Run in VM or test system
./install.sh

# Verify deployment
./deploy_hyprland.sh

# Test individual scripts
./src/deploy/02_security_tools.sh
```

### Testing Checklist

- [ ] Script executes without errors
- [ ] Error handling works correctly
- [ ] Logging is clear
- [ ] No hardcoded credentials
- [ ] File permissions are correct
- [ ] Works on a clean installation
- [ ] Documentation updated

---

## 📤 Pull Request

### Before Submitting

1. **Update your branch**:

   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Test your changes**:

   ```bash
   ./test-all.sh
   ```

3. **Verify ShellCheck**:

   ```bash
   find . -name "*.sh" -exec shellcheck {} \;
   ```

4. **Update documentation** if necessary

### Create Pull Request

```bash
# Push to your fork
git push origin feature/descriptive-name
```

Then on GitHub:

1. Open Pull Request
2. Describe your changes clearly
3. Reference related issues
4. Wait for review

### PR Template

```markdown
## Description
Clear description of the changes

## Type of change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation

## Testing
- [ ] Tested on clean install
- [ ] Tested in VM
- [ ] ShellCheck passed
- [ ] Documentation updated

## Screenshots
(If applicable)

## Checklist
- [ ] My code follows the project style
- [ ] I have commented complex code
- [ ] I have updated documentation
- [ ] My changes don't generate warnings
- [ ] I have added tests if applicable
```

---

## 🎨 Contributing Themes

### Theme Structure

```
dotfiles/waybar/themes/my-theme/
├── config          # Waybar configuration
├── style.css       # CSS styles
└── README.md       # Theme description
```

### Theme Example

```css
/* style.css */
* {
    font-family: "JetBrains Mono Nerd Font";
    font-size: 13px;
}

window#waybar {
    background-color: rgba(26, 27, 38, 0.9);
    color: #cdd6f4;
}

#workspaces button {
    background-color: transparent;
    color: #89b4fa;
}

#workspaces button.active {
    background-color: #89b4fa;
    color: #1e1e2e;
}
```

### Submit a Theme

1. Create your theme in `dotfiles/waybar/themes/`
2. Add a README.md with screenshots
3. Test the theme
4. Submit a PR with the `theme` label

---

## 🛠️ Adding Security Tools

### Check Availability

```bash
# Check official repos
pacman -Ss tool-name

# Check AUR
yay -Ss tool-name
```

### Add to Installer

Edit `src/deploy/02_security_tools.sh`:

```bash
# Add to the appropriate category
ALL_TOOLS=(
    # Recon
    "your-tool|YourTool - Description|Recon"   # ← Add here
)
```

### Document It

Add the tool to the wiki under the appropriate category:

```markdown
### your-tool

**Category**: Reconnaissance
**Description**: Detailed description
**Basic usage**:
\`\`\`bash
your-tool -h
\`\`\`

**Links**:
- [Official docs](https://...)
- [GitHub](https://...)
```

---

## 📚 Improving Documentation

### Wiki

Wiki pages are located in:

- Spanish: `docs/wiki/es/`
- English: `docs/wiki/en/`

### Format

- Use standard Markdown
- Include code examples
- Add screenshots when helpful
- Keep consistency with other pages

### Translation

If translating documentation:

1. Keep the original structure
2. Adapt examples culturally if needed
3. Check spelling and grammar
4. Use correct technical terminology

---

## 🏆 Recognition

Contributors will be acknowledged in:

- README.md (acknowledgments section)
- CONTRIBUTORS.md
- Release notes

---

## 📞 Contact

- **Issues**: [GitHub Issues](https://github.com/panxos/BLACK-ICE_ARCH/issues)
- **Discussions**: [GitHub Discussions](https://github.com/panxos/BLACK-ICE_ARCH/discussions)

---

## 📄 License

By contributing, you agree that your contributions will be licensed under the [MIT License](../../LICENSE).

---

<div align="center">

**[🏠 Back to Wiki](Home.md)**

**Thank you for contributing to BLACK-ICE ARCH!** 🎉

</div>
