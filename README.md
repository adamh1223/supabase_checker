# Supabase checker

A small helper script to ping your Supabase project on a schedule so it stays awake.

You do **not** need to deploy anything for this to work—the script simply needs to run (e.g., via cron) on any machine that has
network access to Supabase and the `.env` values available.

The script is tailored for the "Adam Underwater" project and will pick up values from a local `.env` file if present. The key environment variables supported are:

- `SUPABASE_URL` (e.g., `https://fpoxvfuxgtlyphowqdgf.supabase.co`)
- `SUPABASE_KEY` (service or anon key)
- `SUPABASE_ENDPOINT_PATH` (defaults to `/health`)
- `SUPABASE_TARGET_URL` (full URL override; takes precedence over `SUPABASE_ENDPOINT_PATH`)

## Setup
1. Ensure `curl` is installed on the machine running the cron job.
2. Create a `.env` file beside the script with your connection values (these mirror the user's local setup):
   ```bash
   SUPABASE_URL="https://fpoxvfuxgtlyphowqdgf.supabase.co"
   SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwb3h2ZnV4Z3RseXBob3dxZGdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjc3NDg0MDgsImV4cCI6MjA0MzMyNDQwOH0.nrZ8ImfL0wRSY8-YEgeE0zBgoP8z-GCq8Yj2oYq31U0"
   DATABASE_URL="postgresql://postgres.fpoxvfuxgtlyphowqdgf:JGA1SDb8en5WQfUN@aws-0-us-west-1.pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1"
   DIRECT_URL="postgresql://postgres.fpoxvfuxgtlyphowqdgf:JGA1SDb8en5WQfUN@aws-0-us-west-1.pooler.supabase.com:5432/postgres"
   ADMIN_USER_ID="user_2mtRoRfL1wsjsweMnWgpj1Las0M"
   SUPABASE_PROJECT="Adam-Underwater"
   DB_PASSWORD="JGA1SDb8en5WQfUN"
   ```
   > Only `SUPABASE_URL` and `SUPABASE_KEY` are required by the script; the rest are kept for completeness of your local configuration.

## Usage
Run the script manually (it auto-loads `.env` when present):
```bash
./ping_supabase.sh
```

By default the script calls `${SUPABASE_URL}/health`. You can override the endpoint with either of the following environment variables:
- `SUPABASE_ENDPOINT_PATH`: path appended to `${SUPABASE_URL}` (defaults to `/health`).
- `SUPABASE_TARGET_URL`: full URL to ping; when set it overrides everything else.

The script exits with a non-zero status on failure, which makes it suitable for cron or other schedulers.

## Cron example (every 3 days)
You only need to set this up one time. Cron will then run the ping automatically every 3 days.

1. Make sure the script is executable (only needed once). Run this **inside the repo folder** so the path resolves correctly:
   ```bash
   cd /absolute/path/to/supabase_checker
   chmod +x "$(pwd)/ping_supabase.sh"
   ```
2. Add the cron entry (this is the one command you give to configure the schedule):
   ```bash
   crontab -e
   ```
   Paste the following line when the editor opens, then save and exit:
   ```
   0 9 */3 * * /absolute/path/to/supabase_checker/ping_supabase.sh >> /absolute/path/to/supabase_checker/ping.log 2>&1
   ```
   - Replace `/absolute/path/to/supabase_checker` with the output of `pwd` from step 1 (for example, `/Users/yourname/supabase_checker`).
   - The log file will be created if it does not exist.
3. Verify the entry was saved (optional):
   ```bash
   crontab -l
   ```

> Note: cron's `*/3` day-of-month interval restarts each month. If you need an exact every-3-days cadence across months, consider a systemd timer or a small wrapper script that sleeps for 3 days in a loop.