SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 3/20/2012
-- Description:	
-- Modification: Matthew Bradford TK-19569 Pay Terms are not required on SM Invoices
-- =============================================
CREATE PROCEDURE [dbo].[vspSMGenerateAgreementPeriodicInvoice]
	@SMAgreementBillingScheduleID bigint,
	@SMSessionID int,
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (@SMAgreementBillingScheduleID IS NULL)
	BEGIN
		SET @msg = 'Missing SM Agreement Billing Schedule ID!'
		RETURN 1
	END
	
	IF (@SMSessionID IS NULL)
	BEGIN
		SET @msg = 'Missing SM Session ID!'
		RETURN 1
	END
	
	DECLARE @rcode int, @errmsg varchar(255), @SMCo bCompany, @ScheduledDate bDate, @ExistingInvoiceID bigint,
		@CustGroup bGroup, @Customer bCustomer, @BillToCustomer bCustomer, @InvoiceSummaryLevel char(1),
		@ARCo bCompany, @BatchMonth bMonth, @PayTerms bPayTerms, @BillAddress varchar(60), @BillCity varchar(30),
		@BillZip bZip, @BillAddress2 varchar(60), @BillCountry char(2), @BillState varchar(4),
		@DiscDate bDate, @DueDate bDate, @DiscRate bPct, @ReportID int,
		@InvoiceNumber varchar(10), @SMInvoiceID bigint, @SessionInvoice int, @AmendmentExists bit, 
		@TaxType int, @TaxRate bPct, @TaxCode bTaxCode, @TaxGroup bGroup, @BillingType char(1)
	
	-- Get Defaults for creating the SM Invoice
	SELECT 
		@SMCo = SMAgreementBillingSchedule.SMCo, 
		@ScheduledDate = SMAgreementBillingSchedule.[Date], 
		@ExistingInvoiceID = SMAgreementBillingSchedule.SMInvoiceID,
		@CustGroup = SMAgreement.CustGroup,
		@Customer = SMAgreement.Customer,
		@ReportID = SMAgreement.ReportID,
		@BillToCustomer = ISNULL(SMCustomer.BillToARCustomer, SMCustomer.Customer),
		@InvoiceSummaryLevel = SMCustomer.InvoiceSummaryLevel,
		@PayTerms = ARCM.PayTerms, 
		@BillAddress = ARCM.BillAddress, 
		@BillCity = ARCM.BillCity, 
		@BillZip = ARCM.BillZip,
		@BillAddress2 = ARCM.BillAddress2, 
		@BillCountry = ARCM.BillCountry, 
		@BillState = ARCM.BillState,
		@AmendmentExists = CASE WHEN Amendment.PreviousRevision IS NULL THEN 0 ELSE 1 END,
		@BillingType = BillingType
	FROM dbo.SMAgreementBillingSchedule
	INNER JOIN dbo.SMAgreement ON 
		SMAgreement.SMCo = SMAgreementBillingSchedule.SMCo 
		AND SMAgreement.Agreement = SMAgreementBillingSchedule.Agreement
		AND SMAgreement.Revision = SMAgreementBillingSchedule.Revision
	INNER JOIN dbo.SMCustomer ON
		SMCustomer.SMCo = SMAgreement.SMCo
		AND SMCustomer.CustGroup = SMAgreement.CustGroup
		AND SMCustomer.Customer = SMAgreement.Customer
	INNER JOIN dbo.ARCM ON
		ARCM.CustGroup = SMAgreement.CustGroup
		AND ARCM.Customer = ISNULL(SMCustomer.BillToARCustomer, SMCustomer.Customer)
	LEFT JOIN dbo.SMAgreement Amendment ON Amendment.SMCo=SMAgreement.SMCo
		AND Amendment.Agreement=SMAgreement.Agreement
		AND Amendment.PreviousRevision=SMAgreement.Revision
		AND Amendment.RevisionType = 2
		AND Amendment.DateCancelled IS NULL
	WHERE SMAgreementBillingScheduleID = @SMAgreementBillingScheduleID
	
	-- Check to make sure this scheduled billing has not already been invoiced
	IF (@ExistingInvoiceID IS NOT NULL)
	BEGIN
		SET @msg = 'This scheduled billing has already been invoiced.'
		RETURN 1
	END	
	
	-- Check for pending amendments - Only a problem on Scheduled billings
	IF (@AmendmentExists = 1 AND @BillingType='S')
	BEGIN
		SET @msg = 'This agreement revision has pending amendments.'
		RETURN 1
	END	
	
	--Pay terms are not required, but if available validate them
	IF ( @PayTerms IS NOT NULL )
		BEGIN
		-- Get Pay Term Info
		EXEC @rcode = dbo.bspHQPayTermsDateCalc @PayTerms, @ScheduledDate, @DiscDate OUTPUT, @DueDate OUTPUT, @DiscRate OUTPUT, @errmsg OUTPUT
		
		IF (@rcode <> 0)
		BEGIN
			SET @msg = @errmsg
			RETURN @rcode
		END	
	END
	
	-- Get the ARCo and Batch Month from SMCO
	SELECT @BatchMonth = dbo.vfDateOnlyMonth()
	SELECT @ARCo = SMCO.ARCo, @BatchMonth =
		CASE WHEN @BatchMonth >= DATEADD(month, 1, LastMthSubClsd) AND @BatchMonth <= DATEADD(month, MaxOpen, LastMthARClsd) THEN @BatchMonth
			WHEN @BatchMonth > DATEADD(month, MaxOpen, LastMthARClsd) THEN DATEADD(month, MaxOpen, LastMthARClsd)
			ELSE DATEADD(month, 1, LastMthSubClsd) END
	FROM dbo.SMCO
		INNER JOIN dbo.ARCO ON SMCO.ARCo = ARCO.ARCo
		INNER JOIN dbo.GLCO ON ARCO.GLCo = GLCO.GLCo
	WHERE SMCO.SMCo = @SMCo
	
	BEGIN TRY
		BEGIN TRANSACTION
		-- Get the next AR Invoice Number
			EXEC @rcode = dbo.vspSMGetNextInvoiceNumber @SMCo, @InvoiceNumber OUTPUT, @errmsg OUTPUT
			IF (@rcode <> 0)
			BEGIN
				SET @msg = @errmsg
				RETURN @rcode
			END

			-- Insert into SM Invoice
			INSERT INTO dbo.SMInvoice
			(
				SMCo,
				Invoice,
				CustGroup,
				Customer,
				BillToARCustomer,
				InvoiceNumber,
				InvoiceDate,
				Invoiced,
				BatchMonth,
				ARCo,
				InvoiceSummaryLevel,
				InvoiceType,
				PayTerms,
				DueDate,
				DiscDate,
				DiscRate,
				BillAddress,
				BillCity,
				BillZip,
				BillAddress2,
				BillCountry,
				BillState,
				ReportID
			)
			SELECT
				@SMCo,					
				ISNULL((SELECT MAX(Invoice) + 1 FROM dbo.vSMInvoice WHERE SMCo = @SMCo), 1),
				@CustGroup,				-- From Agreement
				@Customer,				-- From Agreement
				@BillToCustomer,		-- From Customer or alternate bill to
				@InvoiceNumber,			-- From AR
				@ScheduledDate,			-- From Agreement billing schedule
				0,						-- Default to 0 - Not invoiced
				@BatchMonth,			--
				@ARCo,					-- From SMCo
				@InvoiceSummaryLevel,	-- From Customer
				'A',					-- Default to A - Agreement Invoice
				@PayTerms,				-- From ARCM
				@DueDate,				-- From bspHQPayTermsDateCalc
				@DiscDate,				-- From bspHQPayTermsDateCalc
				@DiscRate,				-- From bspHQPayTermsDateCalc
				@BillAddress,			-- From ARCM
				@BillCity,				-- From ARCM
				@BillZip,				-- From ARCM
				@BillAddress2,			-- From ARCM
				@BillCountry,			-- From ARCM
				@BillState,				-- From ARCM
				@ReportID				-- From SMAgreement
			
			SELECT @SMInvoiceID = SCOPE_IDENTITY() 

			/* Get Tax Rate */
			SELECT @TaxGroup=TaxGroup, @TaxType=TaxType, @TaxCode=TaxCode 
			FROM dbo.SMAgreementBillingSchedule
			WHERE SMAgreementBillingScheduleID = @SMAgreementBillingScheduleID
			
			exec vspHQTaxCodeVal @taxgroup=@TaxGroup, @taxcode=@TaxCode, @taxtype=@TaxType, @taxrate=@TaxRate OUTPUT

			-- Update the SMAgreementBillingSchedule SMInvoice ID and Tax Amount
			UPDATE dbo.SMAgreementBillingSchedule SET SMInvoiceID = @SMInvoiceID,
			TaxAmount = ISNULL(TaxBasis*@TaxRate,0)
			WHERE SMAgreementBillingScheduleID = @SMAgreementBillingScheduleID
		
			-- Add the SM Invoice into the Session
			SELECT @SessionInvoice = ISNULL(MAX(SessionInvoice), 0) + 1 FROM dbo.vSMInvoiceSession WHERE SMSessionID = @SMSessionID
			
			INSERT INTO dbo.vSMInvoiceSession (SMInvoiceID, SMSessionID, SessionInvoice) 
			VALUES (@SMInvoiceID, @SMSessionID, @SessionInvoice)
		COMMIT
	END TRY
	BEGIN CATCH
		ROLLBACK
		SELECT @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMGenerateAgreementPeriodicInvoice] TO [public]
GO
