
Function CreateLibraryImageScreensaver(serverURL as String, userID as String)

    obj = CreateObject("roAssociativeArray")
    obj.screen = CreateObject("roScreen", true) 
	obj.screen.Clear(&H000000FF)
    
	obj.ServerURL = serverURL
	obj.UserID = userID
	
    obj.Show = libraryImageScreensaver_Show
    obj.Update = libraryImageScreensaver_Update
    obj.Go = libraryImageScreensaver_Go
	obj.Init = libraryImageScreensaver_Init
		
	obj.CreateIntro = libraryImageScreensaver_CreateIntro
	obj.CreateSprite = libraryImageScreensaver_CreateSprite
	obj.ReloadSprite = libraryImageScreensaver_ReloadSprite
	obj.GetRandomSpriteData = libraryImageScreensaver_GetRandomSpriteData
	obj.GetLogoSprite = libraryImageScreensaver_GetLogoSprite
	obj.ScaleImage = libraryImageScreensaver_ScaleImage
		
	obj.update_period = 6000
	obj.ItemRequestTimeout = 5000
	obj.MaxImages = 100
	obj.MinImages = 15
	obj.MinItemCountFromServer = 20
		
	obj.loc_update_period = 20
	
	obj.Compositor = CreateObject("roCompositor")
	obj.Compositor.SetDrawTo(obj.screen, &h000000FF)
	
	obj.Sprites = CreateObject("roArray", 4, true)
	obj.ImageList = CreateObject("roArray", 25, true)
	obj.ScaleFactors = [0.75,0.9,1.0,1.15,1.25,1.4,1.5,1.75,2.0]
	obj.Deltas = [-2, -3, -4, -5, -6, -7, -8, -9]
	obj.NumSprites = 5
	
	obj.Port = CreateObject("roMessagePort")
	obj.screen.SetMessagePort(obj.port)
	
	obj.RequestImages = libraryImageScreensaver_RequestImages
	obj.HandleServerResponse = libraryImageScreensaver_HandleServerResponse
	obj.LoadImages = libraryImageScreensaver_LoadImages	
	obj.GetUrl = libraryImageScreensaver_GetUrl
		
    return obj
End Function

Sub libraryImageScreensaver_Show()
	m.screen.SwapBuffers()
End Sub

Function RandomElement(ar) As Object
	index = rnd(ar.Count()) - 1
	return ar[index]
End Function

' Returns a random element and removes it from the array
Function ExtractRandomElement(ar) As Object
	index = rnd(ar.Count()) - 1
	element = ar[index]
	ar.Delete(index)
	return element
End Function

Function libraryImageScreensaver_ScaleImage(image as Object, scaleFactor as float) as Object
	
	if (image = invalid) then return invalid
	
	scaleWidth = Int(image.GetWidth() * scaleFactor)
	scaleHeight = Int(image.GetHeight() * scaleFactor)
	
	image2 = CreateObject("roBitmap", {width: scaleWidth, height: scaleHeight, alphaEnable: true})
	
	if (image2 = invalid) then return invalid
	
	'Draw from region 1 to region 2 scaled
	region1 = CreateObject("roRegion", image, 0, 0, image.GetWidth(), image.GetHeight())
	
	if (region1 = invalid) then return invalid
	
	region1.SetScaleMode(1)
	region2 = CreateObject("roRegion", image2, 0, 0, scaleWidth, scaleHeight)
	
	if (region2 = invalid) then return invalid
	
	region2.SetAlphaEnable(true)
	region2.DrawRect(0, 0, scaleWidth, scaleHeight, &h000000FF)
	region2.DrawScaledObject(0, 0, scaleFactor, scaleFactor, region1)
	
	return region2.GetBitmap()
End Function

