-- Migration: Create Row Level Security (RLS) policies
-- Run this in Supabase SQL Editor after 001_create_tables.sql

-- Enable RLS on all tables
ALTER TABLE "Document" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "DocumentPage" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Folder" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Tag" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "DocumentTag" ENABLE ROW LEVEL SECURITY;

-- Document policies
CREATE POLICY "Users can view their own documents"
    ON "Document" FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own documents"
    ON "Document" FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own documents"
    ON "Document" FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own documents"
    ON "Document" FOR DELETE
    USING (auth.uid() = user_id);

-- DocumentPage policies
CREATE POLICY "Users can view pages of their own documents"
    ON "DocumentPage" FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM "Document"
            WHERE "Document".id = "DocumentPage".document_id
            AND "Document".user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert pages to their own documents"
    ON "DocumentPage" FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "Document"
            WHERE "Document".id = "DocumentPage".document_id
            AND "Document".user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update pages of their own documents"
    ON "DocumentPage" FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM "Document"
            WHERE "Document".id = "DocumentPage".document_id
            AND "Document".user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete pages of their own documents"
    ON "DocumentPage" FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM "Document"
            WHERE "Document".id = "DocumentPage".document_id
            AND "Document".user_id = auth.uid()
        )
    );

-- Folder policies
CREATE POLICY "Users can view their own folders"
    ON "Folder" FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own folders"
    ON "Folder" FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own folders"
    ON "Folder" FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own folders"
    ON "Folder" FOR DELETE
    USING (auth.uid() = user_id);

-- Tag policies
CREATE POLICY "Users can view their own tags"
    ON "Tag" FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own tags"
    ON "Tag" FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tags"
    ON "Tag" FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own tags"
    ON "Tag" FOR DELETE
    USING (auth.uid() = user_id);

-- DocumentTag policies
CREATE POLICY "Users can view tags of their own documents"
    ON "DocumentTag" FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM "Document"
            WHERE "Document".id = "DocumentTag".document_id
            AND "Document".user_id = auth.uid()
        )
    );

CREATE POLICY "Users can add tags to their own documents"
    ON "DocumentTag" FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "Document"
            WHERE "Document".id = "DocumentTag".document_id
            AND "Document".user_id = auth.uid()
        )
    );

CREATE POLICY "Users can remove tags from their own documents"
    ON "DocumentTag" FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM "Document"
            WHERE "Document".id = "DocumentTag".document_id
            AND "Document".user_id = auth.uid()
        )
    );
