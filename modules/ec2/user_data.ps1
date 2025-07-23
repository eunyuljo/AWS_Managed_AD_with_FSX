<powershell>
# Set execution policy
Set-ExecutionPolicy Unrestricted -Force

# Configure DNS to use AD servers
$networkAdapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
foreach ($adapter in $networkAdapters) {
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses "${domain_dns_ips}"
}

# Wait for network connectivity
Start-Sleep -Seconds 30

# Create domain join script
$domainJoinScript = @"
`$domain = "${domain_name}"
`$username = "`$domain\${admin_username}"
`$password = ConvertTo-SecureString "${admin_password}" -AsPlainText -Force
`$credential = New-Object System.Management.Automation.PSCredential(`$username, `$password)

try {
    # Join domain
    Add-Computer -DomainName `$domain -Credential `$credential -Restart -Force
    Write-Output "Successfully joined domain `$domain"
} catch {
    Write-Output "Failed to join domain: `$_"
    # Log error for troubleshooting
    `$_ | Out-File -FilePath C:\domain_join_error.log
}
"@

# Save and execute domain join script
$domainJoinScript | Out-File -FilePath C:\domain_join.ps1 -Encoding UTF8

# Execute domain join with retry logic
$maxRetries = 3
$retryCount = 0
$joined = $false

while ($retryCount -lt $maxRetries -and -not $joined) {
    try {
        & powershell.exe -ExecutionPolicy Bypass -File C:\domain_join.ps1
        $joined = $true
    } catch {
        $retryCount++
        Write-Output "Domain join attempt $retryCount failed. Retrying in 60 seconds..."
        Start-Sleep -Seconds 60
    }
}

if (-not $joined) {
    Write-Output "Failed to join domain after $maxRetries attempts"
}

# Install FSx client tools (optional)
try {
    Install-WindowsFeature -Name FS-SMB1 -IncludeManagementTools
    Write-Output "SMB client features installed"
} catch {
    Write-Output "Failed to install SMB features: $_"
}

# Create log entry
$logEntry = "$(Get-Date): EC2 instance initialization completed. Domain join attempted for ${domain_name}"
$logEntry | Out-File -FilePath C:\ec2_init.log -Append

</powershell>