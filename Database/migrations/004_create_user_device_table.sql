-- Migration: Create UserDevice table for push notification tokens
-- Run this in Supabase SQL Editor

-- UserDevice table - stores FCM tokens for push notifications
CREATE TABLE IF NOT EXISTS "UserDevice" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('ios', 'android')),
    device_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, fcm_token)
);

-- Create index for faster lookups by user_id
CREATE INDEX IF NOT EXISTS idx_user_device_user_id ON "UserDevice"(user_id);

-- Create trigger to auto-update updated_at
CREATE TRIGGER update_user_device_updated_at
    BEFORE UPDATE ON "UserDevice"
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE "UserDevice" ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own devices"
    ON "UserDevice" FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own devices"
    ON "UserDevice" FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own devices"
    ON "UserDevice" FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own devices"
    ON "UserDevice" FOR DELETE
    USING (auth.uid() = user_id);
