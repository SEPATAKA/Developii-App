'use client';

import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

type UserRow = {
  id: string;
  name: string;
  email: string;
  locked: boolean;
  investorNumber: string | null;
  memberships: { experience: string }[];
  entities: { entityType: string; verificationStatus: string }[];
};

export default function UsersPage() {
  const [users, setUsers] = useState<UserRow[]>([]);
  const [error, setError] = useState('');

  async function load() {
    try {
      setUsers(await api<UserRow[]>('/admin/users'));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load');
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function toggleLock(id: string, locked: boolean) {
    await api(`/admin/users/${id}/lock`, {
      method: 'PATCH',
      body: JSON.stringify({ locked }),
    });
    await load();
  }

  if (error) return <p className="text-red-600">{error}</p>;

  return (
    <div>
      <h2 className="mb-6 text-2xl font-semibold">Users</h2>
      <div className="overflow-x-auto rounded-xl border border-zinc-200 bg-white">
        <table className="min-w-full text-left text-sm">
          <thead className="border-b bg-zinc-50 text-zinc-500">
            <tr>
              <th className="px-4 py-3">Name</th>
              <th className="px-4 py-3">Investor ID</th>
              <th className="px-4 py-3">Email</th>
              <th className="px-4 py-3">Portals</th>
              <th className="px-4 py-3">Verification</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3">Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.id} className="border-b last:border-0">
                <td className="px-4 py-3">{u.name}</td>
                <td className="px-4 py-3">{u.investorNumber ?? '—'}</td>
                <td className="px-4 py-3">{u.email}</td>
                <td className="px-4 py-3">
                  {u.memberships.map((m) => m.experience).join(', ')}
                </td>
                <td className="px-4 py-3">
                  {u.entities.map((e) => e.verificationStatus).join(', ') ||
                    '—'}
                </td>
                <td className="px-4 py-3">{u.locked ? 'Locked' : 'Active'}</td>
                <td className="px-4 py-3">
                  <button
                    className="rounded border px-2 py-1"
                    onClick={() => toggleLock(u.id, !u.locked)}
                  >
                    {u.locked ? 'Unlock' : 'Lock'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
