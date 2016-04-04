Function createSearchScreen(viewController as Object) As Object

    obj = CreateObject("roAssociativeArray")
    initBaseScreen(obj, viewController)

    screen = CreateObject("roSearchScreen")
    history = CreateObject("roSearchHistory")

    screen.SetMessagePort(obj.Port)

    ' Always start with recent searches, even if we end up doing suggestions
    screen.SetSearchTerms(history.GetAsArray())
    screen.SetSearchTermHeaderText("Recent Searches:")

    screen.SetSearchButtonText("search")
    screen.SetClearButtonEnabled(true)
    screen.SetClearButtonText("clear history")

    ' Standard properties for all our Screen types
    'obj.Item = item
    obj.Screen = screen

	obj.baseHandleMessage = obj.HandleMessage
	obj.HandleMessage = ssHandleMessage

    obj.OnUrlEvent = ssOnUrlEvent
    obj.OnTimerExpired = ssOnTimerExpired

    obj.Progressive = true
    obj.History = history

    obj.SetText = ssSetText

    NowPlayingManager().SetFocusedTextField("Search", "", false)

    return obj

End Function

Function ssHandleMessage(msg) As Boolean

    handled = false

    if type(msg) = "roSearchScreenEvent" then

        if msg.isScreenClosed() then

			handled = true
            m.ViewController.PopScreen(m)
            NowPlayingManager().SetFocusedTextField(invalid, invalid, false)

        else if msg.isCleared() then

            handled = true
            m.History.Clear()
            m.Screen.ClearSearchTerms()

        else if msg.isPartialResult() then

            handled = true
            
			' We got some additional characters, if the user pauses for a
            ' bit then kick off a search suggestion request.
            if m.Progressive then
                if m.ProgressiveTimer = invalid then
                    m.ProgressiveTimer = createTimer()
                    m.ProgressiveTimer.SetDuration(250)
                end if
                m.ProgressiveTimer.Mark()
                m.ProgressiveTimer.Active = true
                m.ViewController.AddTimer(m.ProgressiveTimer, m)
                m.SearchTerm = msg.GetMessage()
                NowPlayingManager().SetFocusedTextField("Search", m.SearchTerm, false)
            end if

        else if msg.isFullResult() then
            
			handled = true
            m.SetText(msg.GetMessage(), true)

        end if

    end if

	return handled

End Function

Sub ssOnTimerExpired(timer)
    
	Debug ("ssOnTimerExpired")

	term = m.SearchTerm
    length = len(term)

    if length > 0
		' URL
		url = GetServerBaseUrl() + "/Search/Hints"

		' Query
		query = {

			UserId: getGlobalVar("user").Id
			Limit: "9"
			SearchTerm: term
			IncludePeople: "true"
			IncludeStudios: "true"
			IncludeGenres: "true"
			IncludeItemTypes: "Movie,BoxSet,Series,Episode,Trailer,Channel,ChannelVideoItem,Video,AdultVideo,MusicVideo,Genre,MusicGenre,MusicArtist,MusicAlbum,Person,People,Studio"
		}

		' Prepare Request
		request = HttpRequest(url)
		request.ContentType("json")
		request.AddAuthorization()
		request.BuildQuery(query)

		' Execute Request
		context = CreateObject("roAssociativeArray")
		context.requestType = "progressive"
		m.ViewController.StartRequest(request.Http, m, context)

	else

        m.Screen.SetSearchTermHeaderText("Recent Searches:")
        searchHistory = m.History
        m.Screen.SetSearchTerms(searchHistory)

    end if

End Sub

Sub ssOnUrlEvent(msg, requestContext)

	Debug ("ssOnUrlEvent")

    suggestions = processSearchHintsResponse(msg.GetString())

	if suggestions <> invalid then

        m.Screen.SetSearchTermHeaderText("Search Suggestions:")
        m.Screen.SetClearButtonEnabled(false)
		
		if suggestions.Count() > 0 then
			m.Screen.SetSearchTerms(suggestions)
		else
			m.Screen.ClearSearchTerms()
		end if
        

    end if

End Sub

