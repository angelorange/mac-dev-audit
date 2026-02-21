# macOS Dev Audit Tool

A professional, modular, stack-agnostic macOS developer environment diagnostics CLI tool.

## Features

- **Disk Usage Analysis** - Check available space and usage patterns
- **Memory Diagnostics** - RAM usage, swap pressure, and memory hogs
- **Process Detection** - Find resource-intensive processes
- **Large Directory Finder** - Identify space-consuming directories
- **Dev Bloat Detection** - Find `node_modules`, build caches, and other dev artifacts

## Installation

### Homebrew (Recommended)

```bash
brew tap YOUR_USERNAME/tap
brew install mac-dev-audit
```

### Manual Installation

```bash
git clone https://github.com/YOUR_USERNAME/mac-dev-audit.git
cd mac-dev-audit
chmod +x mac-dev-audit

# Add to PATH (add to ~/.zshrc or ~/.bashrc)
export PATH="$PATH:/path/to/mac-dev-audit"
```

## Usage

```bash
# Run all diagnostics
mac-dev-audit

# Run specific modules
mac-dev-audit --modules disk,memory

# Output as JSON
mac-dev-audit --json

# Save report to file
mac-dev-audit --report ~/audit-report.txt

# Set size threshold for warnings (in GB)
mac-dev-audit --threshold 2

# Show verbose output
mac-dev-audit --verbose
```

### Available Modules

| Module | Description |
|--------|-------------|
| `disk` | Disk usage analysis |
| `memory` | Memory and swap diagnostics |
| `processes` | Heavy process detection |
| `directories` | Large directory finder |
| `bloat` | Development bloat detection |

### CLI Options

| Option | Description |
|--------|-------------|
| `--help`, `-h` | Show help message |
| `--version`, `-v` | Show version |
| `--modules <list>` | Run specific modules (comma-separated) |
| `--json` | Output in JSON format |
| `--report <file>` | Save report to file |
| `--threshold <GB>` | Size threshold for warnings (default: 1) |
| `--verbose` | Show detailed output |

## Output Formats

### Human-Readable (Default)

```
+==================================================================+
|                    macOS Dev Audit Tool                         |
|                        v1.0.0                                  |
+==================================================================+

+-- Disk Usage --------------------------------------------------
|
|  Total:               500G
|  Used:                380G (76%)
|  Available:           120G
|
|  ! Warning: Disk usage above 75%
|  > Recommendation: Consider freeing up space
|
+-----------------------------------------------------------------
```

### JSON

```json
{
  "version": "1.0.0",
  "timestamp": "2024-01-15T10:30:00Z",
  "modules": {
    "disk": {
      "total": "500G",
      "used": "380G",
      "available": "120G",
      "usage_percent": 76
    }
  },
  "warnings": ["Disk usage above 75%"],
  "recommendations": [{"action": "Consider freeing up space"}]
}
```

## Extending

### Adding Bloat Patterns

Edit `patterns/bloat-patterns.txt`:

```
# Format: pattern|category|explanation
my_cache|cache|My custom cache directory
```

### Adding Modules

Create a new file in `modules/`:

```bash
#!/bin/bash
# modules/mymodule.sh

module_mymodule_name() {
    echo "My Module"
}

module_mymodule_description() {
    echo "Description of what this module does"
}

module_mymodule_run() {
    output_start_module "mymodule"
    output_section "$(module_mymodule_name)"

    # Your diagnostic logic here
    output_item "Key" "Value"

    output_section_end
}
```

## Project Structure

```
mac-dev-audit/
├── mac-dev-audit           # Main entry point
├── lib/
│   ├── core.sh             # Core utilities
│   ├── args.sh             # Argument parsing
│   ├── config.sh           # Configuration
│   └── output.sh           # Output formatting
├── modules/
│   ├── disk.sh             # Disk diagnostics
│   ├── memory.sh           # Memory diagnostics
│   ├── processes.sh        # Process detection
│   ├── directories.sh      # Directory analysis
│   └── bloat.sh            # Bloat detection
├── patterns/
│   └── bloat-patterns.txt  # Bloat patterns
├── config/
│   └── defaults.conf       # Default config
├── Formula/
│   └── mac-dev-audit.rb    # Homebrew formula
└── tests/
    └── test_core.sh        # Test suite
```

## Requirements

- macOS 12.0 (Monterey) or later
- Bash 3.2+ (included with macOS)

## Safety

This tool is **read-only** and does not modify any files. All cleanup recommendations are informational only.

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.
