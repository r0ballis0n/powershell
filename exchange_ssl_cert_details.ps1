# Define the target server and port
$remoteServer = "<RemoteServer>"
$portNumber = <PortNumber>

try {
    # Create a TCP client and connect to the server
    $client = New-Object System.Net.Sockets.TcpClient
    $client.Connect($remoteServer, $portNumber)

    # Get the network stream
    $stream = $client.GetStream()
    $streamReader = New-Object System.IO.StreamReader -ArgumentList $stream
    $streamWriter = New-Object System.IO.StreamWriter -ArgumentList $stream

    # Read the SMTP server's greeting
    $response = $streamReader.ReadLine()
    Write-Host "Server response: $response"

    # Send the EHLO command
    $streamWriter.WriteLine("EHLO $remoteServer")
    $streamWriter.Flush()

    # Read the SMTP server's response
    while ($null  -ne ($response = $streamReader.ReadLine()) -and !$response.StartsWith("250 ")) {
        Write-Host "Server response: $response"
    }

    # Send the STARTTLS command
    $streamWriter.WriteLine("STARTTLS")
    $streamWriter.Flush()

    # Read the SMTP server's response
    $response = $streamReader.ReadLine()
    Write-Host "Server response: $response"

    # Upgrade the connection to SSL/TLS
    $sslStream = New-Object System.Net.Security.SslStream -ArgumentList $stream, $false, { $True }

    # Disable SSL certificate validation
    $sslStream.AuthenticateAsClient($remoteServer)
    
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $sslStream.RemoteCertificate

    # Close the SSL stream, network stream, and TCP connection
    $sslStream.Close()
    $stream.Close()
    $client.Close()

    # Display SSL certificate details
    $cert | Format-List -Property *
} catch {
    Write-Host "An error occurred while attempting to retrieve the SSL certificate details:"
    Write-Host $_.Exception.Message
}
