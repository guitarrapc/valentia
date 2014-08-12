internal static class Win32
{
    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool CreateSymbolicLink(string lpSymlinkFileName, string lpTargetFileName, SymLinkFlag dwFlags);
 
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
        throw new System.ComponentModel.Win32Exception();
    }
}