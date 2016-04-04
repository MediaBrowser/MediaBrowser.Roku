'******************************************************
' Creates the capabilities object that is reported to Emby servers
'******************************************************

Function getDirectPlayProfiles()

	profiles = []
	
	versionArr = getGlobalVar("rokuVersion")
	audioContainers = "mp2,mp3,wma,pcm"

	' firmware 6.1 and greater
        If CheckMinimumVersion(versionArr, [6, 1]) then
	    surroundSound = getGlobalVar("SurroundSound")
	    audioOutput51 = getGlobalVar("audioOutput51")
	    surroundSoundDCA = getGlobalVar("audioDTS")
	else
	' legacy
	    surroundSound = SupportsSurroundSound(false, false)

	    audioOutput51 = getGlobalVar("audioOutput51")
	    surroundSoundDCA = surroundSound AND audioOutput51 'AND (RegRead("fivepointoneDCA", "preferences", "1") = "1")
	    surroundSound = surroundSound AND audioOutput51 'AND (RegRead("fivepointone", "preferences", "1") = "1")
	end if

	' if private mode enabled disable surround sound
	private = FirstOf(regRead("prefprivate"),"0")
	if private = "1" then
		surroundSound = false
	    	audioOutput51 = false
	    	surroundSoundDCA = false
	end if
		
	device = CreateObject("roDeviceInfo")
 	model = left(device.GetModel(),4)

	' preferences
        truehd = firstOf(RegRead("truehdtest"), "0")
	DTStoAC3 = firstOf(RegRead("prefDTStoAC3"), "0")
	directFlash = firstOf(RegRead("prefdirectFlash"), "0")

	if CheckMinimumVersion(versionArr, [5, 3]) then
		audioContainers = audioContainers + ",flac"
	end if
	force = firstOf(regRead("prefPlayMethod"),"Auto")

	if force = "Auto" then

	  ' roku 4 supports apple lossless audio codec
	  if model = "4400" then
		audioContainers = audioContainers + ",alac"
	  end if

	  profiles.push({
		Type: "Audio"
		Container: audioContainers
	  })
	
	  mp4Audio = "aac,mp2,mp3,pcm"
	
	  if surroundSound then
		mp4Audio = mp4Audio + ",ac3"
	  end if
	
	  mp4Video = "h264,mpeg4"
	  mp4Container = "mp4,mov,m4v"

	  ' force flash support directplay
	  if directFlash = "1" then
		mp4Container = mp4Container + ",flv,f4v"
	  end if

	  ' roku 4 has support for hevc and vp9
	  if model = "4400" then
		mp4Video = mp4Video + ",hevc,vp9"
	  end if

	  profiles.push({
		Type: "Video"
		Container: mp4Container
		VideoCodec: mp4Video
		AudioCodec: mp4Audio
	  })
	
	  mkvAudio = "aac,mp2,mp3,flac,pcm"

	  if CheckMinimumVersion(versionArr, [5, 3]) then
		mkvAudio = mkvAudio + ",flac"
	  end if
	
	  if CheckMinimumVersion(versionArr, [5, 1]) then
	
		if surroundSound then
            		mkvAudio = mkvAudio + ",ac3"
        	end if

        	if surroundSoundDCA and DTStoAC3 = "0" then
            		mkvAudio = mkvAudio + ",dca"
        	end if

        	if truehd = "1" then
            		mkvAudio = mkvAudio + ",truehd"
        	end if
	  end if

	  mkvVideo = "h264,mpeg4"

	  ' roku 4 has support for hevc and vp9
	  if model = "4400" then
		mkvVideo = mkvVideo + ",hevc,vp9"
	  end if

          profiles.push({
		Type: "Video"
		Container: "mkv"
		VideoCodec: mkvVideo
		AudioCodec: mkvAudio
	  })
	end if

	return profiles

End Function

