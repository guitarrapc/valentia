using System;
using System.Runtime.InteropServices;
using System.ComponentModel;
using System.Text;
using Microsoft.Win32.SafeHandles;

namespace Valentia.CS
{
    public class SymbolicLink
    {
        private const int FileShareRead = 1;
        private const int FileShareWrite = 2;
        private const int CreationDispositionOpenExisting = 3;
        private const int FileFlagBackupSemantics = 0x02000000;

        internal static class Win32
        {
            [DllImport("kernel32.dll", SetLastError = true)]
            [return: MarshalAs(UnmanagedType.I1)]
            public static extern bool CreateSymbolicLink(string lpSymlinkFileName, string lpTargetFileName, SymLinkFlag dwFlags);

            [DllImport("kernel32.dll", EntryPoint = "GetFinalPathNameByHandleW", CharSet = CharSet.Unicode, SetLastError = true)]
            public static extern int GetFinalPathNameByHandle(IntPtr handle, [In, Out] StringBuilder path, int bufLen, int flags);

            [DllImport("kernel32.dll", EntryPoint = "CreateFileW", CharSet = CharSet.Unicode, SetLastError = true)]
            public static extern SafeFileHandle CreateFile(string lpFileName, int dwDesiredAccess, int dwShareMode, IntPtr SecurityAttributes, int dwCreationDisposition, int dwFlagsAndAttributes, IntPtr hTemplateFile);

            internal enum SymLinkFlag
            {
                File = 0,
                Directory = 1
            }
        }

        public static void CreateSymLink(string name, string target, bool isDirectory = false)
        {
            if (!Win32.CreateSymbolicLink(name, target, isDirectory ? Win32.SymLinkFlag.Directory : Win32.SymLinkFlag.File))
            {
                throw new Win32Exception();
            }
        }

        public static string GetSymbolicLinkTarget(System.IO.DirectoryInfo symlink)
        {
            var directoryHandle = Win32.CreateFile(symlink.FullName, 0, 2, IntPtr.Zero, CreationDispositionOpenExisting, FileFlagBackupSemantics, IntPtr.Zero);
            if (directoryHandle.IsInvalid) throw new Win32Exception(Marshal.GetLastWin32Error());

            var path = new StringBuilder(512);
            var size = Win32.GetFinalPathNameByHandle(directoryHandle.DangerousGetHandle(), path, path.Capacity, 0);
            if (size < 0) throw new Win32Exception(Marshal.GetLastWin32Error()); // The remarks section of GetFinalPathNameByHandle mentions the return being prefixed with "\\?\" // More information about "\\?\" here -> http://msdn.microsoft.com/en-us/library/aa365247(v=VS.85).aspx

            if (path[0] == '\\' && path[1] == '\\' && path[2] == '?' && path[3] == '\\')
            {
                return path.ToString().Substring(4);
            }
            return path.ToString();
        }
    }
}