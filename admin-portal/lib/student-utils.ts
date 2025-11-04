/**
 * Generates student index number following EduTrack pattern
 * Format: MEC{sequential_number}
 * Example: MEC1001, MEC1002, MEC1003
 */
export function generateIndexNumber(
  sequentialNumber: number
): string {
  return `MEC${sequentialNumber}`;
}

/**
 * Gets the next available sequential index number globally across all students
 * by finding the maximum existing index number and adding 1.
 * This ensures index numbers are never reused, even after student deletions.
 * Format: MEC1001, MEC1002, MEC1003, etc.
 */
export async function getNextIndexNumber(
  adminUid: string
): Promise<number> {
  const { adminDb } = await import('./firebase-admin');
  
  const studentsRef = adminDb
    .collection('admins')
    .doc(adminUid)
    .collection('students');
  
  try {
    // Query ALL students to find the maximum index number
    const snapshot = await studentsRef.get();
    
    if (snapshot.empty) {
      return 1001; // Start from 1001 as per requirement
    }
    
    // Extract index numbers from existing students
    let maxIndexNumber = 1000; // Minimum is 1000, so next will be 1001
    
    snapshot.forEach((doc) => {
      const data = doc.data();
      const indexNumber = data.indexNumber as string | undefined;
      
      if (indexNumber && indexNumber.trim()) {
        // Index format: MEC1001, MEC1002, etc.
        // Extract the numeric part after "MEC"
        if (indexNumber.startsWith('MEC')) {
          const numberStr = indexNumber.substring(3);
          const number = parseInt(numberStr, 10);
          if (!isNaN(number) && number > maxIndexNumber) {
            maxIndexNumber = number;
          }
        }
      }
    });
    
    return maxIndexNumber + 1;
  } catch (error) {
    console.error('Error getting next index number:', error);
    // Fallback: count all students and add to 1000
    const snapshot = await studentsRef.get();
    return 1001 + snapshot.size;
  }
}

/**
 * Formats date to YYYY-MM-DD string
 */
export function formatDateToString(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * Parses date string to Date object
 * Supports multiple formats: MM/DD/YYYY, YYYY-MM-DD, DD/MM/YYYY
 */
export function parseDateString(dateStr: string): Date {
  if (!dateStr || dateStr.trim() === '') {
    return new Date();
  }
  
  const trimmed = dateStr.trim();
  
  // Check if it contains slashes (MM/DD/YYYY or DD/MM/YYYY)
  if (trimmed.includes('/')) {
    const parts = trimmed.split('/').map(Number);
    
    if (parts.length === 3) {
      // Assume MM/DD/YYYY format (Google Forms default)
      const [month, day, year] = parts;
      
      // Validate the values
      if (year > 1900 && year < 2100 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return new Date(year, month - 1, day);
      }
    }
  }
  
  // Try YYYY-MM-DD format
  if (trimmed.includes('-')) {
    const parts = trimmed.split('-').map(Number);
    
    if (parts.length === 3) {
      const [year, month, day] = parts;
      
      // Validate the values
      if (year > 1900 && year < 2100 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return new Date(year, month - 1, day);
      }
    }
  }
  
  // Fallback to current date if parsing fails
  console.warn(`Failed to parse date: ${dateStr}, using current date`);
  return new Date();
}

/**
 * Validates student data before saving
 */
export function validateStudentData(data: any): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  
  if (!data.name || data.name.trim().length === 0) {
    errors.push('Name is required');
  }
  
  if (!data.class) {
    errors.push('Class is required');
  }
  
  if (!data.section) {
    errors.push('Section is required');
  }
  
  if (!data.Subjects || !Array.isArray(data.Subjects) || data.Subjects.length === 0) {
    errors.push('At least one subject is required');
  }
  
  if (!data.dob) {
    errors.push('Date of birth is required');
  }
  
  if (!data.sex || !['Male', 'Female'].includes(data.sex)) {
    errors.push('Valid sex (Male/Female) is required');
  }
  
  if (!data.parentName) {
    errors.push('Parent name is required');
  }
  
  if (!data.parentPhone) {
    errors.push('Parent phone is required');
  }
  
  return {
    valid: errors.length === 0,
    errors,
  };
}
