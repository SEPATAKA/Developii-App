'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { clearSession, getSession } from '@/lib/api';
import { useEffect, useState } from 'react';

const links = [
  { href: '/dashboard', label: 'Dashboard' },
  { href: '/users', label: 'Users' },
  { href: '/kyc', label: 'KYC Queue' },
  { href: '/properties', label: 'Properties' },
  { href: '/projects', label: 'Projects' },
  { href: '/transactions', label: 'Transactions' },
  { href: '/audit', label: 'Audit Log' },
  { href: '/config', label: 'Config' },
];

export function AdminShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [ready, setReady] = useState(false);
  const [name, setName] = useState('');

  useEffect(() => {
    const session = getSession();
    if (!session && pathname !== '/login') {
      router.replace('/login');
      return;
    }
    if (session) setName(session.admin.name);
    setReady(true);
  }, [pathname, router]);

  if (!ready) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-zinc-50 text-zinc-600">
        Loading…
      </div>
    );
  }

  if (pathname === '/login') return <>{children}</>;

  return (
    <div className="min-h-screen bg-zinc-50 text-zinc-900">
      <div className="mx-auto flex min-h-screen max-w-7xl">
        <aside className="w-56 border-r border-zinc-200 bg-white p-4">
          <div className="mb-8">
            <p className="text-xs uppercase tracking-wide text-emerald-700">
              Developify
            </p>
            <h1 className="text-lg font-semibold">Admin</h1>
            <p className="text-sm text-zinc-500">{name}</p>
          </div>
          <nav className="space-y-1">
            {links.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className={`block rounded px-3 py-2 text-sm ${
                  pathname.startsWith(link.href)
                    ? 'bg-emerald-50 font-medium text-emerald-800'
                    : 'text-zinc-700 hover:bg-zinc-100'
                }`}
              >
                {link.label}
              </Link>
            ))}
          </nav>
          <button
            className="mt-8 w-full rounded border border-zinc-300 px-3 py-2 text-sm"
            onClick={() => {
              clearSession();
              router.replace('/login');
            }}
          >
            Sign out
          </button>
        </aside>
        <main className="flex-1 p-8">{children}</main>
      </div>
    </div>
  );
}