Function libraryImageScreensaver_GetLogoSprite(laneIndex as Integer) as Object

	spriteData = createObject("roAssociativeArray")
	spriteData.laneIndex = laneIndex
	spriteData.originalImage = m.logo
	spriteData.scaledImage = m.ScaleImage(spriteData.originalImage, 1.0)
	spriteData.isItemImage = false
	spriteData.locX = Int((m.screen.GetWidth() - m.logo.GetWidth()) / 2)
	spriteData.locY = Int((m.screen.GetHeight() - m.logo.GetHeight()) / 2)
	spriteData.deltaKey = m.Deltas[0]
	m.Deltas.Delete(0)
	
	if (m.isVertical)
		spriteData.deltaX = 0
		spriteData.deltaY = spriteData.deltaKey
	else
		spriteData.deltaX = spriteData.deltaKey
		spriteData.deltaY = 0
	end if
	
	return spriteData
End Function

Function libraryImageScreensaver_GetRandomSpriteData(laneIndex as Integer) as Object

	spriteData = CreateObject("roAssociativeArray")
	
	spriteData.deltaX = 0
	spriteData.deltaY = 0
	spriteData.deltaKey = ExtractRandomElement(m.Deltas)
	spriteData.originalImage = ExtractRandomElement(m.ImageList)
	
	if (spriteData.originalImage = invalid) then spriteData.originalImage = m.logo
	
	spriteData.laneIndex = laneIndex
	spriteData.scaledImage = m.ScaleImage(spriteData.originalImage, RandomElement(m.ScaleFactors))
	spriteData.isItemImage = true
		
	if (m.isVertical)
		laneSize = Int((m.screen.GetWidth() - spriteData.scaledImage.GetWidth()) / m.NumSprites)
		laneOffset = Int(laneIndex * laneSize)
		spriteData.locX = rnd(laneSize) + laneOffset
		spriteData.locY = m.screen.GetHeight()
	    spriteData.deltaY = spriteData.deltaKey
	else
		laneSize = Int((m.screen.GetHeight() - spriteData.scaledImage.GetHeight()) / m.NumSprites)
		laneOffset = Int(laneIndex * laneSize)
		spriteData.locX = m.screen.GetWidth()
		spriteData.locY = rnd(laneSize) + laneOffset
		spriteData.deltaX = spriteData.deltaKey		
	end if
	
	return spriteData
End Function

Sub libraryImageScreensaver_ReloadSprite(targetSprite)

	laneIndex = targetSprite.GetData().laneIndex
	oldImage = targetSprite.GetData().originalImage	
	oldDelta = targetSprite.GetData().deltaKey
	isOldItemImage = targetSprite.GetData().isItemImage
	
	spriteData = m.GetRandomSpriteData(laneIndex)
	scl = spriteData.scaledImage
			
	targetSprite.MoveTo(spriteData.locX, spriteData.locY)
	targetSprite.SetRegion(CreateObject("roRegion", scl, 0, 0, scl.GetWidth(), scl.GetHeight()))
	targetSprite.SetData(spriteData)
	
	if (isOldItemImage) then m.ImageList.push(oldImage)
	m.Deltas.push(oldDelta)
	
End Sub

Function libraryImageScreensaver_CreateSprite(laneIndex as Integer) As Object
 
	if (laneIndex = 2)
		spriteData = m.GetLogoSprite(2)
	else				
		spriteData = m.GetRandomSpriteData(laneIndex)		
	end if

	scl = spriteData.scaledImage
	region =  CreateObject("roRegion", scl, 0, 0, scl.GetWidth(), scl.GetHeight())	
	sprite = m.compositor.NewSprite(spriteData.locX, spriteData.locY, region, 1)
	sprite.SetData(spriteData)
	
	return sprite
End Function

Function SpriteIsDone(sprite) As Boolean
	
	if ((sprite.GetX() + sprite.GetRegion().GetWidth()) < 0)
		return true
	else if ((sprite.GetY() + sprite.GetRegion().GetHeight()) < 0)
		return true
	end if
	
	return false	
End Function

