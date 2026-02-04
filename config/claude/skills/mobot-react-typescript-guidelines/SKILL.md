---
name: mobot-react-typescript-guidelines
description: React 19 and TypeScript coding guidelines including component patterns, hooks, type safety, and best practices.
license: MIT
metadata:
   author: moisish
   tags: react, typescript, hooks, components, frontend, react-19
---

# React & TypeScript Development Guidelines

## Table of Contents
- [TypeScript Standards](#typescript-standards)
- [React Component Patterns](#react-component-patterns)
- [Custom Hooks](#custom-hooks)
- [State Management](#state-management)
- [Styling with Tailwind](#styling-with-tailwind)
- [Routing with Wayfinder](#routing-with-wayfinder)
- [API Integration](#api-integration)
- [Type Definitions](#type-definitions)

## TypeScript Standards

### Type Declarations
Use strict TypeScript configuration and explicit typing.

```typescript
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

### Interface vs Type
Prefer interfaces for object shapes, types for unions and computed types.

```typescript
// ✅ Good - Interface for object shapes
interface User {
  id: string;
  name: string;
  email: string;
}

// ✅ Good - Type for unions
type Status = 'loading' | 'success' | 'error';

// ✅ Good - Type for computed types
type UserKeys = keyof User;
```

### Component Props Typing
Use inline typing for simple props, dedicated type files for complex props.

**Decision Rules:**
- **Inline typing**: 1-3 simple parameters, not reused elsewhere
- **Dedicated type files**: Complex interfaces organized in `types/` directory with meaningful filenames

#### Simple Props - Inline Typing
```typescript
// ✅ Good - Simple props inline
function Header({ title }: { title: string }) {
  return <h1>{title}</h1>;
}

function StatusBadge({ 
  status, 
  variant 
}: { 
  status: ResourceStatus; 
  variant?: 'default' | 'outline';
}) {
  return <Badge variant={variant}>{status}</Badge>;
}

// ❌ Bad - Interface for single simple prop
interface HeaderProps {
  title: string;
}
```

#### Complex Props - Dedicated Type Files
For complex interfaces, create dedicated files in the `types/` directory organized by functionality:

```typescript
// types/streaming.ts
export interface ChatStreamChunk {
  type: 'start' | 'chunk' | 'complete' | 'end' | 'error';
  user_message_id?: number;
  content?: string;
  message?: string;
}

export interface UseCustomStreamResult {
  streamChat: (url: string, data: any, callbacks: StreamCallbacks) => Promise<void>;
  isStreaming: boolean;
  error: { message: string } | null;
}

export interface StreamCallbacks {
  onChunk: (chunk: ChatStreamChunk) => void;
  onComplete: (data: any) => void;
  onError: (error: any) => void;
}
```

```typescript
// types/resources.ts
export interface ResourceCardProps {
  resource: Resource;
  onAction: (action: string, resourceId: string) => void;
  isLoading?: boolean;
  className?: string;
}

export interface ResourceFilters {
  status?: ResourceStatus[];
  type?: ResourceType[];
  accountId?: string;
  searchQuery?: string;
}
```

```typescript
// Usage in components
import { ResourceCardProps } from '@/types/resources';
import { StreamCallbacks } from '@/types/streaming';

export const ResourceCard: React.FC<ResourceCardProps> = ({ 
  resource, 
  onAction, 
  isLoading, 
  className 
}) => {
  // Component implementation
};
```

#### Type File Organisation
```
types/
├── index.ts          # Core domain types (User, Resource, etc.)
├── api.ts            # API request/response types
├── forms.ts          # Form validation types
├── streaming.ts      # Streaming functionality types
├── resources.ts      # Resource-related component types
├── scheduling.ts     # Schedule-related types
└── aws.ts           # AWS-specific types
```

### Enum Conventions
Use string enums for better debugging and serialization.

```typescript
// ✅ Good
enum ResourceStatus {
  PENDING = 'pending',
  ACTIVE = 'active',
  STOPPED = 'stopped',
  INACTIVE = 'inactive'
}

// ❌ Bad - numeric enums are less clear
enum ResourceStatus {
  PENDING,
  ACTIVE,
  STOPPED
}
```

### Frontend-Owned Enum Presentation

**Decision**: Backend PHP enums define values only. Frontend owns all presentation concerns (labels, colors, icons). This separation of concerns means:
- Backend: Business logic, validation, storage, raw enum values
- Frontend: Presentation, styling, labels, colors, icons
- Clean boundary between data and presentation

#### How It Works

1. **PHP enums define values** in `app/Enums/`:
```php
// app/Enums/Resource/State.php
enum State: int {
    case Running = 0;
    case Stopped = 1;
    // ...

    // Business logic methods only (canStart, isBillable, etc.)
    // NO color() or icon() methods - those are frontend concerns
}
```

2. **Frontend defines presentation** in `@/lib/enums.ts`:
```tsx
// lib/enums.ts
export const ResourceState = {
    Running: 0,
    Stopped: 1,
    // ...
} as const;

const resourceStateConfigs: Record<ResourceStateValue, ResourceStateConfig> = {
    [ResourceState.Running]: { label: 'Running', color: 'green' },
    [ResourceState.Stopped]: { label: 'Stopped', color: 'gray' },
    // ...
};

export function getResourceStateConfig(state: number): ResourceStateConfig {
    return resourceStateConfigs[state] ?? { label: 'Unknown', color: 'gray' };
}
```

3. **Components use frontend mappings**:
```tsx
import { useResourceState, useResourceType } from '@/hooks/use-enums';

// In component
const stateConfig = useResourceState(resource.state);
// Returns { label: 'Running', color: 'green' }
```

4. **Reusable components**:
```tsx
import { StateBadge } from '@/components/app/features/resources/state-badge';
import { ResourceTypeIcon } from '@/components/app/features/resources/resource-type-icon';

<StateBadge state={resource.state} />
<ResourceTypeIcon type={resource.resource_type} />
```

#### Adding New Enum Values

When adding a new enum value:

1. Add the value to the PHP enum in `app/Enums/`
2. Add the presentation config in `resources/js/lib/enums.ts`

```tsx
// lib/enums.ts - Add new state
export const ResourceState = {
    Running: 0,
    Stopped: 1,
    NewState: 7,  // Add new value
} as const;

const resourceStateConfigs = {
    // ...existing...
    [ResourceState.NewState]: { label: 'New State', color: 'purple' },
};
```

#### Available Hooks and Components

| Hook/Component | Usage |
|----------------|-------|
| `getResourceStateConfig(state)` | Get state label/color (direct) |
| `getResourceTypeConfig(type)` | Get type label/shortLabel/icon/color (direct) |
| `useResourceState(state)` | Get state config (hook wrapper) |
| `useResourceType(type)` | Get type config (hook wrapper) |
| `<StateBadge state={n} />` | Render state badge |
| `<ResourceTypeIcon type={n} />` | Render type icon |

### Generic Constraints
Use generic constraints for better type safety.

```typescript
// ✅ Good
interface ApiResponse<T> {
  data: T;
  message?: string;
  errors?: Record<string, string[]>;
}

interface PaginatedResponse<T> {
  data: T[];
  meta: {
    currentPage: number;
    lastPage: number;
    perPage: number;
    total: number;
  };
}

// ✅ Good - Constrained generic
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}
```

## React Component Patterns

### Component Structure
Use functional components with TypeScript. For simple props, use inline typing. For complex props (4+ properties or reusable types), use interfaces.

#### Simple Props - Inline Typing
For components with simple, non-reusable props (1-3 simple parameters), use inline typing:

```tsx
// ✅ Good - Simple props inline
export default function Dashboard({ needsAwsSetup }: { needsAwsSetup: boolean }) {
  return (
    <div>
      {needsAwsSetup && <AwsSetupBanner />}
      <DashboardContent />
    </div>
  );
}

// ✅ Good - Simple props with 2-3 parameters
function StatusBadge({ 
  status, 
  className 
}: { 
  status: ResourceStatus; 
  className?: string;
}) {
  return <Badge className={`${getStatusColor(status)} ${className}`}>{status}</Badge>;
}

// ❌ Bad - Don't create interface for simple props
interface DashboardProps {
  needsAwsSetup: boolean;
}

export default function Dashboard({ needsAwsSetup }: DashboardProps) {
  // ...
}
```

#### Complex Props - Use Interfaces
For components with complex props (4+ properties, reusable types, or complex objects), use interfaces:

```tsx
// ✅ Good - Complex props with interface
import React from 'react';
import { Resource, ResourceStatus } from '@/types';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';

interface ResourceCardProps {
  resource: Resource;
  onAction: (action: string, resourceId: string) => void;
  isLoading?: boolean;
  className?: string;
}

export const ResourceCard: React.FC<ResourceCardProps> = ({
  resource,
  onAction,
  isLoading = false,
  className = ''
}) => {
  const getStatusColor = (status: ResourceStatus): string => {
    switch (status) {
      case ResourceStatus.ACTIVE:
        return 'bg-green-100 text-green-800';
      case ResourceStatus.STOPPED:
        return 'bg-red-100 text-red-800';
      case ResourceStatus.PENDING:
        return 'bg-yellow-100 text-yellow-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const handleAction = (action: string) => {
    onAction(action, resource.id);
  };

  return (
    <div className={`bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow ${className}`}>
      <div className="flex justify-between items-start mb-4">
        <h3 className="text-lg font-semibold text-gray-900">
          {resource.name}
        </h3>
        <Badge className={getStatusColor(resource.status)}>
          {resource.status}
        </Badge>
      </div>
      
      <div className="space-y-2 mb-4">
        <p className="text-sm text-gray-600">
          Type: {resource.resourceType}
        </p>
        <p className="text-sm text-gray-600">
          ID: {resource.awsResourceId}
        </p>
      </div>
      
      <div className="flex gap-2">
        <Button
          variant="primary"
          size="sm"
          onClick={() => handleAction('start')}
          disabled={isLoading || resource.status === ResourceStatus.ACTIVE}
        >
          Start
        </Button>
        <Button
          variant="secondary"
          size="sm"
          onClick={() => handleAction('stop')}
          disabled={isLoading || resource.status === ResourceStatus.STOPPED}
        >
          Stop
        </Button>
      </div>
    </div>
  );
};
```

### Component Extraction Patterns

When dealing with complex JSX logic (especially in map callbacks or conditional rendering), extract it into a component rather than a render function.

#### Components vs Render Functions

**❌ Bad - Render Functions:**
```tsx
// Don't use plain functions that return JSX
function renderResourceItem(resource: Resource, isSelected: boolean, onToggle: () => void) {
    return (
        <div onClick={onToggle}>
            {/* Complex JSX */}
        </div>
    );
}

// Usage
{resources.map(resource => renderResourceItem(resource, selected, toggle))}
```

**Problems with render functions:**
- Can't use React hooks
- Can't be memoized with `React.memo`
- Don't appear properly in React DevTools
- Not idiomatic React
- Many parameters (code smell)

**✅ Good - Components Within Same File:**
```tsx
// Extract as a component in the same file
interface ResourceItemProps {
    resource: Resource;
    isSelected: boolean;
    onToggle: () => void;
}

function ResourceItem({ resource, isSelected, onToggle }: ResourceItemProps) {
    return (
        <div onClick={onToggle}>
            {/* Complex JSX */}
        </div>
    );
}

// Parent component
export default function ResourceList() {
    return (
        <div>
            {resources.map(resource => (
                <ResourceItem
                    key={resource.id}
                    resource={resource}
                    isSelected={selectedIds.includes(resource.id)}
                    onToggle={() => handleToggle(resource.id)}
                />
            ))}
        </div>
    );
}
```

**Benefits of components:**
- ✅ Can use React hooks if needed later
- ✅ Can be wrapped with `React.memo` for performance
- ✅ Shows up properly in React DevTools
- ✅ Props interface is cleaner than function parameters
- ✅ Follows React best practices
- ✅ More maintainable and testable

#### When to Extract Components

Extract logic into a component (within the same file) when:
- Map callbacks exceed 10-15 lines
- Complex conditional rendering
- Repeated JSX patterns
- Logic that might benefit from memoization

```tsx
// Before: Complex inline map
export default function ScheduleCreate() {
    return (
        <div>
            {availableResources.map((resource) => {
                const typeConfig = getResourceTypeConfig(resource.type);
                const stateConfig = getResourceStateConfig(resource.state);
                const isSelected = selectedIds.includes(resource.uuid);
                const isLocked = !isSelected && remainingSlots === 0;

                return (
                    <div key={resource.uuid} /* ...20+ lines of JSX... */>
                        {/* Complex nested structure */}
                    </div>
                );
            })}
        </div>
    );
}

// After: Extracted component
interface ResourcesListProps {
    availableResources: Resource[];
    selectedIds: string[];
    remainingSlots: number;
    onToggle: (id: string) => void;
}

function ResourcesList({ availableResources, selectedIds, remainingSlots, onToggle }: ResourcesListProps) {
    return (
        <div className="space-y-2">
            {availableResources.map((resource) => {
                const typeConfig = getResourceTypeConfig(resource.type);
                const stateConfig = getResourceStateConfig(resource.state);
                const isSelected = selectedIds.includes(resource.uuid);
                const isLocked = !isSelected && remainingSlots === 0;

                return (
                    <div key={resource.uuid} /* ...complex JSX... */>
                        {/* Complex nested structure */}
                    </div>
                );
            })}
        </div>
    );
}

export default function ScheduleCreate() {
    return (
        <div>
            <ResourcesList
                availableResources={availableResources}
                selectedIds={selectedIds}
                remainingSlots={remainingSlots}
                onToggle={handleToggle}
            />
        </div>
    );
}
```

#### Same File vs Separate File

**Keep component in the same file when:**
- Component is only used in one place
- Tightly coupled to parent's logic
- Not a reusable UI component

**Move to separate file when:**
- Component is reused across multiple pages/components
- Component is a generic UI element (buttons, cards, modals)
- Component has substantial complexity (100+ lines)
- Component benefits from isolated testing

```tsx
// ✅ Good - Keep in same file (single-use)
function ResourcesList({ ... }: ResourcesListProps) { /* ... */ }

export default function ScheduleCreate() {
    return <ResourcesList {...props} />;
}

// ✅ Good - Separate file (reusable)
// components/resource-list.tsx
export function ResourcesList({ ... }: ResourcesListProps) { /* ... */ }

// Multiple pages import and use it
```

### Component Composition
Create reusable UI components with proper composition patterns.

```tsx
// components/ui/Button.tsx
import React from 'react';
import { cva, type VariantProps } from 'class-variance-authority';

const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        primary: 'bg-blue-600 text-white hover:bg-blue-700',
        secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300',
        destructive: 'bg-red-600 text-white hover:bg-red-700',
        outline: 'border border-gray-300 bg-white hover:bg-gray-50',
      },
      size: {
        sm: 'h-8 px-3 text-xs',
        md: 'h-10 px-4',
        lg: 'h-12 px-6 text-lg',
      },
    },
    defaultVariants: {
      variant: 'primary',
      size: 'md',
    },
  }
);

interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  children: React.ReactNode;
}

export const Button: React.FC<ButtonProps> = ({
  className,
  variant,
  size,
  children,
  ...props
}) => {
  return (
    <button
      className={buttonVariants({ variant, size, className })}
      {...props}
    >
      {children}
    </button>
  );
};
```

### Error Boundaries
Implement error boundaries for better error handling.

```tsx
// components/ErrorBoundary.tsx
import React from 'react';

interface ErrorBoundaryState {
  hasError: boolean;
  error?: Error;
}

interface ErrorBoundaryProps {
  children: React.ReactNode;
  fallback?: React.ComponentType<{ error: Error }>;
}

export class ErrorBoundary extends React.Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      const FallbackComponent = this.props.fallback || DefaultErrorFallback;
      return <FallbackComponent error={this.state.error!} />;
    }

    return this.props.children;
  }
}

