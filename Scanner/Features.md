# Document Scanner App - Feature List

## Architecture & Infrastructure

- **Authentication**: Supabase Auth
- **Persistence/Storage**: Supabase Database & Storage
- **Local Storage**: UserDefaults (for onboarding state, preferences)

## Data Model & Database Schema

### Core Tables

#### User (Supabase Auth)
- Handled by Supabase Auth
- User ID used as foreign key in other tables

#### Document
- `id` (UUID, primary key)
- `user_id` (UUID, foreign key to auth.users)
- `name` (string)
- `created_at` (timestamp)
- `updated_at` (timestamp)
- `folder_id` (UUID, nullable, for organization)
- `is_favorite` (boolean)
- `page_count` (integer) - Number of pages in the document
- `file_size` (bigint) - Total file size in bytes

#### DocumentPage
- `id` (UUID, primary key)
- `document_id` (UUID, foreign key to Document)
- `page_number` (integer, 1-indexed)
- `image_url` (string, reference to storage)
- `thumbnail_url` (string, reference to storage)
- `created_at` (timestamp)

#### Folder (optional)
- `id` (UUID, primary key)
- `user_id` (UUID, foreign key)
- `name` (string)
- `parent_id` (UUID, nullable, for nested folders)
- `created_at` (timestamp)

#### Tag (optional)
- `id` (UUID, primary key)
- `user_id` (UUID, foreign key)
- `name` (string)
- `color` (string, optional)

#### DocumentTag (optional, junction table)
- `document_id` (UUID)
- `tag_id` (UUID)

### Storage Buckets

- `documents` - Full resolution images/PDFs
- `thumbnails` - Thumbnail images

## Core Features (MVP)

1. **Scan Documents**
   - Use VisionKit's `VNDocumentCameraViewController` for native iOS document scanning
   - Automatic edge detection and multi-page scanning
   - Camera-based document capture

2. **View & Organize**
   - Gallery/list view of all scanned documents
   - Thumbnail previews
   - Document metadata (name, date, page count)
   - Basic organization (folders, tags, favorites)

3. **Edit Documents**
   - Crop documents
   - Rotate pages
   - Adjust brightness/contrast
   - Apply filters
   - Manual adjustments

4. **Export**
   - Export as PDF
   - Export as images (PNG/JPEG)
   - Share via iOS share sheet
   - Save to Photos or Files app

5. **Merge Documents**
   - Select multiple documents
   - Combine into single PDF
   - Reorder pages

## Advanced Features

6. **Watermark**
   - Add text watermarks
   - Add image watermarks
   - Customizable position and opacity

7. **Digital Signatures**
   - Draw signatures
   - Add signature images
   - Place signatures on documents

8. **OCR (Optical Character Recognition)**
   - Text recognition using Vision framework
   - Extract text from scanned documents
   - Searchable PDFs
   - Copy text from scans

9. **Cloud Sync**
   - Supabase Storage for document sync
   - Cross-device synchronization
   - Automatic backup to cloud

10. **Additional Organization**
    - Folders/categories
    - Tags and labels
    - Search functionality
    - Favorites/bookmarks

## Priority Order

1. Scanning (essential)
2. Viewing/organizing
3. Export
4. Editing
5. Merge
6. Watermark/Sign/OCR (advanced features)


## Markdown Formatting Reference

- `#` - Level 1 heading (main title)
- `##` - Level 2 heading (section)
- `###` - Level 3 heading (subsection)
- `-` - Bullet point/unordered list
- `**text**` - Bold text
- `` `text` `` - Inline code or field name
- `1.` - Numbered list item
