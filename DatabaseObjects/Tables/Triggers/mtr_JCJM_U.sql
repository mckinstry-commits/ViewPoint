USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[mtr_JCJM_U]    Script Date: 12/3/2014 11:23:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 12/3/2014
-- Description:	Consolidated update trigger for JCJM
-- mtrJCJMAutoPopulate: Trigger to auto fill values on JCJM
-- mtr_JCJM_LastChanged_U: Trigger to update 'udLastChanged' date when the JCJM.Description changes.
-- =============================================
CREATE TRIGGER [dbo].[mtr_JCJM_U] 
   ON  [dbo].[bJCJM] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	
	--Update state specific tax rate.
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
	--End update WA B&O Tax

	--Update udDateChanged when Description or Job Status changed.
	IF ( UPDATE(Description) or UPDATE(JobStatus) ) AND ((SELECT trigger_nestlevel() ) < 2)
	BEGIN
		UPDATE j
		SET j.udDateChanged = CONVERT(VARCHAR(30),GETDATE(), 121)
		FROM dbo.JCJM AS j
		INNER JOIN INSERTED AS i ON i.KeyID = j.KeyID
	END
	--Update udDateChanged when Description or Job Status changed.

END