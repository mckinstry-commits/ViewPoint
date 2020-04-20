USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[mtrJCJMAutoPopulate]    Script Date: 12/3/2014 9:53:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 4/3/2014
-- Description:	Trigger to auto fill values on JCJM
-- =============================================
ALTER TRIGGER [dbo].[mtrJCJMAutoPopulate] 
   ON  [dbo].[bJCJM] 
   AFTER INSERT,UPDATE
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
END
