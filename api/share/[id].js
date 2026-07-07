import { kv } from '@vercel/kv';

export default async function handler(req, res) {
  if (req.method !== 'GET') {
    res.setHeader('Allow', 'GET');
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { id } = req.query;
  if (!id || !/^[A-Za-z0-9]{6,12}$/.test(String(id))) {
    return res.status(400).json({ error: 'Invalid share id' });
  }

  if (!process.env.KV_REST_API_URL) {
    return res.status(503).json({ error: 'Share service not configured' });
  }

  try {
    const raw = await kv.get(`share:${id}`);
    if (!raw) {
      return res.status(404).json({ error: 'Share not found or expired' });
    }

    const payload = typeof raw === 'string' ? JSON.parse(raw) : raw;
    res.setHeader('Cache-Control', 'public, max-age=300');
    return res.status(200).json(payload);
  } catch (error) {
    console.error('Failed to fetch share', error);
    return res.status(500).json({ error: 'Failed to fetch share' });
  }
}
