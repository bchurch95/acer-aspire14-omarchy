var BROWSER_IDENTIFIERS = [
  "chrome",
  "chromium",
  "firefox",
  "brave",
  "vivaldi",
  "opera",
  "edge",
  "microsoft-edge",
  "zen",
  "floorp",
  "librewolf",
  "waterfox",
  "tor-browser",
  "epiphany",
  "ladybird",
  "thorium",
  "helium",
  "browser"
]

var MUSIC_SERVICE_KEYWORDS = [
  "apple music",
  "music.apple.com",
  "apple-music",
  "spotify",
  "soundcloud",
  "bandcamp",
  "tidal",
  "deezer",
  "qobuz",
  "pandora",
  "youtube music",
  "music.youtube.com",
  "cider"
]

var MUSIC_ART_DOMAINS = [
  "mzstatic.com",
  "apple.com",
  "scdn.co",
  "spotify.com",
  "sndcdn.com",
  "soundcloud.com",
  "bandcamp.com",
  "tidal.com",
  "deezer.com",
  "qobuz.com"
]

function isBrowser(player) {
  if (!player) return false
  var identity = String(player.identity || "").toLowerCase()
  var desktopEntry = String(player.desktopEntry || "").toLowerCase()
  var dbusName = String(player.dbusName || "").toLowerCase()
  var trackId = String(player.trackId || "").toLowerCase()
  var artUrl = String(player.trackArtUrl || "").toLowerCase()

  for (var i = 0; i < BROWSER_IDENTIFIERS.length; i++) {
    var b = BROWSER_IDENTIFIERS[i]
    if (identity.indexOf(b) !== -1 || desktopEntry.indexOf(b) !== -1 || dbusName.indexOf(b) !== -1) {
      return true
    }
  }

  if (trackId.indexOf("/chromium/") !== -1 || trackId.indexOf("/firefox/") !== -1 || trackId.indexOf("/mozilla/") !== -1) {
    return true
  }

  if (artUrl.indexOf(".com.google.chrome") !== -1 || artUrl.indexOf(".org.chromium") !== -1 || artUrl.indexOf(".mozilla") !== -1) {
    return true
  }

  return false
}

function isKnownMusicPlayer(player, toplevels) {
  if (!player) return false

  var identity = String(player.identity || "").toLowerCase()
  var desktopEntry = String(player.desktopEntry || "").toLowerCase()
  var dbusName = String(player.dbusName || "").toLowerCase()
  var album = String(player.trackAlbum || "").trim()
  var artUrl = String(player.trackArtUrl || "").toLowerCase()
  var title = String(player.trackTitle || "").toLowerCase()

  // 1. Explicit music player / webapp identity or desktopEntry
  for (var i = 0; i < MUSIC_SERVICE_KEYWORDS.length; i++) {
    var kw = MUSIC_SERVICE_KEYWORDS[i]
    if (identity.indexOf(kw) !== -1 || desktopEntry.indexOf(kw) !== -1 || dbusName.indexOf(kw) !== -1) {
      return true
    }
  }

  // 2. Artwork URL from music streaming CDN (e.g. mzstatic.com for Apple Music)
  for (var j = 0; j < MUSIC_ART_DOMAINS.length; j++) {
    if (artUrl.indexOf(MUSIC_ART_DOMAINS[j]) !== -1) {
      return true
    }
  }

  // 3. Check window titles for music service indicators (e.g. "Song by Artist on Apple Music")
  var wins = Array.isArray(toplevels) ? toplevels : []
  for (var k = 0; k < wins.length; k++) {
    var winTitle = String(wins[k] && wins[k].title || "").toLowerCase()
    var winAppId = String(wins[k] && (wins[k].appId || wins[k].initialClass || "") || "").toLowerCase()

    for (var m = 0; m < MUSIC_SERVICE_KEYWORDS.length; m++) {
      var musicKw = MUSIC_SERVICE_KEYWORDS[m]
      if (winTitle.indexOf(musicKw) !== -1 || winAppId.indexOf(musicKw) !== -1) {
        return true
      }
    }
  }

  // 4. Valid album tag on non-YouTube tracks
  if (album !== "" && !isYouTubeText(album) && !isYouTubeText(title)) {
    return true
  }

  return false
}

