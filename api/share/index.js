import { kv } from '@vercel/kv';

const SHARE_TTL_SECONDS = 90 * 24 * 60 * 60;
const MAX_ITEMS = 50;
const ID_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';

function generateShareId() {
  const bytes = crypto.getRandomValues(new Uint8Array(8));
  let id = '';
  for (let i = 0; i < 6; i += 1) {
    id += ID_CHARS[bytes[i] % ID_CHARS.length];
  }
  return id;
}

function isValidPayload(body) {
  return Boolean(
    body
    && typeof body.name === 'string'
    && body.name.trim()
    && Array.isArray(body.items)
    && body.items.length > 0
    && body.items.length <= MAX_ITEMS
    && body.items.every((item) => item && typeof item.name === 'string' && item.name.trim())
  );
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Method not allowed' });
  }

  if (!process.env.KV_REST_API_URL) {
    return res.status(503).json({ error: 'Share service not configured' });
  }

  try {
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    if (!isValidPayload(body)) {
      return res.status(400).json({ error: 'Invalid share payload' });
    }

    const id = generateShareId();
    const payload = {
      name: body.name.trim(),
      items: body.items.map((item) => ({
        name: item.name.trim(),
        quantity: item.quantity ?? null,
        quantityText: item.quantityText ?? null,
        categoryId: item.categoryId ?? null,
        storeId: item.storeId ?? null,
        notes: item.notes ?? null,
        completed: Boolean(item.completed),
      })),
      createdAt: new Date().toISOString(),
    };

    await kv.set(`share:${id}`, JSON.stringify(payload), { ex: SHARE_TTL_SECONDS });

    return res.status(201).json({
      id,
      url: `https://smartgrocerylists.app/s/${id}`,
      expiresInDays: 90,
    });
  } catch (error) {
    console.error('Failed to create share', error);
    return res.status(500).json({ error: 'Failed to create share' });
  }
}
