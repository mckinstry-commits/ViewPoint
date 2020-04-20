SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE [dbo].[vpspCalendarReader]
/******************************
* Created by	 6/20/05 CHS
* Modified		11/09/05 CHS temp
*
*******************************/
(
@pagesitecontrolid int
--@previousmonth datetime,
--@nextmonth datetime
)
AS
	SET NOCOUNT ON;
	
SELECT DateID, SiteID, DisplayOrder, CalendarDate, DateSubject, DateComment, DateColor, PageSiteControlID 
FROM pCalendar with (nolock)
WHERE (PageSiteControlID = @pagesitecontrolid) 
--AND (CalendarDate >= @previousmonth) AND (CalendarDate <= @nextmonth)
ORDER BY DisplayOrder ASC



declare @Submittal tinyint, @RFI tinyint, @RFQ tinyint, @OtherDocDateDue tinyint, @OtherDocDateDueBack tinyint
declare @Issues tinyint, @Subcontract tinyint, @PO tinyint, @Punchlist tinyint, @MeetingMinutesItems tinyint
declare @DailyLog tinyint, @Drawings tinyint, @Tests tinyint, @Inspections tinyint, @MaterialOrders tinyint

select @Submittal = 1, @RFI = 1, @RFQ = 1, @OtherDocDateDue = 1, @OtherDocDateDueBack = 1
select @Issues = 1, @Subcontract = 1, @PO = 1, @Punchlist = 1, @MeetingMinutesItems = 1
select @DailyLog = 1, @Drawings = 1, @Tests = 1, @Inspections = 1, @MaterialOrders = 1

----------------------------------------------------------------------------------------------

Select s.DateReqd as 'CalendarDate', 'Submittal # ' + ltrim(s.Submittal) + ', Rev. # ' + cast(s.Rev as varchar(10)) as 'DateSubject', 
s.SubmittalType + ': ' + s.Description as 'DateComment', 'Blue' as 'DateColor', 
10000+(row_number() over(order by s.DateReqd asc)) AS 'DisplayOrder', 
'40581' as PageSiteControlID, 12 as 'SiteID', 10000+(row_number() over(order by s.DateReqd asc)) as 'DateID'
from PMSM s with (nolock)
where (1 = s.PMCo) and (' 1000-' = s.Project) and (s.DateReqd is not null) and (@Submittal = 1)

union

Select r.DateDue as 'CalendarDate', 'RFI # ' + isnull(ltrim(r.RFI), '') + ', ' + isnull(r.Status, '') as 'DateSubject', 
r.RFIType + ': ' + r.Subject as 'DateComment', 'Blue' as 'DateColor', 
11000+(row_number() over(order by r.DateDue asc)) AS 'DisplayOrder', 
'40581' as PageSiteControlID, 12 as 'SiteID', 11000+(row_number() over(order by r.DateDue asc)) as 'DateID'
from PMRI r with (nolock)
where (1 = r.PMCo) and (' 1000-' = r.Project) and (r.DateDue is not null) and (@RFI = 1)

union

Select r.DateReqd as 'CalendarDate', 'RFQ # ' + ltrim(r.RFQ) + ', Seq # ' + cast(r.RFQSeq as varchar(10)) as 'DateSubject', 
r.PCOType + ': ' + r.RFQ as 'DateComment', 'Blue' as 'DateColor', 
12000+(row_number() over (order by r.DateReqd asc)) AS 'DisplayOrder', 
'40581' as PageSiteControlID, 12 as 'SiteID', 12000+(row_number() over (order by r.DateReqd asc)) as 'DateID'
from PMQD r with (nolock)
where (1 = r.PMCo) and (' 1000-' = r.Project) and (r.DateReqd is not null) and (@RFQ = 1)

union

Select o.DateDue as 'CalendarDate', 'Other Doc (Date Due) # ' + ltrim(o.Document) as 'DateSubject', 
o.DocType + ': ' + o.Description as 'DateComment', 'Blue' as 'DateColor',  
13000+(row_number() over (order by o.DateDue asc)) AS 'DisplayOrder', 
'40581' as PageSiteControlID, 12 as 'SiteID', 13000+(row_number() over (order by o.DateDue asc)) as 'DateID'
from PMOD o with (nolock)
where (1 = o.PMCo) and (' 1000-' = o.Project) and (o.DateDue is not null) and (@OtherDocDateDue = 1)

union

Select o.DateDueBack as 'CalendarDate', 'Other Doc (Date Due Back) # ' + ltrim(o.Document) as 'DateSubject', 
o.DocType + ': ' + o.Description as 'DateComment', 'Blue' as 'DateColor',   
14000+(row_number() over (order by o.DateDueBack asc)) AS 'DisplayOrder', 
'40581' as PageSiteControlID, 12 as 'SiteID', 14000+(row_number() over (order by o.DateDueBack asc)) as 'DateID'
from PMOD o with (nolock)
where (1 = o.PMCo) and (' 1000-' = o.Project) and (o.DateDueBack is not null) and (@OtherDocDateDueBack = 1)

union

Select i.DateInitiated as 'CalendarDate', 'Issues # ' + cast(i.Issue as varchar(10)) as 'DateSubject', 
i.Description as 'DateComment', 'Blue' as 'DateColor', 
15000+(row_number() over (order by i.DateInitiated asc)) AS 'DisplayOrder', 
'40581' as PageSiteControlID, 12 as 'SiteID', 15000+(row_number() over (order by i.DateInitiated asc)) as 'DateID'
from PMIM i with (nolock)
where (1 = i.PMCo) and (' 1000-' = i.Project) and (i.DateInitiated is not null) and (@Issues = 1)

union