function isYouTubeText(str) {
  if (!str) return false
  var s = String(str).toLowerCase()
  return s.indexOf("youtube") !== -1
    || s.indexOf("ytimg") !== -1
    || s.indexOf("googlevideo") !== -1
    || s.indexOf("youtu.be") !== -1
    || s.indexOf("yt3.ggpht") !== -1
}

function isYouTube(player, toplevels) {
  if (!player) return false

  var identity = String(player.identity || "").toLowerCase()
  var desktopEntry = String(player.desktopEntry || "").toLowerCase()
  var dbusName = String(player.dbusName || "").toLowerCase()
  var title = String(player.trackTitle || "").toLowerCase()
  var artist = String(player.trackArtist || "").toLowerCase()
  var album = String(player.trackAlbum || "").toLowerCase()
  var artUrl = String(player.trackArtUrl || "").toLowerCase()
  var url = String(player.url || "").toLowerCase()
  var trackId = String(player.trackId || "").toLowerCase()

  var isMusic = isKnownMusicPlayer(player, toplevels)

  // Direct YouTube metadata matching
  if (isYouTubeText(identity) || isYouTubeText(desktopEntry) || isYouTubeText(dbusName)) return true
  if (isYouTubeText(title) || isYouTubeText(artist) || isYouTubeText(album)) return true
  if (isYouTubeText(artUrl) || isYouTubeText(url) || isYouTubeText(trackId)) return true

  var meta = player.metadata || {}
  if (isYouTubeText(meta["xesam:url"]) || isYouTubeText(meta["mpris:artUrl"]) || isYouTubeText(meta["mpris:trackid"]) || isYouTubeText(meta["xesam:title"])) {
    return true
  }

  // Check window titles for YouTube video indicators (e.g. "Video Title - YouTube - Google Chrome")
  var wins = Array.isArray(toplevels) ? toplevels : []
  for (var i = 0; i < wins.length; i++) {
    var winTitle = String(wins[i] && wins[i].title || "")
    var winTitleLower = winTitle.toLowerCase()

    if (winTitleLower.indexOf("youtube") !== -1 && winTitleLower.indexOf("youtube music") === -1) {
      if (title && winTitleLower.indexOf(title) !== -1) {
        return true
      }
      if (isBrowser(player) && !isMusic) {
        return true
      }
    }
  }

  // If it's a browser player without any music indicator, treat as generic web video and exclude
  if (isBrowser(player) && !isMusic) {
    return true
  }

  return false
}

function isProxyPlayer(player) {
  var dbusName = String(player && player.dbusName || "").toLowerCase()
  var desktopEntry = String(player && player.desktopEntry || "").toLowerCase()
  return dbusName.indexOf("playerctld") !== -1 || desktopEntry === "playerctld"
}

function hasMetadata(player, toplevels) {
  if (isYouTube(player, toplevels)) return false
  return !!(player && (player.trackTitle || player.trackArtist || player.identity || player.desktopEntry))
}

function hasTrackMetadata(player, toplevels) {
  if (isYouTube(player, toplevels)) return false
  return !!(player && (player.trackTitle || player.trackArtist || player.trackAlbum || player.trackArtUrl))
}

function playerCanControl(player, toplevels) {
  if (isYouTube(player, toplevels)) return false
  return !!(player && (player.canTogglePlaying || player.canPlay || player.canPause || player.canGoNext || player.canGoPrevious))
}

