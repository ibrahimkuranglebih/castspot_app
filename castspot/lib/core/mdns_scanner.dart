import 'package:multicast_dns/multicast_dns.dart';

class MdnsScanner {
  static Future<String?> findPCMirrorServer({String serviceType = '_http._tcp.local'}) async {
    final client = MDnsClient();
    try {
      await client.start();

      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(serviceType),
      )) {
        if (!ptr.domainName.contains('PCMirrorServer')) continue;

        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        )) {
          await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
          )) {
            final ipAddress = ip.address.address;
            print('✅ mDNS: Ditemukan PCMirrorServer di $ipAddress:${srv.port}');
            return ipAddress;
          }
        }
      }
    } catch (e) {
      print('💥 mDNS Error: $e');
    } finally {
      client.stop();
    }
    return null;
  }
}
