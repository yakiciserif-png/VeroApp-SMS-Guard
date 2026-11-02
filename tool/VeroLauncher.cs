using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

[assembly: AssemblyTitle("VeroApp SMS Guard")]
[assembly: AssemblyDescription("VeroApp SMS Guard - Cyberpunk Local AI Launcher")]
[assembly: AssemblyCompany("VeroApp Security")]
[assembly: AssemblyProduct("VeroApp SMS Guard")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

namespace VeroAppSmsGuardLauncher
{
    static class Program
    {
        [STAThread]
        static int Main(string[] args)
        {
            try
            {
                string exeDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\', '/');
                string releaseDir = Path.Combine(exeDir, "build", "windows", "x64", "runner", "Release");
                string flutterExe = Path.Combine(releaseDir, "VeroAppSmsGuard.exe");

                if (File.Exists(flutterExe))
                {
                    Process.Start(new ProcessStartInfo
                    {
                        FileName = flutterExe,
                        WorkingDirectory = releaseDir,
                        UseShellExecute = false
                    });
                    return 0;
                }

                MessageBox.Show(
                    "VeroApp SMS Guard çalışma dosyası bulunamadı:\n" + flutterExe,
                    "VeroApp SMS Guard v1.0",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Warning
                );
                return 1;
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "VeroApp SMS Guard başlatılırken hata oluştu:\n" + ex.Message,
                    "VeroApp SMS Guard v1.0",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
                return 1;
            }
        }
    }
}
