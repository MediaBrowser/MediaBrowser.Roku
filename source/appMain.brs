'********************************************************************
'**  Media Browser Roku Client - Main
'********************************************************************

Sub Main()

    'Initialize theme
    initTheme()

    'Create facade screen
    facade = CreateObject("roParagraphScreen")
    facade.Show()

    ' Goto Marker
    checkServerStatus:

    dialogBox = ShowPleaseWait("Please Wait...", "Connecting To MediaBrowser 3 Server")

    'Get MediaBrowser Server
    status = GetServerStatus()

    ' Check If Server Ping Failed
    If status = 0 Then
        dialogBox.Close()
        dialogBox = ShowPleaseWait("Please Wait...", "Could Not Find Server. Attempting Auto-Discovery")

        ' Refresh Server Call
        status = GetServerStatus(true)
    End If
    
    ' Check If Ping And Automated Discovery Failed
    If status = -1 Then
        dialogBox.Close()

        ' Server Not found even after refresh, Give Option To Type In IP Or Try again later
        buttonPress = ShowConnectionFailed()

        If buttonPress=0 Then
            Return
        Else
            savedConf = ShowManualServerConfiguration()
            If savedConf = 1 Then
                ' Retry Connection with manual entries
                Goto checkServerStatus
            Else
                ' Exit Application
                Return
            End if
        End If
    End if

    'Close Dialog Box
    dialogBox.Close()

    'prepare the screen for display and get ready to begin
    screen = CreateLoginPage("", "")
    if screen = invalid then
        print "Unexpected error in CreateLoginPage"
        return
    end if

    'set to go, time to get started
    ShowLoginPage(screen)

End Sub


'*************************************************************
'** Setup the theme for the application
'*************************************************************

Sub initTheme()
    app = CreateObject("roAppManager")
    
    listItemHighlight           = "#ffffff"
    listItemText                = "#707070"
    brandingGreen               = "#37491D"
    backgroundColor             = "#c0c0c0"
    breadcrumbText              = "#eeeeee"

    theme = {
        BackgroundColor: backgroundColor
        OverhangSliceHD: "pkg:/images/Overhang_Background_HD.png"
        OverhangSliceSD: "pkg:/images/Overhang_Background_SD.png"
        OverhangLogoHD: "pkg:/images/mblogowhite.png"
        OverhangLogoSD: "pkg:/images/mblogowhite.png"
        OverhangOffsetSD_X: "35"
        OverhangOffsetSD_Y: "25"
        OverhangOffsetHD_X: "35"
        OverhangOffsetHD_Y: "25"
        BreadcrumbTextLeft: breadcrumbText
        BreadcrumbTextRight: breadcrumbText
        BreadcrumbDelimiter: breadcrumbText
        
        PosterScreenLine1Text: "#dddddd"

        ListItemText: listItemText
        ListItemHighlightText: listItemHighlight
        ListScreenDescriptionText: listItemText
        ListItemHighlightHD: "pkg:/images/select_bkgnd.png"
        ListItemHighlightSD: "pkg:/images/select_bkgnd.png"

        CounterTextLeft: brandingGreen
        CounterSeparator: brandingGreen
        GridScreenBackgroundColor: backgroundColor
        GridScreenListNameColor: brandingGreen
        GridScreenDescriptionTitleColor: brandingGreen

        GridScreenLogoHD: "pkg:/images/mblogowhite.png"
        GridScreenLogoSD: "pkg:/images/mblogowhite.png"
        GridScreenOverhangHeightHD: "124"
        GridScreenOverhangHeightSD: "83"
        GridScreenOverhangSliceHD: "pkg:/images/Overhang_Background_HD.png"
        GridScreenOverhangSliceSD: "pkg:/images/Overhang_Background_SD.png"
        GridScreenLogoOffsetHD_X: "35"
        GridScreenLogoOffsetHD_Y: "25"
        GridScreenLogoOffsetSD_X: "35"
        GridScreenLogoOffsetSD_Y: "25"

        'GridScreenFocusBorderSD: "pkg:/images/grid/GridCenter_Border_Movies_SD43.png"
        'GridScreenBorderOffsetSD: "(-26,-25)"
        'GridScreenFocusBorderHD: "pkg:/images/grid/GridCenter_Border_Movies_HD2.png"
        'GridScreenBorderOffsetHD: "(-15,-15)"

        'GridScreenDescriptionImageSD: "pkg:/images/grid/Grid_Description_Background_Portrait_SD43.png"
        'GridScreenDescriptionOffsetSD:"(125,170)"
        'GridScreenDescriptionImageHD: "pkg:/images/grid/Grid_Description_Background_Portrait_HD.png"
        'GridScreenDescriptionOffsetHD:"(150,205)"
    }

    app.SetTheme( theme )
End Sub
