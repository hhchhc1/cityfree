$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
function Shot($url, $out, $w = 1600, $h = 1000) {
  if (Test-Path $out) { Remove-Item $out -Force }
  $a = @("--headless=new", "--disable-gpu", "--enable-unsafe-swiftshader", "--hide-scrollbars", "--window-size=$w,$h", "--virtual-time-budget=90000", "--screenshot=$out", $url)
  $pr = Start-Process -FilePath $edge -ArgumentList $a -PassThru -NoNewWindow
  $pr.WaitForExit(180000) | Out-Null
  if (!$pr.HasExited) { $pr.Kill() }
  Start-Sleep -Seconds 1
  if (Test-Path $out) { "OK $out $((Get-Item $out).Length)" } else { "FAIL $out" }
}
Shot "http://127.0.0.1:8811/viewer.html?scale1&fix" "C:\Users\lenovo\OneDrive\Desktop\10.13CITYFREE\shots\cmp_packs.png"
Shot "http://127.0.0.1:8811/viewer.html?tiles&fix" "C:\Users\lenovo\OneDrive\Desktop\10.13CITYFREE\shots\cmp_tiles.png"
