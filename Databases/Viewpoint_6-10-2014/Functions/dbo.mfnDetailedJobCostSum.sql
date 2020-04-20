SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create FUNCTION [dbo].[mfnDetailedJobCostSum]
(
	@Company bCompany 
,	@Job  bJob	=null
)
RETURNS TABLE 
AS

RETURN
SELECT
	t1.JCCo
,	t1.Mth
,	t1.Job
,	t1.JobDesc
,	t1.Phase
,	t1.PhaseDesc
,	t1.CostTypeAbbrev
,	t1.CostTypeDesc
,	t1.PostedDate
,	t1.ActualDate	
,	SUM(t1.Cost) AS Cost
,	t1.PRCo
,	t1.Employee
,	t1.EmployeeName
,	SUM(t1.RG) AS RG
,	SUM(t1.OV) AS OV
,	SUM(t1.OT) AS OT
,	SUM(t1.Hours) AS Hours
FROM 
	dbo.mfnDetailedJobCost_LWO(@Company,@Job) t1
GROUP BY
	t1.JCCo
,	t1.Mth
,	t1.Job
,	t1.JobDesc
,	t1.Phase
,	t1.PhaseDesc
,	t1.CostTypeAbbrev
,	t1.CostTypeDesc
,	t1.PostedDate
,	t1.ActualDate	
,	t1.PRCo
,	t1.Employee
,	t1.EmployeeName
GO
