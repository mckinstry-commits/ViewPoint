USE [MCK_INTEGRATION]
GO

/****** Object:  Trigger [trI_WorkOrder]    Script Date: 11/4/2015 10:22:28 AM ******/
DROP TRIGGER [dbo].[trI_WorkOrder]
GO

/****** Object:  Trigger [dbo].[trI_WorkOrder]    Script Date: 11/4/2015 10:22:28 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Eric Shafer/Curt Salada
-- Create date: 4/30/2014
-- Description:	On Insert of new records, fire stored procedure to update SM Work Order records in Viewpoint db.
-- =============================================
CREATE TRIGGER [dbo].[trI_WorkOrder] 
   ON  [dbo].[WorkOrder] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


    -- Insert statements for trigger here
	DECLARE @RowId INT


	DECLARE ins_WorkOrder_crsr CURSOR FOR
	SELECT RowId FROM INSERTED --WHERE TransferType = 'U' -- updates only

	OPEN ins_WorkOrder_crsr
	FETCH NEXT FROM ins_WorkOrder_crsr INTO @RowId

	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC dbo.spUpdateVPWorkOrder @RowId = @RowId -- int
	
		FETCH NEXT FROM ins_WorkOrder_crsr INTO @RowId
	END
	CLOSE ins_WorkOrder_crsr
	DEALLOCATE ins_WorkOrder_crsr

END


GO


