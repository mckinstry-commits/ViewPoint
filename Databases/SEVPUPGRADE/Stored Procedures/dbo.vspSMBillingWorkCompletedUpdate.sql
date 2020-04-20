SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 08/11/11
-- Description:	Add the specified Work Completed record to an existing invoice
--              in the specified Session, or create a new invoice and add it.
-- Modified:    09/15/11 ECV TK-08475 Add consideration of Invoice Grouping setting
--                           on SMCustomer and SMServiceSite.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMBillingWorkCompletedUpdate]
		@SMCo tinyint,
		@WorkOrder int,
		@WorkCompleted int,
		@BillFlag bit,
		@SMSessionID int,
		@SMInvoiceID bigint=NULL OUTPUT, 
		@Invoice varchar(10)=NULL OUTPUT, 
		@msg varchar(255)=NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @DebugFlag bit
	SET @DebugFlag=0
	
	DECLARE @CustGroup bGroup, @BillToARCustomer bCustomer, @Customer bCustomer, @SMWorkCompletedID bigint,
		@PayTerms bPayTerms, @ReportID int, @CurrentSessionID int, @InvoiceGrouping char(1),
		@ServiceSite varchar(20), @InvoiceSummaryLevel char(1), @BillAddress varchar(60), @BillCity varchar(30), 
		@BillState varchar(4), @BillZip bZip, @BillCountry char(2), @BillAddress2 varchar(60)

	SELECT @CustGroup = SMWorkOrderScope.CustGroup, 
		@BillToARCustomer = SMWorkOrderScope.BillToARCustomer,
		@BillAddress=CASE WHEN bARCM.BillAddress IS NULL THEN bARCM.Address ELSE bARCM.BillAddress END, 
		@BillCity=CASE WHEN bARCM.BillAddress IS NULL THEN bARCM.City ELSE bARCM.BillCity END, 
		@BillState=CASE WHEN bARCM.BillAddress IS NULL THEN bARCM.State ELSE bARCM.BillState END, 
		@BillZip=CASE WHEN bARCM.BillAddress IS NULL THEN bARCM.Zip ELSE bARCM.BillZip END, 
		@BillCountry=CASE WHEN bARCM.BillAddress IS NULL THEN bARCM.Country ELSE bARCM.BillCountry END, 
		@BillAddress2=CASE WHEN bARCM.BillAddress IS NULL THEN bARCM.Address2 ELSE bARCM.BillAddress2 END, 
		@Customer = SMWorkOrder.Customer,
		@SMWorkCompletedID = SMWorkCompletedID,
		@CurrentSessionID = SMSessionID,
		@ServiceSite = SMWorkOrder.ServiceSite,
		@ReportID = ISNULL(SMServiceSite.ReportID, SMCustomer.ReportID),
		@InvoiceGrouping = ISNULL(SMServiceSite.InvoiceGrouping, SMCustomer.InvoiceGrouping),
		@InvoiceSummaryLevel = SMCustomer.InvoiceSummaryLevel
	FROM dbo.SMWorkCompleted
	INNER JOIN dbo.SMWorkOrderScope ON SMWorkCompleted.SMCo = SMWorkOrderScope.SMCo 
		AND SMWorkCompleted.WorkOrder = SMWorkOrderScope.WorkOrder 
		AND SMWorkCompleted.Scope = SMWorkOrderScope.Scope
	INNER JOIN dbo.SMWorkOrder ON SMWorkOrder.SMCo = SMWorkOrderScope.SMCo 
		AND SMWorkOrder.WorkOrder = SMWorkOrderScope.WorkOrder
	INNER JOIN bARCM ON bARCM.CustGroup = SMWorkOrderScope.CustGroup
		AND bARCM.Customer = SMWorkOrderScope.BillToARCustomer
	LEFT JOIN dbo.SMCustomer ON SMWorkOrder.SMCo = SMCustomer.SMCo
		AND SMWorkOrder.CustGroup = SMCustomer.CustGroup
		AND SMWorkOrder.Customer = SMCustomer.Customer
	LEFT JOIN dbo.SMServiceSite ON SMWorkOrder.SMCo = SMServiceSite.SMCo
		AND SMWorkOrder.ServiceSite = SMServiceSite.ServiceSite
	WHERE SMWorkCompleted.SMCo = @SMCo
		and SMWorkCompleted.WorkOrder =	@WorkOrder
		and SMWorkCompleted.WorkCompleted =	@WorkCompleted