const DefaultErrorFallback: React.FC<{ error: Error }> = ({ error }) => (
  <div className="p-4 border border-red-300 rounded-md bg-red-50">
    <h2 className="text-lg font-semibold text-red-800">Something went wrong</h2>
    <p className="text-red-700">{error.message}</p>
  </div>
);
```

## Custom Hooks

### Data Fetching Hooks
Create custom hooks for API interactions.

```tsx
// hooks/useResources.ts
import { useState, useEffect, useCallback } from 'react';
import { Resource, ApiResponse, PaginatedResponse } from '@/types';
import { apiClient } from '@/lib/api';

interface UseResourcesOptions {
  accountId?: string;
  status?: string;
  autoFetch?: boolean;
}

interface UseResourcesReturn {
  resources: Resource[];
  isLoading: boolean;
  error: string | null;
  pagination: PaginatedResponse<Resource>['meta'] | null;
  refetch: () => Promise<void>;
  executeAction: (action: string, resourceId: string) => Promise<void>;
}

export const useResources = (options: UseResourcesOptions = {}): UseResourcesReturn => {
  const { accountId, status, autoFetch = true } = options;
  
  const [resources, setResources] = useState<Resource[]>([]);
  const [pagination, setPagination] = useState<PaginatedResponse<Resource>['meta'] | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchResources = useCallback(async () => {
    try {
      setIsLoading(true);
      setError(null);
      
      const params = new URLSearchParams();
      if (accountId) params.append('account_id', accountId);
      if (status) params.append('status', status);

      const response = await apiClient.get<PaginatedResponse<Resource>>(
        `/resources?${params.toString()}`
      );
      
      setResources(response.data.data);
      setPagination(response.data.meta);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to fetch resources';
      setError(errorMessage);
    } finally {
      setIsLoading(false);
    }
  }, [accountId, status]);

  const executeAction = useCallback(async (action: string, resourceId: string) => {
    try {
      await apiClient.post<ApiResponse<void>>(`/resources/${resourceId}/actions`, { action });
      await fetchResources(); // Refresh the list
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Action failed';
      setError(errorMessage);
      throw err; // Re-throw to allow component-level error handling
    }
  }, [fetchResources]);

  useEffect(() => {
    if (autoFetch) {
      fetchResources();
    }
  }, [fetchResources, autoFetch]);

  return {
    resources,
    isLoading,
    error,
    pagination,
    refetch: fetchResources,
    executeAction
  };
};
```

### Form Hooks
Create hooks for form state management.

```tsx
// hooks/useForm.ts
import { useState, useCallback } from 'react';

