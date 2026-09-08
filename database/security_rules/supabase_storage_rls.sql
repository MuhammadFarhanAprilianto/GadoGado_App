-- =========================================================================
-- Supabase Storage & Row Level Security (RLS) Policies
-- Warung Mpo Lemezz POS App
-- =========================================================================

-- 1. Storage Buckets Setup
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('menu-images', 'menu-images', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('receipts', 'receipts', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Storage Policies for avatars
CREATE POLICY 'Public Access for Avatars' 
ON storage.objects FOR SELECT 
USING (bucket_id = 'avatars');

CREATE POLICY 'Authenticated Upload Avatars' 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');

-- 3. Storage Policies for menu-images
CREATE POLICY 'Public Access for Menu Images' 
ON storage.objects FOR SELECT 
USING (bucket_id = 'menu-images');

CREATE POLICY 'Staff Upload Menu Images' 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'menu-images' AND auth.role() = 'authenticated');

CREATE POLICY 'Staff Delete Menu Images' 
ON storage.objects FOR DELETE 
USING (bucket_id = 'menu-images' AND auth.role() = 'authenticated');

-- 4. Storage Policies for receipts
CREATE POLICY 'Public Access for Receipts' 
ON storage.objects FOR SELECT 
USING (bucket_id = 'receipts');

CREATE POLICY 'Authenticated Upload Receipts' 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'receipts' AND auth.role() = 'authenticated');
