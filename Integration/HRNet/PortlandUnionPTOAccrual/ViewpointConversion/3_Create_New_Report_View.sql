USE [HRNET]
GO

create VIEW [mnepto].[TimeCardAggregateReportView]
as
SELECT 
	t2.CompanyNumber
,	t2.EmployeeNumber
,	t2.EmployeeName
,	t2.EmployeeDept
,	t2.EmployeeClass
,	t2.EmployeeType
,	t2.EmployeeUnion
,	t2.EmployeeUnionName
,	t2.EmployeeStatus
,	t2.EmployeeExemptClassification
,	t1.RegularHours
,	t1.OvertimeHours
,	t1.OtherHours
,	t1.OtherHoursType
,	t1.TotalHours
,	t1.WeekEnding
,	t1.Year
,	t1.GroupId
,	t1.Source	
FROM 
	[mnepto].[TimeCardAggregateView] t1 LEFT OUTER JOIN
	[mnepto].[Personnel] t2 ON
		t1.CompanyNumber=t2.CompanyNumber
	AND t1.EmployeeNumber=t2.EmployeeNumber
go

GRANT SELECT ON [mnepto].[TimeCardAggregateReportView] TO nsproportaluser
go
	
