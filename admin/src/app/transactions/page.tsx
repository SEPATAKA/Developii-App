'use client';

import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

type Tx = {
  id: string;
  kind: string;
  status: string;
  amountCents: string | number;
  reference: string;
  entity: { user: { name: string; email: string } };
};

export default function TransactionsPage() {
  const [rows, setRows] = useState<Tx[]>([]);
  const [error, setError] = useState('');

  async function load() {
    try {
      setRows(await api<Tx[]>('/admin/transactions'));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function confirmDeposit(id: string) {
    await api(`/admin/wallet/deposits/${id}/confirm`, { method: 'POST' });
    await load();
  }

  async function approveWithdrawal(id: string) {
    await api(`/admin/wallet/withdrawals/${id}/approve`, { method: 'POST' });
    await load();
  }

  if (error) return <p className="text-red-600">{error}</p>;

  return (
    <div>
      <h2 className="mb-6 text-2xl font-semibold">Transactions</h2>
      <div className="overflow-x-auto rounded-xl border border-zinc-200 bg-white">
        <table className="min-w-full text-left text-sm">
          <thead className="border-b bg-zinc-50 text-zinc-500">
            <tr>
              <th className="px-4 py-3">Reference</th>
              <th className="px-4 py-3">User</th>
              <th className="px-4 py-3">Kind</th>
              <th className="px-4 py-3">Amount</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3">Actions</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((t) => (
              <tr key={t.id} className="border-b last:border-0">
                <td className="px-4 py-3">{t.reference}</td>
                <td className="px-4 py-3">
                  {t.entity.user.name}
                  <div className="text-zinc-500">{t.entity.user.email}</div>
                </td>
                <td className="px-4 py-3">{t.kind}</td>
                <td className="px-4 py-3">{String(t.amountCents)}</td>
                <td className="px-4 py-3">{t.status}</td>
                <td className="px-4 py-3">
                  {t.kind === 'topUp' && t.status === 'pending' ? (
                    <button
                      className="rounded bg-emerald-700 px-2 py-1 text-white"
                      onClick={() => confirmDeposit(t.id)}
                    >
                      Confirm deposit
                    </button>
                  ) : null}
                  {t.kind === 'withdrawal' && t.status === 'pending' ? (
                    <button
                      className="rounded bg-emerald-700 px-2 py-1 text-white"
                      onClick={() => approveWithdrawal(t.id)}
                    >
                      Approve withdrawal
                    </button>
                  ) : null}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
