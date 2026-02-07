# Axio Scan - Document Scanner App

## Overview

Axio Scan is an iOS document scanning app built with SwiftUI, featuring cloud sync, PDF tools, and a premium subscription model.

## Architecture & Infrastructure

| Component | Technology |
|-----------|------------|
| **UI Framework** | SwiftUI |
| **Authentication** | Supabase Auth (hybrid: anonymous + email) |
| **Database** | Supabase PostgreSQL |
| **Storage** | Supabase Storage |
| **In-App Purchases** | RevenueCat |
| **Local Storage** | UserDefaults (onboarding state, preferences) |

## Project Structure

```
Scanner/
├── Configuration/
│   ├── SupabaseConfig.swift      # Supabase API keys and bucket names
│   └── RevenueCatConfig.swift    # RevenueCat API key and product IDs
├── Services/
│   ├── AuthenticationService.swift    # Auth (anonymous, email, sign out)
│   ├── DatabaseService.swift          # Document CRUD operations
│   ├── DatabaseClient.swift           # Protocol for database abstraction
│   ├── SupabaseDatabaseClient.swift   # Supabase implementation
│   └── RevenueCatService.swift        # Purchase and subscription handling
├── Models/
│   ├── Database/
│   │   ├── Document.swift
│   │   ├── DocumentPage.swift
│   │   ├── Folder.swift
│   │   ├── Tag.swift
│   │   └── DocumentTag.swift
│   ├── AppColors.swift
│   └── OnboardingPage.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── DocumentsViewModel.swift
│   ├── DocumentEditViewModel.swift
│   └── MainTabViewModel.swift
├── Views/
│   ├── MainTabView.swift
│   ├── HomeView.swift
│   ├── DocumentsView.swift
│   ├── DocumentEditView.swift
│   ├── SettingsView.swift
│   ├── DocumentToolsView.swift
│   ├── PhotoEditTools/
│   │   ├── CropView.swift
│   │   ├── RotateView.swift
│   │   ├── FiltersView.swift
│   │   ├── AdjustView.swift
│   │   ├── SignView.swift
│   │   ├── WatermarkView.swift
│   │   ├── AnnotateView.swift
│   │   └── RemoveBGView.swift
│   └── ...
├── Managers/
│   ├── DocumentExportManager.swift
│   └── MergeManager.swift
└── ScannerApp.swift              # App entry point
```

## Authentication

### Hybrid Auth Model

| State | Description |
|-------|-------------|
| **Anonymous** | Auto-created on first launch. Data stored with anonymous UUID. |
| **Email Linked** | User upgrades via Settings. Same UUID, now with email credentials. |

### Auth Flow

1. **App Launch** → Check if authenticated
2. **Not authenticated** → Sign in anonymously (auto)
3. **User taps "Create Account"** → `linkEmail()` adds credentials to existing UUID
4. **Sign Out** → Signs back in anonymously (new UUID, loses access to old data)

### Key Methods (AuthenticationService)

- `signInAnonymously()` - Create anonymous session
- `signIn(email:password:)` - Email/password login
- `signUp(email:password:)` - New account (not anonymous)
- `linkEmail(email:password:)` - Upgrade anonymous → email account
- `resetPassword(email:)` - Send password reset email
- `signOut()` - End session

## Data Model

### Database Schema

#### Document
| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key to auth.users |
| `name` | String | Document name |
| `created_at` | Timestamp | Creation date |
| `updated_at` | Timestamp | Last modified |
| `folder_id` | UUID? | Optional folder reference |
| `is_favorite` | Boolean | Favorited flag |
| `page_count` | Integer | Number of pages |
| `file_size` | BigInt | Total size in bytes |

#### DocumentPage
| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `document_id` | UUID | Foreign key to Document |
| `user_id` | UUID | Foreign key to auth.users |
| `page_number` | Integer | 1-indexed page number |
| `image_url` | String | Full image storage URL |
| `thumbnail_url` | String? | Thumbnail storage URL |
| `created_at` | Timestamp | Creation date |

#### Folder
| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key |
| `name` | String | Folder name |
| `parent_id` | UUID? | Parent folder (nested) |
| `created_at` | Timestamp | Creation date |

#### Tag
| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key |
| `name` | String | Tag name |
| `color` | String? | Tag color |

#### DocumentTag (Junction)
| Field | Type | Description |
|-------|------|-------------|
| `document_id` | UUID | Foreign key |
| `tag_id` | UUID | Foreign key |

#### UserDevice
| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key to auth.users |
| `fcm_token` | String | Firebase Cloud Messaging token |
| `platform` | String | 'ios' or 'android' |
| `device_name` | String? | Device name (e.g., "iPhone 15 Pro") |
| `created_at` | Timestamp | Creation date |
| `updated_at` | Timestamp | Last modified |

### Storage Buckets

- `documents` - Full resolution images
- `thumbnails` - Thumbnail images

### Row Level Security (RLS)

All tables have RLS enabled. Users can only access their own data via `auth.uid() = user_id` policies.

## Features

### Implemented ✅

#### Scan & Import
- [x] Smart Scan (VisionKit document camera)
- [x] Import Photos (photo library picker)
- [x] Import Files (file picker)

#### PDF Tools
- [x] Merge documents
- [x] Split documents

#### Edit & Enhance
- [x] Crop
- [x] Rotate
- [x] Filters
- [x] Adjust (brightness/contrast)
- [x] Remove Background

#### Sign & Mark
- [x] Digital signatures
- [x] Watermark
- [x] Annotate

#### Export
- [x] Export to PDF
- [x] Export to JPEG
- [x] Export to PNG

#### Organization
- [x] Document list view
- [x] Thumbnail previews
- [x] Favorites
- [x] Delete documents
- [x] Rename documents

#### Account
- [x] Anonymous authentication
- [x] Email account upgrade
- [x] Sign in / Sign out

### Planned 🔲

- [ ] OCR (text recognition)
- [ ] Searchable PDFs
- [ ] Folders
- [ ] Tags
- [ ] Search
- [ ] Premium subscription features

## Monetization (RevenueCat)

### Configuration

```swift
// RevenueCatConfig.swift
struct RevenueCatConfig {
    static let apiKey = "your_api_key"
    static let premiumEntitlement = "premium"
    
    struct Products {
        static let monthlySubscription = "axioscan_premium_monthly"
        static let yearlySubscription = "axioscan_premium_yearly"
    }
}
```

### Premium Features (Planned)

- Unlimited document storage
- Cloud sync across devices
- Advanced editing tools
- No watermarks on exports
- Priority support

## App Navigation

### Tab Bar

1. **Home** - Quick actions, recent documents
2. **Docs** - All documents list
3. **Scan** (floating button) - Document camera
4. **Tools** - All document tools
5. **Settings** - Account, preferences

### Home View Categories

- Scan (Smart Scan, Import Photos, Import Files)
- PDF (Merge, Split)
- Edit (Crop, Rotate, Filters, Adjust, Remove BG)
- Sign (Sign, Watermark, Annotate)
- Export (PDF, JPEG, PNG)
- Organize (New Folder, Tags, Favorites, Search)

## Database Migrations

Located in `/Database/migrations/`:

1. `001_create_tables.sql` - Core tables
2. `002_create_rls_policies.sql` - Row level security
3. `003_create_storage_policies.sql` - Storage bucket policies
4. `004_create_user_device_table.sql` - Push notification tokens

## Dependencies

| Package | Purpose |
|---------|---------|
| Supabase Swift | Database, Auth, Storage |
| RevenueCat | In-app purchases |
