Import-Module ActiveDirectory

$OldDomain = "OLD_DOMAIN"
$ExportFile = "ADUsersExport.csv"

Get-ADUser -Filter * -Server $OldDomain -Properties * |
Select-Object SamAccountName, GivenName, Surname, DisplayName, EmailAddress, Enabled, Department, Title, StreetAddress, City, PostalCode, Country, OfficePhone, MobilePhone, Fax, UserPrincipalName, Manager |
Export-Csv -Path $ExportFile -NoTypeInformation
