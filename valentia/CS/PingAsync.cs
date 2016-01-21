using System;
using System.Net;
using System.Threading.Tasks;
using System.Linq;
using System.Net.NetworkInformation;
using System.Net.Sockets;

namespace Valentia.CS
{
    public class DnsResponse
    {
        public string HostName { get; private set; }
        public IPAddress IPAddress { get; private set; }
        public bool IsResolved
        {
            get
            {
                IPAddress item = null;
                return !IPAddress.TryParse(this.HostName, out item);
            }
        }

        public DnsResponse(string hostName, IPAddress ip)
        {
            this.HostName = hostName;
            this.IPAddress = ip;
        }
    }

    public class DnsResolver
    {
        public static DnsResponse ResolveIP(IPAddress ip, TimeSpan timeout)
        {
            Func<IPAddress, IPHostEntry> callback = s => Dns.GetHostEntry(s);
            var result = callback.BeginInvoke(ip, null, null);
            if (!result.AsyncWaitHandle.WaitOne(timeout, false))
            {
                return new DnsResponse(ip.ToString(), ip);
            }
            var hostEntry = callback.EndInvoke(result);
            return new DnsResponse(hostEntry.HostName, ip);
        }

        public static DnsResponse ResolveHostName(string hostNameOrAddress, TimeSpan timeout)
        {
            Func<string, IPHostEntry> callback = s => Dns.GetHostEntry(s);
            var result = callback.BeginInvoke(hostNameOrAddress, null, null);
            if (!result.AsyncWaitHandle.WaitOne(timeout, false))
            {
                return new DnsResponse(hostNameOrAddress, null);
            }
            var hostEntry = callback.EndInvoke(result);
            var ip = hostEntry.AddressList.FirstOrDefault(x => x.AddressFamily == AddressFamily.InterNetwork);
            return new DnsResponse(hostNameOrAddress, ip);
        }
    }

    public class PingResponse
    {
        public string HostNameOrAddress { get; set; }
        public IPAddress IPAddress { get; set; }
        public IPStatus Status { get; set; }
        public bool IsSuccess { get; set; }
        public long RoundTripTime { get; set; }
        public bool IsResolved { get; set; }
    }

    public class NetworkInformationExtensions
    {
        private static readonly byte[] _buffer = new byte[16];
        private static readonly PingOptions _options = new PingOptions(64, false);
        private static readonly TimeSpan _pingTimeout = TimeSpan.FromMilliseconds(10);
        private static readonly TimeSpan _dnsTimeout = TimeSpan.FromMilliseconds(20);
        private static bool _resolveDns = true;

        public static async Task<PingResponse[]> PingAsync(string[] hostNameOrAddress)
        {
            return await PingAsync(hostNameOrAddress, _pingTimeout, _resolveDns, _dnsTimeout);
        }

        public static async Task<PingResponse[]> PingAsync(string[] hostNameOrAddress, TimeSpan pingTimeout)
        {
            return await PingAsync(hostNameOrAddress, pingTimeout, _resolveDns, _dnsTimeout);
        }

        public static async Task<PingResponse[]> PingAsync(string[] hostNameOrAddress, bool resolveDns)
        {
            return await PingAsync(hostNameOrAddress, _pingTimeout, resolveDns, _dnsTimeout);
        }

        public static async Task<PingResponse[]> PingAsync(string[] hostNameOrAddress, TimeSpan pingTimeout, bool resolveDns)
        {
            return await PingAsync(hostNameOrAddress, pingTimeout, resolveDns, _dnsTimeout);
        }

        public static async Task<PingResponse[]> PingAsync(string[] hostNameOrAddress, TimeSpan pingTimeout, TimeSpan dnsTimeout)
        {
            return await PingAsync(hostNameOrAddress, pingTimeout, _resolveDns, _dnsTimeout);
        }

        private static async Task<PingResponse[]> PingAsync(string[] hostNameOrAddress, TimeSpan pingTimeout, bool resolveDns, TimeSpan dnsTimeout)
        {
            var pingResult = await Task.WhenAll(hostNameOrAddress.Select(async x =>
            {
                // Resolve only when incoming is HostName.
                IPAddress ip = null;
                DnsResponse resolve = null;
                var isIpAddress = IPAddress.TryParse(x, out ip);
                if (!isIpAddress)
                {
                    resolve = DnsResolver.ResolveHostName(x, dnsTimeout);
                    ip = resolve.IPAddress;
                }

                // Execute PingAsync
                PingReply reply = null;
                using (var ping = new Ping())
                {
                    try
                    {
                        reply = await ping.SendPingAsync(ip, (int)pingTimeout.TotalMilliseconds, _buffer, _options);
                    }
                    catch
                    {
                        // ping throw should never stop operation. just return null.
                    }
                }

                // set RoundtripTime
                long roundTripTime = 0;
                if (reply != null) roundTripTime = reply.RoundtripTime;

                // set Status
                var status = IPStatus.DestinationHostUnreachable;
                if (reply != null) status = reply.Status;

                // set IsSuccess
                var isSuccess = status == IPStatus.Success;

                // return when PingFailed || HostName || OmitResolveDns
                if (!isSuccess || !isIpAddress || !resolveDns)
                    return new PingResponse
                    {
                        HostNameOrAddress = x,
                        IPAddress = ip,
                        Status = status,
                        RoundTripTime = roundTripTime,
                        IsSuccess = isSuccess,
                        IsResolved = !isIpAddress && ip != null,
                    };

                // Resolve Dns only for success host entry.
                var host = x;
                resolve = DnsResolver.ResolveIP(ip, dnsTimeout);
                if (resolve != null) host = resolve.HostName;
                return new PingResponse
                {
                    HostNameOrAddress = host,
                    IPAddress = ip,
                    Status = status,
                    RoundTripTime = roundTripTime,
                    IsSuccess = true,
                    IsResolved = resolve != null && resolve.IsResolved,
                };
            }).ToArray());
            return pingResult;
        }
    }
}