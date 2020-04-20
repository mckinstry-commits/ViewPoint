USE [MCK_INTEGRATION]
GO

/****** Object:  Trigger [trI_Invoice]    Script Date: 11/4/2015 10:20:14 AM ******/
DROP TRIGGER [dbo].[trI_Invoice]
GO

/****** Object:  Trigger [dbo].[trI_Invoice]    Script Date: 11/4/2015 10:20:14 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Eric Shafer/Curt Salada
-- Create date: 4/30/2014
-- Description:	On Insert of new records, get JCCo from Viewpoint and assign
--
-- CS  2014-11-09  exclude test companies when counting JCJM recs
-- CS  2015-10-27  98994 - add inner join to exclude "test" companies
--                 when looking for JCCo
-- =============================================
CREATE TRIGGER [dbo].[trI_Invoice] 
   ON  [dbo].[Invoice] 
   AFTER INSERT
AS 
BEGIN

	if @@ROWCOUNT = 0
		RETURN
        
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


    -- Insert statements for trigger here
	DECLARE @RowId INT, @Job VARCHAR(10), @JCCo TINYINT

	-- cursor for inserted records only, no updates
	DECLARE ins_Invoice_crsr CURSOR FOR
	SELECT RowId, Job FROM INSERTED i
		WHERE NOT EXISTS(SELECT * FROM DELETED d WHERE d.RowId = i.RowId)  
		AND Job IS NOT NULL AND JCCo IS NULL

	OPEN ins_Invoice_crsr
	FETCH NEXT FROM ins_Invoice_crsr INTO @RowId, @Job

	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		-- If Job is populated but JCCo is missing, get JCCo from Viewpoint database

		-- Job number should be unique across companies.
		-- If the same job number exists in multiple companies, or if this
		-- job number does not exist in any company, we will skip assigning the JCCo, 
		-- and instead set the transfer record to Failed status.
		
		DECLARE @jobCount INTEGER
		DECLARE @errMess VARCHAR(200)
		
		SELECT @errMess = ''  
		SELECT @jobCount = COUNT(*) FROM Viewpoint.dbo.JCJM j 
		 INNER JOIN Viewpoint.dbo.HQCO h ON j.JCCo = h.HQCo AND h.udTESTCo = 'N'
		WHERE j.Job = @Job
		
		IF (@jobCount = 0)
			SELECT @errMess = 'Job ' + ISNULL(@Job, 'NULL') + ' not found in Viewpoint db'			

		IF (@jobCount > 1)
			SELECT @errMess = 'Job ' + ISNULL(@Job, 'NULL') + ' found in multiple Viewpoint companies'
	
		IF (@jobCount = 1)
		BEGIN
            -- 98994 add inner join HQCO to exclude test companies      
			SELECT @JCCo = j.JCCo FROM Viewpoint.dbo.JCJM j 
			  INNER JOIN Viewpoint.dbo.HQCO h ON j.JCCo = h.HQCo AND h.udTESTCo = 'N'
			WHERE j.Job = @Job
			UPDATE Invoice SET JCCo = @JCCo WHERE RowId = @RowId
		END

		IF @errMess <> ''
			UPDATE Invoice SET ProcessStatus = 'F', ProcessDesc = @errMess, ProcessTimeStamp = GETDATE() WHERE RowId = @RowId
		
		FETCH NEXT FROM ins_Invoice_crsr INTO @RowId, @Job
	END
	CLOSE ins_Invoice_crsr
	DEALLOCATE ins_Invoice_crsr

END



GO


