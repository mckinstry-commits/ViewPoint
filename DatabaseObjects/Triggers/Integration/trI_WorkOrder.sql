USE [MCK_INTEGRATION]
GO
/****** Object:  Trigger [dbo].[trI_WorkOrder]    Script Date: 3/4/2016 11:27:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Eric Shafer/Curt Salada
-- Create date: 4/30/2014
-- Description:	On Insert of new records, fire stored procedure to update SM Work Order records in Viewpoint db.
--
-- 2016-03-04  Curt S.  only use cursor with multiple inserts (probably never happens)
-- =============================================
ALTER TRIGGER [dbo].[trI_WorkOrder] 
   ON  [dbo].[WorkOrder] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @RowId INT
	DECLARE @RowCount INT
    
	SELECT @RowId = RowId FROM INSERTED
	SELECT @RowCount = @@ROWCOUNT  -- how many rows were inserted?

	IF @RowCount = 1 
	BEGIN
		-- if only one row was inserted, run the stored procedure against that RowId
		EXEC dbo.spUpdateVPWorkOrder @RowId = @RowId -- int  
	END  
	ELSE
	BEGIN
		-- if more than one row was inserted, cursor through all rows  
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
END

