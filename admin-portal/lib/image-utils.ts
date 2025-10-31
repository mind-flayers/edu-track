import axios from 'axios';
import FormData from 'form-data';

/**
 * Extracts file ID from Google Drive URL
 * Supports formats:
 * - https://drive.google.com/file/d/{fileId}/view
 * - https://drive.google.com/open?id={fileId}
 * - https://drive.google.com/uc?id={fileId}
 */
export function extractGoogleDriveFileId(url: string): string | null {
  if (!url) return null;
  
  // Pattern 1: /file/d/{id}/
  const pattern1 = /\/file\/d\/([a-zA-Z0-9_-]+)/;
  const match1 = url.match(pattern1);
  if (match1) return match1[1];
  
  // Pattern 2: ?id={id} or &id={id}
  const pattern2 = /[?&]id=([a-zA-Z0-9_-]+)/;
  const match2 = url.match(pattern2);
  if (match2) return match2[1];
  
  return null;
}

/**
 * Converts Google Drive URL to direct download URL
 */
export function getGoogleDriveDirectUrl(fileId: string): string {
  return `https://drive.google.com/uc?export=download&id=${fileId}`;
}

/**
 * Downloads image from Google Drive and returns as Buffer (Node.js)
 */
export async function downloadImageFromGoogleDrive(url: string): Promise<Buffer> {
  const fileId = extractGoogleDriveFileId(url);
  if (!fileId) {
    throw new Error('Invalid Google Drive URL');
  }
  
  const directUrl = getGoogleDriveDirectUrl(fileId);
  
  try {
    const response = await axios.get(directUrl, {
      responseType: 'arraybuffer',
      timeout: 30000, // 30 seconds
      maxRedirects: 5,
    });
    
    return Buffer.from(response.data);
  } catch (error: any) {
    console.error('Error downloading from Google Drive:', error.message);
    throw new Error(`Failed to download image from Google Drive: ${error.message}`);
  }
}

/**
 * Uploads buffer to Cloudinary and returns the public URL (Server-side)
 */
export async function uploadToCloudinary(
  buffer: Buffer,
  fileName: string
): Promise<string> {
  const cloudName = process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME;
  const uploadPreset = process.env.NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET;
  
  if (!cloudName || !uploadPreset) {
    throw new Error('Cloudinary configuration missing');
  }
  
  // Use form-data package for Node.js
  const formData = new FormData();
  formData.append('file', buffer, {
    filename: fileName,
    contentType: 'image/jpeg',
  });
  formData.append('upload_preset', uploadPreset);
  // Match Flutter app folder structure: profiles/students
  formData.append('folder', 'profiles/students');
  
  try {
    const response = await axios.post(
      `https://api.cloudinary.com/v1_1/${cloudName}/image/upload`,
      formData,
      {
        headers: formData.getHeaders(),
        timeout: 60000, // 60 seconds
        maxContentLength: Infinity,
        maxBodyLength: Infinity,
      }
    );
    
    return response.data.secure_url;
  } catch (error: any) {
    console.error('Error uploading to Cloudinary:', error.message);
    if (error.response) {
      console.error('Cloudinary response:', error.response.data);
    }
    throw new Error(`Failed to upload image to Cloudinary: ${error.message}`);
  }
}

/**
 * Downloads from Google Drive and uploads to Cloudinary
 * Returns the Cloudinary URL (Server-side)
 */
export async function transferGoogleDriveToCloudinary(
  googleDriveUrl: string,
  fileName: string
): Promise<string> {
  const buffer = await downloadImageFromGoogleDrive(googleDriveUrl);
  const cloudinaryUrl = await uploadToCloudinary(buffer, fileName);
  return cloudinaryUrl;
}
