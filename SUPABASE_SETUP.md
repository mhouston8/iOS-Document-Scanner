# Supabase Setup Instructions

## 1. Add Supabase Swift Package

1. Open Xcode
2. Go to **File** → **Add Package Dependencies...**
3. Enter the Supabase Swift package URL:
   ```
   https://github.com/supabase/supabase-swift
   ```
4. Select version: **Latest** or specific version
5. Add the **Supabase** product to your Scanner target

## 2. Configure Supabase Credentials

1. Get your Supabase project URL and anon key:
   - Go to https://app.supabase.com
   - Select your project
   - Go to **Settings** → **API**
   - Copy the **Project URL** and **anon/public key**

2. Update `SupabaseConfig.swift`:
   ```swift
   static let url = "https://your-project.supabase.co"
   static let anonKey = "your-anon-key-here"
   ```

## 3. Uncomment Supabase Code

After adding the package, uncomment the Supabase imports and initialization code in:
- `SupabaseManager.swift`
- `SupabaseDatabaseClient.swift`
- `AuthenticationService.swift`

## 4. Create Database Tables

Run the SQL migrations in Supabase to create the tables:
- `Document`
- `DocumentPage`
- `Folder`
- `Tag`
- `DocumentTag`

See `Documentation/Features.md` for the schema.

## 5. Create Storage Buckets

In Supabase Dashboard:
1. Go to **Storage**
2. Create buckets:
   - `documents` (private)
   - `thumbnails` (private or public)

## 6. Set Up Row Level Security (RLS)

Enable RLS policies so users can only access their own data.
