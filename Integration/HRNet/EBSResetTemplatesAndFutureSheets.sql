USE EZTrack
GO
/*
-- Backup existing records
SELECT * INTO tDaily_20141028 FROM tDaily 
SELECT * INTO tDailyOriginal_20141028 FROM tDailyOriginal 
SELECT * INTO tFinal_20141028 FROM tFinal 
SELECT * INTO tApprovalProcess_20141028 FROM tApprovalProcess 
SELECT * INTO wtTemplates_20141028 FROM wtTemplates 
*/

-- Delete Future Timesheets
-- Reset any future approvals
-- Delete any templates

BEGIN TRAN

DECLARE @date DATETIME
DECLARE @username VARCHAR(30)
DECLARE @empid INT

SELECT @date='10/27/2014'
SELECT @username='billo'
SELECT @empid=EmployeeID FROM dbo.pnUsers WHERE Username=@username 

DELETE FROM tDaily WHERE Chargedate >= @date AND EmployeeID=@empid
DELETE FROM tDailyOriginal WHERE Chargedate >= @date AND EmployeeID=@empid
DELETE FROM tFinal WHERE ChargeDate >= @date AND EmployeeID=@empid
UPDATE tApprovalProcess SET AprStatus=0 where AprStatus<> 0 AND PayPeriodStart >=@date AND EmployeeID=@empid
DELETE wtTemplates WHERE EmployeeID=@empid
UPDATE dbo.wtUserPreferences SET TemplateStatus=0
COMMIT TRAN


SELECT * FROM dbo.wtUserPreferences WHERE userId=1296