Select s.OrigDate as 'CalendarDate', 'Subcontract # ' + ltrim(s.SL) as 'DateSubject', 
isnull(s.Description, '') as 'DateComment', 'Blue' as 'DateColor',   
16000+(row_number() over (order by s.OrigDate asc)) AS 'DisplayOrder', 
'40581' as PageSiteControlID, 12 as 'SiteID', 16000+(row_number() over (order by s.OrigDate asc)) as 'DateID'
from SLHD s with (nolock)
where (1 = s.JCCo) and (' 1000-' = s.Job) and (s.OrigDate is not null) and (@Subcontract = 1)

union

Select p.ExpDate as 'CalendarDate', 'PO # ' + ltrim(p.PO) as 'DateSubject', 
isnull(p.Description, '') as 'DateComment', 'Blue' as 'DateColor',   
17000+(row_number() over (order by p.ExpDate asc)) AS 'DisplayOrder', 
'40581' as PageSiteControlID, 12 as 'SiteID', 17000+(row_number() over (order by p.ExpDate asc)) as 'DateID'
from POHD p with (nolock)
where (1 = p.JCCo) and (' 1000-' = p.Job) and (p.ExpDate is not null) and (@PO = 1)

union

Select p.PunchListDate as 'CalendarDate', 'Punchlist # ' + ltrim(p.PunchList) as 'DateSubject', 
p.Description as 'DateComment', 'Blue' as 'DateColor',   
18000+(row_number() over (order by p.PunchListDate asc)) AS 'DisplayOrder', 
'40581' as PageSiteControlID, 12 as 'SiteID', 18000+(row_number() over (order by p.PunchListDate asc)) as 'DateID'
from PMPU p with (nolock)
where (1 = p.PMCo) and (' 1000-' = p.Project) and (p.PunchListDate is not null) and (@Punchlist = 1)

union

Select m.DueDate as 'CalendarDate', 'Meeting Minutes Item # ' + ltrim(m.Item) as 'DateSubject', 
m.MeetingType + ': ' + m.Description as 'DateComment', 'Blue' as 'DateColor',   
19000+(row_number() over (order by m.DueDate asc)) AS 'DisplayOrder', 
'40581' as PageSiteControlID, 12 as 'SiteID', 19000+(row_number() over (order by m.DueDate asc)) as 'DateID'
from PMMI m with (nolock)
where (1 = m.PMCo) and (' 1000-' = m.Project) and (m.DueDate is not null) and (@MeetingMinutesItems = 1)

union

Select d.LogDate as 'CalendarDate', 'Daily Log # ' + cast(d.DailyLog as varchar(10)) as 'DateSubject', 
d.Description as 'DateComment', 'Blue' as 'DateColor',    
20000+(row_number() over (order by d.LogDate asc)) AS 'DisplayOrder', 
'40581' as PageSiteControlID, 12 as 'SiteID', 20000+(row_number() over (order by d.LogDate asc)) as 'DateID'
from PMDL d with (nolock)
where (1 = d.PMCo) and (' 1000-' = d.Project) and (d.LogDate is not null) and (@DailyLog = 1)

union

Select d.DateIssued as 'CalendarDate', 'Drawing # ' + ltrim(d.Drawing) as 'DateSubject', 
d.DrawingType + ': ' + d.Description as 'DateComment', 'Blue' as 'DateColor',    
21000+(row_number() over (order by d.DateIssued asc)) AS 'DisplayOrder', 
'40581' as PageSiteControlID, 12 as 'SiteID', 21000+(row_number() over (order by d.DateIssued asc)) as 'DateID'
from PMDG d with (nolock)
where (1 = d.PMCo) and (' 1000-' = d.Project) and (d.DateIssued is not null) and (@Drawings = 1)

union

Select t.TestDate as 'CalendarDate', 'Test # ' + ltrim(t.TestCode) as 'DateSubject', 
t.TestType + ': ' + t.Description as 'DateComment', 'Blue' as 'DateColor', 
22000+(row_number() over (order by t.TestDate asc)) AS 'DisplayOrder', 
'40581' as PageSiteControlID, 12 as 'SiteID', 22000+(row_number() over (order by t.TestDate asc)) as 'DateID'
from PMTL t with (nolock)
where (1 = t.PMCo) and (' 1000-' = t.Project) and (t.TestDate is not null) and (@Tests = 1)

union

Select i.InspectionDate as 'CalendarDate', 'Inspection # ' + ltrim(i.InspectionCode) as 'DateSubject', 
i.InspectionType + ': ' + i.Description as 'DateComment', 'Blue' as 'DateColor',  
23000+(row_number() over (order by i.InspectionType asc)) AS 'DisplayOrder', 
'40581' as PageSiteControlID, 12 as 'SiteID', 23000+(row_number() over (order by i.InspectionType asc)) as 'DateID'
from PMIL i with (nolock)
where (1 = i.PMCo) and (' 1000-' = i.Project) and (i.InspectionDate is not null) and (@Inspections = 1)

union

Select i.OrderDate as 'CalendarDate', 'Material Order # ' + ltrim(i.MO) as 'DateSubject', 
i.Description as 'DateComment', 'Blue' as 'DateColor',   
24000+(row_number() over (order by i.OrderDate asc)) AS 'DisplayOrder', 
'40581' as PageSiteControlID, 12 as 'SiteID', 24000+(row_number() over (order by i.OrderDate asc)) as 'DateID'
from INMO i with (nolock)
where (1 = i.JCCo) and (' 1000-' = i.Job) and (i.OrderDate is not null) and (@MaterialOrders = 1)

GO
GRANT EXECUTE ON  [dbo].[vpspCalendarReader] TO [VCSPortal]
GO