interface UseFormOptions<T> {
  initialValues: T;
  validate?: (values: T) => Partial<Record<keyof T, string>>;
  onSubmit: (values: T) => Promise<void> | void;
}

interface UseFormReturn<T> {
  values: T;
  errors: Partial<Record<keyof T, string>>;
  isSubmitting: boolean;
  handleChange: (name: keyof T) => (value: T[keyof T]) => void;
  handleSubmit: (e: React.FormEvent) => Promise<void>;
  reset: () => void;
  setFieldValue: (name: keyof T, value: T[keyof T]) => void;
  setFieldError: (name: keyof T, error: string) => void;
}

export const useForm = <T extends Record<string, any>>(
  options: UseFormOptions<T>
): UseFormReturn<T> => {
  const { initialValues, validate, onSubmit } = options;
  
  const [values, setValues] = useState<T>(initialValues);
  const [errors, setErrors] = useState<Partial<Record<keyof T, string>>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleChange = useCallback((name: keyof T) => (value: T[keyof T]) => {
    setValues(prev => ({ ...prev, [name]: value }));
    // Clear error when user starts typing
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: undefined }));
    }
  }, [errors]);

  const setFieldValue = useCallback((name: keyof T, value: T[keyof T]) => {
    setValues(prev => ({ ...prev, [name]: value }));
  }, []);

  const setFieldError = useCallback((name: keyof T, error: string) => {
    setErrors(prev => ({ ...prev, [name]: error }));
  }, []);

  const handleSubmit = useCallback(async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (validate) {
      const validationErrors = validate(values);
      setErrors(validationErrors);
      
      if (Object.keys(validationErrors).length > 0) {
        return;
      }
    }

    try {
      setIsSubmitting(true);
      await onSubmit(values);
    } catch (error) {
      // Handle submission errors
      console.error('Form submission error:', error);
    } finally {
      setIsSubmitting(false);
    }
  }, [values, validate, onSubmit]);

  const reset = useCallback(() => {
    setValues(initialValues);
    setErrors({});
    setIsSubmitting(false);
  }, [initialValues]);

  return {
    values,
    errors,
    isSubmitting,
    handleChange,
    handleSubmit,
    reset,
    setFieldValue,
    setFieldError
  };
};
```

## State Management

### Context for Global State
Use React Context for global application state.

```tsx
// contexts/AppContext.tsx
import React, { createContext, useContext, useReducer } from 'react';
import { User, AwsAccount } from '@/types';

