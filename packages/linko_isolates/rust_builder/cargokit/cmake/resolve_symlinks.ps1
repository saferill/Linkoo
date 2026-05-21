function Resolve-Symlinks {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $Path
    )

    $normalized = $Path.Replace('\', '/')
    $parts = $normalized.Split('/')

    [string] $realPath = ''
    foreach ($part in $parts) {
        if (-not $part) { continue }
        if ($realPath -and !$realPath.EndsWith('/')) {
            $realPath += '/'
        }
        $realPath += $part
        $item = Get-Item -LiteralPath $realPath -ErrorAction SilentlyContinue
        if ($item -and $item.Target) {
            $target = $item.Target
            if ($target -is [array]) { $target = $target[0] }
            $realPath = $target.Replace('\', '/')
        }
    }
    $realPath.Replace('\', '/')
}

$path=Resolve-Symlinks -Path $args[0]
Write-Host $path
