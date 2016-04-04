'**********************************************************
'** createVideoSpringboardScreen
'** Credit: Plex Roku https://github.com/plexinc/roku-client-public
'**********************************************************

Function createVideoSpringboardScreen(context, index, viewController) As Object

    obj = createBaseSpringboardScreen(context, index, viewController)

    obj.SetupButtons = videoSetupButtons
    obj.GetMediaDetails = videoGetMediaDetails
    obj.baseHandleMessage = obj.HandleMessage
    obj.HandleMessage = handleVideoSpringboardScreenMessage

	obj.ContinuousPlay = false

    obj.checkChangesOnActivate = false
    obj.refreshOnActivate = false
    obj.closeOnActivate = false
    obj.Activate = videoActivate

	obj.DeleteItem = springboardDeleteItem
	obj.CancelLiveTvTimer = springboardCancelTimer
	obj.RecordLiveTvProgram = springboardRecordProgram
	obj.ShowStreamsDialog = springboardShowStreamsDialog
	obj.ShowMoreDialog = springboardShowMoreDialog
	obj.ShowFilmography = springboardShowFilmography
	
	obj.PlayOptions = {}

    obj.Screen.SetDescriptionStyle("movie")

    if NOT AudioPlayer().IsPlaying AND firstOf(RegRead("prefThemeMusic"), "yes") = "yes" then
        AudioPlayer().PlayThemeMusic(obj.Item)
        obj.Cleanup = baseStopAudioPlayer
    end if

    return obj

End Function

'**************************************************************
'** videoSetupButtons
'**************************************************************

Sub videoSetupButtons()
    m.ClearButtons()

	video = m.metadata
	cast = 0
    if video.ContentType = "Program" And video.PlayAccess = "Full"
	
        if canPlayProgram(video)
			m.AddButton("Play", "play")
        end if

        if video.TimerId <> invalid
			m.AddButton("Cancel Recording", "cancelrecording")
			
        else if canRecordProgram(video)
			m.AddButton("Schedule Recording", "record")
        end if

    else if (video.LocationType <> "Virtual" or video.ContentType = "TvChannel") And video.PlayAccess = "Full"

		' This screen is also used for books and games, so don't show a play button
		if video.MediaType = "Video" then
			if video.BookmarkPosition <> 0 then
				time = tostr(formatTime(video.BookmarkPosition))
				m.AddButton("Resume from " + time, "resume")
				m.AddButton("Play from beginning", "play")
			else
				m.AddButton("Play", "play")
			end if
		end if

        if video.Chapters <> invalid and video.Chapters.Count() > 0
			m.AddButton("Play from scene", "scenes")
        end if

        if video.LocalTrailerCount <> invalid and video.LocalTrailerCount > 0
            if video.LocalTrailerCount > 1
				m.AddButton("Trailers", "trailers")
				cast = 1
            else
				m.AddButton("Trailer", "trailer")
				cast = 1
            end if
        end if
		audioStreams = []
		subtitleStreams = []

		if video.StreamInfo <> invalid then
			for each stream in video.StreamInfo.MediaSource.MediaStreams
				if stream.Type = "Audio" then audioStreams.push(stream)
				if stream.Type = "Subtitle" then subtitleStreams.push(stream)
			end For
		end if

        if audioStreams.Count() > 1 Or subtitleStreams.Count() > 0
            m.AddButton("Audio & Subtitles", "streams")
        end if

		m.audioStreams = audioStreams
		m.subtitleStreams = subtitleStreams
    end if

    'if m.screen.CountButtons() < 1
	'm.AddButton("Open", "open")
    'end if

    ' Check for people
     if video.People <> invalid and video.People.Count() > 0 and cast = 0 then

		if video.MediaType = "Video" then
			m.AddButton("Cast & Crew", "cast")
		else
			m.AddButton("People", "people")
		end If
     end if
	if video.ContentType = "Person"
		m.AddButton("Filmography", "filmography")
		if Video.IsFavorite then
			m.AddButton("Remove this person as a Favorite", "removefavorite")
		else
			m.AddButton("Mark this person as a Favorite", "markfavorite")
		end if
	end if
	if m.screen.CountButtons() < 5 and Video.FullDescription <> "" then
		m.AddButton("View Full Description", "description")
	end if
    ' rewster: TV Program recording does not need a more button, and displaying it stops the back button from appearing on programmes that have past
	if video.ContentType <> "Program"
    		versionArr = getGlobalVar("rokuVersion")
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
		AH = ""
		if SurroundSound then
			if audioOutput51 then
				AH = AH + " DD"
			end if
			if SurroundSoundDCA then
				AH = AH + " DTS"
			end if
		else
			AH = " Stereo"
		end if
		private = FirstOf(regRead("prefprivate"),"0")
		if private = "1" then
			AH = " PRIVATE"
		end if
		Extras = "(" + FirstOf(regRead("prefPlayMethod"),"Auto") + " @ " + firstOf(regread("prefmaxframe"), "30") + "fps)"
		if AH <> invalid and AH <> "" then
			 Extras = Extras + AH
		end if
		m.AddButton("More... " + Extras, "more")
	end if

    if m.buttonCount = 0
		m.AddButton("Back", "back")
    end if

