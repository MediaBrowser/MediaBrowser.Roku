'**********************************************************
'**  Emby Roku Client - Poster Screen
'** Credit: Plex Roku https://github.com/plexinc/roku-client-public
'**********************************************************

Function CreatePosterScreen(viewController as Object, item as Object, style As String) As Object

    ' Setup Screen
    obj = CreateObject("roAssociativeArray")

	initBaseScreen(obj, viewController)	
	port = obj.Port

    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)

    ' Setup Common Items
    obj.Item = item
    obj.Screen         = screen
    obj.Port           = port
    obj.SetContent     = SetPosterContent
    obj.ShowMessage    = ShowPosterMessage
    obj.ClearMessage   = ClearPosterMessage
    obj.GetDataContainer = getPosterScreenDataContainer
    obj.ShowList = posterShowContentList
    obj.Show = showPosterScreen
    obj.SetFocusedItem = SetPosterFocusedItem
    obj.HandleMessage = posterHandleMessage
    obj.SetListStyle = posterSetListStyle
    obj.UseDefaultStyles = true
    obj.ListStyle = invalid
    obj.ListDisplayMode = invalid
    obj.FilterMode = invalid
    obj.Facade = invalid

	m.dataLoaderHttpHandler = invalid

	obj.OnDataLoaded = posterOnDataLoaded

	obj.contentArray = []
	obj.focusedList = 0
	obj.names = []

	obj.playOnSelection = false

	' Setup Display Style
	obj.Screen.SetListStyle(style)
	obj.Screen.SetDisplayMode("scale-to-fit")
	obj.SeriesOptionsDialog = posterSeriesOptionsDialog
	
    if NOT AudioPlayer().IsPlaying AND firstOf(RegRead("prefThemeMusic"), "yes") = "yes" then
        AudioPlayer().PlayThemeMusic(item)
        obj.Cleanup = baseStopAudioPlayer
    end if

    Return obj
	
End Function

Sub posterScreenActivate(priorScreen)
	m.baseActivate(priorScreen)
	m.Refresh(true)
end sub

'**********************************************************
'** Set Content for Poster Screen
'**********************************************************

Function SetPosterContent(contentList As Object)

	m.contentArray = contentList

    m.screen.SetContentList(contentList)

End Function


'**********************************************************
'** Set Focused Item for Poster Screen
'**********************************************************

Function SetPosterFocusedItem(index as Integer)
    m.screen.SetFocusedListItem(index)
End Function


'**********************************************************
'** Show Message for Poster Screen
'**********************************************************

Function ShowPosterMessage(message as String)
    m.screen.ShowMessage(message)
End Function


'**********************************************************
'** Clear Message for Poster Screen
'**********************************************************

Function ClearPosterMessage(clear as Boolean)
    m.screen.ClearMessage(clear)
End Function


'**********************************************************
'** Show Poster Screen
'**********************************************************

Function getPosterScreenDataContainer(viewController as Object, item as Object) as Object

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = []

	return obj

End Function

Function showPosterScreen() As Integer

    ' Show a facade immediately to get the background 'retrieving' instead of
    ' using a one line dialog.
    m.Facade = CreateObject("roPosterScreen")
    m.Facade.Show()

    content = m.Item

    container = m.GetDataContainer(m.ViewController, content)

    if container = invalid then
        'dialog = createBaseDialog()
        'dialog.Title = "Content Unavailable"
        'dialog.Text = "An error occurred while trying to load this content, make sure the server is running."
        'dialog.Facade = m.Facade
        'dialog.Show()
        m.closeOnActivate = true
        m.Facade = invalid
        createDialog("Content Unavailable!", "An error occurred while trying to load this content, make sure the server is running.", "OK", true)
        return 0
    end if

    m.names = container.names
    keys = container.keys

    m.FilterMode = m.names.Count() > 0

    if m.FilterMode then

        m.Loader = createPaginatedLoader(container, m.dataLoaderHttpHandler, 25, 25)
        m.Loader.Listener = m

        m.Screen.SetListNames(m.names)

		focusedIndex = 0
		if container.focusedIndex <> invalid then focusedIndex = container.focusedIndex
        m.Screen.SetFocusedList(focusedIndex)

        for index = 0 to keys.Count() - 1
            status = CreateObject("roAssociativeArray")
            status.listDisplayMode = invalid
            status.focusedIndex = 0
            status.content = []
            status.lastUpdatedSize = 0
            m.contentArray[index] = status
        next

        m.Loader.LoadMoreContent(0, 0)

		m.Screen.SetFocusToFilterBanner(false)
    else

        ' We already grabbed the full list, no need to bother with loading
        ' in chunks.

        status = CreateObject("roAssociativeArray")
        status.content = container.items

        m.Loader = createDummyLoader()

        'if container.Count() > 0 then
            'contentType = container.GetMetadata()[0].ContentType
        'else
            'contentType = invalid
        'end if

        if m.UseDefaultStyles then
            'aa = getDefaultListStyle(container.ViewGroup, contentType)
            'status.listStyle = aa.style
            'status.listDisplayMode = aa.display
        else
            status.listStyle = m.ListStyle
            status.listDisplayMode = m.ListDisplayMode
        end if

        status.focusedIndex = 0
        status.lastUpdatedSize = status.content.Count()

        m.contentArray[0] = status

    end if

    m.focusedList = 0
    m.ShowList(0)
    if m.Facade <> invalid then m.Facade.Close()

    return 0
