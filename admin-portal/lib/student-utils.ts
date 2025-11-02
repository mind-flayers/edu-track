/**
 * Generates student index number following EduTrack pattern
 * Format: MEC/{YY}/{classCode}/{rowNumber}
 * Example: MEC/25/10A/01
 */
export function generateIndexNumber(
  year: number,
  className: string,
  section: string,
  rowNumber: number
): string {
  const yy = year.toString().slice(-2); // Last 2 digits of year
  const classCode = className.replace('Grade ', '') + section;
  const paddedRow = rowNumber.toString().padStart(2, '0');
  
  return `MEC/${yy}/${classCode}/${paddedRow}`;
}

/**
 * Gets the next available row number for a class/section combination
 * by finding the maximum existing row number and adding 1.
 * This ensures index numbers are never reused, even after student deletions.
 */
export async function getNextRowNumber(
  adminUid: string,
  className: string,
  section: string
): Promise<number> {
  const { adminDb } = await import('./firebase-admin');
  
  const studentsRef = adminDb
    .collection('admins')
    .doc(adminUid)
    .collection('students');
  
  try {
    // Query all students in the same class and section
    const snapshot = await studentsRef
      .where('class', '==', className)
      .where('section', '==', section)
      .get();
    
    if (snapshot.empty) {
      return 1; // First student in this class/section
    }
    
    // Extract row numbers from existing index numbers
    let maxRowNumber = 0;
    
    snapshot.forEach((doc) => {
      const data = doc.data();
      const indexNumber = data.indexNumber as string | undefined;
      
      if (indexNumber && indexNumber.trim()) {
        // Index format: MEC/25/10A/01
        // Extract the last part (row number)
        const parts = indexNumber.split('/');
        if (parts.length === 4) {
          const rowNumberStr = parts[3];
          const rowNumber = parseInt(rowNumberStr, 10);
          if (!isNaN(rowNumber) && rowNumber > maxRowNumber) {
            maxRowNumber = rowNumber;
          }
        }
      }
    });
    
    return maxRowNumber + 1;
  } catch (error) {
    console.error('Error getting next row number:', error);
    // Fallback to count-based approach if something goes wrong
    const snapshot = await studentsRef
      .where('class', '==', className)
      .where('section', '==', section)
      .get();
    return snapshot.size + 1;
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
