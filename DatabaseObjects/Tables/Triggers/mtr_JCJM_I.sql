USE Viewpoint
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 12/3/2014
-- Description:	Consolidated After Insert trigger.  
-- mckJCJMJobDuplicateValidation: Trigger to prevent duplicate job numbers across jobs.
-- mtrJCJMAutoPopulate: Trigger to auto fill values on JCJM
-- mtr_JCJM_LastChanged_U: Trigger to update 'udLastChanged' date when the JCJM.Description changes.
	/*
--	2014.12.01 - LWO - Update to include update if JobStatus changes.
	*/
-- =============================================
CREATE TRIGGER dbo.mtr_JCJM_I 
   ON  dbo.bJCJM 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here

	--Job Number Validation
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
	--End Job Number validation

	--WA B&O tax default value fill
	IF UPDATE(udStateSpecificTax)
	BEGIN
		
		DECLARE @TaxGroup bGroup, @StateTaxCode bTaxCode, @ReturnTaxRate bRate, @JCCo bCompany, @Job bJob
		SELECT @TaxGroup = TaxGroup, @StateTaxCode = udStateSpecificTax, @JCCo = JCCo, @Job = Job
		FROM INSERTED i

		SELECT @ReturnTaxRate=dbo.vfHQTaxRate(@TaxGroup,@StateTaxCode,GETDATE())
		SET @ReturnTaxRate = ISNULL(@ReturnTaxRate, 0)

		UPDATE dbo.JCJM
		SET udWABOTax = @ReturnTaxRate
		WHERE JCCo = @JCCo AND Job = @Job
	END
	--End default value fill

	--Update date last changed
	IF ( UPDATE(Description) or UPDATE(JobStatus) ) AND ((SELECT trigger_nestlevel() ) < 2)
	BEGIN
		UPDATE j
		SET j.udDateChanged = CONVERT(VARCHAR(30),GETDATE(), 121)
		FROM dbo.JCJM AS j
		INNER JOIN INSERTED AS i ON i.KeyID = j.KeyID
	END
	--End update date last changed.
END
GO
