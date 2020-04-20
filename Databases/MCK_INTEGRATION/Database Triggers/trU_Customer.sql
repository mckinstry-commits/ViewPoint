USE [MCK_INTEGRATION]
GO

/****** Object:  Trigger [trU_Customer]    Script Date: 11/4/2015 10:19:49 AM ******/
DROP TRIGGER [dbo].[trU_Customer]
GO

/****** Object:  Trigger [dbo].[trU_Customer]    Script Date: 11/4/2015 10:19:50 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--ALTER TABLE [dbo].[Customer]  WITH CHECK ADD  CONSTRAINT [FK_Customer_EnterpriseSystem] FOREIGN KEY([SourceSystemId])
--REFERENCES [dbo].[EnterpriseSystem] ([SystemId])
--GO

--ALTER TABLE [dbo].[Customer] CHECK CONSTRAINT [FK_Customer_EnterpriseSystem]
--GO


CREATE TRIGGER [dbo].[trU_Customer]
   ON  [dbo].[Customer]
   AFTER UPDATE
AS 
BEGIN

	SET NOCOUNT ON;
	UPDATE Customer 
		SET DateModified=GETDATE(),ModifiedBy=case when suser_name()<>NULL then suser_name() else suser_sname() END
		FROM INSERTED i
		WHERE Customer.RowId=i.RowId

END


GO


