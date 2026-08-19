/// Default destinations: globally popular sites that Iran commonly filters.
class DomainTarget {
  const DomainTarget(this.host, {this.label});

  final String host;
  final String? label;

  String get short {
    final n = label ?? host;
    return n
        .replaceFirst(RegExp(r'^www\.'), '')
        .replaceFirst(RegExp(r'\.(com|org|net|tv|ai|us)$'), '');
  }
}

const List<DomainTarget> kDefaultDomains = [
  DomainTarget('youtube.com'),
  DomainTarget('instagram.com'),
  DomainTarget('facebook.com'),
  DomainTarget('x.com', label: 'x'),
  DomainTarget('twitter.com'),
  DomainTarget('telegram.org'),
  DomainTarget('whatsapp.com'),
  DomainTarget('discord.com'),
  DomainTarget('tiktok.com'),
  DomainTarget('reddit.com'),
  DomainTarget('netflix.com'),
  DomainTarget('twitch.tv'),
  DomainTarget('spotify.com'),
  DomainTarget('chatgpt.com'),
  DomainTarget('openai.com'),
  DomainTarget('google.com'),
  DomainTarget('gmail.com'),
  DomainTarget('github.com'),
  DomainTarget('wikipedia.org'),
  DomainTarget('linkedin.com'),
  DomainTarget('pinterest.com'),
  DomainTarget('bing.com'),
  DomainTarget('duckduckgo.com'),
  DomainTarget('cloudflare.com'),
  DomainTarget('amazon.com'),
  DomainTarget('bbc.com'),
  DomainTarget('nytimes.com'),
  DomainTarget('signal.org'),
  DomainTarget('zoom.us'),
  DomainTarget('claude.ai'),
];

class DnsResolver {
  const DnsResolver(this.name, this.address, {this.tag});

  final String name;
  final String address;
  final String? tag;

  String get short => tag ?? name;
}

/// Resolvers that matter for Iranian VPN work, plus global baselines.
const List<DnsResolver> kDefaultResolvers = [
  DnsResolver('Cloudflare', '1.1.1.1', tag: 'CF'),
  DnsResolver('Google', '8.8.8.8', tag: 'G8'),
  DnsResolver('Quad9', '9.9.9.9', tag: 'Q9'),
  DnsResolver('OpenDNS', '208.67.222.222', tag: 'OD'),
  DnsResolver('AdGuard', '94.140.14.14', tag: 'AG'),
  DnsResolver('Mullvad', '194.242.2.2', tag: 'MV'),
  DnsResolver('Control D', '76.76.2.0', tag: 'CD'),
  DnsResolver('Shecan', '178.22.122.100', tag: 'SH'),
  DnsResolver('Electro', '78.157.42.100', tag: 'EL'),
  DnsResolver('Radar', '10.202.10.10', tag: 'RD'),
  DnsResolver('403', '10.202.10.202', tag: '403'),
  DnsResolver('Begzar', '185.55.226.26', tag: 'BG'),
  DnsResolver('DNS Pro', '87.107.110.109', tag: 'DP'),
  DnsResolver('Level3', '4.2.2.1', tag: 'L3'),
];

class EdgeTarget {
  const EdgeTarget(this.ip, {this.sni = 'cloudflare.com', this.label});

  final String ip;
  final String sni;
  final String? label;

  String get short => label ?? ip;
}

const List<EdgeTarget> kDefaultEdges = [
  EdgeTarget('1.1.1.1', label: '1.1.1.1'),
  EdgeTarget('1.0.0.1', label: '1.0.0.1'),
  EdgeTarget('104.16.1.1', label: '104.16'),
  EdgeTarget('104.17.1.1', label: '104.17'),
  EdgeTarget('104.18.1.1', label: '104.18'),
  EdgeTarget('104.19.1.1', label: '104.19'),
  EdgeTarget('104.21.0.1', label: '104.21'),
  EdgeTarget('172.67.0.1', label: '172.67'),
];

class ProtoTarget {
  const ProtoTarget(this.id, this.label);

  final String id;
  final String label;
}

const List<ProtoTarget> kProtoTargets = [
  ProtoTarget('v4', 'v4'),
  ProtoTarget('v6', 'v6'),
  ProtoTarget('https', 'tls'),
  ProtoTarget('sni', 'sni'),
];
