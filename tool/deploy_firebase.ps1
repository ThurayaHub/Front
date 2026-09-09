[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9-]+$')]
    [string] $FirebaseProjectId,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^https://')]
    [string] $ApiBaseUrl
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter was not found on PATH.'
}

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    throw 'Node.js/npx was not found on PATH.'
}

$normalizedApiBaseUrl = $ApiBaseUrl.TrimEnd('/')

Write-Host 'Building Thuraya Flutter Web...'
& flutter build web --release "--dart-define=API_BASE_URL=$normalizedApiBaseUrl"
if ($LASTEXITCODE -ne 0) {
    throw 'Flutter Web build failed.'
}

Write-Host 'Deploying build/web to Firebase Hosting...'
& npx --yes firebase-tools@latest deploy --only hosting --project $FirebaseProjectId
if ($LASTEXITCODE -ne 0) {
    throw 'Firebase Hosting deployment failed. Run npx firebase-tools login and retry.'
}

Write-Host "Thuraya is available at https://$FirebaseProjectId.web.app"