Function libraryImageScreensaver_Init(itemType as String, useVertical as Boolean)
	
	Debug("Screensaver requesting images for items of type: " + itemType)	
	
	m.ImageList.Clear()
	m.ItemType = itemType
	m.isVertical = useVertical
	
	if (m.isVertical)		
		m.ImageType = "Primary"
		m.ImageStyle = "mixed-aspect-ratio-portrait"
	else		
		m.ImageType = "Thumb"
		m.ImageStyle = "two-row-flat-landscape-custom"
	end if			
	
	if (m.ItemType = "Series")
		m.logoUrl = "pkg:/images/screensaver/MB-TVFaded.png"
		m.colorLogoUrl = "pkg:/images/screensaver/MB-TVToken.png"
	else
		m.logoUrl = "pkg:/images/screensaver/MB-ClapperFaded.png"
		m.colorLogoUrl = "pkg:/images/screensaver/MB-Clapper.png"
	end if	
	
	m.logo = CreateObject("roBitmap", m.logoUrl)
	
	return m.RequestImages()
	
End Function

Sub libraryImageScreensaver_Go()

	Debug("LibraryImageScreensaver Running")
	
	if (m.Intro <> invalid) then m.Intro.Close()
 
    loc_timer = CreateObject("roTimespan")
    loc_timer.Mark()
	
    m.screen.SwapBuffers()
	
	for i = 0 to (m.NumSprites - 1)	
		m.Sprites.Push(m.CreateSprite(i))
	end for	
	
    m.Update()
				
    while (true)
		if loc_timer.TotalMilliseconds() > m.loc_update_period then
			m.Update()
			loc_timer.Mark()
		end if
     end while
End Sub

Function libraryImageScreensaver_Update()
        
	m.screen.Clear(&H000000FF)

	for each s in m.Sprites
		s.MoveOffset(s.GetData().deltaX, s.GetData().deltaY)
		if (SpriteIsDone(s)) then m.ReloadSprite(s)
	end for
	
	m.compositor.Draw()		
	m.screen.SwapBuffers()
	
End Function

Function libraryImageScreensaver_GetUrl()
    
	url = m.ServerURL + "/Users/" + HttpEncode(m.UserID) + "/Items?recursive=true"
	
    query = {
		sortby: "Random"
		includeitemtypes: m.ItemType
		fields: "Overview"
		imagetypes: m.ImageType
	}

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function libraryImageScreensaver_CreateIntro(totalSteps as Integer) As Object
	
	intro = createObject("roAssociativeArray")
	intro.TotalSteps = totalSteps
	if (intro.TotalSteps < 1) then intro.TotalSteps = 1
	intro.CurrentStep = 0
	
	locX = Int((m.screen.GetWidth() - m.logo.GetWidth()) / 2)
	locY = Int((m.screen.GetHeight() - m.logo.GetHeight()) / 2)
	
	intro.Box = {x:locX,y:locY,w:m.logo.GetWidth(),h:m.logo.GetHeight()}
	intro.canvas = createObject("roImageCanvas")
	
	intro.BaseItem = {url:m.colorLogoUrl, TargetRect:intro.Box}	
	intro.TopItem = {url:m.logoUrl, TargetRect:intro.Box}
	
	intro.Blank = {
      Color: "#FF000000",
      TargetRect: { x: 0, y: 0, w: m.screen.GetWidth(), h: m.screen.GetHeight() }
    }
	intro.Fade = {
      Color: "#00000000",
	  TargetRect: intro.Box
    }
	
    intro.canvas.SetLayer(0, intro.Blank)
    intro.canvas.SetLayer(1, [intro.BaseItem])
    intro.canvas.SetLayer(2, [intro.Fade])
    intro.canvas.SetLayer(3, [intro.TopItem])
    
	intro.Show = libraryImageScreensaver_ShowIntro
	intro.Close = libraryImageScreensaver_CloseIntro
	intro.Update = libraryImageScreensaver_IntroUpdate
	
	intro.updatePeriod = 40
    intro.timer = CreateObject("roTimespan")
    intro.timer.Mark()
	
	return intro
