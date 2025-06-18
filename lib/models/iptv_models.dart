// models/iptv_models.dart

/// 1. Channel (channels.json)
class Channel {
  final String id;
  final String name;
  final List<String>? altNames;
  final String? network;
  final List<String>? owners;
  final String country;
  final String? subdivision;
  final String? city;
  final List<String>? categories;
  final bool isNsfw;
  final String? launched;
  final String? closed;
  final String? replacedBy;
  final String? website;
  final String? logo;

  Channel({
    required this.id,
    required this.name,
    this.altNames,
    this.network,
    this.owners,
    required this.country,
    this.subdivision,
    this.city,
    this.categories,
    required this.isNsfw,
    this.launched,
    this.closed,
    this.replacedBy,
    this.website,
    this.logo,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    altNames: (json['alt_names'] as List<dynamic>?)?.cast<String>(),
    network: json['network'] as String?,
    owners: (json['owners'] as List<dynamic>?)?.cast<String>(),
    country: json['country'] as String? ?? '',
    subdivision: json['subdivision'] as String?,
    city: json['city'] as String?,
    categories: (json['categories'] as List<dynamic>?)?.cast<String>(),
    isNsfw: json['is_nsfw'] as bool? ?? false,
    launched: json['launched'] as String?,
    closed: json['closed'] as String?,
    replacedBy: json['replaced_by'] as String?,
    website: json['website'] as String?,
    logo: json['logo'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'alt_names': altNames,
    'network': network,
    'owners': owners,
    'country': country,
    'subdivision': subdivision,
    'city': city,
    'categories': categories,
    'is_nsfw': isNsfw,
    'launched': launched,
    'closed': closed,
    'replaced_by': replacedBy,
    'website': website,
    'logo': logo,
  };
}

/// 2. Feed (feeds.json)
class Feed {
  final String channel;
  final String id;
  final String name;
  final bool isMain;
  final List<String>? broadcastArea;
  final List<String>? timezones;
  final List<String>? languages;
  final String? format;

  Feed({
    required this.channel,
    required this.id,
    required this.name,
    required this.isMain,
    this.broadcastArea,
    this.timezones,
    this.languages,
    this.format,
  });

  factory Feed.fromJson(Map<String, dynamic> json) => Feed(
    channel: json['channel'] as String? ?? '',
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    isMain: json['is_main'] as bool? ?? false,
    broadcastArea: (json['broadcast_area'] as List<dynamic>?)?.cast<String>(),
    timezones: (json['timezones'] as List<dynamic>?)?.cast<String>(),
    languages: (json['languages'] as List<dynamic>?)?.cast<String>(),
    format: json['format'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'channel': channel,
    'id': id,
    'name': name,
    'is_main': isMain,
    'broadcast_area': broadcastArea,
    'timezones': timezones,
    'languages': languages,
    'format': format,
  };
}

/// 3. StreamInfo (streams.json)
class StreamInfo {
  final String id;
  final String? channel;
  final String? feed;
  final String url;
  final String? referrer;
  final String? userAgent;
  final String? quality;

  StreamInfo(
    this.id, {
    this.channel,
    this.feed,
    required this.url,
    this.referrer,
    this.userAgent,
    this.quality,
  });

  factory StreamInfo.fromJson(Map<String, dynamic> json) => StreamInfo(
    json['id'] as String? ?? '',
    channel: json['channel'] as String?,
    feed: json['feed'] as String?,
    url: json['url'] as String? ?? '',
    referrer: json['referrer'] as String?,
    userAgent: json['user_agent'] as String?,
    quality: json['quality'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'channel': channel,
    'feed': feed,
    'url': url,
    'referrer': referrer,
    'user_agent': userAgent,
    'quality': quality,
  };
}

/// 4. Guide (guides.json)
class Guide {
  final String? channel;
  final String? feed;
  final String site;
  final String siteId;
  final String siteName;
  final String lang;

  Guide({
    this.channel,
    this.feed,
    required this.site,
    required this.siteId,
    required this.siteName,
    required this.lang,
  });

  factory Guide.fromJson(Map<String, dynamic> json) => Guide(
    channel: json['channel'] as String?,
    feed: json['feed'] as String?,
    site: json['site'] as String? ?? '',
    siteId: json['site_id'] as String? ?? '',
    siteName: json['site_name'] as String? ?? '',
    lang: json['lang'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'channel': channel,
    'feed': feed,
    'site': site,
    'site_id': siteId,
    'site_name': siteName,
    'lang': lang,
  };
}

/// 5a. Category (categories.json)
class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

/// 5b. Language (languages.json)
class Language {
  final String name;
  final String code;

  Language({required this.name, required this.code});

  factory Language.fromJson(Map<String, dynamic> json) => Language(
    name: json['name'] as String? ?? '',
    code: json['code'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'name': name, 'code': code};
}

/// 5c. Country (countries.json)
class Country {
  final String name;
  final String code;
  final List<String>? languages;
  final String? flag;

  Country({required this.name, required this.code, this.languages, this.flag});

  factory Country.fromJson(Map<String, dynamic> json) => Country(
    name: json['name'] as String? ?? '',
    code: json['code'] as String? ?? '',
    languages: (json['languages'] as List<dynamic>?)?.cast<String>(),
    flag: json['flag'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'languages': languages,
    'flag': flag,
  };
}

/// 5d. Subdivision (subdivisions.json)
class Subdivision {
  final String country;
  final String name;
  final String code;

  Subdivision({required this.country, required this.name, required this.code});

  factory Subdivision.fromJson(Map<String, dynamic> json) => Subdivision(
    country: json['country'] as String? ?? '',
    name: json['name'] as String? ?? '',
    code: json['code'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'country': country,
    'name': name,
    'code': code,
  };
}

/// 5e. Region (regions.json)
class Region {
  final String code;
  final String name;
  final List<String>? countries;

  Region({required this.code, required this.name, this.countries});

  factory Region.fromJson(Map<String, dynamic> json) => Region(
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? '',
    countries: (json['countries'] as List<dynamic>?)?.cast<String>(),
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'countries': countries,
  };
}

/// 5f. TimezoneModel (timezones.json)
class TimezoneModel {
  final String id;
  final String utcOffset;
  final List<String>? countries;

  TimezoneModel({required this.id, required this.utcOffset, this.countries});

  factory TimezoneModel.fromJson(Map<String, dynamic> json) => TimezoneModel(
    id: json['id'] as String? ?? '',
    utcOffset: json['utc_offset'] as String? ?? '',
    countries: (json['countries'] as List<dynamic>?)?.cast<String>(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'utc_offset': utcOffset,
    'countries': countries,
  };
}

/// 5g. BlocklistItem (blocklist.json)
class BlocklistItem {
  final String channel;
  final String reason;
  final String ref;

  BlocklistItem({
    required this.channel,
    required this.reason,
    required this.ref,
  });

  factory BlocklistItem.fromJson(Map<String, dynamic> json) => BlocklistItem(
    channel: json['channel'] as String? ?? '',
    reason: json['reason'] as String? ?? '',
    ref: json['ref'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'channel': channel,
    'reason': reason,
    'ref': ref,
  };
}

/// Helper Extensions for easier data access
extension ChannelExtensions on Channel {
  bool get isActive => closed == null;
  String? get primaryCategory =>
      categories?.isNotEmpty == true ? categories!.first : null;
  bool get hasLogo => logo != null && logo!.isNotEmpty;
}

extension StreamInfoExtensions on StreamInfo {
  Map<String, String> get httpHeaders {
    final headers = <String, String>{};
    if (referrer != null) headers['Referer'] = referrer!;
    if (userAgent != null) headers['User-Agent'] = userAgent!;
    return headers;
  }

  bool get hasQuality => quality != null && quality!.isNotEmpty;
}

extension FeedExtensions on Feed {
  String? get primaryLanguage =>
      languages?.isNotEmpty == true ? languages!.first : null;
  String? get primaryTimezone =>
      timezones?.isNotEmpty == true ? timezones!.first : null;
}
