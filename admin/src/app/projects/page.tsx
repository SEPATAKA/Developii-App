'use client';

import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

type Allocation = {
  id: string;
  amountCents: number;
  status: string;
  projectName: string;
  town: string;
  investorName: string;
  investorNumber: string | null;
};

type Project = {
  id: string;
  slug: string;
  name: string;
  town: string;
  annualRateBps: number;
  capacityCents: string | number;
  fundedCents: string | number;
  status: string;
};

export default function ProjectsPage() {
  const [rows, setRows] = useState<Project[]>([]);
  const [error, setError] = useState('');
  const [allocations, setAllocations] = useState<Allocation[]>([]);
  const [allocError, setAllocError] = useState('');
  const [allocating, setAllocating] = useState(false);
  const [allocation, setAllocation] = useState({
    investorNumber: '',
    projectId: '',
    amount: '',
  });
  const [form, setForm] = useState({
    slug: '',
    name: '',
    town: '',
    annualRateBps: 1450,
    capacityCents: 100000000,
  });

  async function load() {
    try {
      const [projects, assigned] = await Promise.all([
        api<Project[]>('/admin/projects'),
        api<Allocation[]>('/admin/allocations'),
      ]);
      setRows(projects);
      setAllocations(assigned);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function createProject(e: React.FormEvent) {
    e.preventDefault();
    await api('/admin/projects', {
      method: 'POST',
      body: JSON.stringify(form),
    });
    setForm({
      slug: '',
      name: '',
      town: '',
      annualRateBps: 1450,
      capacityCents: 100000000,
    });
    await load();
  }

  async function allocateFunds(e: React.FormEvent) {
    e.preventDefault();
    setAllocating(true);
    setAllocError('');
    try {
      await api('/admin/allocations', {
        method: 'POST',
        body: JSON.stringify({
          investorNumber: allocation.investorNumber.trim(),
          projectId: allocation.projectId,
          amountCents: zarToCents(allocation.amount),
          idempotencyKey: crypto.randomUUID(),
        }),
      });
      setAllocation({ investorNumber: '', projectId: '', amount: '' });
      await load();
    } catch (err) {
      setAllocError(err instanceof Error ? err.message : 'Allocation failed');
    } finally {
      setAllocating(false);
    }
  }

  if (error) return <p className="text-red-600">{error}</p>;

  return (
    <div className="space-y-8">
      <div>
        <h2 className="mb-6 text-2xl font-semibold">Catalogue projects</h2>
        <div className="overflow-x-auto rounded-xl border border-zinc-200 bg-white">
          <table className="min-w-full text-left text-sm">
            <thead className="border-b bg-zinc-50 text-zinc-500">
              <tr>
                <th className="px-4 py-3">Name</th>
                <th className="px-4 py-3">Rate (bps)</th>
                <th className="px-4 py-3">Funded / Capacity</th>
                <th className="px-4 py-3">Status</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((p) => (
                <tr key={p.id} className="border-b last:border-0">
                  <td className="px-4 py-3">
                    {p.name}
                    <div className="text-zinc-500">
                      {p.town} · {p.slug}
                    </div>
                  </td>
                  <td className="px-4 py-3">{p.annualRateBps}</td>
                  <td className="px-4 py-3">
                    {String(p.fundedCents)} / {String(p.capacityCents)}
                  </td>
                  <td className="px-4 py-3">{p.status}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <form
        onSubmit={createProject}
        className="max-w-xl space-y-3 rounded-xl border border-zinc-200 bg-white p-5"
      >
        <h3 className="font-medium">Create project</h3>
        {(['slug', 'name', 'town'] as const).map((key) => (
          <input
            key={key}
            className="w-full rounded border px-3 py-2 text-sm"
            placeholder={key}
            value={form[key]}
            onChange={(e) => setForm({ ...form, [key]: e.target.value })}
            required
          />
        ))}
        <input
          className="w-full rounded border px-3 py-2 text-sm"
          type="number"
          placeholder="annualRateBps"
          value={form.annualRateBps}
          onChange={(e) =>
            setForm({ ...form, annualRateBps: Number(e.target.value) })
          }
        />
        <input
          className="w-full rounded border px-3 py-2 text-sm"
          type="number"
          placeholder="capacityCents"
          value={form.capacityCents}
          onChange={(e) =>
            setForm({ ...form, capacityCents: Number(e.target.value) })
          }
        />
        <button className="rounded bg-emerald-700 px-3 py-2 text-sm text-white">
          Create
        </button>
      </form>

      <form
        onSubmit={allocateFunds}
        className="max-w-xl space-y-3 rounded-xl border border-zinc-200 bg-white p-5"
      >
        <h3 className="font-medium">Allocate funds</h3>
        <p className="text-sm text-zinc-500">
          Moves available wallet funds for a verified investor into an open
          project. The investor ID is the seven-digit deposit reference.
        </p>
        <input
          className="w-full rounded border px-3 py-2 text-sm"
          placeholder="Investor ID"
          inputMode="numeric"
          value={allocation.investorNumber}
          onChange={(e) =>
            setAllocation({ ...allocation, investorNumber: e.target.value })
          }
          required
        />
        <select
          className="w-full rounded border px-3 py-2 text-sm"
          value={allocation.projectId}
          onChange={(e) =>
            setAllocation({ ...allocation, projectId: e.target.value })
          }
          required
        >
          <option value="">Project</option>
          {rows
            .filter((project) => project.status === 'open')
            .map((project) => (
              <option key={project.id} value={project.id}>
                {project.name} · {project.town}
              </option>
            ))}
        </select>
        <input
          className="w-full rounded border px-3 py-2 text-sm"
          placeholder="Amount (ZAR)"
          inputMode="decimal"
          value={allocation.amount}
          onChange={(e) =>
            setAllocation({ ...allocation, amount: e.target.value })
          }
          required
        />
        {allocError ? <p className="text-sm text-red-600">{allocError}</p> : null}
        <button
          disabled={allocating}
          className="rounded bg-emerald-700 px-3 py-2 text-sm text-white disabled:opacity-60"
        >
          {allocating ? 'Allocating…' : 'Allocate'}
        </button>
      </form>

      <div>
        <h3 className="mb-4 text-lg font-medium">Allocations</h3>
        <div className="overflow-x-auto rounded-xl border border-zinc-200 bg-white">
          <table className="min-w-full text-left text-sm">
            <thead className="border-b bg-zinc-50 text-zinc-500">
              <tr>
                <th className="px-4 py-3">Investor</th>
                <th className="px-4 py-3">Project</th>
                <th className="px-4 py-3">Amount (cents)</th>
                <th className="px-4 py-3">Status</th>
              </tr>
            </thead>
            <tbody>
              {allocations.map((row) => (
                <tr key={row.id} className="border-b last:border-0">
                  <td className="px-4 py-3">
                    {row.investorName}
                    <div className="text-zinc-500">
                      {row.investorNumber ?? '—'}
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    {row.projectName}
                    <div className="text-zinc-500">{row.town}</div>
                  </td>
                  <td className="px-4 py-3">{row.amountCents}</td>
                  <td className="px-4 py-3">{row.status}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function zarToCents(raw: string) {
  const value = raw.trim();
  if (!/^\d+(\.\d{1,2})?$/.test(value)) {
    throw new Error('Enter the amount in rands, with at most two decimal places.');
  }
  const [rands, cents = ''] = value.split('.');
  return Number(rands) * 100 + Number(cents.padEnd(2, '0'));
}
