#!/bin/bash
# Take a screenshot from WSL using PowerShell + Focus-Window module
# Usage: ./screenshot.sh [output.png] [window-title-pattern]
# Examples:
#   ./screenshot.sh screenshot.png VICE     # Capture VICE window
#   ./screenshot.sh screenshot.png          # Capture foreground window after delay

OUTPUT="${1:-screenshot.png}"
PATTERN="${2:-}"

# Convert WSL path to Windows path
if [[ "$OUTPUT" = /* ]]; then
    WIN_PATH=$(wslpath -w "$OUTPUT")
else
    WIN_PATH=$(wslpath -w "$(pwd)/$OUTPUT")
fi

if [[ -n "$PATTERN" ]]; then
    echo "Focusing and capturing window matching: $PATTERN"
    powershell.exe -Command "
        Import-Module Focus-Window -WarningAction SilentlyContinue -ErrorAction Stop
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
            using System;
            using System.Drawing;
            using System.Drawing.Imaging;
            using System.Runtime.InteropServices;
            public class Win32 {
                [DllImport(\"user32.dll\")]
                public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
                [DllImport(\"user32.dll\")]
                public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);
                [DllImport(\"user32.dll\")]
                public static extern bool SetForegroundWindow(IntPtr hWnd);
                [DllImport(\"user32.dll\")]
                public static extern IntPtr GetWindowDC(IntPtr hWnd);
                [DllImport(\"user32.dll\")]
                public static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);
                [DllImport(\"gdi32.dll\")]
                public static extern IntPtr CreateCompatibleDC(IntPtr hdc);
                [DllImport(\"gdi32.dll\")]
                public static extern IntPtr CreateCompatibleBitmap(IntPtr hdc, int nWidth, int nHeight);
                [DllImport(\"gdi32.dll\")]
                public static extern IntPtr SelectObject(IntPtr hdc, IntPtr hgdiobj);
                [DllImport(\"gdi32.dll\")]
                public static extern bool DeleteDC(IntPtr hdc);
                [DllImport(\"gdi32.dll\")]
                public static extern bool DeleteObject(IntPtr hObject);
                [StructLayout(LayoutKind.Sequential)]
                public struct RECT { public int Left, Top, Right, Bottom; }

                public static Bitmap CaptureWindow(IntPtr hWnd) {
                    RECT rect;
                    GetWindowRect(hWnd, out rect);
                    int width = rect.Right - rect.Left;
                    int height = rect.Bottom - rect.Top;

                    Bitmap bmp = new Bitmap(width, height, System.Drawing.Imaging.PixelFormat.Format32bppArgb);
                    Graphics gfxBmp = Graphics.FromImage(bmp);
                    IntPtr hdcBitmap = gfxBmp.GetHdc();

                    PrintWindow(hWnd, hdcBitmap, 2); // PW_RENDERFULLCONTENT = 2

                    gfxBmp.ReleaseHdc(hdcBitmap);
                    gfxBmp.Dispose();

                    return bmp;
                }
            }
'@
        # Find the window
        \$handle = Find-WindowHandle '$PATTERN'
        if (-not \$handle) {
            Write-Error 'Window not found: $PATTERN'
            exit 1
        }

        # Bring to front briefly
        [Win32]::SetForegroundWindow(\$handle) | Out-Null
        Start-Sleep -Milliseconds 200

        # Capture using PrintWindow
        \$bitmap = [Win32]::CaptureWindow(\$handle)
        \$bitmap.Save('$WIN_PATH', [System.Drawing.Imaging.ImageFormat]::Png)
        \$bitmap.Dispose()
        Write-Output 'Screenshot saved'
    " 2>&1
else
    echo "You have 3 seconds to focus the window..."
    sleep 3
    echo "Capturing foreground window..."
    powershell.exe -WindowStyle Hidden -Command "
        Start-Sleep -Milliseconds 200
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        Add-Type @'
            using System;
            using System.Runtime.InteropServices;
            public class Win32 {
                [DllImport(\"user32.dll\")] public static extern IntPtr GetForegroundWindow();
                [DllImport(\"user32.dll\")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
                [StructLayout(LayoutKind.Sequential)]
                public struct RECT { public int Left, Top, Right, Bottom; }
            }
'@
        \$hwnd = [Win32]::GetForegroundWindow()
        \$rect = New-Object Win32+RECT
        [Win32]::GetWindowRect(\$hwnd, [ref]\$rect) | Out-Null
        \$width = \$rect.Right - \$rect.Left
        \$height = \$rect.Bottom - \$rect.Top
        \$bitmap = New-Object System.Drawing.Bitmap(\$width, \$height)
        \$graphics = [System.Drawing.Graphics]::FromImage(\$bitmap)
        \$graphics.CopyFromScreen(\$rect.Left, \$rect.Top, 0, 0, \$bitmap.Size)
        \$bitmap.Save('$WIN_PATH', [System.Drawing.Imaging.ImageFormat]::Png)
        \$graphics.Dispose()
        \$bitmap.Dispose()
    " 2>/dev/null
fi

if [[ -f "$OUTPUT" ]]; then
    echo "Saved: $OUTPUT"
    ls -lh "$OUTPUT"
else
    echo "Error: Screenshot not saved"
fi
