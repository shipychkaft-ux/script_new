# Nightix remote shader package

Upload this folder to the same GitHub repository used by `MainScript.lua`.

Expected layout:

```text
MainScript.lua
ShaderBridge.lua
NeverLose.lua
...
shaders/
  manifest.json
  gradient.json
  gradient.vsh
  gradient.fsh
  ...
```

`ShaderBridge.lua` downloads only the JSON definition at runtime and renders compatible parts through Roblox APIs (`UIGradient`, `UICorner`, `UIStroke`, `BlurEffect`, `BloomEffect`, `ColorCorrectionEffect`). The original `.vsh/.fsh` are reference sources from SystemDLC; Roblox does not execute them directly.

Raw base URL used by Nightix:
`https://raw.githubusercontent.com/shipychkaft-ux/script_new/main/`

After uploading, the shader definition URL for `gradient` is:
`https://raw.githubusercontent.com/shipychkaft-ux/script_new/main/shaders/gradient.json`