Sub ssSetText(text, isComplete)

	if text = invalid or text = "" then 
		m.Screen.SetSearchTermHeaderText("Recent Searches:")
        m.Screen.SetSearchTerms(m.History)		
		m.Screen.SetSearchText("")
		return
	end if
	
    if isComplete then

        m.History.Push(text)

        Debug("Searching for " + text)

        ' Create a dummy item with the key set to the search URL
        item = CreateObject("roAssociativeArray")
        item.Title = "Search for '" + text + "'"
        item.searchTerm = text

        m.ViewController.CreateScreenForItem(item, invalid, [item.Title])

    else
        m.Screen.SetSearchText(text)
    end if

End Sub

Function createSearchResultsScreen(viewController as Object, searchTerm As String) As Object

    imageType      = 0

	names = ["Movies", "Shows", "Episodes", "People", "Trailers", "Videos", "Genres", "Artists", "Albums", "Studios"]
	keys = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getSearchResultRowUrl
	loader.parsePagedResult = parseSearchResultScreenResult
	loader.searchTerm = searchTerm

	screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
	'screen.SetDescriptionVisible(true)
	'screen.displayDescription = 1

    return screen

End Function

Function getSearchResultRowUrl(row as Integer, id as String) as String

    searchTerm = m.searchTerm

    url = GetServerBaseUrl() + "/Search/Hints?UserId=" + getGlobalVar("user").Id

    ' Query
    query = {}

	if row = 0
		query = {
			SearchTerm: searchTerm
			IncludePeople: "false"
			IncludeStudios: "false"
			IncludeGenres: "false"
			IncludeArtists: "false"
			IncludeMedia: "true"
			IncludeItemTypes: "Movie,BoxSet"
		}
	else if row = 1
		query = {
			SearchTerm: searchTerm
			IncludePeople: "false"
			IncludeStudios: "false"
			IncludeGenres: "false"
			IncludeArtists: "false"
			IncludeMedia: "true"
			IncludeItemTypes: "Series"
		}
	else if row = 2
		query = {
			SearchTerm: searchTerm
			IncludePeople: "false"
			IncludeStudios: "false"
			IncludeGenres: "false"
			IncludeArtists: "false"
			IncludeMedia: "true"
			IncludeItemTypes: "Episode"
		}
	else if row = 3
		query = {
			SearchTerm: searchTerm
			IncludePeople: "true"
			IncludeStudios: "false"
			IncludeGenres: "false"
			IncludeArtists: "false"
			IncludeMedia: "true"
			IncludeItemTypes: "People,Person"
		}
	else if row = 4
		query = {
			SearchTerm: searchTerm
			IncludePeople: "false"
			IncludeStudios: "false"
			IncludeGenres: "false"
			IncludeArtists: "false"
			IncludeMedia: "true"
			IncludeItemTypes: "Trailer,ChannelVideoItem"
		}
	else if row = 5
		query = {
			SearchTerm: searchTerm
			IncludePeople: "false"
			IncludeStudios: "false"
			IncludeGenres: "false"
			IncludeArtists: "false"
			IncludeMedia: "true"
			IncludeItemTypes: "Video,AdultVideo,MusicVideo"
		}
	else if row = 6
		query = {
			SearchTerm: searchTerm
			IncludePeople: "false"
			IncludeStudios: "false"
			IncludeGenres: "true"
			IncludeArtists: "false"
			IncludeMedia: "true"
			IncludeItemTypes: "Genre,MusicGenre"
		}
	else if row = 7
		query = {
			SearchTerm: searchTerm
			IncludePeople: "false"
			IncludeStudios: "false"
			IncludeGenres: "false"
			IncludeArtists: "true"
			IncludeMedia: "true"
			IncludeItemTypes: "MusicArtist"
		}
	else if row = 8
		query = {
			SearchTerm: searchTerm
			IncludePeople: "false"
			IncludeStudios: "false"
			IncludeGenres: "false"
			IncludeArtists: "false"
			IncludeMedia: "true"
			IncludeItemTypes: "MusicAlbum"
		}
	else if row = 9
		query = {
			SearchTerm: searchTerm
			IncludePeople: "false"
			IncludeStudios: "true"
			IncludeGenres: "false"
			IncludeArtists: "false"
			IncludeMedia: "true"
			IncludeItemTypes: "Studio"
		}
	end If

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseSearchResultScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	if row = 9 then
		imageType = 1
	else
		imageType = 0
	end if
	primaryImageStyle = "mixed-aspect-ratio-portrait"
	mode = ""

    return parseSearchResultsResponse(json, mode)

