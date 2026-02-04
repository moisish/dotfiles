---
name: mobot-testing-guidelines
description: Testing guidelines for PHP, Laravel, and JavaScript including unit tests, feature tests, and best practices.
license: MIT
metadata:
   author: moisish
   tags: testing, php, laravel, pest, phpunit, jest
---

# Testing Guidelines

This document outlines the testing standards and patterns used in ParkMyAws.

## Testing Framework

- **Pest PHP**: Primary testing framework for feature and unit tests
- **Factories**: Use Laravel factories for model creation in tests
- **Feature Tests**: Test complete user workflows and integrations
- **Unit Tests**: Test individual classes and methods in isolation

## Laravel 12 Mocking

Use Laravel 12's improved mocking syntax for better readability:

```php
// ✅ Laravel 12 syntax
$mock = $this->mock(SomeService::class, function (MockInterface $mock) {
    $mock->expects('methodName')
        ->once()
        ->with('parameter')
        ->andReturn('result');
});

// ❌ Old Mockery syntax
$mock = Mockery::mock(SomeService::class);
$mock->shouldReceive('methodName')->once()->with('parameter')->andReturn('result');
$this->app->instance(SomeService::class, $mock);
```

## AWS Service Testing

```php
use App\Services\AWS\Fake\Aws;

test('AWS service integration', function (): void {
    $mock = $this->mock(STS::class, function (MockInterface $mock) {
        $mock->expects('verifyConnection')
            ->once()
            ->with('role-arn', 'session-name', 'external-id', 'region')
            ->andReturn(['Account' => '123456789012']);
    });

    // Your test code...
});
```

## Database Testing

### Factories

Use factories for creating test data:

```php
// Create with default attributes
$user = User::factory()->create();

// Override specific attributes
$account = AwsAccount::factory()->create([
    'owner_id' => $user->getKey(),
    'status' => AwsAccountStatus::ACTIVE,
]);

// Create multiple records
$accounts = AwsAccount::factory()->count(3)->create();
```

### Database Assertions

```php
// Assert record exists
$this->assertDatabaseHas('aws_accounts', [
    'owner_id' => $user->getKey(),
    'status' => AwsAccountStatus::ACTIVE->value,
]);

// Assert record doesn't exist
$this->assertDatabaseMissing('aws_accounts', [
    'status' => AwsAccountStatus::INACTIVE->value,
]);

// Count records
$this->assertDatabaseCount('aws_accounts', 1);
```

## Feature Test Patterns

### Authentication Tests

```php
test('unauthenticated users cannot access resource', function (): void {
    $this->get(route('resource.index'))
        ->assertRedirect(route('login'));
});

test('authenticated users can access resource', function (): void {
    $user = User::factory()->create();
    
    $this->actingAs($user)
        ->get(route('resource.index'))
        ->assertOk();
});
```

### Form Validation Tests

```php
test('form requires valid input', function (): void {
    $user = User::factory()->create();

    $this->actingAs($user)
        ->post(route('resource.store'), [
            'field' => '', // Invalid data
        ])
        ->assertSessionHasErrors(['field']);
});
```

### API Tests

```php
test('API returns JSON response', function (): void {
    $user = User::factory()->create();

    $this->actingAs($user)
        ->getJson(route('api.resource.index'))
        ->assertOk()
        ->assertJsonStructure([
            'data' => [
                '*' => ['id', 'name', 'created_at'],
            ],
        ]);
});
```

### Inertia Tests

Use typed assertions for better IDE support and type safety:

```php
use Inertia\Testing\AssertableInertia as Assert;

test('page renders with correct props', function (): void {
    $user = User::factory()->create();

    $this->actingAs($user)
        ->get(route('resources.index'))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page
            ->component('resources/index')
            ->has('resources')
            ->has('filters')
        );
});

test('page passes specific data', function (): void {
    $user = User::factory()->create();
    $account = AwsAccount::factory()->create(['owner_id' => $user->getKey()]);
    $resource = Resource::factory()->create(['aws_account_id' => $account->getKey()]);

    $this->actingAs($user)
        ->get(route('resources.index'))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page
            ->component('resources/index')
            ->has('resources.data', 1)
            ->where('resources.data.0.uuid', $resource->uuid)
        );
});
```