End Function

'**********************************************************
'** posterShowContentList
'**********************************************************

Sub posterShowContentList(index)

    status = m.contentArray[index]
    if status = invalid
	createDialog("Display Error!", "No items to display. Status is invalid. Sorry.", "OK", true)
	return
    end if
    m.Screen.SetContentList(status.content)

    if status.listStyle <> invalid then
        m.Screen.SetListStyle(status.listStyle)
    end if
    if status.listDisplayMode <> invalid then
        m.Screen.SetListDisplayMode(status.listDisplayMode)
    end if

    Debug("Showing screen with " + tostr(status.content.Count()) + " elements")

    if status.content.Count() = 0 AND NOT m.FilterMode then
        'dialog = createBaseDialog()
        'dialog.Facade = m.Facade
        'dialog.Title = "No items to display"
        'dialog.Text = "This directory appears to be empty."
        'dialog.Show()
        m.Facade = invalid
        m.closeOnActivate = true
        createDialog("Display Error!", "No items to display. This category appears to be empty.. Sorry.", "OK", true)
    else
        m.Screen.Show()
        m.Screen.SetFocusedListItem(status.focusedIndex)
    end if
End Sub



'**********************************************************
'** posterSeriesShowOptionsDialog
'**********************************************************

Sub posterSeriesOptionsDialog()
    skip = FirstOf(GetGlobalVar("AudioConflict"),"0")
    if skip = "1" or NOT AudioPlayer().Context <> invalid
    	dlg = createBaseDialog()
    	dlg.Title = "Options"
	dlg.item = m.PosterItem
	if dlg.item = invalid
		dlg.item = m.item
	else
		'm.item = dlg.item
	end if
	dlg.parentScreen = m

	series = dlg.item.shortdescriptionline1
	if series <> invalid and series.len() > 25 then series = left(series,25) + "..."

	dlg.HandleButton = handleSeriesOptionsButton

	skip = FirstOf(GetGlobalVar("AudioConflict"),"0")
	musicstop = FirstOf(GetGlobalVar("musicstop"),"0")

	if AudioPlayer().Context <> invalid and musicstop = "0"
		if skip ="0"
			dlg.SetButton("preferAudio", "* For Audio [Selected]")
			dlg.SetButton("preferVideo", "* For Video")
		else
			dlg.SetButton("preferAudio", "* For Audio")
			dlg.SetButton("preferVideo", "* For Video [Selected]")
		end if
	end if

	if dlg.item.MediaType = "Video" or dlg.item.MediaType = "Game" then 
		data = GetFullItemMetadata(dlg.item, false, {})
		if data.MediaType = "Video" and data.BookmarkPosition <> 0 then
			time = tostr(formatTime(dlg.item.BookmarkPosition))
			dlg.SetButton("markplayed", "Clear the Resume Point of " + time)
		else if data.Watched
			dlg.SetButton("markunplayed", "Mark as Unplayed")
		else
			dlg.SetButton("markplayed", "Mark as Played")
		end if
	end if

    	if dlg.item.SeriesName <> invalid then
    		dlg.SetButton("favorites", "Change Favorites")
    	else
		if dlg.item.IsFavorite <> invalid
			data = GetFullItemMetadata(dlg.item, false, {})
			if data.IsFavorite
				dlg.SetButton("removefavorite", "Remove as Favorite")
			else
				dlg.SetButton("markfavorite", "Mark as Favorite")
			end if
		else if m.item.IsFavorite <> invalid
			data = GetFullItemMetadata(m.item, false, {})
			if data.IsFavorite
				dlg.SetButton("removefavorite", "Remove as Favorite")
			else
				dlg.SetButton("markfavorite", "Mark as Favorite")
			end if
		end if
    	end if
	dlg.SetButton("description", "View Full Description")
	thespot = m.contentArray[m.focusedList].content[m.contentArray[m.focusedList].focusedindex]
	status = GetFullItemMetadata(thespot, false, {})
	if dlg.item.SeriesName <> invalid then
		if status.People <> invalid and status.People.Count() > 0
			dlg.SetButton("cast", "Cast & Crew")
		end if
		show = getVideoMetadata(dlg.item.seriesId)
		if show.People <> invalid and show.People.Count() > 0
			dlg.SetButton("maincast", "Main Cast & Crew")
		end if
	else if dlg.item.People <> invalid and dlg.item.People.Count() > 0
		if dlg.item.MediaType = "Video" then
			dlg.SetButton("cast", "Cast & Crew")
		else
			dlg.SetButton("cast", "People")
		end if
	end if

	screen = m.ViewController.screens[m.ViewController.screens.Count() - 1]
	if dlg.item.ParentIndexNumber = invalid and series <> invalid then
		if screen.screenName <> invalid
			if left(screen.screenName,6) <> "Series"
				dlg.SetButton("detail", "-> Go To " + tostr(series))
			end if
		else
			dlg.SetButton("detail", "-> Go To " + tostr(series))
		end if
	end if

	if AudioPlayer().Context <> invalid and musicstop = "0"
		dlg.SetButton("nowplaying", "-> Go To Now Playing")
	end if
	dlg.SetButton("home", "-> Go To Home Screen")
	dlg.SetButton("preferences", "-> Go To Preferences")
	dlg.SetButton("search", "-> Go To Search Screen")
	dlg.SetButton("close", "Close this window")

	dlg.Show()
    end if
