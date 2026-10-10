'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { api, setSession } from '@/lib/api';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('admin@developify.co.za');
  const [password, setPassword] = useState('Developify@Admin1');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const result = await api<{
        accessToken: string;
        admin: { id: string; email: string; name: string; role: string };
      }>('/auth/admin/sign-in', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      });
      setSession(result);
      router.replace('/dashboard');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Sign-in failed');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-zinc-100 px-4">
      <form
        onSubmit={onSubmit}
        className="w-full max-w-md space-y-4 rounded-xl border border-zinc-200 bg-white p-8 shadow-sm"
      >
        <div>
          <p className="text-xs uppercase tracking-wide text-emerald-700">
            Developify
          </p>
          <h1 className="text-2xl font-semibold">Admin sign in</h1>
        </div>
        <label className="block text-sm">
          Email
          <input
            className="mt-1 w-full rounded border border-zinc-300 px-3 py-2"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            type="email"
            required
          />
        </label>
        <label className="block text-sm">
          Password
          <input
            className="mt-1 w-full rounded border border-zinc-300 px-3 py-2"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            type="password"
            required
          />
        </label>
        {error ? <p className="text-sm text-red-600">{error}</p> : null}
        <button
          disabled={loading}
          className="w-full rounded bg-emerald-700 px-3 py-2 text-white disabled:opacity-60"
        >
          {loading ? 'Signing in…' : 'Sign in'}
        </button>
      </form>
    </div>
  );
}
