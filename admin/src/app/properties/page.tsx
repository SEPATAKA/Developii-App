'use client';

import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

type Property = {
  id: string;
  name: string;
  town: string;
  status: string;
  owner: { name: string; email: string };
};

export default function PropertiesPage() {
  const [rows, setRows] = useState<Property[]>([]);
  const [error, setError] = useState('');
  const [formError, setFormError] = useState('');
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({
    ownerEmail: '',
    name: '',
    town: '',
    address: '',
    erf: '',
    size: '',
  });

  async function load() {
    try {
      setRows(await api<Property[]>('/admin/properties'));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed');
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function setStatus(id: string, status: string) {
    await api(`/admin/properties/${id}/status`, {
      method: 'POST',
      body: JSON.stringify({ status }),
    });
    await load();
  }

  async function addProperty(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setFormError('');
    try {
      await api('/admin/properties', {
        method: 'POST',
        body: JSON.stringify(form),
      });
      setForm({
        ownerEmail: '',
        name: '',
        town: '',
        address: '',
        erf: '',
        size: '',
      });
      await load();
    } catch (err) {
      setFormError(err instanceof Error ? err.message : 'Could not add property');
    } finally {
      setSaving(false);
    }
  }

  if (error) return <p className="text-red-600">{error}</p>;

  return (
    <div className="space-y-8">
      <div>
      <h2 className="mb-6 text-2xl font-semibold">Property submissions</h2>
      <div className="overflow-x-auto rounded-xl border border-zinc-200 bg-white">
        <table className="min-w-full text-left text-sm">
          <thead className="border-b bg-zinc-50 text-zinc-500">
            <tr>
              <th className="px-4 py-3">Property</th>
              <th className="px-4 py-3">Owner</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3">Actions</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((p) => (
              <tr key={p.id} className="border-b last:border-0">
                <td className="px-4 py-3">
                  {p.name}
                  <div className="text-zinc-500">{p.town}</div>
                </td>
                <td className="px-4 py-3">
                  {p.owner.name}
                  <div className="text-zinc-500">{p.owner.email}</div>
                </td>
                <td className="px-4 py-3">{p.status}</td>
                <td className="px-4 py-3 space-x-2">
                  <button
                    className="rounded border px-2 py-1"
                    onClick={() => setStatus(p.id, 'offerReady')}
                  >
                    Offer ready
                  </button>
                  <button
                    className="rounded bg-emerald-700 px-2 py-1 text-white"
                    onClick={() => setStatus(p.id, 'live')}
                  >
                    Publish live
                  </button>
                  <button
                    className="rounded border px-2 py-1"
                    onClick={() => setStatus(p.id, 'paused')}
                  >
                    Pause
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      </div>

      <form
        onSubmit={addProperty}
        className="max-w-xl space-y-3 rounded-xl border border-zinc-200 bg-white p-5"
      >
        <h3 className="font-medium">Add property</h3>
        <p className="text-sm text-zinc-500">
          The owner must already have an account. Use their email.
        </p>
        {(
          [
            ['ownerEmail', 'Owner email'],
            ['name', 'Property name'],
            ['town', 'Town'],
            ['address', 'Address'],
            ['erf', 'Erf'],
            ['size', 'Size'],
          ] as const
        ).map(([key, label]) => (
          <input
            key={key}
            className="w-full rounded border px-3 py-2 text-sm"
            placeholder={label}
            value={form[key]}
            onChange={(e) => setForm({ ...form, [key]: e.target.value })}
            required={key === 'ownerEmail' || key === 'name' || key === 'town'}
          />
        ))}
        {formError ? <p className="text-sm text-red-600">{formError}</p> : null}
        <button
          disabled={saving}
          className="rounded bg-emerald-700 px-3 py-2 text-sm text-white disabled:opacity-60"
        >
          {saving ? 'Adding…' : 'Add property'}
        </button>
      </form>
    </div>
  );
}
