---
name: mobot-php-laravel-guidelines
description: Personal PHP and Laravel overrides — strict types, Action pattern (no suffix, handle()), Model::query(), no down(), scope attributes, route conventions. Complements laravel-best-practices skill.
license: MIT
metadata:
   author: moisish
   tags: php, laravel, coding standards, action pattern, strict types, spatie
---

# PHP & Laravel Overrides

These are personal conventions that override or extend the `laravel-best-practices` skill. For everything else (caching, security, validation, db performance, error handling, etc.), follow `laravel-best-practices`.

## PHP Coding Standards

### Strict Types
All PHP files must include `declare(strict_types=1)` immediately after the opening PHP tag.

### Class Defaults
Don't use `final`. Never use the `#[\Override]` attribute.

### Nullable Types
Use the short nullable notation:
```php
// ✅ Good
public ?string $variable;

// ❌ Bad
public string | null $variable;
```

### Void Return Types
Always indicate when a method returns nothing with `void`.

### Typed Properties
Type properties whenever possible. Don't use docblocks for simple types — only add docblocks when type hints can't express the type (iterables with key/value, array shapes).

```php
/**
 * @param array<int, MyObject> $myArray
 * @return \Illuminate\Support\Collection<int,SomeObject>
 * @return array{first: SomeClass, second: SomeClass}
 */
```

### Traits
Each applied trait on its own line:
```php
use TraitA;
use TraitB;
```

### String Handling
Prefer string interpolation over concatenation:
```php
$greeting = "Hi, I am {$name}.";
```

### Control Flow
- Always use curly brackets
- Happy path last — early returns, avoid `else`
- Prefer separate if statements over compound `&&` conditions

### Ternary Formatting
```php
// Short
$name = $isFoo ? 'foo' : 'bar';

// Long — break across lines
$result = $object instanceof Model ?
    $object->name :
    'A default value';
```

### Closure Type Hints
Always type hint closure parameters:
```php
$user->loadCount([
    'posts as published_posts_count' => fn (Builder $query): Builder => $query->published(),
]);

collect($items)->map(fn (Item $item): string => $item->name);
```

### Whitespace
Allow statements to breathe with blank lines between logical groups.

## Laravel Overrides

### Action Classes
- **No "Action" suffix** — use clear verb names: `CreateResource`, `UpdateUserProfile`
- **Use `handle` as the main method**, not `execute`
- Inject dependencies via constructor

```php
class CreateResource
{
    public function __construct(
        private ResourceService $resourceService,
    ) {}

    public function handle(array $data, User $user): Resource
    {
        return $this->resourceService->create($data, $user);
    }
}
```

### Model Conventions

#### Always Use `Model::query()`
```php
// ✅ Good
$users = User::query()->where('status', 'active')->get();

// ❌ Bad
$users = User::where('status', 'active')->get();
```

#### UUID Routing
Never expose internal IDs. Use UUID columns with `HasUuids` and `getRouteKeyName()`.

#### Scopes — Use `#[Scope]` Attribute
```php
#[Scope]
protected function active(Builder $query): void
{
    $query->where('status', ResourceStatus::ACTIVE);
}
```
- `protected` visibility, no `scope` prefix, return `void`

#### Accessors — Use `Attribute::make()`
```php
protected function displayName(): Attribute
{
    return Attribute::make(
        get: fn (): string => ucfirst($this->name)
    )->shouldCache();
}
```

#### Enum Classes
Use backed enums with helper methods:
```php
enum ResourceStatus: int
{
    case PENDING = 0;
    case ACTIVE = 1;

    public function label(): string
    {
        return match($this) {
            self::PENDING => 'Pending',
            self::ACTIVE => 'Active',
        };
    }
}
```

### Migrations — No `down()` Methods
Only write `up()`. If you need to undo, write a new migration.

### Controllers
- **Plural names**: `UsersController`, `PostsController`
- Controller method order: index, create, store, show, edit, update, destroy

### Routes
- **URLs**: kebab-case — `/open-source`
- **Route names**: camelCase with dots — `openSource.packages`
- **Parameters**: camelCase — `{postId}`
- **Controller refs**: tuple notation — `[PostsController::class, 'index']`
- **Group with fluent `->controller()`**:

```php
Route::prefix('resources')
    ->as('resources.')
    ->controller(ResourceController::class)
    ->group(function () {
        Route::get('/', 'index')->name('index');
        Route::get('{resource}', 'show')->name('show');
    });
```

### Views
View files use camelCase.
