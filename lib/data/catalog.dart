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
  const DnsResolver(
    this.name,
    this.address, {
    this.tag,
    this.organization,
    this.location = 'Global Anycast',
    this.description,
    this.isIranian = false,
  });

  final String name;
  final String address;
  final String? tag;
  final String? organization;
  final String location;
  final String? description;
  final bool isIranian;

  String get short => tag ?? name;
}

/// Resolvers that matter for Iranian VPN work, plus global baselines.
const List<DnsResolver> kDefaultResolvers = [
  DnsResolver(
    'Cloudflare',
    '1.1.1.1',
    tag: 'CF',
    organization: 'Cloudflare, Inc.',
    location: 'Global Anycast',
    description:
        'Ultra-fast privacy-centric public resolver with global Anycast edge presence.',
  ),
  DnsResolver(
    'Google',
    '8.8.8.8',
    tag: 'G8',
    organization: 'Google LLC',
    location: 'Global Anycast',
    description: 'Worldwide public DNS service operated by Google.',
  ),
  DnsResolver(
    'Quad9',
    '9.9.9.9',
    tag: 'Q9',
    organization: 'Quad9 Foundation',
    location: 'Switzerland / Global',
    description:
        'Non-profit security resolver focused on malware blocking and zero logging.',
  ),
  DnsResolver(
    'OpenDNS',
    '208.67.222.222',
    tag: 'OD',
    organization: 'Cisco Systems',
    location: 'Global Anycast',
    description:
        'Cisco-owned enterprise and consumer DNS with threat filtering.',
  ),
  DnsResolver(
    'AdGuard',
    '94.140.14.14',
    tag: 'AG',
    organization: 'AdGuard Software',
    location: 'Cyprus / Global',
    description: 'Privacy resolver with ad, tracker, and phishing protection.',
  ),
  DnsResolver(
    'Mullvad',
    '194.242.2.2',
    tag: 'MV',
    organization: 'Mullvad VPN',
    location: 'Sweden',
    description:
        'Strict no-logging DNS service operated by Swedish privacy company Mullvad.',
  ),
  DnsResolver(
    'Control D',
    '76.76.2.0',
    tag: 'CD',
    organization: 'Windscribe / Control D',
    location: 'Global Anycast',
    description:
        'Modern customizable DNS resolver with high-performance routing.',
  ),
  DnsResolver(
    'Shecan',
    '178.22.122.100',
    tag: 'SH',
    organization: 'Shecan Team',
    location: 'Iran',
    isIranian: true,
    description:
        'Iranian DNS service configured to bypass international sanctions on developer and software tools.',
  ),
  DnsResolver(
    'Electro',
    '78.157.42.100',
    tag: 'EL',
    organization: 'Electro Team',
    location: 'Iran',
    isIranian: true,
    description:
        'Iranian sanction-bypassing DNS commonly used for gaming and software platforms.',
  ),
  DnsResolver(
    'Radar',
    '10.202.10.10',
    tag: 'RD',
    organization: 'Radar Game Iran',
    location: 'Iran',
    isIranian: true,
    description:
        'Iranian domestic gaming and CDN routing optimization resolver.',
  ),
  DnsResolver(
    '403',
    '10.202.10.202',
    tag: '403',
    organization: '403.online',
    location: 'Iran',
    isIranian: true,
    description:
        'Domestic Iranian service created to unlock sanction-restricted websites for Iranian users.',
  ),
  DnsResolver(
    'Begzar',
    '185.55.226.26',
    tag: 'BG',
    organization: 'Begzar DNS',
    location: 'Iran',
    isIranian: true,
    description:
        'Iranian domestic DNS resolver for bypassing anti-Iran foreign website bans.',
  ),
  DnsResolver(
    'DNS Pro',
    '87.107.110.109',
    tag: 'DP',
    organization: 'DNS Pro',
    location: 'Iran',
    isIranian: true,
    description: 'Iranian regional public DNS resolver.',
  ),
  DnsResolver(
    'Level3',
    '4.2.2.1',
    tag: 'L3',
    organization: 'Lumen / Level3',
    location: 'USA / Global',
    description:
        'Historic Tier-1 global telecom backbone public recursive resolver.',
  ),
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