End Sub

'**********************************************************
'** handleSeriesOptionsButton
'**********************************************************

Function handleSeriesOptionsButton(command, data) As Boolean

	item = GetFullItemMetadata(m.item, false, {})
	itemId = m.item.Id
	screen = m
	series = m.item.seriesName
	if series <> invalid and series.len() > 25 then series = left(series,25) + "..."

    if command = "cast" then
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	series = getVideoMetadata(m.item.Id)
        newScreen = createPeopleScreen(m.ViewController, series)
	newScreen.ScreenName = "People" + itemId
        m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Cast & Crew"])
	newScreen.Show()
	return true

    else if command = "markunplayed" then
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	screen.refreshOnActivate = true
	postWatchedStatus(itemId, false)
	return true
    else if command = "markplayed" then
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	screen.refreshOnActivate = true
	postWatchedStatus(itemId, true)
	return true
    else if command = "favorites" then
	screen.refreshOnActivate = true
	createPosterFavoritesDialog(m.item)
    else if command = "description" then
	CreateDialog(Item.Title, Item.FullDescription, "OK", true)
	return true
    else if command = "maincast" then
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	series = getVideoMetadata(m.item.seriesId)
        newScreen = createPeopleScreen(m.ViewController, series)
	newScreen.ScreenName = "People" + itemId
        m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Cast & Crew"])
	newScreen.Show()
	return true

    else if command = "nowplaying"
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	'screen.refreshOnActivate = true
        dummyItem = CreateObject("roAssociativeArray")
        dummyItem.ContentType = "audio"
        dummyItem.Key = "nowplaying"
        GetViewController().CreateScreenForItem(dummyItem, invalid, ["Now Playing"])
	return true

    else if command = "home"
	'screen.refreshOnActivate = true
	while m.ViewController.screens.Count() > 0
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	end while
	m.ViewController.CreateHomeScreen()
	return true

    else if command = "preferences"
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	'screen.refreshOnActivate = true
        dummyItem = CreateObject("roAssociativeArray")
        dummyItem.ContentType = "Preferences"
        dummyItem.Key = "Preferences"
        GetViewController().CreateScreenForItem(dummyItem, invalid, ["Preferences"])
	return true

    else if command = "search"
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	'screen.refreshOnActivate = true
        dummyItem = CreateObject("roAssociativeArray")
        dummyItem.ContentType = "Search"
        dummyItem.Key = "Search"
        GetViewController().CreateScreenForItem(dummyItem, invalid, ["Search"])
        return true

    else if command = "detail"
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
        GetViewController().CreateScreenForItem([Item], 0, [item.ContentType, item.Title])
        return true

    else if command = "removefavorite" then
	screen.refreshOnActivate = true
	result = postFavoriteStatus(m.item.Id, false)
	if result then
		createDialog("Favorites Changed", m.item.Title + " has been removed from your favorites.", "OK", true)
	else
		createDialog("Favorites Error!", m.item.Title + " has NOT been removed from your favorites.", "OK", true)
	end if
	m.refreshOnActivate = true
        return true

    else if command = "markfavorite" then
	screen.refreshOnActivate = true
	result = postFavoriteStatus(m.item.Id, true)
	if result then
		createDialog("Favorites Changed", m.item.Title + " has been added to your favorites.", "OK", true)
	else
		createDialog("Favorites Error!", m.item.Title + " has NOT been added to your favorites.", "OK", true)
	end if
        return true

    else if command = "removefavoriteseries" then
	screen.refreshOnActivate = true
	result = postFavoriteStatus(m.item.SeriesId, false)
	if result then
		createDialog("Favorites Changed", FirstOf(series, "The show") + " has been removed from your favorites.", "OK", true)
	else
		createDialog("Favorites Error!", FirstOf(series, "The show") + " has NOT been removed from your favorites.", "OK", true)
	end if
	return true

    else if command = "markfavoriteseries" then
	screen.refreshOnActivate = true
	result = postFavoriteStatus(m.item.SeriesId, true)
	if result then
		createDialog("Favorites Changed", FirstOf(series, "The show") + " has been added to your favorites.", "OK", true)
	else
		createDialog("Favorites Error!", FirstOf(series, "The show") + " has NOT been added to your favorites.", "OK", true)
	end if
	return true

    else if command = "markfavoriteepisode" then
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

    else if command = "removefavoriteepisode" then
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
    else if command = "preferAudio" then
	GetGlobalAA().AddReplace("AudioConflict", "0")
	return true
    else if command = "preferVideo" then
	GetGlobalAA().AddReplace("AudioConflict", "1")
	return true
    else if command = "close" then

	m.Screen.Close()
	return true
    end if
	
    return false

