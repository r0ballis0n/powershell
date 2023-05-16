# Import the Active Directory module
Import-Module ActiveDirectory

# Specify the new UPN suffix and the OU
$newUPN = "newUPN.com"
$ou = "OU=Users,DC=example,DC=com"

# Log file
$logFile = "C:\AD_UPN_Change.log"

# Function to add new UPN suffix
function Add-UPNSuffix {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Suffix
    )

    try {
        $contextType = [System.DirectoryServices.ActiveDirectory.ContextType]::Domain
        $context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext($contextType)
        $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($context)
        $partitions = $domain.GetDirectoryEntry().psbase.children.find("CN=Partitions")
        $upnSuffixes = $partitions.psbase.children.find("CN=UPN Suffixes")

        if ($upnSuffixes.psbase.properties["uPNSuffixes"] -contains $Suffix) {
            Write-Output "UPN suffix $Suffix already exists."
            Add-Content -Path $logFile -Value "$(Get-Date) - UPN suffix $Suffix already exists."
        } else {
            $upnSuffixes.psbase.properties["uPNSuffixes"].add($Suffix)
            $upnSuffixes.psbase.CommitChanges()
            Write-Output "Added UPN suffix $Suffix."
            Add-Content -Path $logFile -Value "$(Get-Date) - Added UPN suffix $Suffix."
        }
    } catch {
        Write-Error $_.Exception.Message
        Add-Content -Path $logFile -Value "$(Get-Date) - Error: $($_.Exception.Message)"
    }
}

# Function to update user UPN
function Update-UserUPN {
    param(
        [Parameter(Mandatory=$true)]
        [string]$OU,
        [string]$UPN
    )

    try {
        Get-ADUser -Filter * -SearchBase $OU | ForEach-Object {
            $newUPN = "$($_.samAccountName)@$UPN"
            Set-ADUser $_ -UserPrincipalName $newUPN -PassThru
            Write-Output "Updated UPN for $($_.samAccountName) to $newUPN."
            Add-Content -Path $logFile -Value "$(Get-Date) - Updated UPN for $($_.samAccountName) to $newUPN."
        }
    } catch {
        Write-Error $_.Exception.Message
        Add-Content -Path $logFile -Value "$(Get-Date) - Error: $($_.Exception.Message)"
    }
}

# Add new UPN suffix
Add-UPNSuffix -Suffix $newUPN

# Update user UPN
Update-UserUPN -OU $ou -UPN $newUPN
``
