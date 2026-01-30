# Claude Code Automation Template

A reusable template for Claude Code automation with pre-configured agents and skills.

## Structure

```
.claude/
├── agents/
│   ├── builder.md   # Build and compile tasks
│   ├── reviewer.md  # Code review and quality
│   ├── tester.md    # Test execution
│   └── db.md        # Database operations
├── skills/
│   ├── build/       # /build - Run project build
│   ├── test/        # /test - Run tests
│   ├── lint/        # /lint - Run linter
│   ├── review/      # /review - Review staged changes
│   ├── migrate/     # /migrate - Run DB migrations
│   └── deps/        # /deps - Install dependencies
└── settings.json
```

## Usage

### Copy to your project

```bash
cp -r .claude /path/to/your/project/
```

### Use skills

Skills are invoked with slash commands:
- `/build` - Build the project
- `/test` - Run tests
- `/lint` - Run linter
- `/review` - Review staged changes
- `/migrate` - Run database migrations
- `/deps` - Install dependencies

### Customize

1. **Agents**: Edit `.claude/agents/*.md` to adjust model, tools, or instructions
2. **Skills**: Add new skills in `.claude/skills/<name>/SKILL.md`
3. **Permissions**: Configure `.claude/settings.json` for allowed/denied commands

## Agent Models

- `sonnet` - Fast, cost-effective (default)
- `opus` - Most capable
- `haiku` - Fastest, cheapest

## Permission Modes

- `default` - Ask for permission
- `bypassPermissions` - Auto-approve (use carefully)
