[DllImport("Advapi32.dll", SetLastError=true, EntryPoint="CredWriteW", CharSet=CharSet.Unicode)]
public static extern bool CredWrite([In] ref Credential userCredential, [In] UInt32 flags);

[StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
public struct Credential
{
   public UInt32 flags;
   public UInt32 type;
   public IntPtr targetName;
   public IntPtr comment;
   public System.Runtime.InteropServices.ComTypes.FILETIME lastWritten;
   public UInt32 credentialBlobSize;
   public IntPtr credentialBlob;
   public UInt32 persist;
   public UInt32 attributeCount;
   public IntPtr Attributes;
   public IntPtr targetAlias;
   public IntPtr userName;
}