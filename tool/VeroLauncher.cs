using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

[assembly: AssemblyTitle("VeroApp SMS Guard")]
[assembly: AssemblyDescription("VeroApp SMS Guard - Cyberpunk Local AI Launcher")]
[assembly: AssemblyCompany("VeroApp Security")]
[assembly: AssemblyProduct("VeroApp SMS Guard")]
[assembly: AssemblyVersion("1.0.3.0")]
[assembly: AssemblyFileVersion("1.0.3.0")]

namespace VeroAppSmsGuardLauncher
{
    static class Program
    {
        [STAThread]
        static int Main(string[] args)
        {
            try
            {
                bool selfTest = args != null && args.Length > 0 && args[0] == "--self-test";
                string exeDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\', '/');
                string projectDir = exeDir;

                // If launched directly from Desktop (C:\Users\ASUS\Desktop\VeroAppSmsGuard.exe),
                // resolve the SPAM ENGELLEME workspace folder automatically.
                string subWorkspace = Path.Combine(exeDir, "SPAM ENGELLEME");
                if (Directory.Exists(subWorkspace))
                {
                    projectDir = subWorkspace;
                }

                string flutterExe = Path.Combine(
                    projectDir,
                    "trustlens_mobile",
                    "build",
                    "windows",
                    "x64",
                    "runner",
                    "Release",
                    "trustlens_mobile.exe"
                );

                string htmlPath = Path.Combine(projectDir, "junkman_pro_live.html");

                if (selfTest)
                {
                    bool ok = File.Exists(flutterExe) || File.Exists(htmlPath);
                    Console.WriteLine("SELF_TEST_OK=" + ok + " PROJECT_DIR=" + projectDir);
                    return ok ? 0 : 1;
                }

                // 1. Prefer native Flutter Windows Release build if present
                if (File.Exists(flutterExe))
                {
                    Process.Start(new ProcessStartInfo
                    {
                        FileName = flutterExe,
                        WorkingDirectory = Path.GetDirectoryName(flutterExe),
                        UseShellExecute = true
                    });
                    return 0;
                }

                // 2. Fallback to standalone Chromium/Edge App-Window simulator
                if (File.Exists(htmlPath))
                {
                    string fileUri = new Uri(htmlPath).AbsoluteUri;
                    string[] browsers = new string[]
                    {
                        @"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
                        @"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
                        @"C:\Program Files\Google\Chrome\Application\chrome.exe",
                        @"C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"
                    };

                    foreach (string browser in browsers)
                    {
                        if (File.Exists(browser))
                        {
                            Process.Start(new ProcessStartInfo
                            {
                                FileName = browser,
                                Arguments = "--app=\"" + fileUri + "\" --window-size=960,860",
                                UseShellExecute = false
                            });
                            return 0;
                        }
                    }

                    Process.Start(new ProcessStartInfo
                    {
                        FileName = htmlPath,
                        UseShellExecute = true
                    });
                    return 0;
                }

                MessageBox.Show(
                    "VeroApp SMS Guard çalışma dosyası bulunamadı:\n" + projectDir,
                    "VeroApp SMS Guard v1.0.0",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Warning
                );
                return 1;
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "VeroApp SMS Guard başlatılırken hata oluştu:\n" + ex.Message,
                    "VeroApp SMS Guard v1.0.0",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
                return 1;
            }
        }
    }
}
