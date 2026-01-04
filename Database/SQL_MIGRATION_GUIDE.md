# SQL Migration Guide

This guide shows how to run the SQL migration files to set up your Supabase database.

## Prerequisites

- Supabase project created
- Access to Supabase Dashboard
- SQL Editor access

## Steps

### 1. Open SQL Editor

1. Go to your Supabase Dashboard: https://app.supabase.com
2. Select your project
3. Click on **SQL Editor** in the left sidebar
4. Click **"New query"**

### 2. Run First Migration (Create Tables)

1. Open the file: `Database/migrations/001_create_tables.sql`
2. Copy the entire contents
3. Paste into the SQL Editor in Supabase
4. Click **"Run"** (or press Cmd/Ctrl + Enter)
5. Wait for success message: "Success. No rows returned"

**What this does:**
- Creates all database tables (Folder, Document, DocumentPage, Tag, DocumentTag)
- Sets up indexes for performance
- Creates triggers for auto-updating `updated_at` timestamp
- Enables UUID extension

### 3. Run Second Migration (RLS Policies)

1. Open the file: `Database/migrations/002_create_rls_policies.sql`
2. Copy the entire contents
3. Paste into the SQL Editor in Supabase
4. Click **"Run"**
5. Wait for success message

**What this does:**
- Enables Row Level Security (RLS) on all tables
- Creates policies so users can only access their own data
- Sets up INSERT, SELECT, UPDATE, DELETE policies for each table

### 6. Verify Tables Were Created

1. Go to **Table Editor** in Supabase Dashboard
2. You should see all tables:
   - `Folder`
   - `Document`
   - `DocumentPage`
   - `Tag`
   - `DocumentTag`

### 7. Verify RLS is Enabled

1. Go to **Authentication** → **Policies**
2. You should see policies for each table
3. Or check table settings - RLS should be enabled

### 8. Verify Storage Policies

1. Go to **Storage** → **Policies** in Supabase Dashboard
2. You should see policies for both `documents` and `thumbnails` buckets
3. Policies should allow INSERT, SELECT, UPDATE, DELETE for authenticated users

### 4. Create Storage Buckets

1. Go to **Storage** in Supabase Dashboard
2. Click **"New bucket"**
3. Create bucket: `documents`
   - Name: `documents`
   - Public: **No** (Private)
   - Click **"Create bucket"**
4. Create bucket: `thumbnails`
   - Name: `thumbnails`
   - Public: **No** (Private) or **Yes** (Public - your choice)
   - Click **"Create bucket"**

### 5. Run Third Migration (Storage RLS Policies)

1. Open the file: `Database/migrations/003_create_storage_policies.sql`
2. Copy the entire contents
3. Paste into the SQL Editor in Supabase
4. Click **"Run"**
5. Wait for success message

**What this does:**
- Creates Row Level Security policies for storage buckets
- Allows authenticated users to upload/read/update/delete files in their own folders
- Ensures users can only access files in paths matching their user ID
- Applies to both `documents` and `thumbnails` buckets

## Troubleshooting

### Error: "relation already exists"
- Tables already exist - this is okay, the migration uses `IF NOT EXISTS`
- You can skip this migration or drop tables first

### Error: "extension uuid-ossp does not exist"
- Run this first: `CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`
- Then run the migration again

### Error: "permission denied"
- Make sure you're using the correct Supabase project
- Check that you have admin access

### Foreign Key Errors
- Make sure tables are created in order:
  1. Folder (first)
  2. Document (references Folder)
  3. DocumentPage (references Document)
  4. Tag
  5. DocumentTag (references Document and Tag)

## Migration Files

- **001_create_tables.sql** - Creates all tables, indexes, and triggers
- **002_create_rls_policies.sql** - Sets up Row Level Security policies for database tables
- **003_create_storage_policies.sql** - Sets up Row Level Security policies for storage buckets

## After Migration

Once migrations are complete:
1. ✅ Tables created
2. ✅ Database RLS enabled
3. ✅ Storage buckets created
4. ✅ Storage RLS policies enabled
5. ✅ Ready to use in app!

You can now test saving documents from your app.
