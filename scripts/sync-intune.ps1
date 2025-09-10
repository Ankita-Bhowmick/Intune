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

# Loop through policy files in Compliance folder
$policyFiles = Get-ChildItem -Path "./Compliance" -Filter *.json
foreach ($file in $policyFiles) {
    Write-Host "Processing file: $($file.Name)"
    
    $policyJson = Get-Content $file.FullName -Raw
    $policy = $policyJson | ConvertFrom-Json

    # Check if 'id' exists
    if (-not $policy.id) {
        Write-Warning "Skipping file '$($file.Name)' — missing 'id' field."
        continue
    }

    $policyId = $policy.id
    $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$policyId"

    Write-Host "Updating policy: $policyId"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method PATCH -Headers $headers -Body $policyJson
        Write-Host "✅ Successfully updated policy: $policyId"
        Write-Host "Response from Graph API:"
        Write-Host ($response | ConvertTo-Json -Depth 5)
    } catch {
        Write-Error "❌ Failed to update policy: $policyId. Error: $_"
    }
}
