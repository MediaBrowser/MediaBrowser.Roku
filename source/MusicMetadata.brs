'*****************************************************************
'**  Emby Roku Client - Music Metadata Class
'*****************************************************************


Function ClassMusicMetadata()
    ' initializes static members once
    this = m.ClassMusicMetadata

    if this = invalid
        this = CreateObject("roAssociativeArray")

        ' constants
        this.class        = "MusicMetadata"

        'variables
        this.jumpList     = {}

        ' functions
        this.GetArtistAlbums = musicmetadata_artist_albums
        this.GetGenreAlbums  = musicmetadata_genre_albums
        this.GetStudioAlbums = musicmetadata_studio_albums
        this.GetAlbumSongs   = musicmetadata_album_songs
	this.GetSong         = musicmetadata_song
	this.GetRecent       = musicmetadata_recent
	this.GetMost         = musicmetadata_most

        ' singleton
        m.ClassMusicMetadata = this
    end if
    
    return this
End Function


Function InitMusicMetadata()
    this = ClassMusicMetadata()
    return this
End Function


'**********************************************************
'** Get Music Albums
'**********************************************************

Function getMusicAlbums(offset = invalid As Dynamic, limit = invalid As Dynamic, filters = invalid As Object) As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        recursive: "true"
        includeitemtypes: "MusicAlbum"
        fields: "PrimaryImageAspectRatio,DateCreated,Overview,Genres"
        sortby: "AlbumArtist,SortName"
        sortorder: "Ascending",
		ImageTypeLimit: "1"
    }

    ' Filter/Sort Query
    if filters <> invalid
        query = AddToQuery(query, filters)
    end if

    ' Paging
    if limit <> invalid And offset <> invalid
        query.AddReplace("StartIndex", itostr(offset))
        query.AddReplace("Limit", itostr(limit))
    end if    

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        return parseItemsResponse(response, 0, "mixed-aspect-ratio-square")
    else
	createDialog("Response Error!", "No Music Albums Found. (invalid)", "OK", true)
    end if

    return invalid
End Function


'**********************************************************
'** Get Music Artists
'**********************************************************

Function getMusicArtists(offset = invalid As Dynamic, limit = invalid As Dynamic, filters = invalid As Object) As Object
    ' URL
    url = GetServerBaseUrl() + "/Artists/AlbumArtists"

    ' Query
    query = {
        userid: getGlobalVar("user").Id
        recursive: "true"
        fields: "PrimaryImageAspectRatio,DateCreated,Overview,Genres"
        sortby: "SortName"
        sortorder: "Ascending",
		ImageTypeLimit: "1"
    }

    if filters <> invalid
        query = AddToQuery(query, filters)
    end if

    if limit <> invalid And offset <> invalid
        query.AddReplace("StartIndex", itostr(offset))
        query.AddReplace("Limit", itostr(limit))
    end if    

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)

    if response <> invalid
        return parseItemsResponse(response, 0, "mixed-aspect-ratio-square")
    else
	createDialog("Response Error!", "No Music Artists Found. (invalid)", "OK", true)
    end if

	return invalid

End Function


'**********************************************************
'** Get Music Genres
'**********************************************************