Function getTranscodingProfiles()

	versionArr = getGlobalVar("rokuVersion")
    	device = CreateObject("roDeviceInfo")
	onlyh264 = firstOf(RegRead("prefonlyh264"), "1")
	onlyAAC = firstOf(RegRead("prefonlyAAC"), "1")
	Unknown = firstOf(RegRead("prefTransAC3"), "aac")
	forceSurround = firstOf(RegRead("prefforceSurround"),"0")
	AACconv = firstOf(RegRead("prefConvAAC"), "aac")
	DefAudio = firstOf(RegRead("prefDefAudio"), "aac")
	versionArr = getGlobalVar("rokuVersion")
	private = FirstOf(regRead("prefprivate"),"0")

	' firmware 6.1 and greater
        If CheckMinimumVersion(versionArr, [6, 1]) then
	    surroundSound = getGlobalVar("SurroundSound")
	    audioOutput51 = getGlobalVar("audioOutput51")
	    surroundSoundDCA = getGlobalVar("SurroundSoundDCA")
	else
	    surroundSound = SupportsSurroundSound(false, false)

	    audioOutput51 = getGlobalVar("audioOutput51")
	    surroundSoundDCA = surroundSound AND audioOutput51 'AND (RegRead("fivepointoneDCA", "preferences", "1") = "1")
	    surroundSound = surroundSound AND audioOutput51 'AND (RegRead("fivepointone", "preferences", "1") = "1")
	end if

	if private = "1" then
		surroundsound = false
		audioOutput51 = false
	    	surroundSoundDCA = false
	end if

	profiles = []
	
	profiles.push({
		Type: "Audio"
		Container: "mp3"
		AudioCodec: "mp3"
		Context: "Streaming"
		Protocol: "Http"
	})
	
	' pass in codecs
	t = m.Codecs
	' the default
	transAudio = DefAudio

	' unknown audio possibly pass ac3
	if t = invalid then transAudio = Unknown

	' force surround can happen if surroundsound is found
	if forceSurround = "1" and surroundSound then transAudio = "ac3"


	' 2.0 channel codecs
	if onlyAAC = "0" and t <> invalid then
	s = CreateObject("roRegex","mp3","i")
		if s.isMatch(t) then
			transAudio = "mp3"
		else
			s = CreateObject("roRegex","mp2","i")
			if s.isMatch(t) then
				transAudio = "mp2"
			end if
		end if
	end if

	' 2.0/5.1 codecs
	if t <> invalid then

		' aac direct-streams in case we are using ac3
		' respect the fourceSurround always with aac
		s = CreateObject("roRegex","aac","i")
		if s.isMatch(t) and forceSurround = "0" then
			transAudio = AACconv
		end if

		' flac direct-streams
		if CheckMinimumVersion(versionArr, [5, 3]) then
			s = CreateObject("roRegex","flac","i")
			if s.isMatch(t) then
				transAudio = "flac"
			end if
		end if
	end if

	' surround sound codecs
	if surroundSound then
	    if t <> invalid then

		' dts/ac3/truehd direct stream as ac3
		s = CreateObject("roRegex","dts","i")
	        r = CreateObject("roRegex","ac3","i")
	        q = CreateObject("roRegex","truehd","i")
	        if q.isMatch(t) or r.isMatch(t) or s.isMatch(t) then
            	    transAudio = "ac3"
	        else

	        end if
	    end if
        end if

	' pass in container
	u = m.Extension

	' the default
	transVideo = "h264"

	' get container
	if u <> invalid then
		' mkv container with mpeg4 cannot be xvid/divx
		r = CreateObject("roRegex","mkv","i")
	        if r.isMatch(u) or onlyh264 = "1" then
			' do nothing mpeg4 in mkv should not pass
		else
			' mpeg4 is not in mkv
			p = CreateObject("roRegex","mpeg4","i")
			if p.isMatch(t) then
				transVideo = "mpeg4"
			end if
		end if
	end if
	print "transvideo " + transVideo + " TransAudio " + transAudio + " T " + FirstOf(t,"Nothing") + " U " + FirstOf(u,"Nothing")

	profiles.push({
		Type: "Video"
		Container: "ts"
		AudioCodec: transAudio
		VideoCodec: transVideo
		Context: "Streaming"
		Protocol: "Hls"
	})

	return profiles

End Function

