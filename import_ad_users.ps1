Import-Module ActiveDirectory

$NewDomain = "NEW_DOMAIN"
$ImportFile = "ADUsersExport.csv"

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
    }
    New-ADUser @UserProperties -Server $NewDomain
}
