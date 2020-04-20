USE [MCK_INTEGRATION]
GO

/****** Object:  Trigger [trI_Site]    Script Date: 11/4/2015 10:21:20 AM ******/
DROP TRIGGER [dbo].[trI_Site]
GO

/****** Object:  Trigger [dbo].[trI_Site]    Script Date: 11/4/2015 10:21:20 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Eric Shafer
-- Create date: 2/20/2014
-- Description:	INSERT trigger to kick off insert to VP stored proc.
-- =============================================
CREATE TRIGGER [dbo].[trI_Site] 
   ON  [dbo].[Site] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here

	DECLARE @RowId INT, @ErrorMessage VARCHAR(MAX), @ErrorLine INT, @ErrorNumber INT, @msg VARCHAR(MAX), @User VARCHAR(128)
	--SELECT @RowId = RowId FROM INSERTED
	
	DECLARE ins_Sites_crsr CURSOR FOR
	SELECT RowId FROM INSERTED

	OPEN ins_Sites_crsr
	FETCH NEXT FROM ins_Sites_crsr INTO @RowId

	WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRY
		EXEC dbo.spInsertSitesToVP @RowId = @RowId -- int
		END TRY
		BEGIN CATCH
			SELECT @ErrorNumber = ERROR_NUMBER()
			, @ErrorMessage = ERROR_MESSAGE()
			, @ErrorLine = ERROR_LINE()
	

		SET @msg = 'ErrorMessage: ' + @ErrorMessage + 'ErrorLine: ' + CONVERT(VARCHAR(10),@ErrorLine) + 'ErrorNumber: ' + CONVERT(VARCHAR(10),@ErrorNumber)
		SET @User = SUSER_SNAME()

		EXEC dbo.spInsertToTransactLog @Table = 'MCK_INTEGRATION.dbo.Site', -- varchar(128)
			@KeyColumn = 'RowId', -- varchar(128)
			@KeyId = @RowId, -- varchar(255)
			@User = @User, -- varchar(128)
			@UpdateInsert = 'N', -- char(1)
			@msg = @msg -- varchar(max)
		END CATCH
	
		FETCH NEXT FROM ins_Sites_crsr INTO @RowId
	END
	CLOSE ins_Sites_crsr
	DEALLOCATE ins_Sites_crsr

END


GO


