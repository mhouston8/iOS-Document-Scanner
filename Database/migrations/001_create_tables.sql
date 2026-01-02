-- Migration: Create core tables for Scanner app
-- Run this in Supabase SQL Editor

-- Note: Supabase has UUID generation enabled by default
-- Using gen_random_uuid() which is built-in (no extension needed)
-- If that doesn't work, uncomment the extension line below:
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Folder table (optional) - Create first since Document references it
CREATE TABLE IF NOT EXISTS "Folder" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    parent_id UUID REFERENCES "Folder"(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Document table
CREATE TABLE IF NOT EXISTS "Document" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    folder_id UUID REFERENCES "Folder"(id) ON DELETE SET NULL,
    is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
    page_count INTEGER NOT NULL DEFAULT 0,
    file_size BIGINT NOT NULL DEFAULT 0
);

-- DocumentPage table
CREATE TABLE IF NOT EXISTS "DocumentPage" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES "Document"(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    page_number INTEGER NOT NULL,
    image_url TEXT NOT NULL,
    thumbnail_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(document_id, page_number)
);

-- Tag table (optional)
CREATE TABLE IF NOT EXISTS "Tag" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    color TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, name)
);

-- DocumentTag junction table (optional)
CREATE TABLE IF NOT EXISTS "DocumentTag" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES "Document"(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES "Tag"(id) ON DELETE CASCADE,
    UNIQUE(document_id, tag_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_document_user_id ON "Document"(user_id);
CREATE INDEX IF NOT EXISTS idx_document_folder_id ON "Document"(folder_id);
CREATE INDEX IF NOT EXISTS idx_document_page_document_id ON "DocumentPage"(document_id);
CREATE INDEX IF NOT EXISTS idx_document_page_user_id ON "DocumentPage"(user_id);
CREATE INDEX IF NOT EXISTS idx_folder_user_id ON "Folder"(user_id);
CREATE INDEX IF NOT EXISTS idx_folder_parent_id ON "Folder"(parent_id);
CREATE INDEX IF NOT EXISTS idx_tag_user_id ON "Tag"(user_id);
CREATE INDEX IF NOT EXISTS idx_document_tag_document_id ON "DocumentTag"(document_id);
CREATE INDEX IF NOT EXISTS idx_document_tag_tag_id ON "DocumentTag"(tag_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update updated_at on Document
CREATE TRIGGER update_document_updated_at
    BEFORE UPDATE ON "Document"
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Note: DocumentPage.user_id is automatically set to auth.uid() via DEFAULT
-- No need to set it in Swift code - database handles it automatically
