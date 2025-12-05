# Contributing to Dev Environment Setup

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Maintain a positive and collaborative environment

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/MyrrdinAlsatian/dev-setup/issues)
2. If not, create a new issue with:
   - Clear, descriptive title
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (OS, version, etc.)
   - Relevant logs or error messages

### Suggesting Features

1. Check existing issues for similar suggestions
2. Create a new issue describing:
   - The problem your feature would solve
   - Proposed solution
   - Alternative solutions considered
   - Any additional context

### Contributing Code

1. **Fork the Repository**
   ```bash
   git clone https://github.com/MyrrdinAlsatian/dev-setup.git
   cd dev-setup
   ```

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/bug-description
   ```

3. **Make Your Changes**
   - Follow the existing code style
   - Add comments for complex logic
   - Update documentation as needed
   - Test your changes on multiple platforms if possible

4. **Test Your Changes**
   ```bash
   # Test with dry-run
   ./setup.sh --dry-run
   
   # Test specific components
   ./setup.sh --skip-tools
   ./setup.sh --skip-dotfiles
   ```

5. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "Clear description of changes"
   ```

   Commit message format:
   - Use present tense ("Add feature" not "Added feature")
   - Use imperative mood ("Move cursor to..." not "Moves cursor to...")
   - Reference issues and pull requests when relevant

6. **Push and Create Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```
   
   Then create a Pull Request on GitHub with:
   - Clear title and description
   - Reference to related issues
   - Screenshots for UI changes
   - List of changes made

## Development Guidelines

### Project Structure

- `setup.sh` / `setup.ps1` - Main entry points
- `scripts/lib/` - Core libraries (logging, OS detection, utilities)
- `scripts/modules/` - Tool-specific installation modules
- `config/` - Configuration files

### Code Style

#### Bash Scripts

```bash
# Use bash strict mode
set -euo pipefail

# Function documentation
################################################################################
# Function description
# Arguments:
#   $1 - Description of first argument
# Returns:
#   Description of return value
################################################################################
function_name() {
    local arg="$1"
    # Implementation
}

# Use descriptive variable names
local descriptive_name="value"

# Use quotes around variables
echo "${variable}"

# Use [[ ]] for conditionals
if [[ -f "${file}" ]]; then
    # Do something
fi
```

#### PowerShell Scripts

```powershell
# Use approved verbs
function Verb-Noun {
    param([string]$Parameter)
    
    # Implementation
}

# Use PascalCase for functions
# Use camelCase for variables
# Add parameter validation where appropriate
```

### Module Development

When adding a new tool module:

1. Create both `.sh` and `.ps1` versions
2. Follow this structure:

```bash
#!/usr/bin/env bash

################################################################################
# Tool Name Installation Module
################################################################################

install_tool() {
    # Check if already installed
    if command_exists tool; then
        log_success "Tool is already installed"
        return 0
    fi
    
    log_step "Installing Tool..."
    
    # OS-specific installation
    if is_linux; then
        install_tool_linux
    elif is_macos; then
        install_tool_macos
    fi
    
    # Verify installation
    if command_exists tool; then
        log_success "Tool installed successfully"
    else
        log_error "Failed to install Tool"
        return 1
    fi
}

configure_tool() {
    log_step "Configuring Tool..."
    # Configuration logic
    log_success "Tool configured successfully"
}
```

3. Add to main setup script
4. Update README.md
5. Test on target platforms

### Testing Checklist

Before submitting a PR, test:

- [ ] Script runs without errors
- [ ] `--help` displays correct information
- [ ] `--dry-run` shows what would be done
- [ ] Error handling works correctly
- [ ] Logging is clear and helpful
- [ ] Documentation is updated
- [ ] Works on target OS (Linux/macOS/Windows)

### Platform-Specific Testing

#### Linux
- Test on Ubuntu/Debian
- Test on Fedora/RHEL if possible
- Verify package manager detection

#### macOS
- Test with Homebrew
- Verify Xcode Command Line Tools handling

#### Windows
- Test with PowerShell 5.1
- Test with PowerShell Core 7+
- Test with and without Chocolatey

## Documentation

When updating documentation:

1. Update README.md for user-facing changes
2. Update code comments for implementation details
3. Update CONTRIBUTING.md for process changes
4. Add examples where helpful

## Questions?

If you have questions about contributing:

1. Check existing documentation
2. Search closed issues
3. Ask in a new issue with the "question" label

## Recognition

Contributors will be recognized in:
- GitHub contributors page
- Release notes for significant contributions
- Project documentation for major features

Thank you for contributing to make development environment setup easier for everyone!