Always import and type the `Assert` parameter:

```php
// ✅ Correct - typed parameter
->assertInertia(fn (Assert $page) => $page->component('dashboard'))

// ❌ Avoid - untyped parameter
->assertInertia(fn ($page) => $page->component('dashboard'))
```

### Route Helpers vs Hardcoded URLs

**Always use `route()` helper in tests** instead of hardcoded URLs for better maintainability:

```php
// ✅ GOOD - Uses route helper
$this->get(route('aws-accounts.index'))->assertOk();
$this->post(route('schedules.store'), $data)->assertRedirect(route('schedules.index'));

// ❌ AVOID - Hardcoded URLs
$this->get('/aws-accounts')->assertOk();
$this->post('/schedules', $data)->assertRedirect('/schedules');
```

**Benefits of route() helper:**
1. **Refactor-proof** - Change URL in routes file, tests automatically updated
2. **Type-safe** - IDE autocomplete helps catch typos
3. **Self-documenting** - Route name clearly shows intent
4. **Consistent** - Matches how URLs are generated in application code

**When to use hardcoded URLs:**
- Testing 404 handling for invalid URLs
- Testing redirects to external URLs
- Explicitly testing URL structure itself

**Example:**
```php
// ✅ Use route() for app routes
test('authenticated users can view dashboard', function (): void {
    $this->actingAs(User::factory()->create())
        ->get(route('dashboard'))
        ->assertOk();
});

// ✅ Use URL when testing 404
test('returns 404 for invalid resource', function (): void {
    $this->actingAs(User::factory()->create())
        ->get('/invalid-page')
        ->assertNotFound();
});
```

## Unit Test Patterns

### Service Tests

```php
test('service method processes data correctly', function (): void {
    $service = new SomeService();
    
    $result = $service->processData(['input' => 'value']);
    
    expect($result)->toBe('expected_output');
});
```

### Model Tests

```php
test('model has correct relationships', function (): void {
    $user = User::factory()->create();
    $account = AwsAccount::factory()->create(['owner_id' => $user->getKey()]);

    expect($user->awsAccounts)->toHaveCount(1);
    expect($account->owner)->toBeInstanceOf(User::class);
});
```

## Test Organisation

### File Structure

```
tests/
├── Feature/              # Integration tests
│   ├── Auth/            # Authentication tests
│   ├── AwsAccount/      # AWS account tests
│   ├── Resource/        # Resource tests (one file per Action)
│   ├── Schedule/        # Schedule tests (one file per Job)
│   └── Settings/        # Settings page tests
├── Unit/                # Unit tests
│   ├── Enums/          # Enum tests
│   └── Services/       # Service class tests
└── Pest.php            # Test configuration
```

### One Test File Per Class

Create a separate test file for each Action, Job, or other testable class:

```
app/Actions/Resource/StartResource.php    → tests/Feature/Resource/StartResourceTest.php
app/Actions/Resource/StopResource.php     → tests/Feature/Resource/StopResourceTest.php
app/Jobs/StartResourceJob.php             → tests/Feature/Schedule/StartResourceJobTest.php
app/Jobs/StopResourceJob.php              → tests/Feature/Schedule/StopResourceJobTest.php
```

Do not group multiple Actions or Jobs into a single test file. Each class gets its own dedicated test file.

### Test Naming

- Use descriptive test names that explain what is being tested
- Use snake_case for test function names
- Group related tests for the same class in one file (not multiple classes)

```php
// ✅ Good test names
test('authenticated users can create AWS accounts with valid data')
test('AWS account creation requires valid role ARN')
test('unauthenticated users cannot access dashboard')

// ❌ Poor test names
test('test create account')
test('validation')
test('auth test')
```

## Continuous Integration

Tests run automatically on:
- Pull requests
- Pushes to main branch
- Scheduled runs (daily)

All tests must pass before code can be merged to main branch.
