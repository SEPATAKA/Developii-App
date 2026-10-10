export type AdminSession = {
  accessToken: string;
  admin: { id: string; email: string; name: string; role: string };
};

const API_URL =
  process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/v1';

export function getSession(): AdminSession | null {
  if (typeof window === 'undefined') return null;
  const raw = localStorage.getItem('developify.admin.session');
  if (!raw) return null;
  try {
    return JSON.parse(raw) as AdminSession;
  } catch {
    return null;
  }
}

export function setSession(session: AdminSession) {
  localStorage.setItem('developify.admin.session', JSON.stringify(session));
}

export function clearSession() {
  localStorage.removeItem('developify.admin.session');
}

export async function api<T>(
  path: string,
  init: RequestInit = {},
): Promise<T> {
  const session = getSession();
  const headers = new Headers(init.headers);
  headers.set('Content-Type', 'application/json');
  if (session?.accessToken) {
    headers.set('Authorization', `Bearer ${session.accessToken}`);
  }
  const res = await fetch(`${API_URL}${path}`, { ...init, headers });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.message || `Request failed (${res.status})`);
  }
  return res.json() as Promise<T>;
}
