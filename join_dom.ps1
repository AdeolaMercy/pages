param(
    [Parameter(Mandatory=$true)]
    [string]$DomainUser,

    [Parameter(Mandatory=$true)]
    [string]$DomainUserPassword,
    
    [Parameter(Mandatory=$false)]
    [string]$DomainName
)

# Convert password to SecureString
$SecurePassword = ConvertTo-SecureString $DomainUserPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential("test.local\$DomainUser", $SecurePassword)

Write-Output "Joining computer to domain..."
Add-Computer -DomainName test.local -Credential $Credential -Force -Restart
