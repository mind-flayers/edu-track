// Admin types
export interface AdminProfile {
  uid: string;
  name: string;
  academyName: string;
  email: string;
  profilePhotoUrl: string;
  smsGatewayToken?: string;
  whatsappGatewayToken?: string;
  createdAt: Date;
  updatedAt: Date;
}

// Student types
export interface Student {
  id: string;
  name: string;
  class: string;
  Subjects: string[]; // Note: Capital 'S' to match Firestore structure
  section: string;
  dob: Date;
  sex: 'Male' | 'Female';
  indexNumber: string;
  parentName: string;
  parentPhone: string;
  whatsappNumber: string;
  address: string;
  photoUrl: string;
  qrCodeData: string;
  joinedAt: Date;
  isActive: boolean;
  isNonePayee: boolean;
}

// CSV Import types - Google Forms column names
export interface StudentCSVRow {
  'Timestamp'?: string;
  'Full Name': string;
  'Class': string;
  'Section': string;
  'Date of Birth': string;
  'Sex': 'Male' | 'Female';
  'Parent/Guardian Name': string;
  'Parent Phone Number': string;
  'Whatsapp Number': string;
  'Address': string;
  'Subjects': string; // Comma-separated subjects
  'Payment type': string;
  'Student Photo': string; // Google Drive link or direct URL
}

// API Response types
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

// Import result types
export interface ImportResult {
  success: number;
  failed: number;
  errors: Array<{ row: number; error: string; data?: any }>;
  successfulStudents: Student[];
}