End Sub

'**********************************************************
'** canPlayProgram
'**********************************************************

Function canPlayProgram(item as Object) As Boolean

	startDateString = item.StartDate
	endDateString = item.EndDate
	
	if startDateString = invalid or endDateString = invalid then return false
	
    ' Current Time
    nowTime = CreateObject("roDateTime")
    nowTime.ToLocalTime()
    nowTimeSeconds = nowTime.AsSeconds()

    ' Start Time
    startTime = CreateObject("roDateTime")
    startTime.FromISO8601String(startDateString)
    startTime.ToLocalTime()

    ' End Time
    endTime = CreateObject("roDateTime")
    endTime.FromISO8601String(endDateString)
    endTime.ToLocalTime()

    return nowTimeSeconds >= startTime.AsSeconds() And nowTimeSeconds < endTime.AsSeconds()
	
End Function

'**********************************************************
'** canRecordProgram
'**********************************************************

Function canRecordProgram(item as Object) As Boolean

	endDateString = item.EndDate
	
	if endDateString = invalid then return false
	
    ' Current Time
    nowTime = CreateObject("roDateTime")
    nowTime.ToLocalTime()

    ' End Time
    endTime = CreateObject("roDateTime")
    endTime.FromISO8601String(endDateString)
    endTime.ToLocalTime()

    return nowTime.AsSeconds() < endTime.AsSeconds()
	
End Function

'**************************************************************
'** videoGetMediaDetails
'**************************************************************

Sub videoGetMediaDetails(content)

    m.metadata = GetFullItemMetadata(content, false, {})
	streaminfo = invalid
	if m.metadata <> invalid then streamInfo = m.metadata.StreamInfo
	
	if streamInfo <> invalid then
		m.PlayOptions.SubtitleStreamIndex = streamInfo.SubtitleStreamIndex
		m.PlayOptions.AudioStreamIndex = streamInfo.AudioStreamIndex
		m.PlayOptions.MediaSourceId = streamInfo.MediaSource.Id
	end if

End Sub

'**************************************************************
'** videoActivate
'**************************************************************

Sub videoActivate(priorScreen)

    if m.closeOnActivate then
        m.Screen.Close()
        return
    end if

    if m.checkChangesOnActivate AND priorScreen.Changes <> invalid then

        m.checkChangesOnActivate = false

        if priorScreen.Changes.DoesExist("continuous_play") then
            m.ContinuousPlay = (priorScreen.Changes["continuous_play"] = "1")
            priorScreen.Changes.Delete("continuous_play")
        end if

        if NOT priorScreen.Changes.IsEmpty() then
            m.Refresh(true)
        end if
    end if

    if m.refreshOnActivate then
	
		m.refreshOnActivate = false
		
        if m.ContinuousPlay AND (priorScreen.isPlayed = true) then
		
            m.GotoNextItem()
			m.PlayOptions = {}
			m.PlayOptions.PlayStart = 0
            
			m.ViewController.CreatePlayerForItem([m.metadata], 0, m.PlayOptions)
        else
            m.Refresh(true)

			m.refreshOnActivate = false
        end if
    end if
End Sub

'**************************************************************
'** handleVideoSpringboardScreenMessage
'**************************************************************

