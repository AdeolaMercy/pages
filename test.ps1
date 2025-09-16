param(
    [string]$DomainName,
    [string]$SafeModeAdminPassword,
    [string]$DomainUser,
    [string]$DomainUserPassword
)

# Convert passwords to secure strings
$SecureSafeModePassword   = ConvertTo-SecureString $SafeModeAdminPassword -AsPlainText -Force
$SecureDomainUserPassword = ConvertTo-SecureString $DomainUserPassword -AsPlainText -Force

Write-Host "Installing AD-Domain-Services feature..."
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

Write-Host "Configuring Domain Controller..."
Install-ADDSForest `
    -DomainName $DomainName `
    -SafeModeAdministratorPassword $SecureSafeModePassword `
    -Force:$true `
    -NoRebootOnCompletion:$true

Write-Host "Domain setup complete. Preparing post-setup script..."

# Create post-setup script that will create the domain user after reboot
$PostScript = @"
Import-Module ActiveDirectory

# Create a new domain user
New-ADUser -Name "$DomainUser" `
    -SamAccountName "$DomainUser" `
    -AccountPassword (ConvertTo-SecureString "$DomainUserPassword" -AsPlainText -Force) `
    -Enabled $true

# Add user to Domain Admins group
Add-ADGroupMember -Identity "Domain Admins" -Members "$DomainUser"

# Restart computer (optional – comment if not needed)
# Restart-Computer -Force
"@

# Save post-domain setup script
$PostScriptPath = "C:\PostDomainSetup.ps1"
$PostScript | Out-File -FilePath $PostScriptPath -Encoding UTF8 -Force

# Schedule post-setup script to run at startup (once)
schtasks /create /sc onstart /tn "PostDomainSetup" /tr "powershell -ExecutionPolicy Bypass -File $PostScriptPath" /ru SYSTEM /f

Write-Host "Post-setup script created and scheduled. Rebooting now..."
Restart-Computer -Force