IF @DebugFlag=1 PRINT 'vspSMBillingWorkCompletedUpdate 0: SMWorkCompletedID='+CONVERT(VARCHAR, @SMWorkCompletedID)

	IF (@BillFlag=1)
	BEGIN
		IF NOT @CurrentSessionID IS NULL  AND dbo.vfIsEqual(@CurrentSessionID, @SMSessionID)=0
		BEGIN
			SET @msg = 'Work Completed record '+CONVERT(varchar,@WorkCompleted)+' for work order '+CONVERT(varchar,@WorkOrder)+' is already in session '+CONVERT(varchar, @CurrentSessionID)+'.'
			RETURN 1
		END
		
IF @DebugFlag=1 PRINT 'vspSMBillingWorkCompletedUpdate 1: ReportID='+CONVERT(VARCHAR, @ReportID)

		-- Determine if this Work Completed record can go in an Invoice that exists in the session.
		SELECT @SMInvoiceID = SMInvoice.SMInvoiceID,
			@Invoice = SMInvoice.Invoice
		FROM dbo.SMInvoice
		INNER JOIN dbo.SMInvoiceSession ON SMInvoiceSession.SMInvoiceID = SMInvoice.SMInvoiceID
		WHERE SMInvoiceSession.SMSessionID = @SMSessionID
			AND SMInvoice.InvoiceType = 'W'
			AND SMInvoice.CustGroup = @CustGroup
			AND SMInvoice.BillToARCustomer = @BillToARCustomer
			AND SMInvoice.Customer = @Customer
			AND dbo.vfIsEqual(SMInvoice.ReportID, @ReportID) = 1
			AND ((@InvoiceGrouping='S' AND SMInvoice.ServiceSite = @ServiceSite)
				OR (@InvoiceGrouping='W' AND SMInvoice.WorkOrder = @WorkOrder)
				OR (@InvoiceGrouping='C' AND SMInvoice.ServiceSite IS NULL AND SMInvoice.WorkOrder IS NULL)
			   )
			   

IF @DebugFlag=1 PRINT 'vspSMBillingWorkCompletedUpdate 2: SMInvoiceID='+CONVERT(VARCHAR, ISNULL(@SMInvoiceID,0))+'  Invoice='+ISNULL(@Invoice,'')

		-- Do we need to create a new invoice.
		IF (@Invoice IS NULL)
		BEGIN
			SELECT @PayTerms = ARCM.PayTerms
			FROM dbo.ARCM
			WHERE CustGroup = @CustGroup 
				AND Customer = @BillToARCustomer
IF @DebugFlag=1 PRINT 'vspSMBillingWorkCompletedUpdate 3: PayTerms='+@PayTerms+'  Invoice='+ISNULL(@Invoice,'')
			
			DECLARE @InvoiceDate bDate, @ARCo bCompany, @BatchMonth bMonth, 
				@NextInvNumber varchar(10), @DiscDate bDate, @DueDate bDate, @DiscRate bPct, @rcode int, @errmsg varchar(100)

			SELECT @InvoiceDate = dbo.vfDateOnly(), @BatchMonth = dbo.vfDateOnlyMonth()
			
			--Create the invoices and get back the SMInoviceIDs
			SELECT @ARCo = SMCO.ARCo, @BatchMonth =
				CASE WHEN @BatchMonth >= DATEADD(month, 1, LastMthSubClsd) AND @BatchMonth <= DATEADD(month, MaxOpen, LastMthARClsd) THEN @BatchMonth
					WHEN @BatchMonth > DATEADD(month, MaxOpen, LastMthARClsd) THEN DATEADD(month, MaxOpen, LastMthARClsd)
					ELSE DATEADD(month, 1, LastMthSubClsd) END
			FROM dbo.SMCO
				INNER JOIN dbo.ARCO ON SMCO.ARCo = ARCO.ARCo
				INNER JOIN dbo.GLCO ON ARCO.GLCo = GLCO.GLCo
			WHERE SMCO.SMCo = @SMCo
	
			-- Get the next AR Invoice Number
			EXEC @rcode = dbo.vspSMGetNextInvoiceNumber @SMCo, @Invoice OUTPUT, @errmsg OUTPUT