End Function

Sub createPosterFavoritesDialog(item)
    dlg = createBaseDialog()
    dlg.Title = "Favorites Options"
    dlg.openParentDialog = true
    seriesName = item.seriesName
    if seriesName <> invalid and seriesName.len() > 25 then seriesName = left(seriesName,25) + "..."

    if item.ParentIndexNumber <> invalid then
      sh = getVideoMetadata(item.Id)
      if sh.IsFavorite then
        dlg.SetButton("removefavorite", "Remove Season " + tostr(item.ParentIndexNumber) + ", Episode " + tostr(item.IndexNumber) + " as a Favorite")
      else
        dlg.SetButton("markfavorite", "Mark Season " + tostr(item.ParentIndexNumber) + ", Episode " + tostr(item.IndexNumber) + " as a Favorite")
      end if
    else
      sh = getVideoMetadata(item.Id)
      if sh.IsFavorite then
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

	dlg.HandleButton = handlePosterFavoritesOptionsButton

    dlg.SetButton("close", "Close This Window")
    dlg.Show()
End Sub

Function handlePosterFavoritesOptionsButton(command, data) As Boolean
	item = m.item
	itemId = item.Id
	screen = m

    if command = "removefavorite" then
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
		screen.refreshOnActivate = true
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		return true
    else if command = "markfavorite" then
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
		screen.refreshOnActivate = true
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		return true
    else if command = "removefavoriteseason" then
		result = postFavoriteStatus(item.SeasonId, false)
		createDialog("Favorites Changed", "Season " + tostr(item.ParentIndexNumber) + " of " + item.SeriesName +  " has been removed from your favorites.", "OK", true)
		return true
    else if command = "markfavoriteseason" then
		postFavoriteStatus(item.SeasonId, true)
		if result then
			createDialog("Favorites Changed", "Season " + tostr(item.ParentIndexNumber) + " of " + item.SeriesName + " has been added to your favorites.", "OK", true)
		else
			createDialog("Favorites Error!", "Season " + tostr(item.ParentIndexNumber) + " of " + item.SeriesName + " has NOT been added to your favorites.", "OK", true)
		end if
        	return true
    else if command = "removefavoriteseries" then
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		result = postFavoriteStatus(item.SeriesId, false)
		if result then
			createDialog("Favorites Changed", FirstOf(item.SeriesName, "The series") + " has been removed from your favorites.", "OK", true)
		else
			createDialog("Favorites Error!", FirstOf(item.SeriesName, "The series") + " has NOT been removed from your favorites.", "OK", true)
		end if
		screen.refreshOnActivate = true
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
        	return true
    else if command = "markfavoriteseries" then
		result = postFavoriteStatus(item.SeriesId, true)
		if result then
			createDialog("Favorites Changed", FirstOf(item.SeriesName, "The series") + " has been added to your favorites.", "OK", true)
		else
			createDialog("Favorites Error!", FirstOf(item.SeriesName, "The series") + " has NOT been added to your favorites.", "OK", true)
		end if
		screen.refreshOnActivate = true
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
        	return true
    else if command = "close" then
		m.Screen.Close()
        return true
    end if
    return false
