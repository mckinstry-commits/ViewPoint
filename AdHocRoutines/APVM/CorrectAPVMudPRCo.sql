--[MCKTESTSQL04\VIEWPOINT].Viewpoint
USE Viewpoint
go

/*
2014.10.31 - LWO - Script to correct APVM udPRCo records from conversion issue.
				   Overwrite the converted '99' value to the PRCo of the current
				   active record of the Employee
*/
DECLARE @doUpdate INT
--select @doUpdate=0
select @doUpdate=1		-- Uncomment to actually perform the update.

BEGIN TRAN

UPDATE APVM SET udPRCo=t1.PRCo
from
(
SELECT 
	apvm.Name
,	apvm.Vendor
,	apvm.udPRCo 
,	apvm.udEmployee
,	preh.PRCo
,	preh.Employee
FROM 
	APVM apvm JOIN
	PREH preh ON
		apvm.udEmployee=preh.Employee
	AND preh.ActiveYN='Y'
	AND preh.PRCo < 100
) t1
WHERE
	dbo.APVM.udPRCo=t1.udPRCo
AND dbo.APVM.udEmployee=t1.udEmployee

IF @doUpdate <> 1
	ROLLBACK TRAN
ELSE
	COMMIT TRAN

GO

  