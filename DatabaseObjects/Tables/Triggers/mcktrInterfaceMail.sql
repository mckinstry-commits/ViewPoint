USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[mcktrInterfaceMail]    Script Date: 11/4/2014 10:12:24 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 11/13/2013
-- Description:	Trigger for Mail On Contract Open
-- =============================================
ALTER TRIGGER [dbo].[mcktrInterfaceMail] 
   ON  [dbo].[bJCCM] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	IF UPDATE(ContractStatus) AND (SELECT ContractStatus FROM inserted) = 1
	BEGIN
		DECLARE @JCCo TINYINT, @Contract VARCHAR(30), @POC INT, @POCEmail VARCHAR(128), @EmailBody VARCHAR(8000), @EmailSubject VARCHAR(255)
			, @CC NVARCHAR(128) = 'B&BS_Bsnss_Oprtns@McKinstry.com'
		
		SELECT @JCCo = i.JCCo, @Contract = i.Contract, @POC=i.udPOC, @POCEmail= COALESCE(p.Email, 'erptest@mckinstry.com')
			FROM INSERTED i
			INNER JOIN JCMP p ON i.JCCo = p.JCCo AND i.udPOC = p.ProjectMgr

		SET @EmailSubject= @Contract + ' has been interfaced'
		SET @EmailBody= 'Your new Contract, ' + @EmailSubject
		
		--COMMENT AFTER GO LIVE
		--SET @POCEmail = 'erptest@mckinstry.com' 
		
		--Redirect email to erptest if not on production server.
		IF( @@SERVERNAME NOT IN ('MCKSQL01\VIEWPOINT','MCKSQL02\VIEWPOINT','SPKSQL01\VIEWPOINT') )
		BEGIN
			SET @POCEmail = 'erptest@mckinstry.com'
			SET @CC = 'erptest@mckinstry.com'
		END

		EXEC msdb.dbo.sp_send_dbmail 
			@profile_name='Viewpoint', 
			@recipients= @POCEmail	
			,@body= @EmailBody ,
			@subject=@EmailSubject, @copy_recipients = @CC
			, @blind_copy_recipients = 'erptest@mckinstry.com';
		IF EXISTS(SELECT 1 FROM dbo.JCCI WHERE JCCo = @JCCo AND Contract = @Contract)
		BEGIN
			UPDATE dbo.JCCI
			SET udLockYN = 'Y'
			WHERE JCCo = @JCCo AND Contract = @Contract
		END
	END
	
END