interface AppState {
  user: User | null;
  selectedAccount: AwsAccount | null;
  theme: 'light' | 'dark';
  isLoading: boolean;
}

type AppAction =
  | { type: 'SET_USER'; payload: User | null }
  | { type: 'SET_SELECTED_ACCOUNT'; payload: AwsAccount | null }
  | { type: 'SET_THEME'; payload: 'light' | 'dark' }
  | { type: 'SET_LOADING'; payload: boolean };

const initialState: AppState = {
  user: null,
  selectedAccount: null,
  theme: 'light',
  isLoading: false,
};

const appReducer = (state: AppState, action: AppAction): AppState => {
  switch (action.type) {
    case 'SET_USER':
      return { ...state, user: action.payload };
    case 'SET_SELECTED_ACCOUNT':
      return { ...state, selectedAccount: action.payload };
    case 'SET_THEME':
      return { ...state, theme: action.payload };
    case 'SET_LOADING':
      return { ...state, isLoading: action.payload };
    default:
      return state;
  }
};

interface AppContextType {
  state: AppState;
  dispatch: React.Dispatch<AppAction>;
  actions: {
    setUser: (user: User | null) => void;
    setSelectedAccount: (account: AwsAccount | null) => void;
    setTheme: (theme: 'light' | 'dark') => void;
    setLoading: (loading: boolean) => void;
  };
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [state, dispatch] = useReducer(appReducer, initialState);

