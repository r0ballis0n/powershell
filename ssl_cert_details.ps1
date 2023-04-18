# Define the target server and port
$remoteServer = "<RemoteServer>"
$portNumber = <PortNumber>

try {
    # Create a TCP client and connect to the server
    $client = New-Object System.Net.Sockets.TcpClient
    $client.Connect($remoteServer, $portNumber)

    # Get the SSL certificate
    $sslStream = New-Object System.Net.Security.SslStream -ArgumentList $client.GetStream()

    # Specify the SSL/TLS protocol versions
    $sslProtocols = @([System.Security.Authentication.SslProtocols]::Tls12, [System.Security.Authentication.SslProtocols]::Tls13)
    $success = $false

    foreach ($sslProtocol in $sslProtocols) {
        try {
            $sslStream.AuthenticateAsClient($remoteServer, $null, $sslProtocol, $false)
            $success = $true
            break
        } catch {
            # Continue to the next protocol version
        }
    }

    if (-not $success) {
        throw "Failed to establish SSL/TLS connection using any of the specified protocol versions"
    }

    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $sslStream.RemoteCertificate

    # Close the TCP connection and the SSL stream
    $sslStream.Close()
    $client.Close()

    # Display SSL certificate details
    $cert | Format-List -Property *
} catch {
    Write-Host "An error occurred while attempting to retrieve the SSL certificate details:"
    Write-Host $_.Exception.Message
}
