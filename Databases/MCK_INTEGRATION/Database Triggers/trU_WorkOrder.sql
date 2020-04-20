USE [MCK_INTEGRATION]
GO

/****** Object:  Trigger [trU_WorkOrder]    Script Date: 11/4/2015 10:22:45 AM ******/
DROP TRIGGER [dbo].[trU_WorkOrder]
GO

/****** Object:  Trigger [dbo].[trU_WorkOrder]    Script Date: 11/4/2015 10:22:45 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



--ALTER TABLE [dbo].[WorkOrder]  WITH CHECK ADD  CONSTRAINT [FK_WorkOrder_EnterpriseSystem] FOREIGN KEY([SourceSystemId])
--REFERENCES [dbo].[EnterpriseSystem] ([SystemId])
--GO

--ALTER TABLE [dbo].[WorkOrder] CHECK CONSTRAINT [FK_WorkOrder_EnterpriseSystem]
--GO


CREATE TRIGGER [dbo].[trU_WorkOrder]
   ON  [dbo].[WorkOrder]
   AFTER UPDATE
AS 
BEGIN

	SET NOCOUNT ON;
	UPDATE WorkOrder 
		SET DateModified=GETDATE(),ModifiedBy=case when suser_name()<>NULL then suser_name() else suser_sname() END
		FROM INSERTED i
		WHERE WorkOrder.RowId=i.RowId

END



GO