Function getCodecProfiles()

	profiles = []

	maxRefFrames = firstOf(getGlobalVar("maxRefFrames"), 12)
	playsAnamorphic = firstOf(getGlobalVar("playsAnamorphic"), false)
        truehd = firstOf(RegRead("truehdtest"), "0")
	device = CreateObject("roDeviceInfo")
	model = left(device.GetModel(),4)
	versionArr = getGlobalVar("rokuVersion")
	framerate = firstOf(regRead("prefmaxframe"), "30")
	Go4k = firstOf(RegRead("prefgo4k"), "0")
	Force = firstOf(RegRead("prefPlayMethod"), "Auto")
	directFlash = firstOf(RegRead("prefdirectFlash"), "0")
	if directFlash = "1" and framerate = "30" then
		framerate = "31"
	end if

	if Force = "Transcode" then
		framerate = 30
	end if

	if Go4k = "0" then
		maxWidth = "1920"
		maxHeight = "1080"
	else
        	maxWidth = "3840"
        	maxHeight = "2160"
	end if

        max4kWidth = "3840"
        max4kHeight = "2160"

	' firmware 6.1 and greater
        If CheckMinimumVersion(versionArr, [6, 1]) then
	    surroundSound = getGlobalVar("SurroundSound")
	    audioOutput51 = getGlobalVar("audioOutput51")
	    surroundSoundDCA = getGlobalVar("SurroundSoundDCA")
	else
	    surroundSound = SupportsSurroundSound(false, false)

	    audioOutput51 = getGlobalVar("audioOutput51")
	    surroundSoundDCA = surroundSound AND audioOutput51 'AND (RegRead("fivepointoneDCA", "preferences", "1") = "1")
	    surroundSound = surroundSound AND audioOutput51 'AND (RegRead("fivepointone", "preferences", "1") = "1")
	end if
	
	' private listening nuke all surround sound
	private = FirstOf(regRead("prefprivate"),"0")
	if private = "1" then
		surroundsound = false
		audioOutput51 = false
	    	surroundSoundDCA = false
	end if

	if getGlobalVar("displayType") <> "HDTV" then
		maxWidth = "1280"
		maxHeight = "720"
	end if

	h264Conditions = []
	h264Conditions.push({
		Condition: "LessThanEqual"
		Property: "RefFrames"
		Value: tostr(maxRefFrames)
		IsRequired: false
	})
	h264Conditions.push({
		Condition: "LessThanEqual"
		Property: "VideoBitDepth"
		Value: "8"
		IsRequired: false
	})
	h264Conditions.push({
		Condition: "LessThanEqual"
		Property: "Width"
		Value: maxWidth
		IsRequired: true
	})
	h264Conditions.push({
		Condition: "LessThanEqual"
		Property: "Height"
		Value: maxHeight
		IsRequired: true
	})
	h264Conditions.push({
		Condition: "LessThanEqual"
		Property: "VideoFramerate"
		Value: framerate
		IsRequired: false
	})
	h264Conditions.push({
		Condition: "EqualsAny"
		Property: "VideoProfile"
		Value: "high|main|baseline|constrained baseline"
		IsRequired: false
	})
	h264Conditions.push({
		Condition: "LessThanEqual"
		Property: "VideoLevel"
		Value: "51"
		IsRequired: false
	})
	if playsAnamorphic = false Then
	h264Conditions.push({
		Condition: "Equals"
		Property: "IsAnamorphic"
		Value: "false"
		IsRequired: false
	})
	end if

	profiles.push({
		Type: "Video"
		Codec: "h264"
		Conditions: h264Conditions
	})

	' roku4 has ability to direct play h265/hevc
	if model = "4400" then

	hevcConditions = []
	hevcConditions.push({
		Condition: "LessThanEqual"
		Property: "Width"
		Value: max4kWidth
		IsRequired: true
	})
	hevcConditions.push({
		Condition: "LessThanEqual"
		Property: "Height"
		Value: max4kHeight
		IsRequired: true
	})
	hevcConditions.push({
		Condition: "LessThanEqual"
		Property: "VideoFramerate"
		Value: "60"
		IsRequired: false
	})
	hevcConditions.push({
		Condition: "LessThanEqual"
		Property: "VideoLevel"
		Value: "31"
		IsRequired: false
	})
	
	profiles.push({
		Type: "Video"
		Codec: "hevc"
		Conditions: hevcConditions
	})

	' roku4 has ability to direct play vp9 too
	vp9Conditions = []
	vp9Conditions.push({
		Condition: "LessThanEqual"
		Property: "Width"
		Value: max4kWidth
		IsRequired: true
	})
	vp9Conditions.push({
		Condition: "LessThanEqual"
		Property: "Height"
		Value: max4kHeight
		IsRequired: true
	})
	vp9Conditions.push({
		Condition: "LessThanEqual"
		Property: "VideoFramerate"
		Value: "30"
		IsRequired: false
	})

	profiles.push({
		Type: "Video"
		Codec: "vp9"
		Conditions: vp9Conditions
	})
	end if ' roku 4
	
	mpeg4Conditions = []
	mpeg4Conditions.push({
		Condition: "LessThanEqual"
		Property: "RefFrames"
		Value: tostr(maxRefFrames)
		IsRequired: false
	})
	mpeg4Conditions.push({
		Condition: "LessThanEqual"
		Property: "VideoBitDepth"
		Value: "8"
		IsRequired: false
	})
	mpeg4Conditions.push({
		Condition: "LessThanEqual"
		Property: "Width"
		Value: maxWidth
		IsRequired: true
	})
	mpeg4Conditions.push({
		Condition: "LessThanEqual"
		Property: "Height"
		Value: maxHeight
		IsRequired: true
	})
	mpeg4Conditions.push({
		Condition: "LessThanEqual"
		Property: "VideoFramerate"
		Value: framerate
		IsRequired: false
	})
	if playsAnamorphic = false Then
	mpeg4Conditions.push({
		Condition: "Equals"
		Property: "IsAnamorphic"
		Value: "false"
		IsRequired: false
	})
	end if
	mpeg4Conditions.push({
		Condition: "NotEquals"
		Property: "CodecTag"
		Value: "DX50"
		IsRequired: false
	})
	t = m.Extension
	if t <> invalid then
		' mkv container with mpeg4 cannot be xvid/divx/mp4v
		r = CreateObject("roRegex","mkv","i")
	        if r.isMatch(t) then
			mpeg4Conditions.push({
				Condition: "NotEquals"
				Property: "CodecTag"
				Value: "DIVX"
				IsRequired: false
			})
			mpeg4Conditions.push({
				Condition: "NotEquals"
				Property: "CodecTag"
				Value: "XVID"
				IsRequired: false
			})
			mpeg4Conditions.push({
				Condition: "NotEquals"
				Property: "CodecTag"
				Value: "MP4V"
				IsRequired: false
			})
		end if
	end if
	
	profiles.push({
		Type: "Video"
		Codec: "mpeg4"
		Conditions: mpeg4Conditions
	})
	
	if model = "4400" then
		AACchannels = "6"
	else
		AACchannels = "2"
	end if

	profiles.push({
		Type: "VideoAudio"
		Codec: "aac"
		Conditions: [{
			Condition: "Equals"
			Property: "IsSecondaryAudio"
			Value: "false"
			IsRequired: false
		},
		{
			Condition: "LessThanEqual"
			Property: "AudioChannels"
			Value: AACchannels
			IsRequired: true
		}]
	})

	' support 7.1 Channel Dolby Digital+ if found
	audioDDPlus = FirstOf(getGlobalVar("audioDDPlus"), false)
	if audioDDPlus and surroundSound then
		ac3Channels = "8"
	else
		ac3Channels = "6"
	end if

	profiles.push({
		Type: "VideoAudio"
		Codec: "ac3"
		Conditions: [{
			Condition: "Equals"
			Property: "IsSecondaryAudio"
			Value: "false"
			IsRequired: false
		},
		{
			Condition: "LessThanEqual"
			Property: "AudioChannels"
			Value: ac3Channels
			IsRequired: false
		}]
	})

        if truehd = "1" then
	profiles.push({
		Type: "VideoAudio"
		Codec: "TrueHD"
		Conditions: [{
			Condition: "Equals"
			Property: "IsSecondaryAudio"
			Value: "false"
			IsRequired: false
		},
		{
			Condition: "LessThanEqual"
			Property: "AudioChannels"
			Value: "8"
			IsRequired: false
		}]
	})

	if truehd = "1" then
		dcaChannels = "8"
	else
		dcaChannels = "6"
	end if

	profiles.push({
		Type: "VideoAudio"
		Codec: "dca"
		Conditions: [{
			Condition: "Equals"
			Property: "IsSecondaryAudio"
			Value: "false"
			IsRequired: false
		},
		{
			Condition: "LessThanEqual"
			Property: "AudioChannels"
			Value: dcaChannels
			IsRequired: false
		}]
	})
	end if
	
	return profiles

