param (
  [Parameter(Mandatory = $true)][string]$resourceGroupName,
  [Parameter(Mandatory = $true)][string]$location
)

# Create Resource Group
Write-Host "Creating a Resource Group $resourceGroupName..."
az group create `
  --name $resourceGroupName `
  --location $location

if ($LASTEXITCODE -ne 0) {
  Write-Host "Failed to create Resource Group" -ForegroundColor Red
  exit 1
}
else {
  Write-Host "Resource Group is created"
}