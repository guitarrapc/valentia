using System;
using System.ComponentModel;
using System.Management.Automation;
using System.Runtime.InteropServices;

namespace Valentia.CS
{
    public enum CredType : uint
    {
        Generic = 1,
        DomainPassword = 2,
        DomainCertificate = 3,
        DomainVisiblePassword = 4,
        GenericCertificate = 5,
        DomainExtended = 6,
        Maximum = 7,  // Maximum supported cred Type
        MaximumEx = (Maximum + 1000),  // Allow new applications to run on old OSes
    }

    public class CredentialManager
    {
        public static void Write(string target, PSCredential credential, CredType type)
        {
            if (credential == null) throw new NullReferenceException("Credential");

            var user = credential.GetNetworkCredential().UserName;
            var pass = credential.GetNetworkCredential().Password;
            var domain = credential.GetNetworkCredential().Domain;
            if (!string.IsNullOrWhiteSpace(domain))
            {
                user = string.Format(@"{0}\{1}", domain, user);
            }
            var nativeCredential = new NativeWriteCredential
            {
                Flags = 0,
                Type = type,
                TargetName = Marshal.StringToCoTaskMemUni(target),
                UserName = Marshal.StringToCoTaskMemUni(user),
                AttributeCount = 0,
                Persist = 2,
                CredentialBlobSize = (uint)System.Text.Encoding.Unicode.GetByteCount(pass),
                CredentialBlob = Marshal.StringToCoTaskMemUni(pass),
            };
            if (!NativeMethod.CredWrite(ref nativeCredential, 0))
            {
                var errorCode = Marshal.GetLastWin32Error();
                throw new Exception("Failed to write credentials", new Win32Exception(errorCode));
            }
        }

        public static PSCredential Read(string target, CredType type, string userName)
        {
            IntPtr credentialPtr;
            if (!NativeMethod.CredRead(target, type, 0, out credentialPtr))
            {
                throw new NullReferenceException("Failed to find credentials in Windows Credential Manager. TargetName: {0}, Type {1}");
            }

            var handler = new CriticalCredentialHandle(credentialPtr);
            var credential = handler.GetCredential();
            if (string.IsNullOrWhiteSpace(userName))
            {
                userName = credential.UserName;
            }
            var secureString = new System.Security.SecureString();
            foreach (var c in credential.CredentialBlob)
                secureString.AppendChar(c);
            var psCredential = new PSCredential(userName, secureString);
            return psCredential;
        }

        public static bool Exists(string target, CredType type)
        {
            try
            {
                Read(target, type, "");
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        public static void Remove(string target, CredType type)
        {
            if (!NativeMethod.CredDelete(target, type, 0))
            {
                throw new NullReferenceException(string.Format("Failed to find credentials in Windows Credential Manager. TargetName: {0}, Type {1}", target, type));
            }
        }
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct NativeReadCredential
    {
        public uint Flags;
        public CredType Type;
        public string TargetName;
        public string Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public uint CredentialBlobSize;
        public string CredentialBlob;
        public uint Persist;
        public uint AttributeCount;
        public IntPtr Attributes;
        public string TargetAlias;
        public string UserName;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    internal struct NativeWriteCredential
    {
        public uint Flags;
        public CredType Type;
        public IntPtr TargetName;
        public IntPtr Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public uint CredentialBlobSize;
        public IntPtr CredentialBlob;
        public uint Persist;
        public uint AttributeCount;
        public IntPtr Attributes;
        public IntPtr TargetAlias;
        public IntPtr UserName;

        public static NativeWriteCredential GetNativeCredential(NativeReadCredential cred)
        {
            var nativeCredential = new NativeWriteCredential
            {
                AttributeCount = 0,
                Attributes = IntPtr.Zero,
                Comment = IntPtr.Zero,
                TargetAlias = IntPtr.Zero,
                Type = CredType.Generic,
                Persist = (uint)1,
                CredentialBlobSize = (uint)cred.CredentialBlobSize,
                TargetName = Marshal.StringToCoTaskMemUni(cred.TargetName),
                CredentialBlob = Marshal.StringToCoTaskMemUni(cred.CredentialBlob),
                UserName = Marshal.StringToCoTaskMemUni(Environment.UserName)
            };
            return nativeCredential;
        }
    }

    internal class CriticalCredentialHandle : Microsoft.Win32.SafeHandles.CriticalHandleZeroOrMinusOneIsInvalid
    {
        public CriticalCredentialHandle(IntPtr preexistingHandle)
        {
            this.SetHandle(preexistingHandle);
        }

        public NativeReadCredential GetCredential()
        {
            if (this.IsInvalid) throw new InvalidOperationException("Invalid CriticalHandle!");
            var ncred = (NativeWriteCredential)Marshal.PtrToStructure(this.handle, typeof(NativeWriteCredential));
            var cred = new NativeReadCredential
            {
                CredentialBlobSize = ncred.CredentialBlobSize,
                CredentialBlob = Marshal.PtrToStringUni(ncred.CredentialBlob, (int) ncred.CredentialBlobSize / 2),
                UserName = Marshal.PtrToStringUni(ncred.UserName),
                TargetName = Marshal.PtrToStringUni(ncred.TargetName),
                TargetAlias = Marshal.PtrToStringUni(ncred.TargetAlias),
                Type = ncred.Type,
                Flags = ncred.Flags,
                Persist = ncred.Persist
            };
            return cred;
        }

        protected override bool ReleaseHandle()
        {
            if (this.IsInvalid) return false;
            NativeMethod.CredFree(this.handle);
            this.SetHandleAsInvalid();
            return true;
        }
    }

    internal class NativeMethod
    {
        [DllImport("Advapi32.dll", SetLastError = true, EntryPoint = "CredWriteW", CharSet = CharSet.Unicode)]
        public static extern bool CredWrite([In] ref NativeWriteCredential userWriteCredential, [In] uint flags);

        [DllImport("Advapi32.dll", EntryPoint = "CredReadW", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern bool CredRead(string target, CredType type, int reservedFlag, out IntPtr CredentialPtr);

        [DllImport("Advapi32.dll", EntryPoint = "CredFree", SetLastError = true)]
        public static extern bool CredFree([In] IntPtr cred);

        [DllImport("Advapi32.dll", EntryPoint = "CredDeleteW", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern bool CredDelete(string target, CredType type, int reservedFlag);
    }
}
