-- Migration: Create Storage Bucket RLS Policies
-- Run this in Supabase SQL Editor after creating the storage buckets

-- Storage policies for 'documents' bucket
-- Allow authenticated users to upload JPG/JPEG files to their own folder
CREATE POLICY "documents_insert_own_jpg"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'documents'
    AND lower(storage.extension(name)) IN ('jpg', 'jpeg')
    AND lower(name) LIKE (auth.uid()::text || '/%')
);

-- Allow authenticated users to select/read files from their own folder
CREATE POLICY "documents_select_own"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'documents'
    AND lower(name) LIKE (auth.uid()::text || '/%')
);

-- Allow authenticated users to update files in their own folder
CREATE POLICY "documents_update_own"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'documents'
    AND lower(name) LIKE (auth.uid()::text || '/%')
);

-- Allow authenticated users to delete files from their own folder
CREATE POLICY "documents_delete_own"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'documents'
    AND lower(name) LIKE (auth.uid()::text || '/%')
);

-- Storage policies for 'thumbnails' bucket
-- Allow authenticated users to upload JPG/JPEG thumbnails to their own folder
CREATE POLICY "thumbnails_insert_own_jpg"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'thumbnails'
    AND lower(storage.extension(name)) IN ('jpg', 'jpeg')
    AND lower(name) LIKE (auth.uid()::text || '/%')
);

-- Allow authenticated users to select/read thumbnails from their own folder
CREATE POLICY "thumbnails_select_own"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'thumbnails'
    AND lower(name) LIKE (auth.uid()::text || '/%')
);

-- Allow authenticated users to update thumbnails in their own folder
CREATE POLICY "thumbnails_update_own"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'thumbnails'
    AND lower(name) LIKE (auth.uid()::text || '/%')
);

-- Allow authenticated users to delete thumbnails from their own folder
CREATE POLICY "thumbnails_delete_own"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'thumbnails'
    AND lower(name) LIKE (auth.uid()::text || '/%')
);