Function handleVideoSpringboardScreenMessage(msg) As Boolean

    handled = false

    if type(msg) = "roSpringboardScreenEvent" then

		item = GetFullItemMetadata(m.metadata, false, {})
		itemId = item.Id
		viewController = m.ViewController
		screen = m

        if msg.isButtonPressed() then

            handled = true
            buttonCommand = m.buttonCommands[str(msg.getIndex())]
            Debug("Button command: " + tostr(buttonCommand))

            if buttonCommand = "play" then

				if firstOf(m.PlayOptions.HasSelection, false) = false then
					m.PlayOptions = {}
				end if
				
                m.PlayOptions.PlayStart = 0
				m.ViewController.CreatePlayerForItem([item], 0, m.PlayOptions)

                ' Refresh play data after playing.
                m.refreshOnActivate = true

            else if buttonCommand = "resume" then

				if firstOf(m.PlayOptions.HasSelection, false) = false then
					m.PlayOptions = {}
				end if
				
                m.PlayOptions.PlayStart = item.BookmarkPosition
				m.ViewController.CreatePlayerForItem([item], 0, m.PlayOptions)

                ' Refresh play data after playing.
                m.refreshOnActivate = true

            else if buttonCommand = "scenes" then
                newScreen = createVideoChaptersScreen(viewController, item, m.PlayOptions)
				newScreen.ScreenName = "Chapters" + itemId
                viewController.InitializeOtherScreen(newScreen, [item.Title, "Scenes"])
				newScreen.Show()

            else if buttonCommand = "trailer" then
                options = {
			PlayStart: 0
			intros: false
		}
		m.ViewController.CreatePlayerForItem(getLocalTrailers(item.Id), 0, options)
            else if buttonCommand = "trailers" then
                newScreen = createLocalTrailersScreen(viewController, item)
		newScreen.ScreenName = "Trailers" + itemId
                viewController.InitializeOtherScreen(newScreen, [item.Title, "Trailers"])
		newScreen.Show()	
            else if buttonCommand = "cancelrecording" then
		m.CancelLiveTvTimer(item)
	    else if buttonCommand = "description" then
		CreateDialog(Item.Title, Item.FullDescription, "OK", true)
		return true
            else if buttonCommand = "streams" then
                m.ShowStreamsDialog(item)
            else if buttonCommand = "record" then
                m.RecordLiveTvProgram(item)
            else if buttonCommand = "filmography" then
                m.ShowFilmography(item)
    	    else if buttonCommand = "cast" then
        	newScreen = createPeopleScreen(m.ViewController, item)
		newScreen.ScreenName = "People" + itemId
        	m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Cast & Crew"])
		newScreen.Show()
        	return true
    	    else if buttonCommand = "people" then
        	newScreen = createPeopleScreen(m.ViewController, item)
		newScreen.ScreenName = "People" + itemId
        	m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "People"])
		newScreen.Show()
        	return true				
            else if buttonCommand = "more" then
                m.ShowMoreDialog(item)
	    ' rewster: handle the back button
	    else if buttonCommand = "back" then
		m.ViewController.PopScreen(m)
    	    else if buttonCommand = "removefavorite" then
		screen.refreshOnActivate = true
		result = postFavoriteStatus(itemId, false)
		if result then
			createDialog("Favorites Changed", item.Title + " has been removed from your favorites.", "OK", true)
		else
			createDialog("Favorites Error!", item.Title + " has NOT been removed from your favorites.", "OK", true)
		end if
		return true
	    else if buttonCommand = "markfavorite" then
		screen.refreshOnActivate = true
		result = postFavoriteStatus(itemId, true)
		if result then
			createDialog("Favorites Changed", item.Title + " has been added to your favorites.", "OK", true)
		else
			createDialog("Favorites Error!", item.Title + " has NOT been added to your favorites.", "OK", true)
		end if
		return true
            else
                handled = false
            end if
        end if
    end if

	return handled OR m.baseHandleMessage(msg)

End Function

'**********************************************************
'** createVideoChaptersScreen
'**********************************************************

Function createVideoChaptersScreen(viewController as Object, video As Object, playOptions) As Object

	' Dummy up an item
    obj = CreatePosterScreen(viewController, video, "flat-episodic-16x9")
	obj.GetDataContainer = getChaptersDataContainer

	obj.baseHandleMessage = obj.HandleMessage
	obj.HandleMessage = handleChaptersScreenMessage

    return obj
	
End Function

Function handleChaptersScreenMessage(msg) as Boolean

	handled = false

    if type(msg) = "roPosterScreenEvent" then

        if msg.isListItemSelected() then

            index = msg.GetIndex()
            content = m.contentArray[m.focusedList].content
            selected = content[index]

			item = m.Item

			startPosition = selected.StartPosition

			playOptions = {
				PlayStart: startPosition,
				intros: false
			}

            m.ViewController.CreatePlayerForItem([item], 0, playOptions)

        end if
			
    end if

	return handled or m.baseHandleMessage(msg)

