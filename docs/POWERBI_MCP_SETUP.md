# Power BI Modeling MCP Server - Installation Guide

## Overview

The Power BI Modeling MCP Server (v0.2.2) is now installed and configured for Claude Code. This enables natural language interaction with Power BI semantic models, allowing you to build, modify, and manage models across Power BI Desktop, Fabric workspaces, and Power BI Project (PBIP) files.

## Installation Details

### Version Information
- **Version**: 0.2.2
- **Platform**: win32-x64
- **Publisher**: Microsoft (analysis-services)
- **Installation Date**: 2026-03-24

### File Locations

**Executable Path**:
```
C:\MCP\powerbi-modeling-mcp\extension\server\powerbi-modeling-mcp.exe
```

**Configuration File**:
```
C:\Users\LiuPr\.claude\settings.json
```

**Installation Script**:
```
C:\Users\LiuPr\OneDrive - Willis Towers Watson\Documents\WTW-Data-Solutions\install_powerbi_mcp.ps1
```

## Configuration

The MCP server has been configured in Claude Code with the following settings:

```json
{
  "mcpServers": {
    "powerbi-modeling": {
      "command": "C:\\MCP\\powerbi-modeling-mcp\\extension\\server\\powerbi-modeling-mcp.exe",
      "args": ["--start"],
      "env": {
        "PBI_MODELING_MCP_CLIENT_ID": "ea0616ba-638b-4df5-95b9-636659ae5121"
      }
    }
  }
}
```

## Available Modes

The MCP server supports multiple operational modes:

| Mode | Command Flag | Description |
|------|-------------|-------------|
| Default | `--start` | ReadWrite mode (default) |
| Read-Only | `--read-only` or `--readonly` | Query only, no modifications |
| Read-Write | `--read-write` or `--readwrite` | Full access |
| Skip Confirmation | `--skip-confirmation` | Auto-approve write operations |

## Compatibility Modes

| Mode | Flag | Support |
|------|------|---------|
| Power BI | `--compatibility=powerbi` | Power BI only (default) |
| Full | `--compatibility=full` | Power BI + Analysis Services |

## Capabilities

The Power BI Modeling MCP Server provides the following capabilities:

### Model Management
- Connect to Power BI semantic models
- Create new models
- Update existing models
- List available databases
- Import/export TMDL folders
- Deploy models to Microsoft Fabric

### Object Operations
- **Tables**: Create, modify, delete tables and columns
- **Measures**: Write and manage DAX measures
- **Relationships**: Define and update table relationships
- **Hierarchies**: Create dimension hierarchies
- **Calculations**: Manage calculated columns and tables

### Analysis Operations
- Execute DAX queries
- Perform trace operations
- Capture and analyze Analysis Services events
- Query model metadata

## Usage Examples

### Basic Operations

**Connect to a model**:
```
Connect to the Power BI model at [path/workspace]
```

**Create a measure**:
```
Create a DAX measure called "Total Sales" that sums the Sales[Amount] column
```

**Add a table relationship**:
```
Create a relationship between Sales[ProductKey] and Product[ProductKey]
```

**Query the model**:
```
Run a DAX query to show top 10 products by sales
```

### Advanced Operations

**Import TMDL**:
```
Import the TMDL folder from [path] into the model
```

**Deploy to Fabric**:
```
Deploy this model to the [workspace name] workspace in Fabric
```

**Bulk operations**:
```
Create a complete date dimension table with standard date hierarchies
```

## Restart Required

After installation, you must **restart VS Code** (Claude Code) for the MCP server to become active. After restart:

1. Open a new Claude Code chat
2. Look for the hammer icon in the chat input area
3. The Power BI MCP server will be available for use

## Verification

To verify the installation is working:

1. Check the executable exists:
   ```powershell
   Test-Path "C:\MCP\powerbi-modeling-mcp\extension\server\powerbi-modeling-mcp.exe"
   ```

2. Test the executable:
   ```powershell
   & "C:\MCP\powerbi-modeling-mcp\extension\server\powerbi-modeling-mcp.exe" --help
   ```

3. Check the configuration:
   ```powershell
   Get-Content "$env:USERPROFILE\.claude\settings.json" | ConvertFrom-Json | Select-Object -ExpandProperty mcpServers
   ```

## Troubleshooting

### MCP Server Not Appearing

If you don't see the hammer icon after restart:

1. Verify the executable path in settings.json is correct
2. Ensure the executable has execution permissions
3. Check VS Code Developer Console for error messages
4. Try completely closing and reopening VS Code (not just reloading)

### Connection Issues

If you can't connect to Power BI models:

1. Ensure Power BI Desktop is installed
2. Verify you have appropriate permissions to the model/workspace
3. Check that the Client ID in the configuration is correct
4. Try running in read-only mode first

### Permission Errors

If you encounter permission errors during write operations:

1. Verify you have edit permissions on the semantic model
2. Check if the model is locked by another process
3. Try using `--skip-confirmation` flag if appropriate

## Best Practices

1. **Use Read-Only Mode for Exploration**: When learning about a model, use read-only mode to prevent accidental changes

2. **Test in Development First**: Always test changes in a development environment before production

3. **Version Control TMDL**: Export TMDL files to version control before making bulk changes

4. **Use Descriptive Names**: When creating measures, tables, or relationships, use clear, descriptive names that follow your organization's naming conventions

5. **Backup Before Bulk Operations**: Create a backup or export before performing bulk modifications

## Additional Resources

- **Official Repository**: https://github.com/microsoft/powerbi-modeling-mcp
- **VS Code Extension**: https://marketplace.visualstudio.com/items?itemName=analysis-services.powerbi-modeling-mcp
- **Microsoft Learn**: https://learn.microsoft.com/en-us/power-bi/developer/mcp/

## Support

For issues or questions:
- GitHub Issues: https://github.com/microsoft/powerbi-modeling-mcp/issues
- Microsoft Power BI Community: https://community.powerbi.com/

## Notes

- This server is in **Public Preview** and tools may change significantly before General Availability
- Recommended AI model: Claude Sonnet 4.5 or GPT-5 for best results
- The server runs locally and does not send model data to external services
