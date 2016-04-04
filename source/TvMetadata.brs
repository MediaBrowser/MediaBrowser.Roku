'*****************************************************************
'**  Emby Roku Client - TV Metadata
'*****************************************************************

'**********************************************************
'** Get TV Seasons for Show
'**********************************************************

Function getTvSeasons(seriesId As String) As Object

    ' Validate Parameter
    if validateParam(seriesId, "roString", "getTvSeasons") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Shows/" + HttpEncode(seriesId) + "/Seasons"
    showmiss = FirstOf(RegRead("prefShowMiss"),"true")
    showup =  FirstOf(RegRead("prefShowUp"),"true")
    
    ' Query
    query = {
       	UserId: getGlobalVar("user").Id
	fields: "PrimaryImageAspectRatio"
    }
    if showmiss = "false" then
	query.AddReplace("IsMissing", "false")
    end if
    if showup = "false" then
	query.AddReplace("IsVirtualUnaired", "false")
    end if

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        listIds   = CreateObject("roArray", 7, true)
        listNames = CreateObject("roArray", 7, true)
        listNumbers = CreateObject("roArray", 7, true)
		
		response = normalizeJson(response)
        jsonObj   = ParseJSON(response)

        if jsonObj = invalid
	    createDialog("JSON Error", "Error while parsing JSON response for Seasons List for Show.", "OK", true)
            Debug("Error while parsing JSON response for TV Seasons List for Show")
            return invalid
        end if

        for each i in jsonObj.Items
            ' Set the Id
            listIds.push( i.Id )

            ' Set the Name
            listNames.push( firstOf(i.Name, "Unknown") )
				
	    listNumbers.push(firstOf(i.IndexNumber, -1))
        end for
        
        return [listIds, listNames, listNumbers]
    else
	createDialog("Response Error!", "Error while parsing JSON response for Seasons List for Show. (invalid)", "OK", true)
    end if
    
    return invalid
End Function


'**********************************************************
'** Get TV Show Next Unplayed Episode
'**********************************************************

Function getTvNextEpisode(seriesId As String) As Object

    ' Validate Parameter
    if validateParam(seriesId, "roString", "getTvNextEpisode") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Shows/NextUp"

    ' Query
    query = {
        UserId: getGlobalVar("user").Id
        SeriesId: seriesId
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        response = normalizeJson(response)
        jsonObj = ParseJSON(response)

        if jsonObj = invalid
	    createDialog("JSON Error", "Error while parsing JSON response for Show Next Unplayed Episode.", "OK", true)
            Debug("Error while parsing JSON response for Show Next Unplayed Episode")
            return invalid
        end if

        if jsonObj.TotalRecordCount = 0
            return invalid
        end if
        
        i = jsonObj.Items[0]

        metaData = {}

        ' Set Season Number
        if i.ParentIndexNumber <> invalid
            metaData.Season = i.ParentIndexNumber
        end if

        ' Set Episode Number
        if i.IndexNumber <> invalid
            metaData.Episode = i.IndexNumber
        end if

        return metaData
    else
    	createDialog("Response Error!", "Error while parsing JSON response for Show Next Unplayed Episode. (invalid)", "OK", true)
    end if
    return invalid
End Function
