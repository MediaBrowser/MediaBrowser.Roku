'**********************************************************
'** createMovieLibraryScreen
'**********************************************************

Function createMovieLibraryScreen(viewController as Object, parentId as String) As Object

    imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

	names = ["Movies  ( Press * for Options )", "Jump In", "Collections", "Favorite Movies", "Genres", "Studios", "Internet Trailers", "Library Trailers"]
	keys = ["0", "1", "2", "3", "4", "5", "6", "7"]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getMovieLibraryRowScreenUrl
	loader.parsePagedResult = parseMovieLibraryScreenResult
	loader.getLocalData = getMovieLibraryScreenLocalData
	loader.parentId = parentId

    if imageType = 0 then
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
    Else
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
    End If

	screen.baseActivate = screen.Activate
	screen.Activate = movieScreenActivate

    screen.displayDescription = (firstOf(RegUserRead("movieDescription"), "1")).ToInt()

	screen.createContextMenu = movieScreenCreateContextMenu

    return screen

End Function

Sub movieScreenActivate(priorScreen)

    imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()
	displayDescription = (firstOf(RegUserRead("movieDescription"), "1")).ToInt()
	
    if imageType = 0 then
		gridStyle = "mixed-aspect-ratio"
    Else
		gridStyle = "two-row-flat-landscape-custom"
    End If

	m.baseActivate(priorScreen)

	if gridStyle <> m.gridStyle or displayDescription <> m.displayDescription then
		
		m.displayDescription = displayDescription
		m.gridStyle = gridStyle
		m.DestroyAndRecreate()

	end if

End Sub

Function getMovieLibraryScreenLocalData(row as Integer, id as String, startItem as Integer, count as Integer) as Object

	if row = 1 then
		return getAlphabetList("MovieAlphabet", m.parentId)
	end If

    return invalid

End Function

Function getMovieLibraryRowScreenUrl(row as Integer, id as String) as String

    filterBy       = (firstOf(RegUserRead("movieFilterBy"), "0")).ToInt()
    sortBy         = (firstOf(RegUserRead("movieSortBy"), "0")).ToInt()
    sortOrder      = (firstOf(RegUserRead("movieSortOrder"), "0")).ToInt()

    url = GetServerBaseUrl()

    query = {}

	if row = 0
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"
		if filterBy = 1
			query.AddReplace("Filters", "IsUnPlayed")
		else if filterBy = 2
			query.AddReplace("Filters", "IsPlayed")
		end if
		if sortBy = 1
			query.AddReplace("SortBy", "DateCreated,SortName")
		else if sortBy = 2
			query.AddReplace("SortBy", "DatePlayed,SortName")
		else if sortBy = 3
			query.AddReplace("SortBy", "PremiereDate,SortName")
		else
			query.AddReplace("SortBy", "SortName")
		end if
		if sortOrder = 1
			query.AddReplace("SortOrder", "Descending")
		end if
		query.AddReplace("IncludeItemTypes", "Movie")
		query.AddReplace("Fields", "Overview")
		query.AddReplace("ParentId", m.parentId)
	else if row = 1
		' Alphabet - should never get in here
	else if row = 2
		' Collections
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"
		query.AddReplace("IncludeItemTypes", "BoxSet")
		query.AddReplace("Fields", "Overview")
		query.AddReplace("SortBy", "SortName")
		'query.AddReplace("ParentId", m.parentId)
		query.AddReplace("ImageTypeLimit", "1")
	else if row = 3
		' Favorite Movies
		url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"
		query.AddReplace("Filters", "IsFavorite")
		query.AddReplace("SortBy", "SortName")
		query.AddReplace("SortOrder", "Ascending")
		query.AddReplace("fields", "PrimaryImageAspectRatio,Overview")
		'query.AddReplace("ImageTypeLimit", "1")
		query.AddReplace("IncludeItemTypes", "Movie")
	else if row = 4
		' Genre
		url = url  + "/Genres?recursive=true"
		query.AddReplace("SortBy", "SortName")
		query.AddReplace("sortorder", "Ascending")
		query.AddReplace("fields", "Overview")
		query.AddReplace("userid", getGlobalVar("user").Id)
		query.AddReplace("ParentId", m.parentId)
		'query.AddReplace("ImageTypeLimit", "1")
		query.AddReplace("IncludeItemTypes", "Movie")
	else if row = 5
		' Studios
		url = url  + "/Studios?recursive=true"
		query.AddReplace("SortBy", "SortName")
		query.AddReplace("sortorder", "Ascending")
		query.AddReplace("fields", "Overview")
		query.AddReplace("userid", getGlobalVar("user").Id)
		query.AddReplace("IncludeItemTypes", "Movie")
		'query.AddReplace("ImageTypeLimit", "1")
		query.AddReplace("ParentId", m.parentId)
	else if row = 6
		' Internet Trailers
		url = url  + "/Trailers?recursive=true"
		if filterBy = 1
			query.AddReplace("Filters", "IsUnPlayed")
		else if filterBy = 2
			query.AddReplace("Filters", "IsPlayed")
		end if
		if sortBy = 1
			query.AddReplace("SortBy", "DateCreated,SortName")
		else if sortBy = 2
			query.AddReplace("SortBy", "DatePlayed,SortName")
		else if sortBy = 3
			query.AddReplace("SortBy", "PremiereDate,SortName")
		else
			query.AddReplace("SortBy", "SortName")
		end if
		if sortOrder = 1
			query.AddReplace("SortOrder", "Descending")
		end if
		query.AddReplace("userid", getGlobalVar("user").Id)
		query.AddReplace("IncludeItemTypes", "Trailer")
		query.AddReplace("Fields", "Overview")
		'query.AddReplace("ImageTypeLimit", "1")
		query.AddReplace("ParentId", m.parentId)
	else if row = 7
		' All Trailers
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"
		if filterBy = 1
			query.AddReplace("Filters", "IsUnPlayed")
		else if filterBy = 2
			query.AddReplace("Filters", "IsPlayed")
		end if
		if sortBy = 1
			query.AddReplace("SortBy", "DateCreated,SortName")
		else if sortBy = 2
			query.AddReplace("SortBy", "DatePlayed,SortName")
		else if sortBy = 3
			query.AddReplace("SortBy", "PremiereDate,SortName")
		else
			query.AddReplace("SortBy", "SortName")
		end if
		if sortOrder = 1
			query.AddReplace("SortOrder", "Descending")
		end if
		query.AddReplace("fields", "Overview")
		query.AddReplace("HasTrailer", "true")
		query.AddReplace("ParentId", m.parentId)
		query.AddReplace("IncludeItemTypes", "Movie,Trailer")
	end If
	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for
    return url