Function getMusicGenres() As Object
    ' URL
    url = GetServerBaseUrl() + "/MusicGenres"

    ' Query
    query = {
        userid: getGlobalVar("user").Id
        recursive: "true"
        includeitemtypes: "Audio,MusicVideo"
        fields: "PrimaryImageAspectRatio,DateCreated,Overview,Genres"
        sortby: "SortName"
        sortorder: "Ascending"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        return parseItemsResponse(response, 0, "mixed-aspect-ratio-portrait")
    else
	createDialog("Response Error!", "No Music Genres Found. (invalid)", "OK", true)
    end if

    return invalid
End Function


'**********************************************************
'** Get Albums by Artist
'**********************************************************

Function musicmetadata_artist_albums(artistName As String) As Object
    ' Validate Parameter
    if validateParam(artistName, "roString", "musicmetadata_artist_albums") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        artists: artistName
        recursive: "true"
        includeitemtypes: "MusicAlbum"
        fields: "PrimaryImageAspectRatio,DateCreated,Overview,Genres"
        sortby: "SortName"
        sortorder: "Ascending",
		ImageTypeLimit: "1"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        return parseItemsResponse(response, 0, "arced-square")
    else
	createDialog("Response Error!", "No Music Albums by Artist Found. (invalid)", "OK", true)
    end if

    return invalid
End Function


'**********************************************************
'** Get Albums by Genre
'**********************************************************

Function musicmetadata_genre_albums(genreName As String) As Object
    ' Validate Parameter
    if validateParam(genreName, "roString", "musicmetadata_genre_albums") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        genres: genreName
        recursive: "true"
        includeitemtypes: "MusicAlbum"
        fields: "PrimaryImageAspectRatio,DateCreated,Overview,Genres"
        sortby: "SortName"
        sortorder: "Ascending",
		ImageTypeLimit: "1"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        return parseItemsResponse(response, 0, "arced-square")
    else
	createDialog("Response Error!", "No Music Albums by Genre Found. (invalid)", "OK", true)
    end if

    return invalid
End Function

'**********************************************************
'** Get Albums by Studio
'**********************************************************

Function musicmetadata_studio_albums(StudioName As String) As Object
    ' Validate Parameter
    if validateParam(StudioName, "roString", "musicmetadata_studio_albums") = false return invalid
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

    ' Query
    query = {
        IncludeItemTypes: "MusicAlbum",
        fields: "PrimaryImageAspectRatio,DateCreated,Overview,Genres",
        sortby: "SortName",
        sortorder: "Ascending",
	studios: studioName,
	ImageTypeLimit: "1"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        return parseItemsResponse(response, 0, "arced-square")
    else
	createDialog("Response Error!", "No Music Albums by Studio Found. (invalid)", "OK", true)
    end if

    return invalid
End Function


'**********************************************************
'** Get Songs within an Album
'**********************************************************

Function musicmetadata_album_songs(albumId As String) As Object
    ' Validate Parameter
    if validateParam(albumId, "roString", "musicmetadata_album_songs") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        parentid: albumId
        recursive: "true"
        includeitemtypes: "Audio"
        fields: "PrimaryImageAspectRatio,MediaSources,DateCreated,Overview,Genres"
        sortby: "SortName"
        sortorder: "Ascending",
		ImageTypeLimit: "1"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid
		return parseItemsResponse(response, 0, "list")
    else
	createDialog("Response Error!", "No Songs within a Music Album Found. (invalid)", "OK", true)
    end if

    return invalid
End Function

Function musicmetadata_song(albumId As String) As Object

	url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"
	
	query = {}
        query.AddReplace("SortBy", "AlbumArtist,SortName")
        query.AddReplace("SortOrder", "Ascending")
        query.AddReplace("IncludeItemTypes", "Audio")
        query.AddReplace("Fields", "MediaSources,AudioInfo,ParentId,DateCreated,Overview,Genres")
	query.AddReplace("filters", "IsFavorite")
	'query.AddReplace("parentId", m.parentId)
        query.AddReplace("ImageTypeLimit", "1")

	' Prepare Request
	request = HttpRequest(url)
	request.ContentType("json")
	request.AddAuthorization()
	request.BuildQuery(query)

	' Execute Request
	response = request.GetToStringWithTimeout(10)
	if response <> invalid
		return parseItemsResponse(response, 0, "list")
	else
		createDialog("Response Error!", "No Music Favorites Found. (invalid)", "OK", true)
	end if

	return invalid
End Function

Function musicmetadata_recent(albumId As String) As Object

	url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?IncludeItemTypes=Audio"

	query = {
            SortBy: "DatePlayed",
            SortOrder: "Descending",
            IncludeItemTypes: "Audio",
            Limit: "100",
            Recursive: "true",
            Fields: "PrimaryImageAspectRatio,AudioInfo,MediaSources,SyncInfo",
            Filters: "IsPlayed",
            ImageTypeLimit: "1",
            EnableImageTypes: "Primary,Backdrop,Banner,Thumb"
	}

	' Prepare Request
	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for
	request = HttpRequest(url)
	request.ContentType("json")
	request.AddAuthorization()

	' Execute Request
	response = request.GetToStringWithTimeout(20)
	if response <> invalid
		reply = parseItemsResponse(response, 0, "list")
		return reply
	else
		createDialog("Response Error!", "No Recently Played Music Found. (invalid)", "OK", true)
	end if

	return invalid
End Function

Function musicmetadata_most(albumId As String) As Object

	url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?IncludeItemTypes=Audio"
	
       query = {
            SortBy: "PlayCount",
            SortOrder: "Descending",
            IncludeItemTypes: "Audio",
            Limit: "100",
            Recursive: "true",
            Fields: "PrimaryImageAspectRatio,AudioInfo,MediaSources,SyncInfo",
            Filters: "IsPlayed",
            ImageTypeLimit: "1",
            EnableImageTypes: "Primary,Backdrop,Banner,Thumb"
        }

	' Prepare Request
	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for
	request = HttpRequest(url)
	request.ContentType("json")
	request.AddAuthorization()
	

	' Execute Request
	response = request.GetToStringWithTimeout(20)
	if response <> invalid
		reply = parseItemsResponse(response, 0, "list")
		return reply
	else
		createDialog("Response Error!", "No Most Played Music Found. (invalid)", "OK", true)
	end if

	return invalid
End Function