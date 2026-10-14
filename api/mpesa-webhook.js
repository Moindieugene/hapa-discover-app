// api/mpesa-webhook.js
// Vercel serverless function to receive M-Pesa webhook callbacks and confirm payments in Supabase.

module.exports = async (req, res) => {
  if (req.method !== 'POST') return res.status(405).send('Method not allowed');

  const secret = req.headers['x-hapa-signature'] || req.headers['x-webhook-secret'] || req.headers['x-hub-signature'];
  if (!secret || secret !== process.env.MPESA_WEBHOOK_SECRET) {
    return res.status(401).json({ error: 'Invalid webhook secret' });
  }

  try {
    const body = req.body || {};
    const mpesa_code = String((body.mpesa_code || body.MpesaReceiptNumber || '')).trim().toUpperCase();
    if (!mpesa_code) return res.status(400).json({ error: 'Missing mpesa_code' });

    const SUPABASE_URL = process.env.SUPABASE_URL;
    const SERVICE_ROLE = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!SUPABASE_URL || !SERVICE_ROLE) return res.status(500).json({ error: 'Server not configured' });

    // Look up payment by mpesa_code
    const listUrl = `${SUPABASE_URL}/rest/v1/payments?mpesa_code=eq.${encodeURIComponent(mpesa_code)}&select=*`;
    const listRes = await fetch(listUrl, {
      method: 'GET',
      headers: { apikey: SERVICE_ROLE, Authorization: `Bearer ${SERVICE_ROLE}`, 'Content-Type': 'application/json' }
    });
    const payments = await listRes.json();
    if (!Array.isArray(payments) || payments.length === 0) {
      return res.status(404).json({ error: 'No payment found for code' });
    }

    // Update the first matching payment to confirmed
    const updateUrl = `${SUPABASE_URL}/rest/v1/payments?id=eq.${payments[0].id}`;
    const upd = await fetch(updateUrl, {
      method: 'PATCH',
      headers: { apikey: SERVICE_ROLE, Authorization: `Bearer ${SERVICE_ROLE}`, 'Content-Type': 'application/json', Prefer: 'return=representation' },
      body: JSON.stringify({ status: 'confirmed' })
    });
    const updated = await upd.json();

    return res.status(200).json({ ok: true, updated });
  } catch (err) {
    console.error('Webhook error', err);
    return res.status(500).json({ error: err.message || 'internal' });
  }
};