IF @DebugFlag=1 PRINT 'vspSMBillingWorkCompletedUpdate 4: Invoice='+ISNULL(@Invoice,'')
			
			-- Look up the Due Date and Disc Date based on the PayTerms of the Bill To Customer
			EXEC @rcode = dbo.bspHQPayTermsDateCalc @PayTerms, @InvoiceDate, @DiscDate OUTPUT, @DueDate OUTPUT, @DiscRate OUTPUT, @errmsg OUTPUT
IF @DebugFlag=1 PRINT 'vspSMBillingWorkCompletedUpdate 5: DiscDate='+Convert(varchar,@DiscDate,101)
			
			INSERT dbo.SMInvoice (SMCo, CustGroup, BillToARCustomer, BillAddress, BillCity, BillState, BillZip, BillCountry, BillAddress2, Customer, Invoice, InvoiceDate, BatchMonth, Invoiced, PayTerms, DueDate, DiscDate, DiscRate, ReportID, ARCo, ServiceSite, WorkOrder, InvoiceSummaryLevel, InvoiceType)
			VALUES (@SMCo, @CustGroup, @BillToARCustomer, @BillAddress, @BillCity, @BillState, @BillZip, @BillCountry, @BillAddress2, @Customer, @Invoice, @InvoiceDate, @BatchMonth, 0, @PayTerms, @DueDate, @DiscDate, @DiscRate, @ReportID, @ARCo, 
				CASE WHEN @InvoiceGrouping='S' THEN @ServiceSite ELSE NULL END, CASE WHEN @InvoiceGrouping='W' THEN @WorkOrder ELSE NULL END, @InvoiceSummaryLevel, 'W')

			SET @SMInvoiceID = SCOPE_IDENTITY()
IF @DebugFlag=1 PRINT 'vspSMBillingWorkCompletedUpdate 6: SMInvoiceID='+Convert(varchar,@SMInvoiceID)

			EXEC vspSMSessionAddInvoice @SMSessionID, @SMInvoiceID
		END

		--Update the current work completed record with the SMInvoiceID.
IF @DebugFlag=1 PRINT 'vspSMBillingWorkCompletedUpdate 7'
		UPDATE dbo.SMWorkCompletedDetail
			SET SMInvoiceID = @SMInvoiceID
			WHERE SMWorkCompletedID = @SMWorkCompletedID
IF @DebugFlag=1 PRINT 'vspSMBillingWorkCompletedUpdate 7: WorkCompletedDetail Rows updated='+Convert(varchar,@@RowCount)
				
	END
	ELSE IF (@BillFlag = 0)
	BEGIN
		-- Get the SMInvoiceID
IF @DebugFlag=1 PRINT 'vspSMBillingWorkCompletedUpdate 8'
		SELECT @SMInvoiceID=SMInvoiceID
			FROM dbo.SMWorkCompletedDetail
			WHERE SMWorkCompletedID = @SMWorkCompletedID			
IF @DebugFlag=1 PRINT 'vspSMBillingWorkCompletedUpdate 8: SMInvoiceID='+Convert(varchar,@SMInvoiceID)

		-- Remove the Work Completed from the Invoice.
		UPDATE dbo.SMWorkCompletedDetail
			SET SMInvoiceID = NULL
		FROM dbo.SMWorkCompletedDetail
		WHERE SMWorkCompletedID = @SMWorkCompletedID			
		-- Delete the invoice from the session.
		IF NOT EXISTS(SELECT 1 FROM dbo.SMWorkCompleted WHERE SMInvoiceID = @SMInvoiceID)
		BEGIN
			DELETE dbo.vSMInvoiceSession WHERE SMSessionID = @SMSessionID AND SMInvoiceID = @SMInvoiceID
			DELETE dbo.SMInvoice WHERE SMInvoiceID = @SMInvoiceID
		END			

	END
	
END
GO
GRANT EXECUTE ON  [dbo].[vspSMBillingWorkCompletedUpdate] TO [public]
GO
