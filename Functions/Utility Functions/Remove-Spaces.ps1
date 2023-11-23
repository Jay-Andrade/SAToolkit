function Remove-Spaces {
    param (
        [Parameter(Mandatory = $TRUE, Position = 0)]
        [String]$inputString
    )

    $outputString = $inputString -replace "\s", ''

    return $outputString
}