End Function

Function getChaptersDataContainer(viewController as Object, item as Object) as Object

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = item.Chapters

	return obj

End Function

'**********************************************************
'** createSpecialFeaturesScreen
'**********************************************************

Function createSpecialFeaturesScreen(viewController as Object, item As Object) As Object

	' TODO: Add option to poster screen to play item directly when selected

    obj = CreatePosterScreen(viewController, item, "flat-episodic-16x9")
	obj.GetDataContainer = getSpecialFeaturesDataContainer

	obj.playOnSelection = true

    return obj
	
End Function

Function getSpecialFeaturesDataContainer(viewController as Object, item as Object) as Object

    items = getSpecialFeatures(item.Id)

    if items = invalid
        return invalid
    end if

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = items

	return obj

End Function

'**********************************************************
'** createLocalTrailersScreen
'**********************************************************

Function createLocalTrailersScreen(viewController as Object, item As Object) As Object

	' TODO: Add option to poster screen to play item directly when selected

    obj = CreatePosterScreen(viewController, item, "flat-episodic-16x9")

	obj.GetDataContainer = getLocalTrailersDataContainer

	obj.playOnSelection = true

    return obj

End Function


Function getLocalTrailersDataContainer(viewController as Object, item as Object) as Object

    items = getLocalTrailers(item.Id)

    if items = invalid
        return invalid
    end if

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = items

	return obj

End Function

'**********************************************************
'** createPeopleScreen
'**********************************************************

function createPeopleScreen(viewController as Object, item as Object) as Object

    obj = CreatePosterScreen(viewController, item, "arced-poster")

	obj.GetDataContainer = getItemPeopleDataContainer

    return obj
end function

Function getItemPeopleDataContainer(viewController as Object, item as Object) as Object

    items = convertItemPeopleToMetadata(item.People)

    if items = invalid
        return invalid
    end if

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = items

	return obj

End Function

Sub springboardShowFilmography(item)
	newScreen = createFilmographyScreen(m.viewController, item)
	newScreen.ScreenName = "Filmography" + item.Id		
	m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Filmography"])
	newScreen.Show()
End Sub

Sub createFavoritesDialog(item)

    dlg = createBaseDialog()
    dlg.Title = "Favorites Options"
    dlg.openParentDialog = true
    seriesName = item.seriesName
    if seriesName <> invalid and seriesName.len() > 25 then seriesName = left(seriesName,25) + "..."

    if item.ParentIndexNumber <> invalid then
      if item.IsFavorite then
        dlg.SetButton("removefavorite", "Remove Season " + tostr(item.ParentIndexNumber) + ", Episode " + tostr(item.IndexNumber) + " as a Favorite")
      else
        dlg.SetButton("markfavorite", "Mark Season " + tostr(item.ParentIndexNumber) + ", Episode " + tostr(item.IndexNumber) + " as a Favorite")
      end if
    else
      if item.IsFavorite then
	dlg.SetButton("removefavorite", "Remove as Favorite")
      else
	dlg.SetButton("markfavorite", "Mark as Favorite")
      end if
    end if

    'if item.parentIndexNumber <> invalid then
	'dlg.SetButton("markfavoriteseason", "Mark Season " + tostr(item.ParentIndexNumber) + " as a Favorite")
	'dlg.SetButton("removefavoriteseason", "Remove Season " + tostr(item.ParentIndexNumber) + " as a Favorite")
    'end if

    if item.SeriesName <> invalid then
	sh = getVideoMetadata(item.seriesId)
	if sh.isFavorite
		dlg.SetButton("removefavoriteseries", "Remove " + tostr(seriesName) + " as a Favorite")
	else
		dlg.SetButton("markfavoriteseries", "Mark " + tostr(seriesName) + " as a Favorite")
	end if
    end if

	dlg.item = item
	dlg.parentScreen = m.parentScreen

	dlg.HandleButton = handleFavoritesOptionsButton

    dlg.SetButton("close", "Close This Window")
    dlg.Show()
End Sub

