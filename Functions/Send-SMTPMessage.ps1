<#
.SYNOPSIS
This function allows sending an email through an SMTP server. Tested with SMTP2Go.

.PARAMETER To
Address of the recipient to receive the email. Can be an array of recipients.

.PARAMETER From
The displayed name of the sender that the recipient will see.

.PARAMETER Subject
The subject of the message being sent. Defaults to "Automated message from: $To"

.PARAMETER Body
The primary body of the message formatted with HTML.

.PARAMETER URL
The RESTAPI URL of the SMTP service to call. Defaults to SMTP2Go.

.PARAMETER APIKey
The APIKey to use when calling the RestMethod.

.EXAMPLE
Send-SMTPMessage -To 'recipient@example.com' -From 'sender@example.net' -Subject 'Example' -Body 'Example' -APIKey $APIKey
#>
function Send-SMTPMessage {

    Param (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        [Array]$To,

        [Parameter(Mandatory = $TRUE, Position = 1)]
        [String]$From,

        [Parameter(Position = 2)]
        [String]$Subject = "Automated message from: $($from)",

        [Parameter(Mandatory = $TRUE, Position = 3)]
        [String]$Body,

        [Parameter(Position = 4)]
        [String]$URL = 'https://api.smtp2go.com/v3/email/send',

        [Parameter(Mandatory = $TRUE, Position = 5)]
        [String]$APIKey
    )

    $payload = @{
        api_key = $APIKey
        to = $To
        sender = $SenderAddress
        subject = $Subject
        html_body = $Body

    } | ConvertTo-Json

    $requestparams = @{
        method = 'POST'
        body = $payload
        ContentType = "application/json"
        uri = $URL
    }

    try {
        $response = Invoke-RestMethod @requestparams
        if ($response.data.succeeded -eq 1) {
            Write-Syslog -Category 'INFO' -Message "Successfully sent SMTP Message to: $To with subject: $Subject"
        } else {
            Write-Syslog -Category 'WARN' -Message "Tried to send SMTP Message to: $To with subject: $Subject. Did not receive any error or success message."
        }
    }
    catch {
        Write-Syslog -Category 'ERROR' -Message "Failed to send SMTP Message to: $To with subject: $Subject. Error: $_"
    }
}