# Load secrets
$tenantId = $env:TENANT_ID
$clientId = $env:CLIENT_ID
$clientSecret = $env:CLIENT_SECRET

# Get access token
$body = @{
    grant_type    = "client_credentials"
    scope         = "https://graph.microsoft.com/.default"
    client_id     = $clientId
    client_secret = $clientSecret
}
$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method POST -Body $body
$accessToken = $tokenResponse.access_token

# Set headers
$headers = @{
    Authorization = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

# Loop through policy files
$policyFiles = Get-ChildItem -Path "./compliance" -Filter *.json
foreach ($file in $policyFiles) {
    $policyJson = Get-Content $file.FullName -Raw
    $policy = $policyJson | ConvertFrom-Json

    # Example: Update existing policy by ID
    $policyId = $policy.id
    $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$policyId"

    Write-Host "Updating policy: $policyId"
    Invoke-RestMethod -Uri $uri -Method PATCH -Headers $headers -Body $policyJson
}
