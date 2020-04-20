USE [MCK_INTEGRATION]
GO

/****** Object:  Trigger [trI_Customer]    Script Date: 11/4/2015 10:19:25 AM ******/
DROP TRIGGER [dbo].[trI_Customer]
GO

/****** Object:  Trigger [dbo].[trI_Customer]    Script Date: 11/4/2015 10:19:25 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Eric Shafer
-- Create date: 2/19/2014
-- Description:	On Insert of new records, fire stored procedure to insert AR and SM Customer records in Viewpoint db.
-- 2014-09-13 CS  If ProcessStatus = "1" call 1-time conversion sproc
-- =============================================
CREATE TRIGGER [dbo].[trI_Customer] 
   ON  [dbo].[Customer] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


    -- Insert statements for trigger here
	DECLARE @RowId INT
	DECLARE @ProcessStatus CHAR(1)

	DECLARE ins_Customer_crsr CURSOR FOR
	SELECT RowId, ProcessStatus FROM INSERTED

	OPEN ins_Customer_crsr
	FETCH NEXT FROM ins_Customer_crsr INTO @RowId, @ProcessStatus

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @ProcessStatus = '1' 
			EXEC dbo.spConvertCustomer @RowId = @RowId
		ELSE
			EXEC dbo.spInsertCustomersToVP @RowId = @RowId -- int
	
		FETCH NEXT FROM ins_Customer_crsr INTO @RowId, @ProcessStatus
	END
	CLOSE ins_Customer_crsr
	DEALLOCATE ins_Customer_crsr

END

GO


