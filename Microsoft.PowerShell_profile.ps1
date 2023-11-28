###########################################################################################
####                                  外观                                             ####
###########################################################################################

# $Prompt = "Welcome to PowerShell, KiyonoRin. "
# Write-Host $Prompt

## 去除默认的PowerShell提示(settings文件中修改)
#"commandline": "%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -Nologo",

## 自定义输出界面(建议去除，提升性能)
# $startWork = "                    _          _ _
#  _ __   _____      _____ _ __ ___| |__   ___| | |
# | '_ \ / _ \ \ /\ / / _ \ '__/ __| '_ \ / _ \ | |
# | |_) | (_) \ V  V /  __/ |  \__ \ | | |  __/ | |
# | .__/ \___/ \_/\_/ \___|_|  |___/_| |_|\___|_|_|
# |_|
# "
# Write-Host $startWork

## 设置Posh主题
# 已弃用, 现采用 starship
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/arrow.omp.json" | Invoke-Expression


###########################################################################################
####                                   功能拓展                                         ####
###########################################################################################

# 修复因为默认安装路径修改导致的变量定义不生效
$env:SCOOP = 'C:\UserScoop'
# $env:SCOOP_GLOBAL = 'C:\ProgramData\scoop'
# [Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP, 'Machine')
# 初始化 Starship
Invoke-Expression (&starship init powershell)

## 导入模块
# Import-Module ZLocation
Import-Module PSReadLine
import-Module Terminal-Icons

# 自动建议
Set-PSReadLineOption -PredictionSource History

# 命令补全
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -PredictionSource History
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit


###########################################################################################
####                                 自定义功能                                          ####
###########################################################################################

## 别名函数
function ListForce {
    Get-ChildItem -Force
}
# function DiskSystemInformation {
# & neofetch ; & duf ;
# }
function RecycleBinFolder {
    explorer.exe shell:RecycleBinFolder
}
function cd.. {
    Set-location ../..
}


# 定义别名
Set-Alias la ListForce
Set-Alias gh Get-Help
Set-Alias vi neovim
Set-Alias vi nvim
Set-Alias ll ChildItem
Set-Alias get-trash RecycleBinFolder
# Set-Alias top btop
# Set-Alias info DiskSystemInformation
# Set-Alias ... cd..


###########################################################################################
####                                 自定义函数                                          ####
###########################################################################################


function which ($command) {
    # 函数描述: 实现 Linux 上的 which 命令。
    #
    # 参数说明:
    # $command: 要查找的命令名称。
    #
    # 返回值说明:
    # 命令所在路径，如果命令不存在，则返回空字符串。
    #
    # 代码说明:
    # 1. 使用 Get-command cmdlet 获取命令的名称。
    # 2. 使用 Select-Object cmdlet 获取命令所在路径。
    Get-command -name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}


function trash {
    # 函数描述：用于删除文件至回收站，添加 Filter 参数。
    #
    # 参数说明：
    # $FilePaths：删除操作的文件路径数组。
    # $Filter：如果启用，将筛选出要删除的文件。
    # $FilterPattern：如果使用 -Filter，可以指定用于筛选文件的正则表达式模式。
    #
    # 返回值说明：
    # 无。

    # 代码说明：
    # 1. 使用 New-Object cmdlet 创建 Shell.Application 对象。
    # 2. 使用 Namespace 属性获取回收站对象。
    # 3. 使用 $allDeleted 变量记录是否全部删除成功。
    # 4. 遍历 $FilePaths 数组，获取每个文件路径。
    # 5. 如果启用 -Filter，则使用 Get-ChildItem cmdlet 获取符合筛选条件的文件。
    # 6. 使用 foreach 循环遍历所有文件，并尝试将其移动到回收站。
    # 7. 如果删除失败，则将 $allDeleted 变量设置为 false，并输出错误信息。
    # 8. 如果全部删除成功，则无需输出任何内容。
    param (
        [string[]]$FilePaths, # 删除操作的文件路径数组
        [switch]$Filter, # 如果启用，将筛选出要删除的文件
        [string]$FilterPattern # 如果使用 -Filter, 可以指定用于筛选文件的正则表达式模式
    )

    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.Namespace(0xA)

    $allDeleted = $true  # 用于记录是否全部删除成功

    foreach ($Path in $FilePaths) {
        $files = @()
        if ($Filter) {
            $filteredFiles = Get-ChildItem -Path $Path -File -Recurse | Where-Object { $_.Name -match $FilterPattern }
            $files += $filteredFiles
        }
        else {
            $files += Get-Item $Path
        }

        foreach ($file in $files) {
            try {
                $recycleBin.MoveHere($file.FullName)
            }
            catch {
                $allDeleted = $false
                Write-Host "删除失败: $($file.FullName) - $($_.Exception.Message)"
            }
        }
    }

    if ($allDeleted) {
        # 全部删除成功，不需要输出任何内容
    }
}


function OBS {
    # 函数描述：以管理员身份启动应用程序，并设置默认工作目录
    # 获取应用程序路径
    $appPath = "C:\UserScoop\apps\obs-studio\29.1.3\bin\64bit\obs64.exe"
    # 设置应用程序的默认工作目录
    $workingDirectory = "C:\UserScoop\apps\obs-studio\29.1.3\bin\64bit\"
    # 以管理员身份启动应用程序
    Start-Process $appPath -Verb RunAs -WorkingDirectory $workingDirectory
}


function Format-FileSize($Path, $Unit = "MB") {
    # 函数描述：将文件大小格式化为指定的单位。
    #
    # 参数说明：
    # $Path：文件路径。
    # $Unit：文件大小单位，默认为 MB。
    #
    # 返回值说明：
    # 文件大小，格式化为指定的单位。
    #
    # 代码说明：
    # 1. 获取文件大小。
    # 2. 进行错误检查。
    # 3. 将文件大小转换为指定的单位。
    # 4. 格式化文件大小。
    # 5. 输出文件大小。

    $length = Get-Item $Path | Select-Object Length

    $length = [int]$length.Length
    # 进行错误检查
    if ($length -eq $null) {
        throw "无法获取文件大小。"
    }

    switch ($Unit) {
        "B" {
            $output = $length
        }
        "KB" {
            $output = $length / 1KB
        }
        "MB" {
            $output = $length / 1MB
        }
        "GB" {
            $output = $length / 1GB
        }
        "TB" {
            $output = $length / 1TB
        }
        default {
            return "未知单位"
        }
    }
    $output = $output.ToString("0.0000")
    Write-Host "$output $Unit"
}

function Get-Mpv {
    # 函数描述：输出MPV的自定义帮助文档
    #
    # 参数说明：
    # $Path：文件路径。
    #
    # 返回值说明：
    # 无返回值。
    #
    # 代码说明：
    # 1. 获取参数。
    # 2. 判断参数。
    # 3. 打开文件。
    # 4. 读取文件内容。
    # 5. 关闭文件。
    # 6. 输出文件内容。

    Param(
        $Path = "E:\Scipts\mpv-help"
    )

    switch ($args[0]) {
        "-l" {
            $Path = "E:\Scipts\mpv-help" 
        }
        "-ll" {
            $Path = "E:\Scipts\mpvAnime4K-help"
        }
        default {
            # 无参数，使用默认路径
        }
    }

    try {
        $File = New-Object IO.StreamReader($Path)
        $Content = $File.ReadToEnd()
        $File.Close()
        Write-Host $Content
    }
    catch {
        Write-Error $_.Exception.Message
    }
}

