param([string]$json = '_pcg_ground.json', [string]$proj = 'project_dsh01')
$base = "C:\Users\lenovo\AppData\Roaming\AI World Creator\projects\$proj"
$src = "$base\scene.data"
$tmp = "$base\scene.data.tmp"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$text = [System.IO.File]::ReadAllText("C:\Users\lenovo\OneDrive\Desktop\10.13CITYFREE\$json")
$zin = [System.IO.Compression.ZipFile]::OpenRead($src)
$fs = [System.IO.File]::Create($tmp)
$zout = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
foreach($e in $zin.Entries){
  $ne = $zout.CreateEntry($e.FullName, [System.IO.Compression.CompressionLevel]::Optimal)
  if($e.FullName -eq 'SerializePcgData.json'){
    $sw = New-Object System.IO.StreamWriter($ne.Open(), (New-Object System.Text.UTF8Encoding($false)))
    $sw.Write($text); $sw.Dispose()
  } else {
    $s = $e.Open(); $d = $ne.Open(); $s.CopyTo($d); $d.Dispose(); $s.Close()
  }
}
$zout.Dispose(); $fs.Dispose(); $zin.Dispose()
Move-Item $tmp $src -Force
"scene.data <- $json  proj=$proj size=$((Get-Item $src).Length)"
