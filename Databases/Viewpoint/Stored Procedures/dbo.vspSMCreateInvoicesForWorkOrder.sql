SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
DECLARE @rcode int, @SMSessionID int 
exec @rcode = vspSMCreateSessionForWorkOrder 2, 4, @SMSessionID OUTPUT
SELECT @rcode, @SMSessionID 
*/

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 11/3/10
-- Description:	Create a session for all billable work order details
-- Changes:		12/23/10 Eric Vaterlaus Added Pay Terms, Due Date, Disc Date and Disc Rate to be included in SM Invoice record.
--				4/4/10 JVH - Pulled out some of the functionality into other stored procedures so that the logic could be shared.
--							Also renamed from vspSMCreateSessionForWorkOrder to vspSMCreateInvoicesForWorkOrder
--				05/06/11 MH Added ARCo, ARPostedMth, and ARTrans as values being pumped into SMInvoice.
--              07/28/11 EricV Added check of Provisional flag when selecting WorkCompleted records to bill.
--              09/15/11 EricV Added InvoiceSummaryLevel to the SMInvoice record.
--				11/02/12 Matthew Bradford TK-18934 Working on work completed included in agreement costs not showing up.
--				11/03/12 Lane G TK-19722 Billing Workorders will now filter out NonBillable that equal yes.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMCreateInvoicesForWorkOrder]
	@SMCo bCompany, @WorkOrder int, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--Create a table variable for keeping track of the records that will be updated and
	--their corresponding values for inserting the correct values
	DECLARE @InvoicableWorkCompleted TABLE
	(
		SMWorkCompletedID int,
		CustGroup bGroup,
		BillToARCustomer bCustomer,
		Customer bCustomer,
		InvoiceSummaryLevel char(1)
	)
	
	INSERT INTO @InvoicableWorkCompleted (SMWorkCompletedID, CustGroup, BillToARCustomer, Customer, InvoiceSummaryLevel)
	SELECT SMWorkCompleted. SMWorkCompletedID, SMWorkOrderScope.CustGroup, SMWorkOrderScope.BillToARCustomer, SMWorkOrder.Customer, SMCustomer.InvoiceSummaryLevel
	FROM dbo.SMWorkCompleted
		INNER JOIN dbo.SMWorkOrderScope ON SMWorkCompleted.SMCo = SMWorkOrderScope.SMCo AND SMWorkCompleted.WorkOrder = SMWorkOrderScope.WorkOrder AND SMWorkCompleted.Scope = SMWorkOrderScope.Scope
		INNER JOIN dbo.SMWorkOrder ON SMWorkOrder.SMCo = SMWorkOrderScope.SMCo AND SMWorkOrder.WorkOrder = SMWorkOrderScope.WorkOrder
		LEFT JOIN dbo.SMCustomer ON SMCustomer.SMCo = SMWorkOrder.SMCo AND SMCustomer.Customer = SMWorkOrder.Customer
	WHERE SMWorkCompleted.SMCo = @SMCo 
		AND SMWorkCompleted.WorkOrder = @WorkOrder 
		AND SMWorkCompleted.SMInvoiceID IS NULL 
		AND SMWorkCompleted.BackupSMInvoiceID IS NULL
		AND SMWorkCompleted.Provisional=0
		AND (SMWorkCompleted.Coverage IS NULL OR SMWorkCompleted.Coverage <> 'C')
		AND NOT SMWorkCompleted.NonBillable = 'Y'

	IF @@rowcount = 0
	BEGIN
		--If there were no records available for billing then stop processing
		--and the return value of 1 will indicate that there were no records to process
		SET @msg = 'There are no work completed entries to bill.'
		
		RETURN 1
	END
	
	DECLARE @DistinctInvoices TABLE
	(
		CustGroup bGroup,
		BillToARCustomer bCustomer,
		BillAddress varchar(60) NULL,
		BillCity varchar(30) NULL,
		BillState varchar(4) NULL,
		BillZip bZip NULL,
		BillCountry char(2) NULL,
		BillAddress2 varchar(60) NULL,
		Customer bCustomer,
		InvoiceNo varchar(10) NULL,
		PayTerms bPayTerms NULL,
		DueDate bDate NULL,
		DiscDate bDate NULL,
		DiscRate bPct NULL,
		InvoiceSummaryLevel char(1) NULL,
		KeyID int identity(1, 1)
	)
	
	-- Create a list of distinct invoices
	INSERT @DistinctInvoices (CustGroup, BillToARCustomer, BillAddress, BillCity, BillState, BillZip, BillCountry, BillAddress2, Customer, InvoiceSummaryLevel)
	SELECT DISTINCT InvoicableWorkCompleted.CustGroup, BillToARCustomer, 
		CASE WHEN bARCM.BillAddress IS NULL THEN bARCM.Address ELSE bARCM.BillAddress END, 
		CASE WHEN bARCM.BillAddress IS NULL THEN bARCM.City ELSE bARCM.BillCity END, 
		CASE WHEN bARCM.BillAddress IS NULL THEN bARCM.State ELSE bARCM.BillState END, 
		CASE WHEN bARCM.BillAddress IS NULL THEN bARCM.Zip ELSE bARCM.BillZip END, 
		CASE WHEN bARCM.BillAddress IS NULL THEN bARCM.Country ELSE bARCM.BillCountry END, 
		CASE WHEN bARCM.BillAddress IS NULL THEN bARCM.Address2 ELSE bARCM.BillAddress2 END,
		InvoicableWorkCompleted.Customer, InvoiceSummaryLevel
	FROM @InvoicableWorkCompleted InvoicableWorkCompleted
	LEFT JOIN bARCM ON bARCM.CustGroup = InvoicableWorkCompleted.CustGroup
		AND bARCM.Customer = InvoicableWorkCompleted.BillToARCustomer

	UPDATE DistinctInvoices
	SET PayTerms = ARCM.PayTerms
	FROM @DistinctInvoices DistinctInvoices
		INNER JOIN dbo.ARCM ON DistinctInvoices.CustGroup = ARCM.CustGroup AND DistinctInvoices.BillToARCustomer = ARCM.Customer

	DECLARE @CurrentKeyID int, @InvoiceDate bDate, @ARCo bCompany, @BatchMonth bMonth, @ReportID int, @PayTerms bPayTerms,
		@NextInvNumber varchar(10), @DiscDate bDate, @DueDate bDate, @DiscRate bPct, @rcode int, @errmsg varchar(100)

	SELECT @CurrentKeyID = 0, @InvoiceDate = dbo.vfDateOnly(), @BatchMonth = dbo.vfDateOnlyMonth()
	
	--Create the invoices and get back the SMInoviceIDs
	SELECT @ARCo = SMCO.ARCo, @BatchMonth =
		CASE WHEN @BatchMonth >= DATEADD(month, 1, LastMthSubClsd) AND @BatchMonth <= DATEADD(month, MaxOpen, LastMthARClsd) THEN @BatchMonth
			WHEN @BatchMonth > DATEADD(month, MaxOpen, LastMthARClsd) THEN DATEADD(month, MaxOpen, LastMthARClsd)
			ELSE DATEADD(month, 1, LastMthSubClsd) END
	FROM dbo.SMCO
		INNER JOIN dbo.ARCO ON SMCO.ARCo = ARCO.ARCo
		INNER JOIN dbo.GLCO ON ARCO.GLCo = GLCO.GLCo
	WHERE SMCO.SMCo = @SMCo
	
	-- Gets the custom Report ID from the service site and the customer, the custom Report ID may not be defined ether for the service site or customer. 
	SELECT @ReportID = COALESCE(SMServiceSite.ReportID, SMCustomer.ReportID)
	FROM dbo.SMWorkOrder
		LEFT JOIN dbo.SMCustomer ON SMWorkOrder.SMCo = SMCustomer.SMCo AND SMWorkOrder.CustGroup = SMCustomer.CustGroup AND SMWorkOrder.Customer = SMCustomer.Customer
		LEFT JOIN dbo.SMServiceSite ON SMWorkOrder.SMCo = SMServiceSite.SMCo AND SMWorkOrder.ServiceSite = SMServiceSite.ServiceSite
	WHERE SMWorkOrder.SMCo = @SMCo AND SMWorkOrder.WorkOrder = @WorkOrder
	
	-- Update the list of invoices with a default invoice number
	InvoiceLoop:
	BEGIN
		SELECT TOP 1 @PayTerms = PayTerms, @CurrentKeyID = KeyID
		FROM @DistinctInvoices
		WHERE KeyID > @CurrentKeyID
		ORDER BY KeyID
		IF @@rowcount = 1
		BEGIN
			-- Get the next AR Invoice Number
			EXEC @rcode = dbo.vspSMGetNextInvoiceNumber @SMCo, @NextInvNumber OUTPUT, @errmsg OUTPUT
			IF @rcode = 0
			BEGIN
				UPDATE @DistinctInvoices
				SET InvoiceNo = @NextInvNumber
				WHERE KeyID = @CurrentKeyID
			END
			
			-- Look up the Due Date and Disc Date based on the PayTerms of the Bill To Customer
			EXEC @rcode = dbo.bspHQPayTermsDateCalc @PayTerms, @InvoiceDate, @DiscDate OUTPUT, @DueDate OUTPUT, @DiscRate OUTPUT, @errmsg OUTPUT
			IF @rcode = 0
			BEGIN
				UPDATE @DistinctInvoices
				SET DueDate = @DueDate, DiscDate = @DiscDate, DiscRate = @DiscRate
				WHERE KeyID = @CurrentKeyID
			END
		
			GOTO InvoiceLoop
		END
	END

	DECLARE @InvoicesCreated TABLE
	(
		SMInvoiceID bigint,
		CustGroup bGroup,
		BillToARCustomer bCustomer
	)
	
	INSERT dbo.SMInvoice (SMCo, CustGroup, BillToARCustomer, BillAddress, BillCity, BillState, BillZip, BillCountry, BillAddress2, Customer, Invoice, InvoiceDate, BatchMonth, Invoiced, PayTerms, DueDate, DiscDate, DiscRate, ReportID, ARCo, InvoiceSummaryLevel, InvoiceType)
		OUTPUT INSERTED.SMInvoiceID, INSERTED.CustGroup, INSERTED.BillToARCustomer
			INTO @InvoicesCreated
	SELECT @SMCo, CustGroup, BillToARCustomer, BillAddress, BillCity, BillState, BillZip, BillCountry, BillAddress2, Customer, ISNULL(InvoiceNo,''), @InvoiceDate, @BatchMonth, 0, PayTerms, DueDate, DiscDate, DiscRate, @ReportID, @ARCo, InvoiceSummaryLevel, 'W'
	FROM @DistinctInvoices

	--Update the current work completed records so that they are in the batch.
	UPDATE dbo.SMWorkCompletedDetail
		SET SMInvoiceID = InvoicesCreated.SMInvoiceID
	FROM dbo.SMWorkCompletedDetail
		INNER JOIN @InvoicableWorkCompleted InvoicableWorkCompleted ON SMWorkCompletedDetail.SMWorkCompletedID = InvoicableWorkCompleted.SMWorkCompletedID
		INNER JOIN @InvoicesCreated InvoicesCreated ON InvoicableWorkCompleted.CustGroup = InvoicesCreated.CustGroup AND InvoicableWorkCompleted.BillToARCustomer = InvoicesCreated.BillToARCustomer
	
	--Output the invoices created so that we can add them to a new session.
	SELECT SMInvoiceID
	FROM @InvoicesCreated
	
	RETURN 0
END






GO
GRANT EXECUTE ON  [dbo].[vspSMCreateInvoicesForWorkOrder] TO [public]
GO