Function handleFavoritesOptionsButton(command, data) As Boolean
	item = m.item
	itemId = item.Id
	screen = m

    if command = "removefavorite" then
		screen.refreshOnActivate = true
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		result = postFavoriteStatus(itemId, false)
		if item.ParentIndexNumber <> invalid
			text = item.Title + chr(10) + "Season " + tostr(item.ParentIndexNumber) + ", Episode " + tostr(item.IndexNumber) + " of " + item.SeriesName
		else
			text = FirstOf(item.Title, "The episode")
		end if
		if result then
			createDialog("Favorites Changed", text + " has been removed from your favorites.", "OK", true)
		else
			createDialog("Favorites Error!", text + " has NOT been removed from your favorites.", "OK", true)
		end if
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		return true
    else if command = "markfavorite" then
		screen.refreshOnActivate = true
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		result = postFavoriteStatus(itemId, true)
		if item.ParentIndexNumber <> invalid
			text = item.Title + chr(10) + "Season " + tostr(item.ParentIndexNumber) + ", Episode " + tostr(item.IndexNumber) + " of " + item.SeriesName
		else
			text = FirstOf(item.Title, "The episode")
		end if
		if result then
			createDialog("Favorites Changed", text + " has been added to your favorites.", "OK", true)
		else
			createDialog("Favorites Error!", text + " has NOT been added to your favorites.", "OK", true)
		end if
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		return true
    else if command = "removefavoriteseason" then
		screen.refreshOnActivate = true
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		result = postFavoriteStatus(item.SeasonId, false)
		createDialog("Favorites Changed", "Season " + tostr(item.ParentIndexNumber) + " of " + item.SeriesName +  " has been removed from your favorites.", "OK", true)
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
        	return true
    else if command = "markfavoriteseason" then
		screen.refreshOnActivate = true
		postFavoriteStatus(item.SeasonId, true)
		if result then
			createDialog("Favorites Changed", "Season " + tostr(item.ParentIndexNumber) + " of " + item.SeriesName + " has been added to your favorites.", "OK", true)
		else
			createDialog("Favorites Error!", "Season " + tostr(item.ParentIndexNumber) + " of " + item.SeriesName + " has NOT been added to your favorites.", "OK", true)
		end if
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		return true
    else if command = "removefavoriteseries" then
		screen.refreshOnActivate = true
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		result = postFavoriteStatus(item.SeriesId, false)
		if result then
			createDialog("Favorites Changed", FirstOf(item.SeriesName, "The series") + " has been removed from your favorites.", "OK", true)
		else
			createDialog("Favorites Error!", FirstOf(item.SeriesName, "The series") + " has NOT been removed from your favorites.", "OK", true)
		end if
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
        	return true
    else if command = "markfavoriteseries" then
		screen.refreshOnActivate = true
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		result = postFavoriteStatus(item.SeriesId, true)
		if result then
			createDialog("Favorites Changed", FirstOf(item.SeriesName, "The series") + " has been added to your favorites.", "OK", true)
		else
			createDialog("Favorites Error!", FirstOf(item.SeriesName, "The series") + " has NOT been added to your favorites.", "OK", true)
		end if
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
        	return true
    else if command = "close" then
		m.Screen.Close()
		return true
    end if
    return false
End Function

Sub createGoToDialog(item)

    dlg = createBaseDialog()
    dlg.Title = "Go To Options"
    dlg.openParentDialog = true

    if item.SeriesName <> invalid then
    	series = item.SeriesName
    	if series.len() > 25 then series = left(series,25) + "..."
	dlg.SetButton("series", "-> Go To " + FirstOf(series, "The series"))
    end if
    musicstop = FirstOf(GetGlobalVar("musicstop"),"0")
    if AudioPlayer().Context <> invalid and musicstop = "0"
	dlg.SetButton("nowplaying", "-> Go To Now Playing")
    end if
    dlg.SetButton("home", "-> Go To Home Screen")
    dlg.SetButton("preferences", "-> Go To Preferences")
    dlg.SetButton("search", "-> Go To Search Screen")
    dlg.SetButton("close", "Close This Window")
    dlg.item = item
    dlg.parentScreen = m.parentScreen
    dlg.HandleButton = handleGoToOptionsButton
    dlg.Show()
End Sub

