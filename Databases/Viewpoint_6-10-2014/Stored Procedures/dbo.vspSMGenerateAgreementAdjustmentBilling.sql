SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
--		  Author: Eric Vaterlaus
--	 Create date: 7/23/2012
--	 Description: Create an Agreement Adjustment Billing and add it to an Agreement Invoice
--	
--		Modified: 08/09/13 LDG - Replaced vspSMSessionCreate with vspSMSessionStart
-- =============================================
CREATE PROCEDURE [dbo].[vspSMGenerateAgreementAdjustmentBilling]
	@SMCo bCompany,
	@Agreement varchar(20),
	@Revision int,
	@Description varchar(Max),
	@AdjustmentAmount bDollar,
	@TaxType tinyint,
	@TaxGroup bGroup,
	@TaxCode bTaxCode,
	@TaxBasis bDollar,
	@SMInvoiceID bigint OUTPUT,
	@msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (@SMCo IS NULL)
	BEGIN
		SET @msg = 'Missing SMCo!'
		RETURN 1
	END
	IF (@Agreement IS NULL)
	BEGIN
		SET @msg = 'Missing Agreement!'
		RETURN 1
	END
	
	IF (@Revision IS NULL)
	BEGIN
		SET @msg = 'Missing Agreement Revision!'
		RETURN 1
	END

	IF (@AdjustmentAmount IS NULL)
	BEGIN
		SET @msg = 'Missing Agreement Adjustment Amount!'
		RETURN 1
	END
	
	IF NOT EXISTS(SELECT 1 FROM SMAgreement WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision = @Revision AND DateActivated IS NOT NULL)
	BEGIN
		SET @msg = 'A Billing Adjustment cannot be create for this Agreement Revision.'
		RETURN 1
	END
	
	DECLARE @rcode int, @errmsg varchar(255), @Billing int, @SMAgreementBillingScheduleID bigint, @SMSessionID int
	
	SELECT @Billing = ISNULL(MAX(Billing),0)+1 FROM SMAgreementBillingSchedule
		WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@Revision AND Service IS NULL
	
	BEGIN TRY
		BEGIN TRANSACTION
		INSERT SMAgreementBillingSchedule (SMCo, Agreement, Revision, Billing, Date, BillingAmount, TaxType, TaxGroup, TaxCode, TaxBasis, BillingType)
		SELECT @SMCo, @Agreement, @Revision, @Billing, dbo.vfDateOnly(), @AdjustmentAmount, @TaxType, @TaxGroup, @TaxCode, @TaxBasis, 'A'
		
		SELECT @SMAgreementBillingScheduleID = SCOPE_IDENTITY()
		COMMIT
	END TRY
	BEGIN CATCH
		ROLLBACK
		SELECT @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH
	
	/* Create a Session for the Invoice */
	EXEC vspSMSessionStart @SMCo=@SMCo, @SMSessionID=@SMSessionID OUTPUT

	BEGIN TRY
		/* Now create the Agreement Invoice */
		EXEC @rcode = vspSMGenerateAgreementPeriodicInvoice	@SMAgreementBillingScheduleID, @SMSessionID, @msg OUTPUT
		IF @rcode<>0
		BEGIN
			DELETE SMAgreementBillingSchedule WHERE SMAgreementBillingScheduleID = @SMAgreementBillingScheduleID
			RETURN 1
		END
	END TRY
	BEGIN CATCH
		DELETE SMAgreementBillingSchedule WHERE SMAgreementBillingScheduleID = @SMAgreementBillingScheduleID
		SELECT @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH
	
	SELECT @SMInvoiceID=SMInvoiceID FROM SMAgreementBillingSchedule WHERE SMAgreementBillingScheduleID = @SMAgreementBillingScheduleID
	UPDATE SMInvoice SET DescriptionOfWork = @Description WHERE SMInvoiceID = @SMInvoiceID
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMGenerateAgreementAdjustmentBilling] TO [public]
GO