function canHandleAction(player, action, toplevels) {
  if (!player || isYouTube(player, toplevels)) return false
  if (action === "next") return !!player.canGoNext
  if (action === "previous") return !!player.canGoPrevious
  if (action === "play") return !!(player.canPlay || player.canTogglePlaying)
  if (action === "pause") return !!(player.canPause || player.canTogglePlaying)
  if (action === "playPause") return !!(player.canTogglePlaying || player.canPlay || player.canPause)
  return false
}

function canCycleSource(player, toplevels) {
  if (isYouTube(player, toplevels)) return false
  return !!(player && hasMetadata(player, toplevels) && (player.isPlaying || player.canPlay))
}

function nodeProps(node) {
  return node && node.ready && node.properties ? node.properties : {}
}

function isPlaybackStream(node) {
  if (!node || !node.isStream) return false
  if (node.isSink === true) return true

  var mediaClass = String(node.type || "")
  return mediaClass.indexOf("Stream/Output/Audio") !== -1
    || mediaClass.indexOf("AudioOutStream") !== -1
    || mediaClass.indexOf("Output") !== -1
}

function streamLabelKey(label) {
  var key = String(label || "").toLowerCase()
  key = key.replace(/^pipewire alsa \[/, "")
  key = key.replace(/\]$/, "")
  key = key.replace(/^alsa playback \[/, "")
  key = key.replace(/[^a-z0-9]+/g, "")
  return key
}

function rawStreamLabel(node) {
  if (!node) return ""
  var p = nodeProps(node)
  return p["application.name"]
    || node.description
    || p["media.name"]
    || p["node.name"]
    || node.name
}

function playerAppLabel(player) {
  if (!player) return ""
  var dbus = String(player.dbusName || "")
  dbus = dbus.replace(/^org\.mpris\.MediaPlayer2\./, "")
  dbus = dbus.replace(/\.instance[0-9]+$/, "")
  return player.desktopEntry || player.identity || dbus
}

function playerHasPlaybackStream(player, playbackStreams) {
  var playerKey = streamLabelKey(playerAppLabel(player))
  if (!playerKey) return false

  var streams = Array.isArray(playbackStreams) ? playbackStreams : []
  for (var i = 0; i < streams.length; i++) {
    var streamKey = streamLabelKey(rawStreamLabel(streams[i]))
    if (!streamKey) continue
    if (streamKey === playerKey
        || streamKey.indexOf(playerKey) !== -1
        || playerKey.indexOf(streamKey) !== -1)
      return true
  }

  return false
}

function playerKey(player) {
  if (!player) return ""
  return String(player.dbusName || player.desktopEntry || player.identity || "")
}

function trackSignature(player) {
  if (!player) return ""
  return [
    player.trackTitle || "",
    player.trackArtist || "",
    player.trackAlbum || "",
    player.trackArtUrl || ""
  ].join("\u001f")
}

function trackChanged(previousSignature, player) {
  return trackSignature(player) !== String(previousSignature || "")
}

function labelFor(player) {
  if (!player) return ""
  return player.trackTitle || player.identity || player.desktopEntry || ""
}

function osdMessage(player, fallback) {
  if (!player) return fallback
  var label = labelFor(player)
  if (label && player.trackArtist) return label + " - " + player.trackArtist
  return label || fallback
}

if (typeof module !== "undefined") {
  module.exports = {
    isYouTube: isYouTube,
    isBrowser: isBrowser,
    isProxyPlayer: isProxyPlayer,
    hasMetadata: hasMetadata,
    hasTrackMetadata: hasTrackMetadata,
    playerCanControl: playerCanControl,
    canHandleAction: canHandleAction,
    canCycleSource: canCycleSource,
    nodeProps: nodeProps,
    isPlaybackStream: isPlaybackStream,
    streamLabelKey: streamLabelKey,
    rawStreamLabel: rawStreamLabel,
    playerAppLabel: playerAppLabel,
    playerHasPlaybackStream: playerHasPlaybackStream,
    playerKey: playerKey,
    trackSignature: trackSignature,
    trackChanged: trackChanged,
    labelFor: labelFor,
    osdMessage: osdMessage
  }
}
