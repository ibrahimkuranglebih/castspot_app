import 'dart:io';

import 'package:lan_scanner/lan_scanner.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:network_info_plus/network_info_plus.dart';

class MdnsDevice {
  final String name;
  final String ip;

  MdnsDevice({required this.name, required this.ip});
}

class NetworkScanner {
  static const String _serviceType = '_http._tcp.local';
  static const String _serviceNameHint = 'pcmirrorserver'; 
  
  static Future<String?> findFlaskServerIp({int port = 5000}) async {
    final ipFromMdns = await _findViaMdns(port: port);
    if (ipFromMdns != null) return ipFromMdns;

    return _findViaSubnetScan(port: port);
  }


  static Future<String?> _findViaMdns({required int port}) async {
    final client = MDnsClient();
    try {
      await client.start();

      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(_serviceType),
      )) {
        if (!ptr.domainName.toLowerCase().contains(_serviceNameHint)) continue;

        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        )) {
          if (srv.port != port) continue;

          await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
          )) {
            final ipAddr = ip.address.address;
            stdout.writeln('mDNS: ditemukan di $ipAddr:$port');
            return ipAddr;
          }
        }
      }
    } catch (e) {
      stderr.writeln('💥 mDNS error: $e');
    } finally {
      client.stop();
    }

    stdout.writeln('⚠️  mDNS tidak menemukan service.');
    return null;
  }

  /// Mendapatkan daftar perangkat mDNS lengkap dengan nama dan IP.
  static Future<List<MdnsDevice>> scanMdnsDevices({int port = 5000}) async {
    final List<MdnsDevice> foundDevices = [];
    final client = MDnsClient();

    try {
      await client.start();

      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(_serviceType),
      )) {
        if (!ptr.domainName.toLowerCase().contains(_serviceNameHint)) continue;

        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        )) {
          if (srv.port != port) continue;

          await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
          )) {
            final ipAddr = ip.address.address;
            final hostname = srv.target
                .replaceAll('.$_serviceType', '')
                .replaceAll('.local', '')
                .replaceAll('.', '');

            final device = MdnsDevice(name: hostname, ip: ipAddr);
            stdout.writeln('✅ mDNS device ditemukan: ${device.name} @ ${device.ip}');
            foundDevices.add(device);
          }
        }
      }
    } catch (e) {
      stderr.writeln('💥 Error saat mDNS scanning: $e');
    } finally {
      client.stop();
    }

    return foundDevices;
  }

  /* ──────────────────────── FALLBACK SECTION ──────────────────────── */

  static Future<String?> _findViaSubnetScan({required int port}) async {
    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      if (ip == null) {
        stderr.writeln('❌ Tidak dapat mendeteksi IP Wi-Fi');
        return null;
      }

      final subnet = ip.substring(0, ip.lastIndexOf('.')) + '.0/24';
      stdout.writeln('🌐 Memulai scanning subnet: $subnet');

      final scanner = LanScanner();
      final stream = scanner.icmpScan(
        subnet,
        timeout: const Duration(seconds: 2),
      );

      final hosts = await stream.toList();

      for (final host in hosts.where((h) => h.pingTime != null)) {
        final hostIp = host.internetAddress.address;
        stdout.writeln('➡️ Mengecek port $port di $hostIp…');
        if (await _checkPortOpen(hostIp, port)) {
          stdout.writeln('✅ Flask server ditemukan di $hostIp:$port');
          return hostIp;
        }
      }

      stdout.writeln('❌ Tidak ditemukan server Flask di jaringan ini.');
      return null;
    } catch (e) {
      stderr.writeln('💥 Error saat scanning jaringan: $e');
      return null;
    }
  }

  static Future<bool> _checkPortOpen(String ip, int port) async {
    try {
      final socket = await Socket.connect(ip, port,
          timeout: const Duration(milliseconds: 500));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
