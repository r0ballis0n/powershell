# Import Active Directory module if not already imported
if (-not (Get-Module -Name ActiveDirectory)) {
    Import-Module ActiveDirectory
}

# Variables
$outputFile = "ADGroupsReport.html"
$OUs = @() # Leave empty for all OUs, or specify one or more OUs like: @("OU=Example1,DC=domain,DC=com", "OU=Example2,DC=domain,DC=com")

# Initialize HTML content
$htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>AD Groups Report</title>
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
    <h1>AD Groups Report</h1>
    <table>
        <tr>
            <th>Group Name</th>
            <th>Members</th>
        </tr>
"@

$htmlFooter = @"
    </table>
</body>
</html>
"@

# Function to get group members
function Get-GroupMembers($Group) {
    $members = Get-ADGroupMember -Identity $Group -Recursive | Sort-Object Name
    $memberList = ""

    foreach ($member in $members) {
        $memberList += $member.Name + "<br>"
    }

    return $memberList
}

# Get groups and process them
if ($OUs.Count -eq 0) {
    $groups = Get-ADGroup -Filter * | Sort-Object Name
} else {
    $groups = @()
    foreach ($OU in $OUs) {
        $groups += Get-ADGroup -Filter * -SearchBase $OU | Sort-Object Name
    }
}

$groupRows = ""

foreach ($group in $groups) {
    $groupName = $group.Name
    $groupMembers = Get-GroupMembers -Group $group

    $groupRows += @"
        <tr>
            <td>$groupName</td>
            <td>$groupMembers</td>
        </tr>
"@
}

# Write the HTML file
$htmlContent = $htmlHeader + $groupRows + $htmlFooter
$htmlContent | Set-Content -Path $outputFile
