import { auth } from './firebase-client';

/**
 * Gets the current user's ID token for API authentication
 */
export async function getAuthToken(): Promise<string> {
  const user = auth.currentUser;
  
  if (!user) {
    throw new Error('User not authenticated');
  }
  
  const token = await user.getIdToken();
  return token;
}

/**
 * Makes an authenticated API request with the user's ID token
 */
export async function authenticatedFetch(
  url: string,
  options: RequestInit = {}
): Promise<Response> {
  const token = await getAuthToken();
  
  const headers = new Headers(options.headers);
  headers.set('Authorization', `Bearer ${token}`);
  
  return fetch(url, {
    ...options,
    headers,
  });
}
