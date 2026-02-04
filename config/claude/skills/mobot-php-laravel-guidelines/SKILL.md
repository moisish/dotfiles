---
name: mobot-php-laravel-guidelines
description: Personal PHP and Laravel coding guidelines including strict types, Action pattern, controller ordering, route conventions, and migration patterns.
license: MIT
metadata:
   author: moisish
   tags: php, laravel, coding standards, action pattern, strict types, spatie
---

# PHP & Laravel Development Guidelines

## Table of Contents
- [PHP Coding Standards](#php-coding-standards)
- [Laravel 12 Patterns](#laravel-12-patterns)
- [Database Conventions](#database-conventions)
- [Security Practices](#security-practices)
- [Naming Conventions](#naming-conventions)

## PHP Coding Standards

### Strict Types Declaration
**All PHP files must include `declare(strict_types=1)` immediately after the opening PHP tag.**

```php
<?php

declare(strict_types=1);

namespace App\Models;

// ... rest of the file
```

This enforces strict typing throughout the application and prevents type coercion issues that can lead to bugs.

### Class Defaults
By default, we don't use `final`. In our team, there aren't many benefits that `final` offers as we don't rely too much on inheritance.

### Type Declarations

#### Nullable Types
Use the short nullable notation instead of union types with null.

```php
// ✅ Good
public ?string $variable;

// ❌ Bad
public string | null $variable;
```

#### Void Return Types
Always indicate when a method returns nothing with `void`.

```php
// In a Laravel Service Provider
public function register(): void
{
    //
}
```

#### Typed Properties
Type properties whenever possible. Don't use docblocks for simple types.

```php
// ✅ Good
class Foo
{
    public string $bar;
}

// ❌ Bad
class Foo
{
    /** @var string */
    public $bar;
}
```

### Docblocks

Don't use docblocks for methods that can be fully type hinted unless you need a description.

```php
// ✅ Good - no unnecessary docblock
class Url
{
    public static function fromString(string $url): Url
    {
        // ...
    }
}

// ❌ Bad - redundant docblock
class Url
{
    /**
     * Create a url from a string.
     *
     * @param string $url
     * @return \Spatie\Url\Url
     */
    public static function fromString(string $url): Url
    {
        // ...
    }
}
```

#### Docblocks for Iterables
When your function gets passed an iterable, specify the type of key and value.

```php
/**
 * @param array<int, MyObject> $myArray
 * @param int $typedArgument
 */
function someFunction(array $myArray, int $typedArgument): void
{
    //
}

/**
 * @return \Illuminate\Support\Collection<int,SomeObject>
 */
function someFunction(): Collection
{
    //
}

// For arrays with fixed keys
/**
 * @return array{first: SomeClass, second: SomeClass}
 */
function someFunction(): array
{
    //
}
```

### Constructor Property Promotion
Use constructor property promotion if all properties can be promoted. Put each one on a line of its own with a comma after the last one.

```php
// ✅ Good
class MyClass
{
    public function __construct(
        protected string $firstArgument,
        protected string $secondArgument,
    ) {}
}

// ❌ Bad
class MyClass
{
    protected string $secondArgument;

    public function __construct(protected string $firstArgument, string $secondArgument)
    {
        $this->secondArgument = $secondArgument;
    }
}
```

### Traits
Each applied trait should go on its own line.

```php
// ✅ Good
class MyClass
{
    use TraitA;
    use TraitB;
}

// ❌ Bad
class MyClass
{
    use TraitA, TraitB;
}
```

### PHP Attributes
While we use some PHP 8+ attributes for specific Laravel features, avoid certain attributes that add unnecessary overhead.

#### Override Attribute
**Never use the `#[\Override]` attribute.** We prefer explicit code without additional metadata.

```php
// ❌ Bad - never use Override attribute
class ChildClass extends ParentClass
{
    #[\Override]
    public function someMethod(): void
    {
        // implementation
    }
}

// ✅ Good - clean method override
class ChildClass extends ParentClass
{
    public function someMethod(): void
    {
        // implementation
    }
}
```

### String Handling
Prefer string interpolation over concatenation.

```php
// ✅ Good
$greeting = "Hi, I am {$name}.";

// ❌ Bad
$greeting = 'Hi, I am ' . $name . '.';
```

### Control Structures

#### If Statements
Always use curly brackets and follow the happy path pattern.

```php
// ✅ Good - happy path last
if (! $goodCondition) {
    throw new Exception;
}

// Happy path code here

// ❌ Bad
if ($condition) ...
```

#### Avoid Else
Prefer early returns over else statements.

```php
// ✅ Good
if (! $conditionA) {
    return;
}

if (! $conditionB) {
    return;
}

// condition A and B passed

// ❌ Bad
if ($conditionA) {
    if ($conditionB) {
        // condition A and B passed
    } else {
        // condition A passed, B failed
    }
} else {
    // condition A failed
}
```

#### Compound Conditions
Prefer separate if statements over compound conditions for better debugging.

```php
// ✅ Good
if (! $conditionA) {
    return;
}

if (! $conditionB) {
    return;
}

// ❌ Bad
if ($conditionA && $conditionB && $conditionC) {
    // do stuff
}
```

### Ternary Operators
Use multiple lines for complex ternary expressions.

```php
// ✅ Good - short expression
$name = $isFoo ? 'foo' : 'bar';

// ✅ Good - long expression
$result = $object instanceof Model ?
    $object->name :
    'A default value';
```

### Closure Type Hints
**Always type hint closure parameters**, especially when used with Laravel's query builder, collections, or callbacks.

```php
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\HasMany;

// ✅ Good - Type hinted closure parameters
$user->loadCount([
    'posts as published_posts_count' => fn (Builder $query): Builder => $query->published(),
]);

$accounts = $user->awsAccounts()
    ->with(['resources' => fn (HasMany $query): HasMany => $query->running()])
    ->get();

collect($items)->map(fn (Item $item): string => $item->name);

// ❌ Bad - Untyped closures
$user->loadCount([
    'posts as published_posts_count' => fn ($query) => $query->published(),
]);

collect($items)->map(fn ($item) => $item->name);
```

### Comments
Avoid comments by writing expressive code. When needed, format properly.

```php
// There should be a space before a single line comment.

/*
 * If you need to explain a lot you can use a comment block. Notice the
 * single * on the first line.
 */

// ✅ Good - expressive method name
$this->calculateLoans();

// ❌ Bad - comment explaining code
// Start calculating loans
```

### Whitespace
Allow statements to breathe with blank lines between logical groups.

```php
// ✅ Good
public function getPage($url)
{
    $page = $this->pages()->where('slug', $url)->first();

    if (! $page) {
        return null;
    }

    if ($page['private'] && ! Auth::check()) {
        return null;
    }

    return $page;
}
```

## Laravel 12 Patterns

### Action Classes Pattern
Use Action classes for business logic instead of fat controllers or models.

#### Naming Convention
**Do not use "Action" suffix.**
Action class names should be clear verbs describing what they do.

#### Method Convention
**Use `handle` as the main method name.**
All Action classes must use `handle` as their primary public method, not `execute` or other names.

```php
// ✅ Good - Clear verb without Action suffix
// app/Actions/Resources/CreateResource.php
class CreateResource
{
    public function __construct(
        private ResourceService $resourceService,
        private AwsService $awsService
    ) {}
    
    public function handle(array $data, User $user): Resource
    {
        $this->awsService->validateAccountAccess($data['aws_account_id'], $user);

        return $this->resourceService->create($data, $user);
    }
}

// ❌ Bad - Don't use Action suffix
class CreateResourceAction
{
    // ...
}
```

#### More Action Examples
```php
// ✅ Good Action naming
class ConfigureAwsAccount { /* ... */ }
class UpdateUserProfile { /* ... */ }  
class ProcessScheduleExecution { /* ... */ }
class ValidateAwsCredentials { /* ... */ }

// ❌ Bad Action naming
class StoreAwsAccountAction { /* ... */ }
class UpdateUserProfileAction { /* ... */ }
class ProcessScheduleExecutionAction { /* ... */ }
```

### Controller Structure
Keep controllers thin and delegate to Action classes.

```php
class ResourceController extends Controller
{
    public function index(GetResources $action)
    {
        return $action->handle(auth()->user());
    }
    
    public function store(StoreResourceRequest $request, CreateResource $action)
    {
        return $action->handle($request->validated(), auth()->user());
    }
    
    public function update(UpdateResourceRequest $request, Resource $resource, UpdateResource $action)
    {
        return $action->handle($resource, $request->validated(), auth()->user());
    }
    
    public function destroy(Resource $resource, DeleteResource $action)
    {
        return $action->handle($resource, auth()->user());
    }
}
```

#### Controller Method Ordering
Controllers should follow Laravel's resourceful method order for consistency:
1. `index` - Display a listing
2. `create` - Show form to create new resource
3. `store` - Store a newly created resource
4. `show` - Display specified resource
5. `edit` - Show form to edit resource
6. `update` - Update specified resource
7. `destroy` - Delete specified resource

**For non-CRUD actions, extract them into separate controllers** rather than adding custom methods to resourceful controllers.

```php
// ✅ Good - Follows standard order
class PostsController extends Controller
{
    public function index() { /* ... */ }
    public function create() { /* ... */ }
    public function store() { /* ... */ }
    public function show(Post $post) { /* ... */ }
    public function edit(Post $post) { /* ... */ }
    public function update(Post $post) { /* ... */ }
    public function destroy(Post $post) { /* ... */ }
}

// ❌ Bad - Custom actions mixed with CRUD
class PostsController extends Controller
{
    public function index() { /* ... */ }
    public function publish(Post $post) { /* ... */ } // Extract to PublishPostController
    public function show(Post $post) { /* ... */ }
}
```

### Route Naming Conventions
**URLs:** Use kebab-case for all URL segments.

```php
Route::get('/open-source', ...);
Route::get('/user-profile', ...);
```

**Route names:** Use camelCase with dot notation for hierarchy.

```php
Route::get('/open-source', ...)->name('openSource');
Route::get('/open-source/packages', ...)->name('openSource.packages');
```

**Route parameters:** Use camelCase for parameter names.

```php
Route::get('/posts/{postId}', ...);
Route::get('/users/{userId}/posts/{postSlug}', ...);
```

**Controller references:** Always use tuple notation.

```php
// ✅ Good
Route::get('/posts', [PostsController::class, 'index']);

// ❌ Bad
Route::get('/posts', 'PostsController@index');
```

### Configuration File Conventions
**Config files:** Use kebab-case for filenames.

```php
// config/pdf-generator.php
// config/mail-templates.php
```

**Config keys:** Use snake_case for all configuration keys.

```php
// config/pdf-generator.php
return [
    'chrome_path' => env('CHROME_PATH'),
    'node_path' => env('NODE_PATH'),
];
```

**Service configurations:** Add service-related configs to `config/services.php` rather than creating separate files.

```php
// config/services.php
return [
    'github' => [
        'client_id' => env('GITHUB_CLIENT_ID'),
        'client_secret' => env('GITHUB_CLIENT_SECRET'),
    ],
];
```

**Important:** Always use the `config()` helper to retrieve configuration. Never use `env()` outside of configuration files.

```php
// ✅ Good
$path = config('pdf-generator.chrome_path');

// ❌ Bad - never use env() in application code
$path = env('CHROME_PATH');
```

### Artisan Command Conventions
**Command names:** Use kebab-case.

```php
// ✅ Good
protected $signature = 'delete-old-records';
protected $signature = 'send-reminder-emails';

// ❌ Bad
protected $signature = 'deleteOldRecords';
protected $signature = 'send_reminder_emails';
```

**User feedback:** Always provide clear feedback to the user.

```php
public function handle()
{
    $this->info('Starting process...');

    // ... do work ...

    $this->comment('All done!');
}
```

**Progress indication:** Show progress for loops and provide a summary at the end.

```php
public function handle()
{
    $items = Item::query()->where('processed', false)->get();

    $this->info("Found {$items->count()} items to process.");

    $items->each(function(Item $item) {
        // Output BEFORE processing (easier to debug which item failed)
        $this->info("Processing item ID {$item->id}...");
        $this->processItem($item);
    });

    $this->comment("Successfully processed {$items->count()} items.");
}
```

### Migration Naming Conventions
**Migration files:** Laravel generates these automatically with timestamps. Follow Laravel's naming patterns.

**Migration methods:** Only write `up()` methods in migrations. Do not write `down()` methods.

```php
// ✅ Good - Only up method
public function up(): void
{
    Schema::create('posts', function (Blueprint $table) {
        $table->id();
        $table->string('title');
        $table->timestamps();
    });
}

// ❌ Bad - Don't write down methods
public function down(): void
{
    Schema::dropIfExists('posts');
}
```

**Rationale:** Down methods are rarely used in production and can become outdated. If you need to undo a migration, write a new migration instead.

### Model Conventions
Use Laravel 12 features and conventions.

#### Query Pattern
**Always use the explicit query pattern** for consistency and clarity.

```php
// ✅ Good - Always start with Model::query()
$users = User::query()
    ->where('status', 'active')
    ->with(['posts', 'profile'])
   ->latest()
    ->get();

$account = AwsAccount::query()
    ->where('uuid', $uuid)
    ->with('owner')
    ->firstOrFail();

// ❌ Bad - Avoid direct Model methods
$users = User::where('status', 'active')->get();
$account = AwsAccount::find($id);
```

#### UUID Routing Pattern
**For models that need routes, never expose internal IDs. Always use UUID columns.**

```php
// routes/web.php

// ✅ Good - Always expose UUID /aws-accounts/01234567-89ab-cdef-0123-456789abcdef
// ❌ Bad - Exposes Internal ID /aws-accounts/123
Route::prefix('aws-accounts/{awsAccount}')
    ->name('aws-accounts.')
    ->controller(AwsAccountController::class)
    ->group(function () {
        Route::get('/', 'show')->name('show');
        Route::put('/', 'update')->name('update');
        Route::delete('/', 'destroy')->name('destroy');
});
```

```php
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class AwsAccount extends Model
{
    use HasUuids;
    
    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'id', // Hide internal database ID
    ];
    
    /**
     * Get the columns that should receive a unique identifier.
     */
    public function uniqueIds(): array
    {
        return $this->usesUniqueIds() ? [$this->getRouteKeyName()] : parent::uniqueIds();
    }

    /**
     * The route key name for the model.
     */
    public function getRouteKeyName(): string
    {
        return 'uuid';
    }
    
    // Use PHP 8 Attributes for model scopes
    // NOTE: Scope methods are protected, no "scope" prefix, type-hinted Builder, return void
    #[Scope]
    protected function active(Builder $query): void
    {
        $query->where('status', ResourceStatus::ACTIVE);
    }
    
    #[Scope]
    protected function byType(Builder $query, string $type): void
    {
        $query->where('resource_type', $type);
    }
    
    #[Scope]
    protected function recent(Builder $query): void
    {
        $query->where('created_at', '>=', now()->subDays(30));
    }
    
    // Use Attribute::make for accessors
    protected function displayName(): Attribute
    {
        return Attribute::make(
            get: fn (): string => ucfirst($this->name)
        )->shouldCache();
    }
    
    // Use casts() method instead of property
    protected function casts(): array
    {
        return [
            'status' => ResourceStatus::class,
            'resource_type' => ResourceType::class,
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }
}
```

#### Scope Usage Examples
```php
// Usage in controllers/queries - always start with Model::query()
$activeAccounts = AwsAccount::query()->active()->get();
$recentEc2Resources = Resource::query()->recent()->byType('ec2')->get();
$activeAndRecent = Resource::query()->active()->recent()->paginate(15);

// With relationships and ordering
$userAccounts = AwsAccount::query()
    ->where('owner_id', $userId)
    ->active()
    ->with('owner')
   ->latest()
    ->get();
```

#### Always Prefer Scopes Over Inline Conditions
**When a scope exists for a query condition, always use the scope.** This ensures consistency, makes code more readable, and centralizes business logic.

```php
// ✅ Good - Use the scope
$accounts = $user->awsAccounts()->active()->get();
$resources = Resource::query()->running()->get();

// ❌ Bad - Inline condition when scope exists
$accounts = $user->awsAccounts()->where('status', AwsAccountStatus::ACTIVE)->get();
$resources = Resource::query()->where('state', State::Running)->get();
```

This applies to:
- Status checks (`active()`, `inactive()`, `pending()`)
- State filters (`running()`, `stopped()`)
- Time-based filters (`recent()`, `needsSync()`)
- Type filters (`ec2()`, `rds()`)

#### Scope Best Practices
- **Always use `protected` visibility** for scope methods
- **Do NOT use `scope` prefix** in method names
- **Type hint `Builder $query`** parameter
- **Return `void`** - modify the query object directly
- **Use descriptive names** that clearly indicate the filtering behavior
- **Group related scopes** (status, time, relationships) for better organisation

### Model Accessors & Mutators
**Always use the Laravel `Attribute` class for accessors and mutators.** Never use the legacy `getXxxAttribute()` or `setXxxAttribute()` methods.

```php
use Illuminate\Database\Eloquent\Casts\Attribute;

class Resource extends Model
{
    // ✅ Good - Laravel Attribute class
    protected function displayName(): Attribute
    {
        return Attribute::make(
            get: fn (): string => $this->name ?? $this->resource_id,
        );
    }

    // ✅ Good - With both getter and setter
    protected function formattedPrice(): Attribute
    {
        return Attribute::make(
            get: fn (int $value): string => number_format($value / 100, 2),
            set: fn (string $value): int => (int) ($value * 100),
        );
    }

    // ❌ Bad - Legacy accessor pattern
    public function getDisplayNameAttribute(): string
    {
        return $this->name ?? $this->resource_id;
    }
}
```

#### Accessor Best Practices
- **Use `protected` visibility** for accessor methods
- **Use camelCase method names** matching the attribute name
- **Type hint the closure return type** for clarity
- **Use `->shouldCache()`** for expensive computed attributes

### Enum Classes
Use enum classes for status fields with helper methods.

```php
enum ResourceStatus: int
{
    case PENDING = 0;
    case ACTIVE = 1;
    case INACTIVE = 2;
    case STOPPED = 3;
    
    public function label(): string
    {
        return match($this) {
            self::PENDING => 'Pending',
            self::ACTIVE => 'Active',
            self::INACTIVE => 'Inactive',
            self::STOPPED => 'Stopped',
        };
    }
    
    public function color(): string
    {
        return match($this) {
            self::PENDING => 'yellow',
            self::ACTIVE => 'green',
            self::INACTIVE => 'gray',
            self::STOPPED => 'red',
        };
    }
}
```

## Database Conventions

### Migration Structure
```php
// Migration naming: timestamp_descriptive_action
// 2025_01_15_000000_create_aws_accounts_table.php

Schema::create('aws_accounts', function (Blueprint $table) {
    // Primary key (always 'id') - for internal database use only
    $table->id();
    
    // UUID for public/route identification - always add for models with routes
    $table->uuid()->unique();
    
    // Foreign keys (singular_table_name_id)
    $table->foreignId('owner_id')->constrained('users');
    
    // Column naming (snake_case)
    $table->string('name');
    $table->string('account_id');
    $table->string('role_arn');
    $table->string('region');
    
    // For statuses, use unsignedTinyInteger with Enum classes
    $table->unsignedTinyInteger('status')->default(AwsAccountStatus::PENDING->value);
    
    // User tracking
    $table->auditors(); // Macro for created_by, updated_by
    
    // Standard timestamps
    $table->timestamps();
    $table->softDeletes();
});
```

### Query Optimization
**Always use Model::query() pattern for consistent and optimized queries.**

```php
// ✅ Good: Eager loading to prevent N+1 queries
$accounts = AwsAccount::query()
    ->with(['owner', 'resources'])
    ->active()
    ->get();

// ✅ Good: Select only needed columns (include uuid for route binding)
$accounts = AwsAccount::query()
    ->select('uuid', 'name', 'status', 'owner_id')
    ->where('owner_id', $userId)
    ->get();

// ✅ Good: Use pagination for large datasets
$resources = Resource::query()
    ->where('aws_account_id', $accountId)
    ->with('awsAccount')
   ->latest()
    ->paginate(20);

// ✅ Good: Complex queries with scopes
$activeRecentAccounts = AwsAccount::query()
    ->active()
    ->where('owner_id', auth()->id())
    ->with(['owner', 'resources' => fn($query) => $query->select('id', 'name', 'aws_account_id')])
   ->latest()
    ->get();
```

## Security Practices

### AWS Credential Management
```php
class AwsService
{
    private function getCredentialsForAccount(AwsAccount $account): Credentials
    {
        $stsClient = new StsClient([
            'version' => 'latest',
            'region' => config('aws.default_region'),
        ]);
        
        $result = $stsClient->assumeRole([
            'RoleArn' => $account->role_arn,
            'RoleSessionName' => 'parkmyaws-' . $account->getKey() . '-' . time(),
            'ExternalId' => $account->getRouteKey(),
            'DurationSeconds' => 3600,
        ]);
        
        return new Credentials(
            $result['Credentials']['AccessKeyId'],
            $result['Credentials']['SecretAccessKey'],
            $result['Credentials']['SessionToken']
        );
    }
}
```

### Input Validation
```php
class ScheduleRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:1000'],
            'timezone' => ['required', 'string', Rule::in(timezone_identifiers_list())],
            'schedule_config' => ['required', 'array'],
            'schedule_config.start_time' => ['required', 'date_format:H:i'],
            'schedule_config.stop_time' => ['required', 'date_format:H:i', 'after:schedule_config.start_time'],
            'resource_ids' => ['required', 'array', 'min:1'],
            'resource_ids.*' => ['integer', 'exists:resources,id']
        ];
    }
}
```

## Laravel-Specific Conventions

### Configuration
Configuration files must use kebab-case, keys use snake_case.

```php
// config/pdf-generator.php
return [
    'chrome_path' => env('CHROME_PATH'),
];
```

Add service credentials to `config/services.php`:

```php
return [
    'ses' => [
        'key' => env('SES_AWS_ACCESS_KEY_ID'),
        'secret' => env('SES_AWS_SECRET_ACCESS_KEY'),
        'region' => env('SES_AWS_DEFAULT_REGION', 'us-east-1'),
    ],
];
```

### Artisan Commands
Command names should be kebab-cased with proper feedback.

```bash
# ✅ Good
php artisan delete-old-records

# ❌ Bad
php artisan deleteOldRecords
```

```php
// in a Command
public function handle(): void
{
    $this->comment("Start processing items...");

    $items->each(function(Item $item) {
        $this->info("Processing item id `{$item->getKey()}`...");
        $this->processItem($item);
    });

    $this->comment("Processed {$items->count()} items.");
}
```

### Controllers
Controllers should use plural resource names and stick to CRUD operations.

```php
class PostsController
{
    // Standard CRUD methods: index, create, store, show, edit, update, destroy
}

// For non-CRUD actions, extract to separate controllers
class FavoritePostsController
{
    public function store(Post $post): Response
    {
        request()->user()->favorites()->attach($post);
        return response(null, 200);
    }

    public function destroy(Post $post): Response
    {
        request()->user()->favorites()->detach($post);
        return response(null, 200);
    }
}
```

### Views and Validation
View files use camelCase. Validation rules use array notation.

```php
// ✅ Good
public function rules(): array
{
    return [
        'email' => ['required', 'email'],
    ];
}

// ❌ Bad
public function rules(): array
{
    return [
        'email' => 'required|email',
    ];
}
```

### Blade Templates
```blade
{{-- Indent using four spaces --}}
<a href="/open-source">
    Open Source
</a>

{{-- Don't add spaces after control structures --}}
@if($condition)
    Something
@endif
```

### Authorization
Use camelCase for policies and prefer CRUD words (use 'view' instead of 'show').

```php
Gate::define('editPost', function ($user, $post) {
    return $user->getKey() == $post->user_id;
});
```

### Translations
Use the `__` function for translations.

```blade
<h2>{{ __('newsletter.form.title') }}</h2>
{!! __('newsletter.form.description') !!}
```

## Naming Conventions

### Controllers
- Plural resource name + Controller suffix
- Invokable controllers: Action + Controller suffix

```php
UsersController
EventDaysController
PerformCleanupController
```

### Models and Services
- Singular, PascalCase
- Services: Name + Service suffix

```php
User
AwsAccount
ResourceService
```

### Jobs, Events, Listeners
- Jobs: Action description
- Events: Tense-based (before/after)
- Listeners: Action + Listener suffix

```php
CreateUser
PerformDatabaseCleanup

ApprovingLoan  // before
LoanApproved   // after

SendInvitationMailListener
```

### Commands and Mailables
- Commands: Action + Command suffix
- Mailables: Description + Mail suffix

```php
PublishScheduledPostsCommand
AccountActivatedMail
```

### Enums
Clear names without prefixes.

```php
OrderStatus
BookingType
ResourceStatus
```

## Routes

### Route Grouping Pattern
**Always group routes by prefix and name using the fluent `->controller()` method.** This keeps related routes together and reduces repetition.

```php
// ✅ Good - Grouped with prefix, name, and controller
Route::prefix('resources')
    ->as('resources.')
    ->controller(ResourceController::class)
    ->group(function () {
        Route::get('/', 'index')->name('index');
        Route::get('{resource}', 'show')->name('show');
        Route::post('/', 'store')->name('store');
        Route::put('{resource}', 'update')->name('update');
        Route::delete('{resource}', 'destroy')->name('destroy');
    });

// ❌ Bad - Repetitive controller references
Route::get('resources', [ResourceController::class, 'index'])->name('resources.index');
Route::get('resources/{resource}', [ResourceController::class, 'show'])->name('resources.show');
Route::post('resources', [ResourceController::class, 'store'])->name('resources.store');
```

### Nested Route Groups
For settings or admin sections, nest groups appropriately:

```php
Route::middleware('auth')
    ->prefix('settings')
    ->group(function (): void {
        Route::redirect('/', 'profile');

        Route::prefix('profile')
            ->as('profile.')
            ->controller(ProfileController::class)
            ->group(function () {
                Route::get('/', 'edit')->name('edit');
                Route::patch('/', 'update')->name('update');
                Route::delete('/', 'destroy')->name('destroy');
            });

        Route::prefix('password')
            ->as('password.')
            ->controller(PasswordController::class)
            ->group(function () {
                Route::get('/', 'edit')->name('edit');
                Route::put('/', 'update')->name('update');
            });

        Route::get('appearance', fn() => Inertia::render('settings/appearance'))->name('appearance');
    });
```

### Route Naming Conventions
- Use dot notation for route names: `resources.index`, `resources.show`
- Use the `->as()` method (alias for `->name()`) for route name prefixes in groups
- Keep route names consistent with resource naming 
