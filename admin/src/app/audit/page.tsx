'use client';

import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

type Log = {
  id: string;
  action: string;
  resource: string;
  resourceId?: string;
  createdAt: string;
};

export default function AuditPage() {
  const [rows, setRows] = useState<Log[]>([]);
  const [error, setError] = useState('');

  useEffect(() => {
    api<Log[]>('/admin/audit-logs')
      .then(setRows)
      .catch((e) => setError(e.message));
  }, []);

  if (error) return <p className="text-red-600">{error}</p>;

  return (
    <div>
      <h2 className="mb-6 text-2xl font-semibold">Audit log</h2>
      <div className="overflow-x-auto rounded-xl border border-zinc-200 bg-white">
        <table className="min-w-full text-left text-sm">
          <thead className="border-b bg-zinc-50 text-zinc-500">
            <tr>
              <th className="px-4 py-3">When</th>
              <th className="px-4 py-3">Action</th>
              <th className="px-4 py-3">Resource</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.id} className="border-b last:border-0">
                <td className="px-4 py-3">
                  {new Date(r.createdAt).toLocaleString()}
                </td>
                <td className="px-4 py-3">{r.action}</td>
                <td className="px-4 py-3">
                  {r.resource} {r.resourceId ? `· ${r.resourceId}` : ''}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