End Function

'**********************************************************
'** createGenreSearchScreen
'**********************************************************

Function createGenreSearchScreen(viewController as Object, genre As String) As Object

    imageType      = 0

	names = ["Movies", "Shows", "Trailers", "Albums"]
	keys = ["0", "1", "2", "3"]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getGenreRowScreenUrl
	loader.parsePagedResult = parseGenreScreenResult
	loader.genre = genre

	screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
	screen.SetDescriptionVisible(true)
	screen.displayDescription = 1

    return screen
	
End Function

Function getGenreRowScreenUrl(row as Integer, id as String) as String

    genre = m.genre

    ' URL
    url = GetServerBaseUrl()

    ' Query
    query = {}

	if row = 0
		' Movies
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "Movie"
			fields: "Overview"
			sortby: "SortName"
			sortorder: "Ascending",
			genres: genre
		}
	else if row = 1
		' Tv
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "Series"
			fields: "Overview"
			sortby: "SortName"
			sortorder: "Ascending",
			genres: genre
		}
	else if row = 2
		' Trailers
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "Trailer,ChannelVideoItem"
			fields: "Overview"
			sortby: "SortName"
			sortorder: "Ascending",
			genres: genre
		}
	else if row = 3
		' Albums
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "MusicAlbums"
			fields: "Overview"
			sortby: "SortName"
			sortorder: "Ascending",
			genres: genre
		}
	end If

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseGenreScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	imageType      = 0
	primaryImageStyle = "mixed-aspect-ratio-portrait"
	mode = ""

    return parseItemsResponse(json, imageType, primaryImageStyle, mode)

End Function

'**********************************************************
'** createStudioSearchScreen
'**********************************************************

Function createStudioSearchScreen(viewController as Object, studio As String) As Object

    imageType      = 0

	names = ["Movies", "Shows", "Trailers", "Albums"]
	keys = ["0", "1", "2", "3"]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getStudioRowScreenUrl
	loader.parsePagedResult = parseStudioScreenResult
	loader.studio = studio

	screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
	screen.SetDescriptionVisible(true)
	screen.displayDescription = 1

    return screen
	
End Function

Function getStudioRowScreenUrl(row as Integer, id as String) as String

    studio = m.studio

    ' URL
    url = GetServerBaseUrl()

    ' Query
    query = {}

	if row = 0
		' Movies
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "Movie"
			fields: "Overview"
			sortby: "SortName"
			sortorder: "Ascending",
			studios: studio
		}
	else if row = 1
		' Tv
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "Series"
			fields: "Overview"
			sortby: "SortName"
			sortorder: "Ascending",
			studios: studio
		}
	else if row = 2
		' Trailers
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "Trailer,ChannelVideoItem"
			fields: "Overview"
			sortby: "SortName"
			sortorder: "Ascending",
			studios: studio
		}
	else if row = 3
		' Albums
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "MusicAlbums"
			fields: "Overview"
			sortby: "SortName"
			sortorder: "Ascending",
			studios: studio
		}
	end If

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseStudioScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	imageType      = 0
	primaryImageStyle = "mixed-aspect-ratio-portrait"
	mode = ""

    return parseItemsResponse(json, imageType, primaryImageStyle, mode)

End Function


'**********************************************************
'** processSearchHintsResponse
'**********************************************************

Function processSearchHintsResponse(json as String) as Object


    if json <> invalid

		response = normalizeJson(json)
        jsonObj     = ParseJSON(response)

        if jsonObj = invalid
	    createDialog("JSON Error", "Error while parsing JSON response for Search Hints.", "OK", true)
            Debug("Error while parsing JSON response for Search Hints")
            return invalid
        end if

        totalRecordCount = jsonObj.TotalRecordCount

        contentList = CreateObject("roArray", 10, true)

        for each i in jsonObj.SearchHints
            if i.Name <> invalid And i.Name <> ""
                contentList.push( i.Name )
            end if
        end for

        return contentList

    else

		return invalid
    end if

End Function