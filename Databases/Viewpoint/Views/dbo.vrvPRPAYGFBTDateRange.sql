SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/**********************************************************
  Purpose:  

	Create an FBT date range based on Summary date range

			
  Maintenance Log:			Version
	Coder	Date	Issue#	One#	Description of Change
	CWirtz	4/15/11	142504	B-04283	New
********************************************************************/
CREATE VIEW [dbo].[vrvPRPAYGFBTDateRange] AS


SELECT 
PRCo,TaxYear,Employee,BeginDate,EndDate,SummarySeq,ItemCode
,(CASE WHEN ((DATEPART(mm,BeginDate) = 7)AND (DATEPART(dd,BeginDate)=1)   )
THEN '04/01/'+CAST (DATEPART(yyyy,BeginDate)AS char(4)) 
ELSE CAST (BeginDate as varchar(10))  END) AS FBTBeginDateString

,(CASE WHEN (DATEPART(yyyy,BeginDate)=DATEPART(yyyy,EndDate)) THEN CAST (EndDate as varchar(10))
ELSE (CASE WHEN (DATEPART(mm,EndDate) > 3 ) THEN '03/31/' +CAST (DATEPART(yyyy,EndDate)AS char(4)) 
ELSE CAST (EndDate as varchar(10)) END)END) AS FBTEndDateString

,CAST((CASE WHEN ((DATEPART(mm,BeginDate) = 7)AND (DATEPART(dd,BeginDate)=1)   )
THEN '04/01/'+CAST (DATEPART(yyyy,BeginDate)AS char(4)) 
ELSE CONVERT (char(10),BeginDate ,102)  END) AS smalldatetime)AS FBTBeginDate

,CAST((CASE WHEN (DATEPART(yyyy,BeginDate)=DATEPART(yyyy,EndDate)) THEN CONVERT (char(10),EndDate ,102)
ELSE (CASE WHEN (DATEPART(mm,EndDate) > 3 ) THEN '03/31/' +CAST (DATEPART(yyyy,EndDate)AS char(4)) 
ELSE CONVERT (char(10),EndDate ,102) END)END) AS smalldatetime) AS FBTEndDate


FROM PRAUEmployeeItemAmounts 
WHERE  ItemCode='FBT'







GO
GRANT SELECT ON  [dbo].[vrvPRPAYGFBTDateRange] TO [public]
GRANT INSERT ON  [dbo].[vrvPRPAYGFBTDateRange] TO [public]
GRANT DELETE ON  [dbo].[vrvPRPAYGFBTDateRange] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRPAYGFBTDateRange] TO [public]
GO