  const actions = {
    setUser: (user: User | null) => dispatch({ type: 'SET_USER', payload: user }),
    setSelectedAccount: (account: AwsAccount | null) => 
      dispatch({ type: 'SET_SELECTED_ACCOUNT', payload: account }),
    setTheme: (theme: 'light' | 'dark') => dispatch({ type: 'SET_THEME', payload: theme }),
    setLoading: (loading: boolean) => dispatch({ type: 'SET_LOADING', payload: loading }),
  };

  return (
    <AppContext.Provider value={{ state, dispatch, actions }}>
      {children}
    </AppContext.Provider>
  );
};

export const useApp = (): AppContextType => {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
};
```

## Styling with Tailwind

### Component Styling Patterns
Use Tailwind utility classes with consistent patterns.

```tsx
// components/ui/Card.tsx
import React from 'react';
import { cva, type VariantProps } from 'class-variance-authority';

const cardVariants = cva(
  'rounded-lg shadow-sm border',
  {
    variants: {
      variant: {
        default: 'bg-white border-gray-200',
        secondary: 'bg-gray-50 border-gray-200',
        outline: 'bg-transparent border-gray-300',
      },
      size: {
        sm: 'p-4',
        md: 'p-6',
        lg: 'p-8',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'md',
    },
  }
);

interface CardProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof cardVariants> {
  children: React.ReactNode;
}

export const Card: React.FC<CardProps> = ({
  className,
  variant,
  size,
  children,
  ...props
}) => {
  return (
    <div className={cardVariants({ variant, size, className })} {...props}>
      {children}
    </div>
  );
};

// Usage in components
const ResourceList: React.FC = () => {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {resources.map(resource => (
        <Card key={resource.id} className="hover:shadow-md transition-shadow">
          <ResourceCard resource={resource} onAction={handleAction} />
        </Card>
      ))}
    </div>
  );
};
```

### Responsive Design Patterns
```tsx
// components/ResponsiveGrid.tsx
interface ResponsiveGridProps {
  children: React.ReactNode;
  className?: string;
}

