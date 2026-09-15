# Android VpnService + sing-box / libbox

Sources in this folder are copied into the generated `android/` tree by
`./tool/bootstrap.sh` (or `tool/bootstrap.ps1`). Compile `libbox.aar` with
`./tool/build_libbox.sh` on a machine that has Go and the Android NDK. Do not
commit the AAR. After the AAR exists, re-run bootstrap so it is linked from
`android/app/libs`.