End Function

Function getSeriesPeopleDataContainer(viewController as Object, item as Object) as Object

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

'**********************************************************
'** posterHandleMessage
'**********************************************************

Function posterHandleMessage(msg) As Boolean

    	handled = false

	if type(msg) = "roPosterScreenEvent" then
        handled = true

        '* Focus change on the filter bar causes content change
            if msg.isListFocused() then

            	m.focusedList = msg.GetIndex()
            	m.ShowList(m.focusedList)
            	m.Loader.LoadMoreContent(m.focusedList, 0)

            else if msg.isListItemSelected() then

            	index = msg.GetIndex()
            	content = m.contentArray[m.focusedList].content
            	selected = content[index]

            if selected <> invalid then

                contentType = selected.ContentType

                Debug("Content type in poster screen: " + tostr(contentType))

				if m.playOnSelection = true then

					m.ViewController.CreatePlayerForItem(content, index, {})

				else
					if contentType = "Series" or m.names.Count() = 0 then
						breadcrumbs = [selected.Title]
					else
						breadcrumbs = [m.names[m.focusedList], selected.Title]
					end if

					m.ViewController.CreateScreenForItem(content, index, breadcrumbs)
				end If

            end if

            else if msg.isScreenClosed() then
            	m.ViewController.PopScreen(m)

	    else if msg.isListItemFocused() then

            ' We don't immediately update the screen's content list when
            ' we get more data because the poster screen doesn't perform
            ' as well as the grid screen (which has an actual method for
            ' refreshing part of the list). Instead, if the user has
            ' focused toward the end of the list, update the content.

            status = m.contentArray[m.focusedList]
            status.focusedIndex = msg.GetIndex()
            if status.focusedIndex + 10 > status.lastUpdatedSize AND status.content.Count() > status.lastUpdatedSize then
                m.Screen.SetContentList(status.content)
                status.lastUpdatedSize = status.content.Count()
            end if
        
	    else if msg.isRemoteKeyPressed() then
			if msg.GetIndex() = 10 then
				m.PosterItem = m.contentArray[m.focusedList].content[m.contentArray[m.focusedList].focusedindex]
				m.SeriesOptionsDialog()
			else if msg.GetIndex() = 13 then
				Debug("Playing item directly from poster screen")
				status = m.contentArray[m.focusedList]
				m.ViewController.CreatePlayerForItem(status.content, status.focusedIndex, {})
            		end if
		end if
	end If
	return handled
End Function

'**********************************************************
'** posterOnDataLoaded
'**********************************************************

Sub posterOnDataLoaded(row As Integer, data As Object, startItem as Integer, count As Integer, finished As Boolean)
    status = m.contentArray[row]
    status.content = data

    ' If this was the first content we loaded, set up the styles
    if startItem = 0 AND count > 0 then
        if m.UseDefaultStyles then
            if data.Count() > 0 then
                'aa = getDefaultListStyle(data[0].ViewGroup, data[0].contentType)
                'status.listStyle = aa.style
                'status.listDisplayMode = aa.display
            end if
        else
            status.listStyle = m.ListStyle
            status.listDisplayMode = m.ListDisplayMode
        end if
    end if

    if row = m.focusedList AND (finished OR startItem = 0 OR status.focusedIndex + 10 > status.lastUpdatedSize) then
        m.ShowList(row)
        status.lastUpdatedSize = status.content.Count()
    end if

    ' Continue loading this row
    m.Loader.LoadMoreContent(row, 0)
End Sub

'**********************************************************
'** posterSetListStyle
'**********************************************************

Sub posterSetListStyle(style, displayMode)
    m.ListStyle = style
    m.ListDisplayMode = displayMode
    m.UseDefaultStyles = false
End Sub