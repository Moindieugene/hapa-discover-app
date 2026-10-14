HAPA PWA v2 - online business sign-up (free, no domain needed)

A. SET UP THE DATABASE (once, ~10 min)
   Run supabase.sql first, THEN supabase-payments.sql (adds the KSh 50 M-Pesa fee).
1. Sign up free at supabase.com > New project (pick a region close to Kenya, save the DB password).
2. Left menu > SQL Editor > New query > paste everything from supabase.sql > Run.
3. Authentication > Providers > Email: for easiest testing turn OFF "Confirm email"
   (turn it back on later if you want email verification).
4. Project Settings > API: copy the Project URL and the "anon public" key.
   (Never use the "service_role" key in the app.)
5. Open index.html in a text editor. Near the top of the script find SB_URL and SB_KEY
   and paste the two values between the quotes. Save.

B. PUT IT ONLINE
Netlify Drop (app.netlify.com/drop): drag this folder onto the page. Or GitHub Pages.
Open the https:// link on your phone > Install app / Add to Home Screen.

C. CONFIRMING PAYMENTS
Owners send KSh 50 to 0708294404 and type the M-Pesa code in the app.
In Supabase > Table Editor > payments, match the code with your M-Pesa SMS,
then set its status to "confirmed". The listing goes live for 30 days automatically.
Set "rejected" if the code is fake.

D. UPDATING LATER
Change the cache name in sw.js (hapa-v5 -> hapa-v6) each time you redeploy.

Vercel deployment notes:
- This repo includes a small build script (scripts/generate-config.js) that writes config.js from Vercel environment variables SUPABASE_URL and SUPABASE_ANON_KEY. Do not commit your service_role key.
- After connecting this repo to Vercel, set these Environment Variables in the project settings:
  SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, MPESA_WEBHOOK_SECRET
- The M-Pesa webhook serverless function is at /api/mpesa-webhook and uses the service role key only on the server.
