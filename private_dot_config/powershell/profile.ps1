
#region conda initialize
# !! Contents within this block are managed by 'conda init' !!
If (Test-Path "/home/froa/miniconda3/bin/conda") {
    (& "/home/froa/miniconda3/bin/conda" "shell.powershell" "hook") | Out-String | ?{$_} | Invoke-Expression
}
#endregion