End Function

Sub libraryImageScreensaver_ShowIntro()
	if (m.canvas <> invalid) then m.canvas.Show()
End Sub

Sub libraryImageScreensaver_CloseIntro()
	if (m.canvas <> invalid) then m.canvas.Close()
End Sub

'The fade layer gets darker as the value of curStep increases
Sub libraryImageScreensaver_IntroUpdate(curStep as Integer)

	m.CurrentStep = curStep
	
	if (m.timer.TotalMilliseconds() > m.updatePeriod)	
		
		progress = Int((m.CurrentStep / m.TotalSteps) * 255)
		
		if (progress > 255) then progress = 255
		bytes = CreateObject("roByteArray")
		bytes.push(progress)
		hexString = bytes.toHexString()
	
		m.Fade.Color = "#" + hexString + "000000"		
		m.canvas.SetLayer(2, [m.Fade])
		
		m.canvas.Show()
		m.timer.Mark()
	end if	
End Sub

Function libraryImageScreensaver_RequestImages() As Boolean
	
	url = m.GetUrl().GetString()
	
    ' Prepare Request
    requestContext = HttpRequest(url)
    requestContext.ContentType("json")
    requestContext.AddAuthorization()
	requestContext.AddParam("StartIndex", tostr(0))
	requestContext.AddParam("Limit", tostr(m.MaxImages))
	request = requestContext.GetRequest()
    request.SetPort(m.Port)
	
	if (request.AsyncGetToString() = false) then return false
		
	msg = wait(m.ItemRequestTimeout, request.GetPort())
	
	if msg.GetResponseCode() <> 200 then
		Debug("Unexpected " + tostr(msg.GetResponseCode()) + " response from " + tostr(url) + " - " + tostr(msg.GetFailureReason()))
		return false
	end if

	return m.HandleServerResponse(msg)			
	
End Function

Function libraryImageScreensaver_HandleServerResponse(msg) As Boolean

	fixedResponse = normalizeJson(msg.GetString())
	jsonObj = ParseJSON(fixedResponse)
	if (jsonObj = invalid) then return false

	items = jsonObj.Items
	if (items.Count() < m.MinItemCountFromServer) then return false
	
	return m.LoadImages(items)
	
End Function

Function libraryImageScreensaver_LoadImages(items as Object) As Boolean

	count = items.Count()	
    Debug("libraryImageScreensaver Loaded " + tostr(count) + " elements")
	
	m.Intro = m.CreateIntro(count * 2)
	m.Intro.Show()

	imageRequests = CreateObject("roArray", 100, true)	
	sizes = GetImageSizes(m.ImageStyle)		
	
	curStep = 0	
	imagesPort = CreateObject("roMessagePort")
	
	for each item in items
		imageUrl = "tmp:/LibraryImage" + tostr(imageRequests.Count()) + ".png"
		xfer = CreateObject("roUrlTransfer")
		xfer.SetMessagePort(imagesPort)
		
		sendUrl = m.ServerURL + "/Items/" + HttpEncode(item.Id) + "/Images/" + m.ImageType + "/0" 
		sendUrl = sendUrl + "?width=" + itostr(sizes.hdWidth)	+ "&height=" + itostr(sizes.hdHeight)	
		xfer.SetUrl(sendUrl)
		
		xfer.AsyncGetToFile(imageUrl)
		imageRequests.push({Transfer: xfer, Url: imageUrl})
		
		curStep = curStep + 1
		m.Intro.Update(curStep)
	end for	
	
	for each ireq in imageRequests
		if (ireq <> invalid)
			wait(5, ireq.Transfer.GetPort())			
			image = CreateObject("roBitmap", ireq.Url)
			if (image <> invalid) then m.ImageList.push(image)
		end if
		
		curStep = curStep + 1
		m.Intro.Update(curStep)		
	end for
	
	m.Intro.Update(count * 2)
	
	return (m.ImageList.Count() >= m.MinImages)	
End Function
