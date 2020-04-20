USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[mtr_JCJM_LastChanged_U]    Script Date: 12/1/2014 10:10:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 7/17/2014
-- Description:	Trigger to update 'udLastChanged' date when the JCJM.Description changes.
-- =============================================
ALTER TRIGGER [dbo].[mtr_JCJM_LastChanged_U] 
   ON  [dbo].[bJCJM] 
   AFTER UPDATE
AS 
BEGIN
	/*
	2014.12.01 - LWO - Update to include update if JobStatus changes.
	*/
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here

	IF ( UPDATE(Description) or UPDATE(JobStatus) ) AND ((SELECT trigger_nestlevel() ) < 2)
	BEGIN
		UPDATE j
		SET j.udDateChanged = CONVERT(VARCHAR(30),GETDATE(), 121)
		FROM dbo.JCJM AS j
		INNER JOIN INSERTED AS i ON i.KeyID = j.KeyID
		
	END

END
go
