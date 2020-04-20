SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE      PROCEDURE [dbo].[vpspDeleteSiteMenuAndControls]
 (
 	@SiteID int
 )
 AS
 SET NOCOUNT OFF;

--Delete all of the Calendar Events Today controls
DELETE pCalendarEventsToday WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = @SiteID)
DELETE pCalendarEventsToday WHERE CalendarID IN (SELECT CalendarID FROM pCalendar WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = @SiteID))
DELETE pCalendarEventsToday WHERE CalendarID IN (SELECT CalendarID FROM pCalendar WHERE SiteID = @SiteID)


DELETE pCalendarEventsToday WHERE PageSiteControlID IN 
(SELECT PageSiteControlID FROM pPageSiteControls WHERE PageSiteTemplateID IN (SELECT PageSiteTemplateID FROM pPageSiteTemplates WHERE SiteID = @SiteID))



 --Delete all of the Calendar controls data
 DELETE pCalendar WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = @SiteID)
 DELETE pCalendar WHERE SiteID = @SiteID
 PRINT 'Deleted Calendars'

 
 --Delete all of the Camera controls data
 DELETE pCameraControl WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = @SiteID)
 Print 'Deleted Cameras'
 

DELETE pCameraControl WHERE PageSiteControlID IN 
(SELECT PageSiteControlID FROM pPageSiteControls WHERE PageSiteTemplateID IN (SELECT PageSiteTemplateID FROM pPageSiteTemplates WHERE SiteID = @SiteID))



--Delete the Contacts controls
--DELETE pContacts WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = @SiteID)


 --Delete all of the Contact Type Info 
 --DELETE pContactsTypeInfo WHERE ContactID IN (SELECT ContactID FROM pContacts WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = @SiteID))
 --DELETE pContactsTypeInfo WHERE ContactID IN (SELECT ContactID FROM pContacts WHERE SiteID = @SiteID)
 --Print 'Deleted Contat Type Info'
 
DELETE pContactMethods WHERE ContactID IN (SELECT ContactID FROM pContacts WHERE PageSiteControlID IN
(SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = @SiteID))

 --Delete all of the Contacts 
 DELETE pContacts WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = @SiteID)
 DELETE pContacts WHERE SiteID = @SiteID
 Print 'Deleted Contacts'
 


DELETE pContactMethods WHERE ContactID IN (
SELECT ContactID FROM pContacts WHERE PageSiteControlID IN 
(SELECT PageSiteControlID FROM pPageSiteControls WHERE PageSiteTemplateID IN (SELECT PageSiteTemplateID FROM pPageSiteTemplates WHERE SiteID = @SiteID)))

DELETE pContacts WHERE PageSiteControlID IN 
(SELECT PageSiteControlID FROM pPageSiteControls WHERE PageSiteTemplateID IN (SELECT PageSiteTemplateID FROM pPageSiteTemplates WHERE SiteID = @SiteID))


 --Delete all of the Directory Browser controls data
 DELETE pDirectoryBrowser WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = @SiteID)
 Print 'Deleted Directory Browsers'

 --Delete all of the Custom controls data
 DELETE pCustomControl WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = @SiteID)
 Print 'Deleted Customs'
 
 --Delete all of the Display controls data
 DELETE pDisplayControl WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = @SiteID)
 Print 'Deleted Displays'
 
 --Delete all of the Forum Views
 DELETE pForumViews WHERE ForumID IN (SELECT ForumID FROM pForum WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = @SiteID))
 Print 'Deleted Forum Views'
 
 --Delete all of the Forum controls data
 DELETE pForum WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = @SiteID)
 Print 'Deleted Forums'
 
 --Delete all of the Link controls data
 DELETE pLinkControl WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = @SiteID)
 Print 'Deleted Link Controls'
 
 --Delete all of the Report lists for the Site
 --DELETE pReportLists WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = @SiteID)
 --Print 'Deleted Reports'
 
 --Delete all the the Role Security Records for the current Site Menu
 DELETE pMenuSiteLinkRoles WHERE SiteID = @SiteID
 Print 'Deleted Menu Security'
 
 --Delete all of the Menu Links for the current Site Menu
 DELETE pMenuSiteLinks WHERE SiteID = @SiteID
 Print 'Deleted Menu'
 
 --Delete all of the Role Security records for the PageSiteControls for the site
 DELETE pPageSiteControlSecurity WHERE SiteID = @SiteID
 DELETE pPageSiteControlSecurity WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = @SiteID)
 Print 'Deleted Page Security'
 
 --Delete all of the current layouts for the Pages for the Site
 DELETE pPageSiteControls WHERE SiteID = @SiteID
 Print 'Deleted Page Layout'
 
 --Delete all of he current Page for the Site
 DELETE pPageSiteControlSecurity WHERE PageSiteControlID IN 
 	(SELECT PageSiteControlID FROM pPageSiteControls WHERE PageSiteTemplateID IN (SELECT PageSiteTemplateID FROM pPageSiteTemplates WHERE SiteID = @SiteID))
 DELETE pPageSiteControls WHERE PageSiteTemplateID IN (SELECT PageSiteTemplateID FROM pPageSiteTemplates WHERE SiteID = @SiteID)
 
 UPDATE pSites SET PageSiteTemplateID = NULL WHERE SiteID = @SiteID
 
 DELETE pPageSiteTemplates WHERE SiteID = @SiteID
 Print 'Deleted Page Templates'
 
 
 
 





GO
GRANT EXECUTE ON  [dbo].[vpspDeleteSiteMenuAndControls] TO [VCSPortal]
GO
