# Services Architecture

This folder contains services that handle external operations and business logic.

## Architecture Patterns

### Database Service - Protocol Abstraction (Database-Agnostic)

**Files:**
- `DatabaseClient.swift` - Protocol defining database operations interface
- `SupabaseDatabaseClient.swift` - Supabase-specific implementation
- `DatabaseService.swift` - Service that uses the protocol (database-agnostic)

**Pattern:** Protocol abstraction allows the service to work with any database implementation.

**Benefits:**
- **Testable** - Easy to create `MockDatabaseClient` for testing
- **Flexible** - Can switch database providers without changing service code
- **Future-proof** - Easy to add other implementations (Firebase, custom, etc.)

**Usage:**
```swift
let service = DatabaseService(client: SupabaseDatabaseClient())
// Or for testing:
let service = DatabaseService(client: MockDatabaseClient())
```

### Authentication Service - Direct Injection (Simpler, Still Testable)

**Files:**
- `AuthService.swift` - Direct Supabase Auth integration

**Pattern:** Direct service implementation with dependency injection.

**Benefits:**
- **Simpler** - Less abstraction, easier to understand
- **Still testable** - Can inject mock service for testing
- **Focused** - Only handles Supabase Auth (no need for multiple implementations)

**Usage:**
```swift
let authService = AuthService()
// Or for testing:
let authService = MockAuthService()
```

## Why Different Patterns?

- **DatabaseService** uses protocol abstraction because we might want to support multiple database backends or need extensive testing flexibility.
- **AuthService** uses direct injection because we're only using Supabase Auth and want a simpler, more straightforward implementation while still maintaining testability.

Both patterns support dependency injection and are testable, but serve different needs based on complexity and flexibility requirements.
