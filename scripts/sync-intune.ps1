# ----------------------------------------
# 🔐 Step 1: Load secrets from environment
# ----------------------------------------
$tenantId = $env:TENANT_ID
$clientId = $env:CLIENT_ID
$clientSecret = $env:CLIENT_SECRET

# ----------------------------------------
# 🔗 Step 2: Authenticate with Microsoft Graph
# ----------------------------------------
$body = @{
    grant_type    = "client_credentials"
    scope         = "https://graph.microsoft.com/.default"
    client_id     = $clientId
    client_secret = $clientSecret
}

# Request access token from Azure AD
$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method POST -Body $body
$accessToken = $tokenResponse.access_token

# ----------------------------------------
# 📦 Step 3: Prepare headers for Graph API
# ----------------------------------------
$headers = @{
    Authorization = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

# ----------------------------------------
# 📁 Step 4: Loop through JSON policy files
# ----------------------------------------
$policyFiles = Get-ChildItem -Path "./Compliance" -Filter *.json
foreach ($file in $policyFiles) {
    Write-Host "📄 Processing file: $($file.Name)"
    
    $policyJson = Get-Content $file.FullName -Raw
    $policy = $policyJson | ConvertFrom-Json

    # Validate that 'id' exists
    if (-not $policy.id) {
        Write-Warning "⚠️ Skipping file '$($file.Name)' — missing 'id' field."
        continue
    }

    $policyId = $policy.id

    # ----------------------------------------
    # 🌐 Step 5: Connect to Microsoft Graph API
    # ----------------------------------------
    $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$policyId"

    Write-Host "🔄 Updating policy in Intune: $policyId"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method PATCH -Headers $headers -Body $policyJson
        Write-Host "✅ Successfully updated policy: $policyId"
        Write-Host "📨 Response from Microsoft Graph:"
        Write-Host ($response | ConvertTo-Json -Depth 5)
    } catch {
        Write-Error "❌ Failed to update policy: $policyId. Error: $_"
    }
}