End Function

Function getContainerProfiles()

	profiles = []

	videoContainerConditions = []
	
	versionArr = getGlobalVar("rokuVersion")
    major = versionArr[0]

    if major < 4 then
		' If everything else looks ok and there are no audio streams, that's
		' fine on Roku 2+.
		videoContainerConditions.push({
			Condition: "NotEquals"
			Property: "NumAudioStreams"
			Value: "0"
			IsRequired: false
		})
	end if
	
	' Multiple video streams aren't supported, regardless of type.
    videoContainerConditions.push({
		Condition: "Equals"
		Property: "NumVideoStreams"
		Value: "1"
		IsRequired: false
	})
		
	profiles.push({
		Type: "Video"
		Conditions: videoContainerConditions
	})
	
	return profiles

End Function

Function getSubtitleProfiles()

	profiles = []
	
	profiles.push({
		Format: "srt"
		Method: "External"
		
		' If Roku adds support for non-Latin characters, remove this
		Language: "und,afr,alb,baq,bre,cat,dan,eng,fao,glg,ger,ice,may,gle,ita,lat,ltz,nor,oci,por,roh,gla,spa,swa,swe,wln,est,fin,fre,dut"
	})
	
	profiles.push({
		Format: "srt"
		Method: "Embed"
		
		' If Roku adds support for non-Latin characters, remove this
		Language: "und,afr,alb,baq,bre,cat,dan,eng,fao,glg,ger,ice,may,gle,ita,lat,ltz,nor,oci,por,roh,gla,spa,swa,swe,wln,est,fin,fre,dut"
	})
			
	return profiles

