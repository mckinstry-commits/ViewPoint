USE [MCK_INTEGRATION]
GO

/****** Object:  Trigger [trU_Invoice]    Script Date: 11/4/2015 10:20:43 AM ******/
DROP TRIGGER [dbo].[trU_Invoice]
GO

/****** Object:  Trigger [dbo].[trU_Invoice]    Script Date: 11/4/2015 10:20:43 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE TRIGGER [dbo].[trU_Invoice]
   ON  [dbo].[Invoice]
   AFTER UPDATE
AS 
BEGIN

	SET NOCOUNT ON;
	UPDATE Invoice 
		SET DateModified=GETDATE(),ModifiedBy=case when suser_name()<>NULL then suser_name() else suser_sname() END
		FROM INSERTED i
		WHERE Invoice.RowId=i.RowId

END




GO


