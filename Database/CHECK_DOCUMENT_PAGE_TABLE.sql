-- Check DocumentPage table structure
-- Run this in Supabase SQL Editor

-- 1. Check if table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'DocumentPage';

-- 2. Check all columns in DocumentPage
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'DocumentPage'
ORDER BY ordinal_position;

-- 3. Check if there are any issues with the table
SELECT * FROM "DocumentPage" LIMIT 1;
