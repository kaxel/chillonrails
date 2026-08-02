# Song Submissions + Stripe Checkout

Native Rails replacement for the old Cognito Forms embed on `/submit`
(`/pages/submit` still works and points at the same form).

## How it works

1. Guest visits `/submit` and fills in name, email, artist/band name, and one or
   more song rows (title + audio file). The "Add another song" button clones a
   row via the `song_fields` Stimulus controller and updates the live price total.
2. On submit, each audio file is uploaded **directly from the browser to S3**
   (Active Storage direct upload) — files never pass through the Rails server.
3. `SubmissionsController#create` saves the `Submission` + `SubmissionSong`
   records (status `pending`), prices it at **$3.00/song**
   (`Submission::PRICE_PER_SONG_CENTS`), creates a Stripe Checkout Session, and
   redirects the browser to Stripe's hosted payment page.
4. After payment, Stripe calls `POST /webhooks/stripe`. On
   `checkout.session.completed` the submission is marked `paid` and a
   confirmation email is sent (Postmark). The user lands on
   `/submissions/:token/success`.

Pricing lives in one place: `Submission::PRICE_PER_SONG_CENTS`.

## Environment variables

Set these in `.env` (local) and in the Render dashboard (production):

| Var | Purpose |
| --- | --- |
| `STRIPE_SECRET_KEY` | Stripe API key (`sk_test_…` locally, `sk_live_…` in prod) |
| `STRIPE_WEBHOOK_SECRET` | Signing secret for the `/webhooks/stripe` endpoint (`whsec_…`) |
| `AWS_ACCESS_KEY_ID` | IAM key for the Active Storage S3 bucket (prod only) |
| `AWS_SECRET_ACCESS_KEY` | IAM secret (prod only) |
| `AWS_REGION` | e.g. `us-east-1` |
| `AWS_S3_BUCKET` | Bucket name |

Development uses local disk (`config.active_storage.service = :local`), so the
AWS vars can stay empty locally. Production uses `:amazon`.

## AWS S3 setup

1. Create a bucket (e.g. `chillfiltr-submissions`) in your region.
2. Create an IAM user with programmatic access and this policy (scoped to the
   bucket):

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"],
         "Resource": [
           "arn:aws:s3:::chillfiltr-submissions",
           "arn:aws:s3:::chillfiltr-submissions/*"
         ]
       }
     ]
   }
   ```

3. **CORS is required** for browser direct uploads. Add this CORS config to the
   bucket (replace the origin with your domain):

   ```json
   [
     {
       "AllowedHeaders": ["*"],
       "AllowedMethods": ["PUT"],
       "AllowedOrigins": ["https://chillfiltr.com"],
       "ExposeHeaders": ["Origin", "Content-Type", "Content-MD5", "Content-Disposition"],
       "MaxAgeSeconds": 3600
     }
   ]
   ```

   Add `http://localhost:3000` to `AllowedOrigins` too if you switch dev to S3.

## Stripe setup

1. Grab your API keys from https://dashboard.stripe.com/apikeys and set
   `STRIPE_SECRET_KEY`.
2. Create a webhook endpoint pointing at `https://chillfiltr.com/webhooks/stripe`
   subscribed to the `checkout.session.completed` event. Copy its signing secret
   into `STRIPE_WEBHOOK_SECRET`.
3. **Local testing** with the Stripe CLI:

   ```sh
   stripe listen --forward-to localhost:3000/webhooks/stripe
   ```

   The CLI prints a `whsec_…` secret — use it as `STRIPE_WEBHOOK_SECRET` locally.
   Trigger a test event with `stripe trigger checkout.session.completed`.

## Notes / follow-ups

- **S3-first, pay-second**: files land in S3 before payment, so unpaid
  submissions accumulate as `status: pending`. `PurgePendingSubmissionsJob`
  destroys pending submissions (and purges their audio) older than 24h; it's
  scheduled daily at 4am via `config/recurring.yml` (production only). Run it
  manually with `PurgePendingSubmissionsJob.perform_now(24)`.
- The webhook handler is idempotent (a second delivery won't re-send email).
