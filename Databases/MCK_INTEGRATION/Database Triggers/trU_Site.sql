USE [MCK_INTEGRATION]
GO

/****** Object:  Trigger [trU_Site]    Script Date: 11/4/2015 10:21:39 AM ******/
DROP TRIGGER [dbo].[trU_Site]
GO

/****** Object:  Trigger [dbo].[trU_Site]    Script Date: 11/4/2015 10:21:39 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Eric Shafer
-- Create date: 2/20/2014
-- Description:	UPDATE trigger to update modifiedby and Date modified fields
-- =============================================
CREATE TRIGGER [dbo].[trU_Site] 
   ON  [dbo].[Site] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for trigger here
	UPDATE Site 
	SET DateModified=GETDATE(),ModifiedBy=case when suser_name()<>NULL then suser_name() else suser_sname() END
		FROM INSERTED i
		WHERE Site.RowId=i.RowId	
END

GO