export const ResponsiveGrid: React.FC<ResponsiveGridProps> = ({
  children,
  className = ''
}) => {
  return (
    <div className={`
      grid gap-4
      grid-cols-1
      sm:grid-cols-2
      lg:grid-cols-3
      xl:grid-cols-4
      ${className}
    `}>
      {children}
    </div>
  );
};
```

### Theme Support
```tsx
// hooks/useTheme.ts
import { useApp } from '@/contexts/AppContext';

export const useTheme = () => {
  const { state, actions } = useApp();

  const toggleTheme = () => {
    const newTheme = state.theme === 'light' ? 'dark' : 'light';
    actions.setTheme(newTheme);
    localStorage.setItem('theme', newTheme);
  };

  return {
    theme: state.theme,
    setTheme: actions.setTheme,
    toggleTheme,
  };
};
```

## Routing with Wayfinder

This project uses [Laravel Wayfinder](https://github.com/laravel/wayfinder) for type-safe routing. Wayfinder generates TypeScript route definitions from Laravel routes, providing autocompletion and type safety.

### Never Use Hardcoded URLs

**Always use Wayfinder route functions instead of hardcoded URL strings.**

```tsx
// ❌ Bad - Hardcoded URLs
<Link href="/dashboard">Dashboard</Link>
<Link href="/resources">Resources</Link>
<Link href={`/resources/${uuid}`}>View Resource</Link>
router.visit('/resources?state=0');

// ✅ Good - Wayfinder routes
import { dashboard } from '@/routes';
import { index as resourcesIndex, show as resourcesShow } from '@/routes/resources';

<Link href={dashboard()}>Dashboard</Link>
<Link href={resourcesIndex()}>Resources</Link>
<Link href={resourcesShow(uuid)}>View Resource</Link>
router.visit(resourcesIndex.url({ query: { state: '0' } }));
```

### Importing Routes

Routes are auto-generated by Wayfinder and located in `resources/js/routes/`. Import them by their function name:

```tsx
// Import from root routes
import { dashboard, home, login, register, appearance } from '@/routes';

// Import from nested route files
import { index as resourcesIndex, show as resourcesShow } from '@/routes/resources';
import { edit as editProfile, update as updateProfile } from '@/routes/profile';
import { edit as editPassword, update as updatePassword } from '@/routes/settings/password';
import { show as showTwoFactor, enable, disable } from '@/routes/two-factor';
```

### Route Function Patterns

Wayfinder route functions return `RouteDefinition` objects that are compatible with Inertia's `Link` component:

```tsx
// Basic route (no parameters)
dashboard()           // Returns RouteDefinition for /dashboard

