# Manual Table Setup Guide (Supabase Table Editor)

This guide shows how to create tables manually using Supabase's Table Editor (no SQL required).

## Steps

1. Go to Supabase Dashboard → **Table Editor**
2. Click **"New table"** for each table below

---

## 1. Folder Table

**Table name:** `Folder`

**Columns:**
- `id` - Type: `uuid`, Primary Key: ✓, Default Value: `gen_random_uuid()`
- `user_id` - Type: `uuid`, Nullable: ✗, Foreign Key: `auth.users(id)` → `id`
- `name` - Type: `text`, Nullable: ✗
- `parent_id` - Type: `uuid`, Nullable: ✓, Foreign Key: `Folder(id)` → `id`
- `created_at` - Type: `timestamptz`, Nullable: ✗, Default Value: `now()`

**Settings:**
- Enable Row Level Security: ✓

---

## 2. Document Table

**Table name:** `Document`

**Columns:**
- `id` - Type: `uuid`, Primary Key: ✓, Default Value: `gen_random_uuid()`
- `user_id` - Type: `uuid`, Nullable: ✗, Foreign Key: `auth.users(id)` → `id`
- `name` - Type: `text`, Nullable: ✗
- `created_at` - Type: `timestamptz`, Nullable: ✗, Default Value: `now()`
- `updated_at` - Type: `timestamptz`, Nullable: ✗, Default Value: `now()`
- `folder_id` - Type: `uuid`, Nullable: ✓, Foreign Key: `Folder(id)` → `id`
- `is_favorite` - Type: `boolean`, Nullable: ✗, Default Value: `false`
- `page_count` - Type: `int4` (integer), Nullable: ✗, Default Value: `0`
- `file_size` - Type: `int8` (bigint), Nullable: ✗, Default Value: `0`

**Settings:**
- Enable Row Level Security: ✓

---

## 3. DocumentPage Table

**Table name:** `DocumentPage`

**Columns:**
- `id` - Type: `uuid`, Primary Key: ✓, Default Value: `gen_random_uuid()`
- `document_id` - Type: `uuid`, Nullable: ✗, Foreign Key: `Document(id)` → `id`
- `page_number` - Type: `int4` (integer), Nullable: ✗
- `image_url` - Type: `text`, Nullable: ✗
- `thumbnail_url` - Type: `text`, Nullable: ✓
- `created_at` - Type: `timestamptz`, Nullable: ✗, Default Value: `now()`

**Unique Constraints:**
- Add unique constraint on: `(document_id, page_number)`

**Settings:**
- Enable Row Level Security: ✓

---

## 4. Tag Table (Optional)

**Table name:** `Tag`

**Columns:**
- `id` - Type: `uuid`, Primary Key: ✓, Default Value: `gen_random_uuid()`
- `user_id` - Type: `uuid`, Nullable: ✗, Foreign Key: `auth.users(id)` → `id`
- `name` - Type: `text`, Nullable: ✗
- `color` - Type: `text`, Nullable: ✓
- `created_at` - Type: `timestamptz`, Nullable: ✓, Default Value: `now()`

**Unique Constraints:**
- Add unique constraint on: `(user_id, name)`

**Settings:**
- Enable Row Level Security: ✓

---

## 5. DocumentTag Table (Optional - Junction Table)

**Table name:** `DocumentTag`

**Columns:**
- `id` - Type: `uuid`, Primary Key: ✓, Default Value: `gen_random_uuid()`
- `document_id` - Type: `uuid`, Nullable: ✗, Foreign Key: `Document(id)` → `id`
- `tag_id` - Type: `uuid`, Nullable: ✗, Foreign Key: `Tag(id)` → `id`

**Unique Constraints:**
- Add unique constraint on: `(document_id, tag_id)`

**Settings:**
- Enable Row Level Security: ✓

---

## After Creating Tables

### Enable UUID Extension (if not already enabled)

1. Go to **SQL Editor**
2. Run: `CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`

### Set Up Row Level Security Policies

After creating tables, you'll need to create RLS policies. You can:
- Use the SQL migration file: `002_create_rls_policies.sql`
- Or create policies manually in **Authentication** → **Policies**

### Create Storage Buckets

1. Go to **Storage**
2. Create bucket: `documents` (Private)
3. Create bucket: `thumbnails` (Private or Public)

---

## Notes

- **Order matters:** Create `Folder` before `Document` (since Document references Folder)
- **Foreign Keys:** Make sure to set up foreign key relationships in the Table Editor
- **RLS:** Enable Row Level Security on all tables for security
- **Indexes:** Supabase may auto-create indexes, but you can add more in **Database** → **Indexes** if needed
