'use client';

import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

type ConfigRow = { id: string; key: string; value: unknown };

export default function ConfigPage() {
  const [rows, setRows] = useState<ConfigRow[]>([]);
  const [key, setKey] = useState('withdrawalFeeCents');
  const [value, setValue] = useState('150');
  const [error, setError] = useState('');

  async function load() {
    try {
      setRows(await api<ConfigRow[]>('/admin/config'));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function save(e: React.FormEvent) {
    e.preventDefault();
    let parsed: unknown = value;
    try {
      parsed = JSON.parse(value);
    } catch {
      // keep string
    }
    await api(`/admin/config/${key}`, {
      method: 'PUT',
      body: JSON.stringify({ value: parsed }),
    });
    await load();
  }

  if (error) return <p className="text-red-600">{error}</p>;

  return (
    <div className="space-y-8">
      <div>
        <h2 className="mb-6 text-2xl font-semibold">System config</h2>
        <ul className="space-y-2 rounded-xl border border-zinc-200 bg-white p-4 text-sm">
          {rows.map((r) => (
            <li key={r.id}>
              <span className="font-medium">{r.key}</span>: {JSON.stringify(r.value)}
            </li>
          ))}
        </ul>
      </div>
      <form
        onSubmit={save}
        className="max-w-md space-y-3 rounded-xl border border-zinc-200 bg-white p-5"
      >
        <h3 className="font-medium">Update config</h3>
        <input
          className="w-full rounded border px-3 py-2 text-sm"
          value={key}
          onChange={(e) => setKey(e.target.value)}
        />
        <input
          className="w-full rounded border px-3 py-2 text-sm"
          value={value}
          onChange={(e) => setValue(e.target.value)}
        />
        <button className="rounded bg-emerald-700 px-3 py-2 text-sm text-white">
          Save
        </button>
      </form>
    </div>
  );
}
