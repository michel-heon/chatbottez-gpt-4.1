/**
 * Utility functions for consistent error handling
 */

/**
 * Safely extracts error message from unknown error type
 * @param error Unknown error object
 * @returns Error message string
 */
export function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  if (typeof error === 'string') {
    return error;
  }
  return 'Unknown error';
}

/**
 * Safely converts unknown error to Error instance
 * @param error Unknown error object
 * @returns Error instance
 */
export function toError(error: unknown): Error {
  if (error instanceof Error) {
    return error;
  }
  if (typeof error === 'string') {
    return new Error(error);
  }
  return new Error('Unknown error');
}

/**
 * Type guard to check if error is an Error instance
 * @param error Unknown error object
 * @returns Boolean indicating if error is Error instance
 */
export function isError(error: unknown): error is Error {
  return error instanceof Error;
}
