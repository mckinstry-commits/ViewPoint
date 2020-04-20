/*
2015.01.28 - LWO -
	Utility Script to change the AP Company Parameter
	Audit Options/Subcontract "Allow transactions to exceed current total cost"

	Periodically, AP needs this value unchecked (set to 'N') to allow AP processing, then 
	checked ( set to 'Y' ) when their processing is complete.

	SHOULD ONLY BE USED AT THE DIRECTION OF AP MANAGER

	Usage:  Comment/Uncomment the allicable "SET @SLTotYN='?'" lines below and run in the appropriate 
			Viewpoint Database.
*/
USE Viewpoint
GO

DECLARE @SLTotYN bYN

SET @SLTotYN='N'	-- Uncheck
--SET @SLTotYN='Y'	-- Check

BEGIN TRAN 

UPDATE APCO SET SLTotYN=@SLTotYN WHERE SLTotYN<>@SLTotYN AND APCo<100 --AND APCo IN (1,20)

IF @@ERROR=0
	COMMIT TRAN
ELSE 
	ROLLBACK TRAN
go


--SELECT APCo,SLTotYN AS AllowSubToExceed, getdate() as DateUpdated, suser_sname() as UpdatedBy FROM APCO WHERE APCo<100 ORDER BY 1
--go
DECLARE @msg VARCHAR(2000)

SELECT 
@msg =	'<html><head><title>AP Co Parm Message</title></head><body>'
+		'<p>The setting(s) to allow AP value(s) to exceed subcontract value have been updated.<br/>'
+		'<br/>The attached shows the current settings in the system.<br/></p>'
+		'<hr/><br/><font size="-2" color="silver"><i>'  
+		@@SERVERNAME + '.' + DB_NAME() + ' [' + suser_sname() + ' @ ' + CONVERT(VARCHAR(20),GETDATE(),100) + '] '
+		'</i></font><br/><br/></body></html>'  

EXEC msdb.dbo.sp_send_dbmail 
	@profile_name = 'Viewpoint' 
,	@recipients = 'windis@mckinstry.com;ReikoV@McKinstry.com' --recipients [ ; ...n ]' 
,	@copy_recipients = 'billo@mckinstry.com;arunt@mckinstry.com;howards@mckinstry.com' --copy_recipient [ ; ...n ]' 
--,	@blind_copy_recipients = 'blind_copy_recipient [ ; ...n ]' 
,	@from_address = 'billo@mckinstry.com' 
,	@reply_to = 'billo@mckinstry.com'  
,	@subject = 'AP Allow Subcontract to Exceed Update'  
,	@body = @msg  
,	@body_format = 'HTML' 
,	@importance = 'Normal' 
,	@sensitivity = 'Normal' 
--,  @file_attachments = 'attachment [ ; ...n ]' 
,	@query = 'SELECT APCo,SLTotYN AS AllowSubToExceed FROM APCO WHERE APCo<100 ORDER BY 1' 
,	@execute_query_database = 'Viewpoint' 
,	@attach_query_result_as_file = 0 
--,	@query_attachment_filename = query_attachment_filename 
,	@query_result_header = 1 
,	@query_result_width = 100 
,	@query_result_separator = '=' 
,	@exclude_query_output = 0 
,	@append_query_error = 0 
,	@query_no_truncate = 1  
,	@query_result_no_padding = 0  
--,	@mailitem_id = mailitem_id  [ OUTPUT ]