Function handleGoToOptionsButton(returned, data) As Boolean
	item = m.item
	itemId = item.Id
	screen = m

    if returned = "nowplaying"
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	'screen.refreshOnActivate = true
        dummyItem = CreateObject("roAssociativeArray")
        dummyItem.ContentType = "audio"
        dummyItem.Key = "nowplaying"
        GetViewController().CreateScreenForItem(dummyItem, invalid, ["Now Playing"])
	return true

    else if returned = "home"
	'screen.refreshOnActivate = true
	while m.ViewController.screens.Count() > 0
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	end while
	m.ViewController.CreateHomeScreen()
	return true

    else if returned = "preferences"
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	'screen.refreshOnActivate = true
        dummyItem = CreateObject("roAssociativeArray")
        dummyItem.ContentType = "Preferences"
        dummyItem.Key = "Preferences"
        GetViewController().CreateScreenForItem(dummyItem, invalid, ["Preferences"])
	return true

    else if returned = "search"
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	'screen.refreshOnActivate = true
        dummyItem = CreateObject("roAssociativeArray")
        dummyItem.ContentType = "Search"
        dummyItem.Key = "Search"
        GetViewController().CreateScreenForItem(dummyItem, invalid, ["Search"])
        return true

    else if returned = "series"
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	'screen.refreshOnActivate = true
	series = getVideoMetadata(m.item.seriesId)
	series.ContentType = "Series"
	series.MediaType = "Series"
        GetViewController().CreateScreenForItem([series], 0, ["Shows", Series.Title])
        return true

    else if returned = "close"
	m.Screen.Close()
    end if

    return false
End Function

Sub springboardShowMoreDialog(item)
    dlg = createBaseDialog()
    dlg.Title = "More Options"
    DeleteAll = firstOf(RegRead("prefDelAll"), "1")

	if item.MediaType = "Video" or item.MediaType = "Game" then 

		if item.MediaType = "Video" and item.BookmarkPosition <> 0 then
			time = tostr(formatTime(item.BookmarkPosition))
			dlg.SetButton("markplayed", "Clear the Resume Point of " + time)
		else if item.Watched
			dlg.SetButton("markunplayed", "Mark as Unplayed")
		else
			dlg.SetButton("markplayed", "Mark as Played")
		end if
	end if
	'if item.MediaType = "Video" and item.BookmarkPosition <> 0 then
	'	time = tostr(formatTime(item.BookmarkPosition))
	'	dlg.SetButton("markplayed", "Clear Resume point of " + time)
	'end if
    if item.SeriesName <> invalid then
    	dlg.SetButton("favorites", "Change Favorites")
    else if item.ContentType <> "Person"
	if item.IsFavorite
		dlg.SetButton("removefavorite", "Remove as Favorite")
	else
		dlg.SetButton("markfavorite", "Mark as Favorite")
	end if
    end if

    ' delete
    if item.CanDelete and DeleteAll = "1" Then
        dlg.SetButton("delete", "Delete Item")
    end if

    ' Check for people
    if item.People <> invalid and item.People.Count() > 0

	if item.MediaType = "Video" then
		if item.LocalTrailerCount <> invalid and item.LocalTrailerCount > 0
			dlg.SetButton("cast", "Cast & Crew")
		end if
	else
		dlg.SetButton("people", "People")
	end If
    end if
   if item.SeriesName <> invalid then
	sh = getVideoMetadata(item.seriesId)
	if sh.People <> invalid and sh.People.Count() > 0
		dlg.SetButton("maincast", "Main Cast & Crew")
	end if
    end if

    ' Check for special features
    if item.SpecialFeatureCount <> invalid and item.SpecialFeatureCount > 0
        dlg.SetButton("specials", "Special Features")
    end if

	dlg.item = item
	dlg.parentScreen = m

	dlg.HandleButton = handleMoreOptionsButton

	dlg.SetButton("goto", "-> Go To ...")

	if (item.LocationType <> "Virtual" or item.ContentType = "TvChannel") And item.PlayAccess = "Full" and item.MediaType = "Video" then
		force = FirstOf(regRead("prefPlayMethod"),"Auto")
		private = FirstOf(regRead("prefprivate"),"0")
		if force <> "DirectPlay" then 
			dlg.SetButton("DirectPlay", "* Force DirectPlay")
		else
			dlg.SetButton("DirectPlay", "* Force DirectPlay [Selected]")
		end if

		if force <> "DirectStream" then 
			dlg.SetButton("DirectStream", "* Force DirectStream")
		else
			dlg.SetButton("DirectStream", "* Force DirectStream [Selected]")
		end if

		if force <> "Transcode" then 
			dlg.SetButton("Transcode", "* Force Transcode")
		else
			dlg.SetButton("Transcode", "* Force Transcode [Selected]")
		end if

		if force = "Auto" and private = "0" then 
			dlg.SetButton("Auto", "* Use Auto-Detection [Selected]")
		else
			dlg.SetButton("Auto", "* Use Auto-Detection")
		end if

		if force = "Auto" and private = "1" then 
			dlg.SetButton("Auto2", "* Use Auto-Detection Private [Selected]")
		else 
			dlg.SetButton("Auto2", "* Use Auto-Detection Private")
		end if
	end if
    dlg.SetButton("close", "Close This Window")
    dlg.Show()

