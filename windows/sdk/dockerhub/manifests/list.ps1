function list($token,$image,$ref,$header,$registry="registry.hub.docker.com",$raw=$true){
  # application/vnd.docker.distribution.manifest.v2+json
  $header_default="application/vnd.docker.distribution.manifest.list.v2+json"

  if(!$header){
    $header=$header_default
  }

  $type = "manifest"

  if($header -eq $header_default){
    $type = "manifest list"
  }

  Write-host "==> Get [ $image $ref ] $type ..." -ForegroundColor Green

  . $PSScriptRoot/../cache/cache.ps1

  if (!($ref -is [string])) {
    $ref = $ref.toString()
  }

  $cache_file = getCachePath "manifest@${registry}@$($image.replace('/','@'))@$($ref.replace('sha256:','')).json"

  try{
    $result = Invoke-WebRequest `
      -Authentication OAuth `
      -Token (ConvertTo-SecureString $token -Force -AsPlainText) `
      -Headers @{"Accept" = "$header" } `
      "https://$registry/v2/$image/manifests/$ref" `
      -PassThru `
      -OutFile $cache_file `
      -UserAgent "Docker-Client/19.03.5 (Windows)"
  }catch{
    $result = $_.Exception.Response

    if($header -eq $header_default){
      # $result = $_.Exception.Response
      # write-host $result.StatusCode
      # $code = (ConvertFrom-Json $content).errors[0].code
      # if($code -ne "MANIFEST_UNKNOWN"){

      #   return
      # }

      Write-host "==> Get [ $image $ref ] $type error [ $($result.StatusCode) ], please try get manifest ..." -ForegroundColor Red

      if(!$raw){
        return $false
      }

      return ConvertFrom-Json -InputObject @"
{
  "schemaVersion": 1
}
"@
    }

    Write-Host "==> [error] Get [ $image $ref ] $type error [ $($result.StatusCode) ]" -ForegroundColor Red

    return $false
  }

  write-host "==> $type digest is $($result.Headers.'Docker-Content-Digest')" -ForegroundColor Green

  if($raw){
    return ConvertFrom-Json (Get-Content $cache_file -Raw)
  }

  return $cache_file
}