End Function

Function getDeviceProfile() 

	maxVideoBitrate = firstOf(RegRead("prefVideoQuality"), "3200")
	maxVideoBitrate = maxVideoBitrate.ToInt() * 1000
	
	profile = {
		MaxStaticBitrate: "40000000"
		MaxStreamingBitrate: tostr(maxVideoBitrate)
		MusicStreamingTranscodingBitrate: "192000"
		
		DirectPlayProfiles: getDirectPlayProfiles()
		TranscodingProfiles: getTranscodingProfiles()
		CodecProfiles: getCodecProfiles()
		ContainerProfiles: getContainerProfiles()
		SubtitleProfiles: getSubtitleProfiles()
		Name: "Roku"
	}
	
	return profile
	
End Function

Function getCapabilities() 

	caps = {
		PlayableMediaTypes: ["Audio","Video","Photo"]
		SupportsMediaControl: true
		SupportedCommands: ["MoveUp","MoveDown","MoveLeft","MoveRight","Select","Back","GoHome","SendString","GoToSearch","GoToSettings","DisplayContent","SetAudioStreamIndex","SetSubtitleStreamIndex"]
		MessageCallbackUrl: ":8324/emby/message"
		DeviceProfile: getDeviceProfile()
		SupportedLiveMediaTypes: ["Video"]
		AppStoreUrl: "https://www.roku.com/channels#!details/44191/emby"
		IconUrl: "https://raw.githubusercontent.com/wiki/MediaBrowser/Emby.Roku/Images/icon.png"
	}
	
	return caps
	
End Function