End Sub

Function handleMoreOptionsButton(command, data) As Boolean

	item = m.item
	itemId = item.Id
	screen = m.parentScreen

    if command = "favorites" then
	screen.refreshOnActivate = true
	createFavoritesDialog(item)

    else if command = "goto" then
	screen.refreshOnActivate = true
	createGoToDialog(item)

    else if command = "cast" then
        newScreen = createPeopleScreen(m.ViewController, item)
	newScreen.ScreenName = "People" + itemId
        m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Cast & Crew"])
	newScreen.Show()
        return true
    else if command = "maincast" then
	series = getVideoMetadata(m.item.seriesId)
        newScreen = createPeopleScreen(m.ViewController, series)
	newScreen.ScreenName = "People" + itemId
        m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Cast & Crew"])
	newScreen.Show()
        return true
    else if command = "people" then
	newScreen = createPeopleScreen(m.ViewController, item)
	newScreen.ScreenName = "People" + itemId
	m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "People"])
	newScreen.Show()
	return true
    else if command = "markunplayed" then
	screen.refreshOnActivate = true
	postWatchedStatus(itemId, false)
	return true
    else if command = "markfavorite" then
	screen.refreshOnActivate = true
	result = postFavoriteStatus(itemId, true)
	if item.ParentIndexNumber <> invalid
		text = item.Title + chr(10) + "Season " + tostr(item.ParentIndexNumber) + ", Episode " + tostr(item.IndexNumber) + " of " + item.SeriesName
	else
		text = FirstOf(item.Title, "The item")
	end if
	if result then
		createDialog("Favorites Changed", text + " has been added to your favorites.", "OK", true)
	else
		createDialog("Favorites Error!", text + " has NOT been added to your favorites.", "OK", true)
	end if
        return true
    else if command = "removefavorite" then
	screen.refreshOnActivate = true
	result = postFavoriteStatus(itemId, false)
	if item.ParentIndexNumber <> invalid
		text = item.Title + chr(10) + "Season " + tostr(item.ParentIndexNumber) + ", Episode " + tostr(item.IndexNumber) + " of " + item.SeriesName
	else
		text = FirstOf(item.Title, "The item")
	end if
	if result then
		createDialog("Favorites Changed", text + " has been removed from your favorites.", "OK", true)
	else
		createDialog("Favorites Error!", text + " has NOT been removed from your favorites.", "OK", true)
	end if
        return true
    else if command = "markplayed" then
	screen.refreshOnActivate = true
	postWatchedStatus(itemId, true)
	return true
    else if command = "specials" then
        newScreen = createSpecialFeaturesScreen(m.ViewController, item)
	newScreen.ScreenName = "Chapters" + itemId
	m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Special Features"])
	newScreen.Show()
	return true
    else if command = "delete" then
	springboardDeleteItem(item)
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	return true
    else if command = "DirectPlay" or command = "DirectStream" or command = "Transcode" or command = "Auto" then
	regWrite("prefPlayMethod",command)
	regwrite("prefprivate", "0")
	getDeviceProfile()
	m.Screen.Close()
	screen.refreshOnActivate = true
	return true
    else if command = "Auto2" then
	regWrite("prefPlayMethod","Auto")
	regwrite("prefprivate", "1")
	getDeviceProfile()
	m.Screen.Close()
	screen.refreshOnActivate = true
	return true
    else if command = "homescreen"
	while m.ViewController.screens.Count() > 0
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	end while
	m.ViewController.CreateHomeScreen()
	return true
    else if command = "close" then
	m.Screen.Close()
	return true
    end if
	
    return false

End Function

Sub springboardShowStreamsDialog(item)

    createAudioAndSubtitleDialog(m.audioStreams, m.subtitleStreams, m.PlayOptions)
End Sub

'******************************************************
' createAudioAndSubtitleDialog
'******************************************************

