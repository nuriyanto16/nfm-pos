const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8080/api';
const IMAGE_BASE = API_BASE.replace('/api', '');

export function getFullUrl(url) {
  if (!url) return '';
  if (url.startsWith('http')) return url;
  return `${IMAGE_BASE}${url.startsWith('/') ? '' : '/'}${url}`;
}
