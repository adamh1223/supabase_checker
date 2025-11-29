# Supabase checker

A small helper script to ping your Supabase project on a schedule so it stays awake.

## Setup
1. Ensure `curl` is installed on the machine running the cron job.
2. (Optional) Export your project's anonymous key if you want the request to include authentication headers:
   ```bash
   export SUPABASE_ANON_KEY="<your-anon-key>"
   ```

## Usage
Run the script manually:
```bash
SUPABASE_PROJECT_REF=fpoxvfuxgtlyphowqdgf ./ping_supabase.sh
```

By default the script calls `https://<project-ref>.supabase.co/health`. You can override the endpoint with either of the following environment variables:
- `SUPABASE_ENDPOINT_PATH`: path appended to `https://<project-ref>.supabase.co` (defaults to `/health`).
- `SUPABASE_TARGET_URL`: full URL to ping; when set it overrides everything else.

The script exits with a non-zero status on failure, which makes it suitable for cron or other schedulers.

## Cron example (every 6 days)
Add this entry with `crontab -e` to run the ping at 9:00 AM every 6 days:
```
0 9 */6 * * /path/to/repo/ping_supabase.sh >> /path/to/repo/ping.log 2>&1
```
> Note: cron's `*/6` day-of-month interval restarts each month. If you need an exact every-6-days cadence across months, consider a systemd timer or a small wrapper script that sleeps for 6 days in a loop.
