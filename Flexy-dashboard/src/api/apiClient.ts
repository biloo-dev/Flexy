import axios, { type AxiosInstance, type AxiosResponse } from 'axios';

const baseURL = import.meta.env.VITE_API_BASE_URL || '/api/v1';
export const isMockMode = import.meta.env.VITE_USE_MOCK_API === 'true';

export const apiClient: AxiosInstance = axios.create({
  baseURL,
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
});

// Request interceptor: attach Bearer token
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('flexi_auth_token');
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor: standard error handling & response unwrapping
apiClient.interceptors.response.use(
  (response: AxiosResponse) => {
    return response;
  },
  (error) => {
    if (error.response) {
      const status = error.response.status;
      let message = error.response.data?.error?.message || 'An unexpected server error occurred.';

      switch (status) {
        case 401:
          message = 'Session expired or unauthenticated. Please log in again.';
          localStorage.removeItem('flexi_auth_token');
          if (window.location.pathname !== '/login') {
            window.location.href = '/login';
          }
          break;
        case 403:
          message = 'You do not have permission to perform this action.';
          break;
        case 404:
          message = error.response.data?.error?.message || 'The requested resource was not found.';
          break;
        case 409:
          message = error.response.data?.error?.message || 'Conflict: Resource already exists.';
          break;
        case 422:
          message = error.response.data?.error?.message || 'Validation error. Please verify input data.';
          break;
        case 429:
          message = 'Rate limit exceeded. Please wait a moment.';
          break;
        case 500:
          message = 'Internal server error on the FLEXI backend.';
          break;
      }
      console.error(`[API Error ${status}]:`, message, error.response.data);
    }
    return Promise.reject(error);
  }
);

// Unwraps { success: true, data: T } from NestJS ApiResponseDto
export function extractData<T>(response: AxiosResponse | any): T {
  if (response && response.data && typeof response.data === 'object' && 'success' in response.data) {
    return response.data.data as T;
  }
  return (response.data ?? response) as T;
}

// Helper for Mock API endpoints to simulate latency & test environments
export async function mockRequest<T>(data: T, delayMs: number = 180): Promise<T> {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve(JSON.parse(JSON.stringify(data)));
    }, delayMs);
  });
}

export default apiClient;