// Route with parameters
resourcesShow(uuid)   // Returns RouteDefinition for /resources/{uuid}

// Route with query parameters
resourcesIndex({ query: { state: '0', type: '1' } })

// Get URL string only (for router.visit or native elements)
resourcesIndex.url()                           // '/resources'
resourcesIndex.url({ query: { state: '0' } })  // '/resources?state=0'
```

### Using Routes with Link Components

```tsx
import { Link } from '@inertiajs/react';
import { dashboard } from '@/routes';
import { show as resourcesShow } from '@/routes/resources';

// Link component accepts RouteDefinition directly
<Link href={dashboard()}>Dashboard</Link>
<Link href={resourcesShow(resource.uuid)}>View</Link>
```

### Using Routes with router.visit

When using `router.visit`, use the `.url()` method to get the URL string:

```tsx
import { router } from '@inertiajs/react';
import { index as resourcesIndex } from '@/routes/resources';

// Navigate with query parameters
router.visit(resourcesIndex.url({ query: { state: '0' } }));

// Navigate without parameters
router.visit(resourcesIndex.url());
```

### Using Routes in Types

The `NavItem` and `BreadcrumbItem` types accept `RouteDefinition` objects via the `InertiaLinkProps['href']` type:

```tsx
import { type InertiaLinkProps } from '@inertiajs/react';

interface NavItem {
    title: string;
    href: NonNullable<InertiaLinkProps['href']>;  // Accepts string or RouteDefinition
    icon?: LucideIcon | null;
}

interface BreadcrumbItem {
    title: string;
    href: NonNullable<InertiaLinkProps['href']>;
}
```

### Helper Functions

Use the `resolveUrl` and `isSameUrl` helpers when you need to work with URL strings:

```tsx
import { resolveUrl, isSameUrl } from '@/lib/utils';

// Convert RouteDefinition or string to URL string
const url = resolveUrl(item.href);  // '/dashboard'

// Compare URLs regardless of type
if (isSameUrl(page.url, item.href)) {
    // Active state logic
}
```

### Generating Routes

Routes are generated with Laravel Wayfinder. After adding or modifying routes in Laravel, regenerate the TypeScript definitions:

```bash
php artisan wayfinder:generate
```

This command generates route files in `resources/js/routes/`.

## API Integration

### API Client Setup
```typescript
// lib/api.ts
import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios';

class ApiClient {
  private instance: AxiosInstance;

  constructor() {
    this.instance = axios.create({
      baseURL: '/api',
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    });

    this.setupInterceptors();
  }

