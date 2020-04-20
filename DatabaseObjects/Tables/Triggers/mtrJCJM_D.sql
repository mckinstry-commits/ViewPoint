USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[mtrJCJM_D]    Script Date: 12/3/2014 9:58:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Eric Shafer
-- Create date: 5/14/2014
-- Description:	Cascade Delete UD table records.
-- =============================================
CREATE TRIGGER [dbo].[mtrJCJM_D] 
   ON  [dbo].[bJCJM] 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	DECLARE @JCCo bCompany, @Job bJob

	SELECT @JCCo = d.JCCo, @Job = Job FROM DELETED d

	DELETE FROM dbo.udProjectBuildings 
	WHERE Co = @JCCo AND Project = @Job

	DELETE FROM dbo.udProjMWBE
	WHERE Co = @JCCo AND Project = @Job

	DELETE FROM dbo.udBidders
	WHERE Co = @JCCo AND Project = @Job

	DELETE FROM dbo.udJobResSys
	WHERE Co = @JCCo AND ProjectNum = @Job

	DELETE FROM dbo.udProjOffering
	WHERE Co = @JCCo AND Project = @Job
END

