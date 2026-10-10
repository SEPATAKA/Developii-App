'use client';

import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

type Dashboard = {
  users: number;
  pendingKyc: number;
  pendingDeposits: number;
  pendingWithdrawals: number;
  propertiesUnderReview: number;
  projects: number;
};

export default function DashboardPage() {
  const [data, setData] = useState<Dashboard | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    api<Dashboard>('/admin/dashboard')
      .then(setData)
      .catch((e) => setError(e.message));
  }, []);

  if (error) return <p className="text-red-600">{error}</p>;
  if (!data) return <p>Loading dashboard…</p>;

  const cards = [
    { label: 'Users', value: data.users },
    { label: 'Pending KYC', value: data.pendingKyc },
    { label: 'Pending deposits', value: data.pendingDeposits },
    { label: 'Pending withdrawals', value: data.pendingWithdrawals },
    { label: 'Properties in review', value: data.propertiesUnderReview },
    { label: 'Projects', value: data.projects },
  ];

  return (
    <div>
      <h2 className="mb-6 text-2xl font-semibold">Dashboard</h2>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {cards.map((card) => (
          <div
            key={card.label}
            className="rounded-xl border border-zinc-200 bg-white p-5"
          >
            <p className="text-sm text-zinc-500">{card.label}</p>
            <p className="mt-2 text-3xl font-semibold">{card.value}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
