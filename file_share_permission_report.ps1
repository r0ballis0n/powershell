# Define output file
$outputFile = "ShareReport.html"

# Initialize HTML content
$htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Share Report</title>
    <style>
        body { font-family: Arial, sans-serif; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid black; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        tr:hover { background-color: #ddd; }
        h1 { text-align: center; }
    </style>
</head>
<body>
    <h1>Share Report</h1>
    <table>
        <tr>
            <th>Share Name</th>
            <th>Share Path</th>
            <th>Share Permissions</th>
            <th>NTFS Permissions</th>
        </tr>
"@

$htmlFooter = @"
    </table>
</body>
</html>
"@

# Function to get share permissions
function Get-SharePermission($ShareName) {
    $permissions = @()
    $acls = Get-SmbShareAccess -Name $ShareName

    foreach ($acl in $acls) {
        if ($acl.AccountName -notmatch "NT Authority|Application Package Authority") {
            $permissions += $acl.AccountName + " (" + $acl.AccessControlType + " - " + $acl.AccessRight + ")<br>"
        }
    }

    return ($permissions -join '')
}

# Function to get NTFS permissions
function Get-NTFSPermission($FolderPath) {
    $permissions = @()
    $acls = Get-Acl -Path $FolderPath

    foreach ($ace in $acls.Access) {
        if ($ace.IdentityReference.Value -notmatch "NT Authority|Application Package Authority") {
            $permissions += $ace.IdentityReference.Value + " (" + $ace.FileSystemRights + ")<br>"
        }
    }

    return ($permissions -join '')
}

# Get shares and process them
$shares = Get-SmbShare -Special $false | Where-Object { $_.Name -ne 'print$' }
$shareRows = ""

foreach ($share in $shares) {
    $sharePath = $share.Path
    $shareName = $share.Name
    $sharePermissions = Get-SharePermission -ShareName $shareName
    $ntfsPermissions = Get-NTFSPermission -FolderPath $sharePath

    $shareRows += @"
        <tr>
            <td>$shareName</td>
            <td>$sharePath</td>
            <td>$sharePermissions</td>
            <td>$ntfsPermissions</td>
        </tr>
"@
}

# Write the HTML file
$htmlContent = $htmlHeader + $shareRows + $htmlFooter
$htmlContent | Set-Content -Path $outputFile
