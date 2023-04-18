Import-Module ActiveDirectory

$NewDomain = "NEW_DOMAIN"
$ImportFile = "ADUsersExport.csv"
$DefaultPassword = "TempPassword123!" # Set a default temporary password here

$securePassword = ConvertTo-SecureString $DefaultPassword -AsPlainText -Force

$users = Import-Csv -Path $ImportFile

ForEach ($user in $users) {
    $UserProperties = @{
        'SamAccountName' = $user.SamAccountName
        'GivenName' = $user.GivenName
        'Surname' = $user.Surname
        'DisplayName' = $user.DisplayName
        'EmailAddress' = $user.EmailAddress
        'Enabled' = $user.Enabled
        'Department' = $user.Department
        'Title' = $user.Title
        'StreetAddress' = $user.StreetAddress
        'City' = $user.City
        'PostalCode' = $user.PostalCode
        'Country' = $user.Country
        'OfficePhone' = $user.OfficePhone
        'MobilePhone' = $user.MobilePhone
        'Fax' = $user.Fax
        'UserPrincipalName' = $user.UserPrincipalName
        'AccountPassword' = $securePassword
    }
    New-ADUser @UserProperties -Server $NewDomain
}
