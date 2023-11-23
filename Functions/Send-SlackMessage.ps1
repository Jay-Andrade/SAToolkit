<#
.SYNOPSIS
This function allows automated message posting in Slack.

.PARAMETER messageBody
The body of the message that will be displayed in Slack.

.PARAMETER URL
Slack API URL, should not need to be changed for internal use.

.PARAMETER Username
Optional. The username in Slack the message will display as being from.

.PARAMETER Channel
The Slack channel the message will display in. Defaults to RMM Automation chanel.

.PARAMETER Emoji
Optional emoji to add to message. Use the Slack name for the emoji.

.PARAMETER IconURL
Optional URL for icon to add to message.

.EXAMPLE
$SlackMessage = "*#$ticket Onboarding Log for: $user*`n`nPSA Ticket:``````$ticketurl`````` `nLog file download: ``````$FileURL`````` `n"
Send-SlackMessage -MessageBody $SlackMessage -Username "Automation Bot" -url $slackURL -channel $slackChannel
Will post a message regarding automated user onboarding in the specified Slack channel. $slackMessage included to provide idea of formatting.

#>
function Send-SlackMessage {
    param (
        [Parameter(Mandatory = $TRUE, Position=0)]
        [String]$MessageBody,

        [Parameter(Mandatory = $TRUE, Position = 1)] # Add the "Incoming WebHooks" integration to get started: https://slack.com/apps/A0F7XDUAZ-incoming-webhooks
        [String]$Url, 

        [Parameter(Position = 2)]
        [String]$Username = 'SACommon',

        [Parameter(Mandatory = $TRUE, Position = 3)] #RMM Automation chanel by default
        [String]$Channel,

        [Parameter(Position = 4)]
        [String]$Emoji,

        [Parameter(Position = 5)]
        [String]$IconUrl
    )

    

    $body = @{ 
        text = $MessageBody
        channel = $Channel
        username = $Username
        icon_emoji = $Emoji
        icon_url = $IconUrl 
    } | ConvertTo-Json

    $Params = @{
        method = 'POST'
        body = $body
        ContentType = "application/json"
        uri = $url
    }

    try {
        Invoke-RestMethod @Params
        Write-Syslog -category 'INFO' -message "Posted message to Slack successfully." -displayMessage
    } catch {
        Write-Syslog -category 'ERROR' -message "Failed to post message to Slack: $_" -displayMessage
    }
}