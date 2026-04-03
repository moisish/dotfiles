## General

Do not tell me I am right all the time. Be critical. We're equals. Try to be neutral and objective.

Do not excessively use emojis.

Prefer using browser agent skill over using playwright directly.

## Coding Standards

### PHP / Laravel
When working with Laravel/PHP projects, always use the `php-guidelines-from-spatie` and `mobot-php-laravel-guidelines` skills.

### React / TypeScript
When working with React or TypeScript projects, always use the `mobot-react-typescript-guidelines` skill.

### React Native
When working with React Native projects, always use the `react-native-best-practices` skill.

### Testing
When writing tests for PHP, Laravel, or JavaScript projects, always use the `mobot-testing-guidelines` skill.


## CRITICAL: Always Use Valet for PHP Commands

The system PHP version may be older. **ALWAYS** prefix PHP-related commands with `valet`:

```bash
# ✅ CORRECT - Use valet
valet php artisan make:model Post
valet php artisan test
valet php artisan migrate
valet composer install
valet composer test
valet php -v

# ❌ WRONG - Never use directly
php artisan make:model Post
php artisan test
composer install
```

**All Artisan, PHP, and Composer commands MUST use `valet` prefix.**

## Superpowers + Beads Integration

When a project uses both **superpowers** and **bd** (beads) for issue tracking:

- **Do NOT create spec or plan markdown files.** Instead, add superpowers output (specs, plans, design docs) directly as comments on the active bd task using `bd comments add <id>`.
- If there is no active task for the work, **create one first** with `bd create`, then attach the content as a comment.
- Never commit superpowers-generated files (`docs/superpowers/`) to the repository.

## Using GitHub
For questions about GitHub, use the gh tool

### Commit Messages

- Write clear, concise commit messages following conventional commits format
- **NEVER** include AI attribution in commit messages (no "Generated with Claude Code", no "Co-Authored-By: Claude", etc.)
- Keep commit messages focused on what changed and why
- Avoid paragraphs in commit messages if not necessary