End Function

Function parseMovieLibraryScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()
	primaryImageStyle = "mixed-aspect-ratio-portrait"
	mode = ""

	if row = 4
		mode = "moviegenre"
	else if row = 5
		mode = "moviestudio"
		ImageType = 1
	else if row = 7
		mode = "localtrailers"
	end if

    return parseItemsResponse(json, imageType, primaryImageStyle, mode)

End Function

Function movieScreenCreateContextMenu()
	
	options = {
		settingsPrefix: "movie"
		sortOptions: ["Name", "Date Added", "Date Played", "Release Date"]
		filterOptions: ["None", "Unplayed", "Played"]
		showSortOrder: true
	}
	createContextMenuDialog(options)

	return true

End Function

'**********************************************************
'** createMovieAlphabetScreen
'**********************************************************

Function createMovieAlphabetScreen(viewController as Object, letter As String, parentId = invalid) As Object

    imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

	names = ["Movies","Favorite Movies"]
	keys = [letter,letter]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getMovieAlphabetScreenUrl
	loader.parsePagedResult = parseMovieAlphabetScreenResult
	loader.parentId = parentId

    if imageType = 0 then
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
    Else
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
    End If

	screen.displayDescription = (firstOf(RegUserRead("movieDescription"), "1")).ToInt()

    if screen.displayDescription = 0 then
        screen.SetDescriptionVisible(false)
    end if

    return screen

End Function

Function getMovieAlphabetScreenUrl(row as Integer, id as String) as String

	letter = id

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

    ' Query
    query = {
        IncludeItemTypes: "Movie"
        fields: "Overview"
        sortby: "SortName"
        sortorder: "Ascending",
		ImageTypeLimit: "1"
    }
	
	if m.parentId <> invalid then query.parentId = m.parentId

    if row = 0 then
	if letter = "#" then
		filters = {
			NameLessThan: "a"
		}
    	else
        	filters = {
            		NameStartsWith: letter
        	}
	end if
    else
	if letter = "#" then
		filters = {
			NameLessThan: "a"
			isFavorite: "true"
		}
    	else
        	filters = {
            		NameStartsWith: letter
			isFavorite: "true"
        	}
	end if
    end if

    if filters <> invalid
        query = AddToQuery(query, filters)
    end if

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseMovieAlphabetScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

    return parseItemsResponse(json, imageType, "mixed-aspect-ratio-portrait")

End Function


'**********************************************************
'** createMovieGenreScreen
'**********************************************************

Function createMovieGenreScreen(viewController as Object, genre As String) As Object

    imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

	names = ["Movies","Favorite Movies"]
	keys = [genre,genre]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getMovieGenreScreenUrl
	loader.parsePagedResult = parseMovieGenreScreenResult

    if imageType = 0 then
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
    Else
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
    End If

    screen.displayDescription = (firstOf(RegUserRead("movieDescription"), "1")).ToInt()

    if screen.displayDescription = 0 then
        screen.SetDescriptionVisible(false)
    end if

    return screen

End Function

Function getMovieGenreScreenUrl(row as Integer, id as String) as String

	genre = id

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

    ' Query
    query = {
        IncludeItemTypes: "Movie"
        fields: "Overview"
        sortby: "SortName"
        sortorder: "Ascending",
		genres: genre,
		ImageTypeLimit: "1"
    }

    ' add favorites
    if row = 1 then query.AddReplace("filters", "IsFavorite")

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseMovieGenreScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

    return parseItemsResponse(json, imageType, "mixed-aspect-ratio-portrait")

End Function


'******************************************************
' createMovieStudiosScreen
'******************************************************

Function createMovieStudioScreen(viewController as Object, studio As String) As Object

    imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()

	names = ["Movies","Favorite Movies"]
	keys = [studio,studio]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getMovieStudioScreenUrl
	loader.parsePagedResult = parseMovieStudioScreenResult

    if imageType = 0 then
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
    Else
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
    End If

    screen.displayDescription = (firstOf(RegUserRead("movieDescription"), "1")).ToInt()

    return screen

End Function

Function getMovieStudioScreenUrl(row as Integer, id as String) as String

	studio = id

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

    ' Query
    query = {
        IncludeItemTypes: "Movie",
        fields: "Overview",
        sortby: "SortName",
        sortorder: "Ascending",
	studios: studio,
	ImageTypeLimit: "1"
    }

    ' add favorites
    if row = 1 then query.AddReplace("filters", "IsFavorite")

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseMovieStudioScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

    imageType      = (firstOf(RegUserRead("movieImageType"), "0")).ToInt()
    return parseItemsResponse(json, imageType, "mixed-aspect-ratio-portrait")

End Function