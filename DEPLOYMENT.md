# Thuraya free test deployment

The test architecture is:

`Flutter Web on Firebase Hosting -> Thuraya .NET API on Render Free -> Azure SQL Free`

Testers receive one URL:

`https://thuraya-test-amr-202609.web.app`

No secret is committed to either repository. The Flutter API URL is injected at build time, Render stores API secrets, and the Azure SQL connection string is copied to the local clipboard only during setup.

## 1. Create Azure SQL Free

Azure CLI must already be signed in. From the backend repository run:

```powershell
.\deploy\Create-ThurayaAzureSql.ps1 `
  -SqlServerName thuraya-test-sql-amr-202609
```

The script creates the serverless database with the Azure free limit and `AutoPause` exhaustion behavior, then copies the connection string to the clipboard without printing it.

## 2. Create the Render Free API

The backend repository includes `Dockerfile` and `render.yaml`.

1. Push the backend changes to GitHub.
2. Sign in to [Render](https://dashboard.render.com/).
3. Select **New -> Blueprint** and connect `ThurayaHub/thuraya-backend`.
4. Use the repository-root `render.yaml`.
5. When Render asks for `ConnectionStrings__DefaultConnection`, paste the connection string created in step 1.
6. Confirm the service plan is **Free** and deploy.

The first deploy cannot access Azure SQL until its outbound addresses are allowlisted. In the created Render service, open **Connect -> Outbound** and copy every IPv4 CIDR range. Then run:

```powershell
.\deploy\Add-RenderSqlFirewallRanges.ps1 `
  -SqlServerName thuraya-test-sql-amr-202609 `
  -CidrRange 'CIDR_1','CIDR_2'
```

Trigger **Manual Deploy -> Deploy latest commit** in Render. Verify:

`https://thuraya-test-api.onrender.com/health`

The service enables the deterministic 200-restaurant test seed. Seeding and EF Core migrations run on startup and are idempotent.

## 3. Build and deploy Flutter Web

From the frontend repository:

```powershell
.\tool\deploy_firebase.ps1 `
  -FirebaseProjectId thuraya-test-amr-202609 `
  -ApiBaseUrl https://thuraya-test-api.onrender.com
```

Firebase Hosting supplies HTTPS, which browsers require for location access. Testers must allow location permission in Safari or Chrome.

## Free-tier limitations

- Render Free sleeps after 15 minutes without inbound traffic. The first request can take about one minute.
- Render's filesystem is ephemeral. Restaurant/profile images uploaded to local `wwwroot/uploads` can disappear on restart, redeploy, or sleep. Existing seeded restaurants use the Flutter fallback image.
- Azure SQL uses the free serverless allowance and pauses for the rest of the month instead of billing if the free monthly compute limit is exhausted.
- Keep Azure SQL restricted to Render's listed outbound CIDR ranges; do not open it to all public IP addresses.

## Redeploy after a code change

Both repositories now use GitHub Actions:

- Backend pull requests and pushes must pass restore, Release build, tests,
  publish, and Docker image validation. Render is configured with
  `autoDeployTrigger: checksPass`, so it deploys `main` only after those checks
  succeed.
- Frontend pull requests and pushes must pass Flutter analysis, tests, Android
  compilation, and the production web build. A successful push to `main`
  deploys the exact tested web artifact to Firebase Hosting.

Before the first frontend CI deployment, add a GitHub Actions repository secret
named `FIREBASE_SERVICE_ACCOUNT` containing the complete Firebase service
account JSON key. Keep the existing PowerShell deployment script for an
authorized manual fallback.

If Firebase CLI created the project-specific secret name
`FIREBASE_SERVICE_ACCOUNT_THURAYA_TEST_AMR_202609`, the workflow accepts that
name as well. After correcting the previous immutable JavaScript cache policy,
existing testers might need one hard refresh or one site-data clear; subsequent
deployments revalidate Flutter files automatically.