  private setupInterceptors() {
    // Request interceptor for auth token
    this.instance.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem('auth_token');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Response interceptor for error handling
    this.instance.interceptors.response.use(
      (response) => response,
      (error) => {
        if (error.response?.status === 401) {
          // Handle unauthorized - redirect to login
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );
  }

  async get<T>(url: string, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> {
    return this.instance.get<T>(url, config);
  }

  async post<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> {
    return this.instance.post<T>(url, data, config);
  }

  async put<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> {
    return this.instance.put<T>(url, data, config);
  }

  async delete<T>(url: string, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> {
    return this.instance.delete<T>(url, config);
  }
}

export const apiClient = new ApiClient();
```

## Type Definitions

### File Organisation Structure
Organize types in dedicated files within the `types/` directory, grouped by functionality:

### Core Domain Types
```typescript
// types/index.ts - Core business domain types
export enum ResourceStatus {
  PENDING = 'pending',
  ACTIVE = 'active',
  STOPPED = 'stopped',
  INACTIVE = 'inactive'
}

export enum ResourceType {
  EC2 = 'ec2',
  RDS = 'rds',
  ECS = 'ecs',
  LAMBDA = 'lambda',
  ELASTICACHE = 'elasticache'
}

export interface Resource {
  id: string;
  name: string;
  awsResourceId: string;
  resourceType: ResourceType;
  status: ResourceStatus;
  awsAccount: AwsAccount;
  lastDiscoveredAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface AwsAccount {
  id: string;
  name: string;
  accountId: string;
  region: string;
  status: string;
  roleArn: string;
  externalId: string;
}

export interface User {
  id: string;
  name: string;
  email: string;
  emailVerifiedAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Schedule {
  id: string;
  name: string;
  description?: string;
  isActive: boolean;
  timezone: string;
  scheduleConfig: {
    startTime: string;
    stopTime: string;
    days: number[];
  };
  resources: Resource[];
  user: User;
  createdAt: string;
  updatedAt: string;
}
```

### API Types
```typescript
// types/api.ts - API request/response types
export interface ApiResponse<T> {
  data: T;
  message?: string;
  errors?: Record<string, string[]>;
}

export interface PaginatedResponse<T> {
  data: T[];
  meta: {
    currentPage: number;
    lastPage: number;
    perPage: number;
    total: number;
  };
  links: {
    first: string;
    last: string;
    prev?: string;
    next?: string;
  };
}

export interface ApiError {
  message: string;
  errors?: Record<string, string[]>;
  code?: string;
}
```

### Form Types
```typescript
// types/forms.ts - Form validation and data types
export interface LoginForm {
  email: string;
  password: string;
  remember: boolean;
}

export interface RegisterForm {
  name: string;
  email: string;
  password: string;
  passwordConfirmation: string;
}

export interface ResourceForm {
  name: string;
  awsAccountId: string;
  awsResourceId: string;
  resourceType: ResourceType;
}

export interface ScheduleForm {
  name: string;
  description?: string;
  timezone: string;
  startTime: string;
  stopTime: string;
  days: number[];
  resourceIds: string[];
}
```

### Component-Specific Types
```typescript
// types/resources.ts - Resource component types
export interface ResourceCardProps {
  resource: Resource;
  onAction: (action: string, resourceId: string) => void;
  isLoading?: boolean;
  className?: string;
}

export interface ResourceFilters {
  status?: ResourceStatus[];
  type?: ResourceType[];
  accountId?: string;
  searchQuery?: string;
}

export interface ResourceTableColumn {
  key: keyof Resource;
  label: string;
  sortable?: boolean;
  width?: string;
}
```

### Feature-Specific Types
```typescript
// types/streaming.ts - Streaming functionality types  
export interface ChatStreamChunk {
  type: 'start' | 'chunk' | 'complete' | 'end' | 'error';
  user_message_id?: number;
  content?: string;
  message?: string;
}

export interface UseCustomStreamResult {
  streamChat: (url: string, data: any, callbacks: StreamCallbacks) => Promise<void>;
  isStreaming: boolean;
  error: { message: string } | null;
}

export interface StreamCallbacks {
  onChunk: (chunk: ChatStreamChunk) => void;
  onComplete: (data: any) => void;
  onError: (error: any) => void;
}
```

### Utility Types
```typescript
// types/utils.ts
// Make all properties optional
export type Partial<T> = {
  [P in keyof T]?: T[P];
};

// Pick specific properties
export type Pick<T, K extends keyof T> = {
  [P in K]: T[P];
};

// Omit specific properties
export type Omit<T, K extends keyof T> = Pick<T, Exclude<keyof T, K>>;

// Create form types from models
export type CreateResourceForm = Omit<Resource, 'id' | 'createdAt' | 'updatedAt' | 'awsAccount'>;
export type UpdateResourceForm = Partial<CreateResourceForm>;

// Event handler types
export type EventHandler<T = void> = () => T;
export type EventHandlerWithParam<P, T = void> = (param: P) => T;

// Async event handlers
export type AsyncEventHandler = () => Promise<void>;
export type AsyncEventHandlerWithParam<P> = (param: P) => Promise<void>;
```

## Performance Optimizations

### Component Memoization
```tsx
// Use React.memo for components that receive stable props
export const ResourceCard = React.memo<ResourceCardProps>(({ 
  resource, 
  onAction, 
  isLoading 
}) => {
  // Component implementation
}, (prevProps, nextProps) => {
  // Custom comparison function if needed
  return (
    prevProps.resource.id === nextProps.resource.id &&
    prevProps.resource.status === nextProps.resource.status &&
    prevProps.isLoading === nextProps.isLoading
  );
});

// Use useMemo and useCallback for expensive computations
const ExpensiveComponent: React.FC<{ items: Item[] }> = ({ items }) => {
  const expensiveValue = useMemo(() => {
    return items.reduce((acc, item) => acc + item.value, 0);
  }, [items]);

  const handleItemClick = useCallback((itemId: string) => {
    // Handle click
  }, []);

  return (
    <div>
      {/* Component content */}
    </div>
  );
};
```

### Lazy Loading
```tsx
// Lazy load components for code splitting
import { lazy, Suspense } from 'react';

const ResourceDashboard = lazy(() => import('@/pages/ResourceDashboard'));
const ScheduleManager = lazy(() => import('@/pages/ScheduleManager'));

const App: React.FC = () => {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <Routes>
        <Route path="/resources" element={<ResourceDashboard />} />
        <Route path="/schedules" element={<ScheduleManager />} />
      </Routes>
    </Suspense>
  );
};
``` 