Sub createAudioAndSubtitleDialog(audioStreams, subtitleStreams, playOptions)

    Debug ("createAudioAndSubtitleDialog")
	Debug ("Current AudioStreamIndex: " + tostr(playOptions.AudioStreamIndex))
	Debug ("Current SubtitleStreamIndex: " + tostr(playOptions.SubtitleStreamIndex))
	
    if audioStreams.Count() > 1 or subtitleStreams.Count() > 0
		dlg = createBaseDialog()
		dlg.Title = "Audio & Subtitles"

		dlg.HandleButton = handleAudioAndSubtitlesButton

		dlg.audioStreams = audioStreams
		dlg.subtitleStreams = subtitleStreams
		dlg.playOptions = playOptions

		dlg.SetButton("audio", "Audio")
		dlg.SetButton("subtitles", "Subtitles")
		dlg.SetButton("close", "Close This Window")

		dlg.Show(true)

    end if

End Sub

Function handleAudioAndSubtitlesButton(command, data) As Boolean

	if command = "audio" then

		createStreamSelectionDialog("Audio", m.audioStreams, m.subtitleStreams, m.playOptions, true)
        return true

    else if command = "subtitles" then

		createStreamSelectionDialog("Subtitle", m.audioStreams, m.subtitleStreams, m.playOptions, true)
        return true

    else if command = "close" then

		return true

    end if

    return true
End Function

Sub createStreamSelectionDialog(streamType, audioStreams, subtitleStreams, playOptions, openParentDialog)

    dlg = createBaseDialog()
    dlg.Title = "Select " + streamType

	dlg.HandleButton = handleStreamSelectionButton

	dlg.streamType = streamType
	dlg.audioStreams = audioStreams
	dlg.subtitleStreams = subtitleStreams
	dlg.playOptions = playOptions
	dlg.openParentDialog = openParentDialog

    if streamType = "Subtitle" then 
		streams = subtitleStreams
		currentIndex = playOptions.SubtitleStreamIndex
	else
		streams = audioStreams
		currentIndex = playOptions.AudioStreamIndex
	end If
	
	if streamType = "Subtitle" then 
	
		title = "None"
		
		if currentIndex = invalid or currentIndex = -1 then title = title + " [Selected]"
		dlg.SetButton("none", title)
	end If
	
	for each stream in streams

		if dlg.Buttons.Count() < 5 then

			title = firstOf(stream.Language, "Unknown language")

			if currentIndex = stream.Index then title = title + " [Selected]"

			dlg.SetButton(tostr(stream.Index), title)
		end if

	end For

    dlg.SetButton("close", "Close This Window")
    dlg.Show(true)
End Sub

Function handleStreamSelectionButton(command, data) As Boolean

    if command = "none" then

		m.playOptions.HasSelection = true
		
		if m.streamType = "Audio" then
			m.playOptions.AudioStreamIndex = -1
		else
			m.playOptions.SubtitleStreamIndex = -1
		end If

		if m.openParentDialog = true then createAudioAndSubtitleDialog(m.audioStreams, m.subtitleStreams, m.playOptions)

        return true
    else if command = "close" or command = invalid then

		if m.openParentDialog = true then createAudioAndSubtitleDialog(m.audioStreams, m.subtitleStreams, m.playOptions)
        return true

	else if command <> invalid then

		m.playOptions.HasSelection = true
		
		if m.streamType = "Audio" then
			m.playOptions.AudioStreamIndex = command.ToInt()
		else
			m.playOptions.SubtitleStreamIndex = command.ToInt()
		end If

		if m.openParentDialog = true then createAudioAndSubtitleDialog(m.audioStreams, m.subtitleStreams, m.playOptions)

		return true
    end if

    return false
End Function

'******************************************************
' Cancel Timer Dialog
'******************************************************

Function showCancelLiveTvTimerDialog()
	return showContextViewMenuYesNoDialog("Confirm Action", "Are you sure you wish to cancel this recording?")
End Function


'******************************************************
' Delete Recording Dialog
'******************************************************

Function showDeleteRecordingDialog(item)
	return showContextViewMenuYesNoDialog("Confirm Action", "Are you sure you wish to permanently delete " +item.Title+" from your library?")
End Function

Sub springboardDeleteItem(item)
	if showDeleteRecordingDialog(item) = "1" then
        	deleteLiveTvRecording(item)
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	end if
End Sub

Sub springboardCancelTimer(item)
	m.refreshOnActivate = true

	if showCancelLiveTvTimerDialog() = "1" then
        cancelLiveTvTimer(item.TimerId)
		m.Refresh(true)
	end if
End Sub

Sub springboardRecordProgram(item)
	m.refreshOnActivate = true

    timerInfo = getDefaultLiveTvTimer(item.Id)
    createLiveTvTimer(timerInfo)
	
	m.Refresh(true)
End Sub