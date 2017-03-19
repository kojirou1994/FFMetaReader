import Foundation
import CommandLineKit

/*
MP4Box -tag-list
Supported iTunes tag modifiers:
album_artist	usage: album_artist=album artist
album	usage: album=name
tracknum	usage: track=x/N
track	usage: track=name
artist	usage: artist=name
comment	usage: comment=any comment
compilation	usage: compilation=yes,no
composer	usage: composer=name
created	usage: created=time
disk	usage: disk=x/N
tool	usage: tool=name
genre	usage: genre=name
name	usage: name=name
tempo	usage: tempo=integer
writer	usage: writer=name
group	usage: group=name
cover	usage: cover=file.jpg,file.png
encoder	usage: encoder=name
gapless	usage: gapless=yes,no
all	usage: all=NULL

mp4tags
mp4tags: You must specify at least one MP4 file.
usage mp4tags OPTION... FILE...
Adds or modifies iTunes-compatible tags on MP4 files.

-help            Display this help text and exit
-version         Display version information and exit
-A, -album       STR  Set the album title
-a, -artist      STR  Set the artist information
-b, -tempo       NUM  Set the tempo (beats per minute)
-c, -comment     STR  Set a general comment
-C, -copyright   STR  Set the copyright information
-d, -disk        NUM  Set the disk number
-D, -disks       NUM  Set the number of disks
-e, -encodedby   STR  Set the name of the person or company who encoded the file
-E, -tool        STR  Set the software used for encoding
-g, -genre       STR  Set the genre name
-G, -grouping    STR  Set the grouping name
-H, -hdvideo     NUM  Set the HD flag (1\0)
-i, -type        STR  Set the Media Type(tvshow, movie, music, ...)
-I, -contentid   NUM  Set the content ID
-j, -genreid     NUM  Set the genre ID
-l, -longdesc    STR  Set the long description
-L, -lyrics      NUM  Set the lyrics
-m, -description STR  Set the short description
-M, -episode     NUM  Set the episode number
-n, -season      NUM  Set the season number
-N, -network     STR  Set the TV network
-o, -episodeid   STR  Set the TV episode ID
-O, -category    STR  Set the category
-p, -playlistid  NUM  Set the playlist ID
-P, -picture     PTH  Set the picture as a .png
-B, -podcast     NUM  Set the podcast flag.
-R, -albumartist STR  Set the album artist
-s, -song        STR  Set the song title
-S  -show        STR  Set the TV show
-t, -track       NUM  Set the track number
-T, -tracks      NUM  Set the number of tracks
-x, -xid         STR  Set the globally-unique xid (vendor:scheme:id)
-X, -rating      STR  Set the Rating(none, clean, explicit)
-w, -writer      STR  Set the composer information
-y, -year        NUM  Set the release date
-z, -artistid    NUM  Set the artist ID
-Z, -composerid  NUM  Set the composer ID
-r, -remove      STR  Remove tags by code (e.g. "-r cs"
removes the comment and song tags)
*/

enum Tagger {
	case mp4box
	case mp4tags
}

enum iTunesTag: String {
	case title
	case artist
	case album_artist
	case composer
	case album
	case genre
	case track
	case disc
	case compilation
	case date
	case copyright
	case comment
	
	func params(info: String) -> (Tagger, String) {
		switch self {
		case .title:
			return (.mp4box, "name=\(info)")
		case .artist:
			return (.mp4box, "artist=\(info)")
		case .album_artist:
			return (.mp4box, "album_artist=\(info)")
		case .composer:
			return (.mp4tags, "-w \"\(info)\"")
		case .album:
			return (.mp4box, "album=\(info)")
		case .genre:
			return (.mp4box, "genre=\(info)")
		case .track:
			return (.mp4box, "tracknum=\(info)")
		case .disc:
			return (.mp4box, "disk=\(info)")
		case .compilation:
			return (.mp4box, "compilation=\(info == "0" ? "no": "yes")")
		case .date:
			return (.mp4box, "created=\(info)")
		case .copyright:
			return (.mp4tags, "-C \"\(info)\"")
		case .comment:
			return (.mp4tags, "-c \"\(info)\"")
		}
	}
}

let mp4box = "MP4Box -itags \"album_artist=→Pia-no-jaC←:tracknum=1/6:disk=1/1\" MP4Box_add.m4a"

func parseMetaFile(path: String) throws -> [iTunesTag : String] {
	let content = try String(contentsOfFile: path)
	let lines = content.components(separatedBy: "\n")
	var meta = [iTunesTag : String]()
	lines.forEach { (str) in
		guard let separate = str.range(of: "="),
			let tag = iTunesTag.init(rawValue: str.substring(to: separate.lowerBound)) else {
			return
		}
		let info = str.substring(from: separate.upperBound)
		if info != "" {
			meta[tag] = info
		}
	}
	return meta
}

let input = CommandLine.arguments[1]
let metaFile = input.replacingOccurrences(of: ".m4a", with: "_meta.txt")
let fm = FileManager.default
//fm.createFile(atPath: "tag.sh", contents: nil, attributes: nil)

//let output = FileHandle(forWritingAtPath: "tag.sh")!
//output.write("#!/bin/zsh\n\n".data(using: .utf8)!)

func generateCMD(tags: [iTunesTag : String]) {
	var mp4boxCMD = [String]()
	var mp4tagCMD = [String]()
	for (tag, info) in tags {
		let (tagger, param) = tag.params(info: info)
		switch tagger {
		case .mp4box:
			mp4boxCMD.append(param)
		case .mp4tags:
			mp4tagCMD.append(param)
		}
	}
	let coverJpeg = input.replacingOccurrences(of: ".m4a", with: ".jpg")
	let coverPng = input.replacingOccurrences(of: ".m4a", with: ".png")
	if fm.fileExists(atPath: coverJpeg) {
		mp4boxCMD.append("cover=\(coverJpeg)")
	} else if fm.fileExists(atPath: coverPng) {
		mp4boxCMD.append("cover=\(coverPng)")
	}
	print("MP4Box -itags \"\(mp4boxCMD.joined(separator: ":"))\" \"\(input)\"\n")
	print("mp4tags \(mp4tagCMD.joined(separator: " ")) \"\(input)\"\n")
}

generateCMD(tags: try! parseMetaFile(path: metaFile))
