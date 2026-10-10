'use client';

import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

type Draft = {
  id: string;
  status: string;
  submittedAt?: string;
  entity: { entityType: string; user: { name: string; email: string } };
};

export default function KycPage() {
  const [rows, setRows] = useState<Draft[]>([]);
  const [error, setError] = useState('');

  async function load() {
    try {
      setRows(await api<Draft[]>('/admin/kyc/queue'));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function decide(id: string, decision: 'verified' | 'correctionRequired') {
    await api(`/admin/kyc/${id}/decide`, {
      method: 'POST',
      body: JSON.stringify({ decision }),
    });
    await load();
  }

  if (error) return <p className="text-red-600">{error}</p>;

  return (
    <div>
      <h2 className="mb-6 text-2xl font-semibold">KYC review queue</h2>
      <div className="space-y-3">
        {rows.length === 0 ? (
          <p className="text-zinc-500">No pending KYC submissions.</p>
        ) : null}
        {rows.map((row) => (
          <div
            key={row.id}
            className="rounded-xl border border-zinc-200 bg-white p-4"
          >
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <p className="font-medium">{row.entity.user.name}</p>
                <p className="text-sm text-zinc-500">
                  {row.entity.user.email} · {row.entity.entityType}
                </p>
              </div>
              <div className="flex gap-2">
                <button
                  className="rounded bg-emerald-700 px-3 py-1.5 text-sm text-white"
                  onClick={() => decide(row.id, 'verified')}
                >
                  Approve
                </button>
                <button
                  className="rounded border px-3 py-1.5 text-sm"
                  onClick={() => decide(row.id, 'correctionRequired')}
                >
                  Request correction
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
