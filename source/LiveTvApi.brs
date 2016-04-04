'******************************************************
' getDefaultLiveTvTimer
'******************************************************

Function getDefaultLiveTvTimer(programId As String) As Object
    
	url = GetServerBaseUrl() + "/LiveTv/Timers/Defaults"

    query = {
        ProgramId: programId
    }

    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    response = request.GetToStringWithTimeout(10)
	
    if response <> invalid
	
        return ParseJSON(response)
		
    end if

    return invalid
	
End Function



'**********************************************************
'** cancelLiveTvTimer
'**********************************************************

Function cancelLiveTvTimer(timerId As String) As Boolean
    
	url = GetServerBaseUrl() + "/LiveTv/Timers/" + HttpEncode(timerId)

    request = HttpRequest(url)
    request.AddAuthorization()
    request.SetRequest("DELETE")

    response = request.PostFromStringWithTimeout("", 5)

    if response <> invalid then
        createDialog("Success", "The timer was successfully cancelled.", "OK", true)
    else
        createDialog("Error", "An error has occured. The timer was not cancelled. Sorry.", "OK", true)
    end if
	
    return response <> invalid
	
End Function


'**********************************************************
'** deleteLiveTvRecording
'**********************************************************

Function OLDdeleteLiveTvRecording(recordingId As String) As Boolean

    url = GetServerBaseUrl() + "/LiveTv/Recordings/" + HttpEncode(recordingId)

    request = HttpRequest(url)
    request.AddAuthorization()
    request.SetRequest("DELETE")

    response = request.PostFromStringWithTimeout("", 5)

    return response <> invalid
	
End Function

'**********************************************************
'** createLiveTvTimer
'**********************************************************

Function createLiveTvTimer(timerObj As Object) As Boolean

    url = GetServerBaseUrl() + "/LiveTv/Timers"

    request = HttpRequest(url)
    request.AddAuthorization()
	request.ContentType("json")

	json = SimpleJSONBuilder(timerObj)
	
    response = request.PostFromStringWithTimeout(json, 5)

    if response <> invalid then
        createDialog("Success", "The timer was successfully created.", "OK", true)
    else
        createDialog("Error", "An error has occured. The timer was not created. Sorry.", "OK", true)
    end if
	
    return response <> invalid
	
End Function

'**********************************************************
'** deleteAnyItem
'**********************************************************

Function deleteLiveTvRecording(item as Object) As Boolean

    loadingDialog = CreateObject("roOneLineDialog")
    loadingDialog.SetTitle("Deleting item...")
    loadingDialog.ShowBusyAnimation()
    loadingDialog.Show()

    if item.ContentType = "Recording" then
    	url = GetServerBaseUrl() + "/LiveTv/Recordings/" + HttpEncode(Item.Id)
    else
    	url = GetServerBaseUrl() + "/Items/" + HttpEncode(Item.Id)
    end if
    request = HttpRequest(url)
    request.AddAuthorization()
    request.SetRequest("DELETE")

    response = request.PostFromStringWithTimeout("", 5)
    loadingDialog.Close()
    if response <> invalid then
        createDialog("Delete Success!", item.Title+" has been deleted permanently from your library.", "OK", true)
    else
        createDialog("Delete Error!", "An error has occured. "+item.Title+" was not deleted. Sorry.", "OK", true)
    end if
    return response <> invalid
	
End Function