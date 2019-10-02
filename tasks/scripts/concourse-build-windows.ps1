. .\ci\tasks\scripts\go-build.ps1

$sha = & git -C concourse rev-parse HEAD
$archive = "concourse-${sha}-windows-amd64.zip"

# can't figure out how to pass an empty string arg in PowerShell, so just
# configure a noop for the fallback
$ldflags = "-X noop.Noop=noop"
if (Test-Path "final-version\version") {
  $finalVersion = (Get-Content "final-version\version")
  $ldflags = "-X github.com/concourse/concourse.Version=$finalVersion"
}

Push-Location concourse
  go install github.com/gobuffalo/packr/packr
  packr build -o concourse.exe -ldflags "$ldflags" ./cmd/concourse
  mv concourse.exe ..\concourse-windows
Pop-Location

Push-Location concourse-windows
  mkdir bin
  mv concourse.exe bin

  mkdir fly-assets
  if (Test-Path "..\fly-linux") {
    cp ..\fly-linux\fly-*.tgz fly-assets
  }

  if (Test-Path "..\fly-windows") {
    cp ..\fly-windows\fly-*.zip fly-assets
  }

  if (Test-Path "..\fly-darwin") {
    cp ..\fly-darwin\fly-*.tgz fly-assets
  }

  mkdir concourse
  mv bin concourse
  mv fly-assets concourse

  Compress-Archive `
    -LiteralPath .\concourse `
    -DestinationPath ".\${archive}"

  Get-FileHash -Algorithm SHA1 ".\${archive}" | `
    Out-File -Encoding utf8 ".\${archive}.sha1"

  Remove-Item .\concourse -Recurse
Pop-Location
