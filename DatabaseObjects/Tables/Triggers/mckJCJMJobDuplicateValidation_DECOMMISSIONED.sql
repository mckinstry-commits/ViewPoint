USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[mckJCJMJobDuplicateValidation]    Script Date: 12/3/2014 9:54:24 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 1/2/2004
-- Description:	Trigger to prevent duplicate job numbers across jobs.
-- =============================================
ALTER TRIGGER [dbo].[mckJCJMJobDuplicateValidation] 
   ON  [dbo].[bJCJM] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	DECLARE @IJCCo TINYINT, @IJob bJob, @ITestCo CHAR(1)

	SELECT @IJCCo = i.JCCo, @IJob = i.Job 
		FROM INSERTED i
	SELECT @ITestCo = udTESTCo 
		FROM HQCO 
		WHERE @IJCCo = HQCo

	IF EXISTS(SELECT TOP 1 1 FROM JCJM j
		INNER JOIN HQCO c ON j.JCCo = c.HQCo 
		WHERE @ITestCo = c.udTESTCo AND LEFT(@IJob,6) = LEFT(j.Job,6) AND @IJCCo <> HQCo
		) OR EXISTS
	(SELECT TOP 1 1 FROM JCJM j
		INNER JOIN HQCO c ON j.JCCo = c.HQCo
	WHERE @ITestCo = c.udTESTCo AND @IJob = j.Job AND @IJCCo <> HQCo)
	BEGIN
		RAISERROR('Job number already in use.  Select a different number.',16,11)
		ROLLBACK TRANSACTION
	END

END
