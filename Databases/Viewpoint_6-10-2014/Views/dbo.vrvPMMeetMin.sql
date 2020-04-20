SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[vrvPMMeetMin] as

/******************************
*This view is used for the PM Meeting Minutes reports
*created 2/4/08 CR
*
*
*
* PMMeetMin&ItemList.rpt
************************************/



SELECT Sort='H',PMMM.PMCo, PMMM.Project, PMMM.MeetingType,  PMMM.Meeting, PMMM.MinutesType, PMMM.MeetingDate,
PMMM.MeetingTime, PMMM.Location, PMMM.Subject, PMMM.NextDate, PMMM.NextTime, PMMM.NextLocation, 
PMMM.VendorGroup, PMMM.FirmNumber, PMMM.Preparer, InitFirm=0, Initiator=0, ResponsibleFirm=0, ResponsiblePerson=0,
Item=null, OriginalItem=null, InitDate=null, PMMIDueDate=null, PMMIStatus=null, PMMIIssue=null, Minutes=null,
PMMM.Notes

from PMMM 


union all

select 'L',PMMI.PMCo, PMMI.Project, PMMI.MeetingType,  PMMI.Meeting, MinutesType, MeetingDate='12/31/2050',
MeetingTime=null, Location=null, Subject=null, NextDate=null, NextTime=null, NextLocation=null, 
PMMI.VendorGroup, FirmNumber=0, Preparer=null, PMMI.InitFirm, PMMI.Initiator, PMMI.ResponsibleFirm, PMMI.ResponsiblePerson,
PMMI.Item, PMMI.OriginalItem, PMMI.InitDate, PMMI.DueDate, PMMI.Status, PMMI.Issue, PMMI.Minutes, Notes=null

from PMMI

GO
GRANT SELECT ON  [dbo].[vrvPMMeetMin] TO [public]
GRANT INSERT ON  [dbo].[vrvPMMeetMin] TO [public]
GRANT DELETE ON  [dbo].[vrvPMMeetMin] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMMeetMin] TO [public]
GRANT SELECT ON  [dbo].[vrvPMMeetMin] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPMMeetMin] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPMMeetMin] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPMMeetMin] TO [Viewpoint]
GO
