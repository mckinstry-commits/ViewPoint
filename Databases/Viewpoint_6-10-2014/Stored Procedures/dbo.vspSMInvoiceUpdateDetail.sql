SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 4/24/13
-- Description:	Adds or removes work order, flat price work order scope, or work completed to an invoice
-- Modified:  06/20/13 EricV TFS-53340 Update InvoiceDetailSeq column on SMInvoiceLine with vSMFlatPriceRevenueSplit.Seq for Flat Price invoice lines
--                                          Update GLCo, RevenueAccount and RevenueWIPAccount on the vSMFlatPriceRevenueSplit when creating the first related SMInvoiceLine.
--				7/12/13 JVH TFS-55616 Fixed invoice grouping.
--				9/20/13 JVH TFS-39816 Added support for partially billing flat price scopes
--              10/21/13 EricV TFS-64707 Added SMSessionID parameter to query of vfSMWorkOrderInvoiceDetail.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMInvoiceUpdateDetail]
	@SMSessionID bigint, @Bill bit, @SMCo tinyint, @WorkOrder int, @Scope int, @WorkCompleted int,
	@Invoice int, @InvoiceDetail int,
	@ServiceCenter varchar(10), @Division varchar(10),
	@CustGroup bGroup, @Customer bCustomer, @BillToCustomer bCustomer,
	@ServiceSite varchar(20),
	@StartDate bDate, @EndDate bDate,
	@LineType tinyint,
	@ReferenceNumber varchar(60),
	@Amount bDollar = NULL,
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @rcode int

	IF @Bill = 0
	BEGIN
		DECLARE @InvoiceDetailToRemove TABLE (SMCo bCompany NOT NULL, Invoice int NOT NULL, InvoiceDetail int NOT NULL)

		--Remove only invoice detail that is part of the invoice's session.
		INSERT @InvoiceDetailToRemove
		SELECT vfSMWorkOrderInvoiceDetail.SMCo, vfSMWorkOrderInvoiceDetail.Invoice, vfSMWorkOrderInvoiceDetail.InvoiceDetail
		FROM dbo.vfSMWorkOrderInvoiceDetail(@SMSessionID, @SMCo, @WorkOrder, @Scope, @WorkCompleted, @ServiceCenter, @Division, @CustGroup, @Customer, @BillToCustomer, @ServiceSite, @StartDate, @EndDate, @LineType, @ReferenceNumber)
			INNER JOIN dbo.vSMInvoice ON vfSMWorkOrderInvoiceDetail.SMCo = vSMInvoice.SMCo AND vfSMWorkOrderInvoiceDetail.Invoice = vSMInvoice.Invoice
			INNER JOIN dbo.vSMInvoiceSession ON vSMInvoice.SMInvoiceID = vSMInvoiceSession.SMInvoiceID
		WHERE vSMInvoiceSession.SMSessionID = @SMSessionID AND
			(
				@Invoice IS NULL OR
				@InvoiceDetail IS NULL OR
				(
					vfSMWorkOrderInvoiceDetail.Invoice = @Invoice AND
					vfSMWorkOrderInvoiceDetail.InvoiceDetail = @InvoiceDetail
				)
			)

		--Mark the invoice detail as removed so that reversing entries can be sent to AR
		UPDATE vSMInvoiceDetail
		SET IsRemoved = 1
		FROM @InvoiceDetailToRemove InvoiceDetailToRemove
			INNER JOIN dbo.vSMInvoiceDetail ON InvoiceDetailToRemove.SMCo = vSMInvoiceDetail.SMCo AND InvoiceDetailToRemove.Invoice = vSMInvoiceDetail.Invoice AND InvoiceDetailToRemove.InvoiceDetail = vSMInvoiceDetail.InvoiceDetail

		--Remove the invoice detail that has an invoiced line so that what is left are invoice detail records that should be deleted.
		DELETE InvoiceDetailToRemove
		FROM @InvoiceDetailToRemove InvoiceDetailToRemove
			INNER JOIN dbo.vSMInvoiceLine ON InvoiceDetailToRemove.SMCo = vSMInvoiceLine.SMCo AND InvoiceDetailToRemove.Invoice = vSMInvoiceLine.Invoice AND InvoiceDetailToRemove.InvoiceDetail = vSMInvoiceLine.InvoiceDetail
		WHERE vSMInvoiceLine.LastPostedARLine IS NOT NULL

		DELETE CurrentAndInvoiced
		FROM @InvoiceDetailToRemove InvoiceDetailToRemove
			INNER JOIN dbo.vSMInvoiceLine ON InvoiceDetailToRemove.SMCo = vSMInvoiceLine.SMCo AND InvoiceDetailToRemove.Invoice = vSMInvoiceLine.Invoice AND InvoiceDetailToRemove.InvoiceDetail = vSMInvoiceLine.InvoiceDetail
			INNER JOIN dbo.vSMInvoiceLine CurrentAndInvoiced ON vSMInvoiceLine.SMCo = CurrentAndInvoiced.SMCo AND vSMInvoiceLine.InvoiceLine = CurrentAndInvoiced.InvoiceLine

		DELETE vSMInvoiceDetail
		FROM @InvoiceDetailToRemove InvoiceDetailToRemove
			INNER JOIN dbo.vSMInvoiceDetail ON InvoiceDetailToRemove.SMCo = vSMInvoiceDetail.SMCo AND InvoiceDetailToRemove.Invoice = vSMInvoiceDetail.Invoice AND InvoiceDetailToRemove.InvoiceDetail = vSMInvoiceDetail.InvoiceDetail

		--Delete the invoice session and the invoice if there is no longer any invoice detail on it
		DELETE vSMInvoiceSession
		FROM @InvoiceDetailToRemove InvoiceDetailToRemove
			INNER JOIN dbo.vSMInvoice ON InvoiceDetailToRemove.SMCo = vSMInvoice.SMCo AND InvoiceDetailToRemove.Invoice = vSMInvoice.Invoice
			INNER JOIN dbo.vSMInvoiceSession ON vSMInvoice.SMInvoiceID = vSMInvoiceSession.SMInvoiceID
			LEFT JOIN dbo.vSMInvoiceDetail ON vSMInvoice.SMCo = vSMInvoiceDetail.SMCo AND vSMInvoice.Invoice = vSMInvoiceDetail.Invoice
		WHERE vSMInvoiceDetail.SMInvoiceDetailID IS NULL

		--If after invoice detail has been deleted from the invoice and there is no longer any invoice detail associated with the invoice
		--then the invoice can be deleted.
		DELETE vSMInvoice
		FROM @InvoiceDetailToRemove InvoiceDetailToRemove
			INNER JOIN dbo.vSMInvoice ON InvoiceDetailToRemove.SMCo = vSMInvoice.SMCo AND InvoiceDetailToRemove.Invoice = vSMInvoice.Invoice
			LEFT JOIN dbo.vSMInvoiceDetail ON vSMInvoice.SMCo = vSMInvoiceDetail.SMCo AND vSMInvoice.Invoice = vSMInvoiceDetail.Invoice
		WHERE vSMInvoiceDetail.SMInvoiceDetailID IS NULL
	END
	ELSE IF @Bill = 1
	BEGIN
		DECLARE @InvoiceDetailToAdd TABLE (SMCo bCompany NOT NULL, WorkOrder int NOT NULL, Scope int NULL, WorkCompleted int NULL,
			CustGroup bGroup NOT NULL, Customer bCustomer NOT NULL, BillToCustomer bCustomer NOT NULL, ServiceSite varchar(20) NOT NULL,
			InvoiceGrouping char(1) NOT NULL, ReportID int NULL, Invoice int NULL, InvoiceDetail int NULL, 
			Amount bDollar NULL, TaxGroup bGroup NULL, TaxCode bTaxCode NULL, TaxRate bRate NULL)
		
		DECLARE @InvoiceDate bDate, @TaxGroup bGroup, @TaxCode bTaxCode, @TaxRate bRate
		SELECT @InvoiceDate = dbo.vfDateOnly()

		--Capture all the detail that should be added to the invoice.
		INSERT @InvoiceDetailToAdd (SMCo, WorkOrder, Scope, WorkCompleted, CustGroup, Customer, BillToCustomer, ServiceSite, InvoiceGrouping, ReportID, Invoice, InvoiceDetail, Amount)
		SELECT SMCo, WorkOrder, CASE WHEN PriceMethod = 'F' THEN Scope END, CASE WHEN PriceMethod = 'T' THEN WorkCompleted END,
			CustGroup, Customer,
			CASE WHEN BillToCustomer IS NULL THEN Customer ELSE BillToCustomer END,
			ServiceSite,
			InvoiceGrouping, ReportID,
			Invoice, InvoiceDetail, NewAmount
		FROM
		(
			SELECT vfSMWorkOrderInvoiceDetail.*,
				ISNULL(vSMServiceSite.InvoiceGrouping, vSMCustomer.InvoiceGrouping) InvoiceGrouping,
				ISNULL(vSMServiceSite.ReportID, vSMCustomer.ReportID) ReportID,
				ISNULL(@Amount, BillableAmount) NewAmount
			FROM dbo.vfSMWorkOrderInvoiceDetail(@SMSessionID, @SMCo, @WorkOrder, @Scope, @WorkCompleted, @ServiceCenter, @Division, @CustGroup, @Customer, @BillToCustomer, @ServiceSite, @StartDate, @EndDate, @LineType, @ReferenceNumber)
				LEFT JOIN dbo.vSMCustomer ON vfSMWorkOrderInvoiceDetail.SMCo = vSMCustomer.SMCo AND vfSMWorkOrderInvoiceDetail.CustGroup = vSMCustomer.CustGroup AND vfSMWorkOrderInvoiceDetail.Customer = vSMCustomer.Customer
				LEFT JOIN dbo.vSMServiceSite ON vfSMWorkOrderInvoiceDetail.SMCo = vSMServiceSite.SMCo AND vfSMWorkOrderInvoiceDetail.ServiceSite = vSMServiceSite.ServiceSite
				LEFT JOIN dbo.vSMCO ON vfSMWorkOrderInvoiceDetail.SMCo = vSMCO.SMCo
		) InvoiceDetailToAdd
		WHERE (PriceMethod = 'T' AND InvoiceDetail IS NULL) OR (PriceMethod = 'F' AND BillingAmount <> NewAmount)

		SELECT TOP 1 @msg = 'Flat price split not completed for SMCo: ' + dbo.vfToString(vSMWorkOrderScope.SMCo) + ', WorkOrder: ' + dbo.vfToString(vSMWorkOrderScope.WorkOrder) + ', Scope: ' + dbo.vfToString(vSMWorkOrderScope.Scope)
		FROM @InvoiceDetailToAdd InvoiceDetailToAdd
			INNER JOIN dbo.vSMWorkOrderScope ON InvoiceDetailToAdd.SMCo = vSMWorkOrderScope.SMCo AND InvoiceDetailToAdd.WorkOrder = vSMWorkOrderScope.WorkOrder AND InvoiceDetailToAdd.Scope = vSMWorkOrderScope.Scope
			LEFT JOIN dbo.vSMEntity ON vSMWorkOrderScope.SMCo = vSMEntity.SMCo AND vSMWorkOrderScope.WorkOrder = vSMEntity.WorkOrder AND vSMWorkOrderScope.Scope = vSMEntity.WorkOrderScope
			LEFT JOIN dbo.vSMFlatPriceRevenueSplit ON vSMEntity.SMCo = vSMFlatPriceRevenueSplit.SMCo AND vSMEntity.EntitySeq = vSMFlatPriceRevenueSplit.EntitySeq
		GROUP BY vSMWorkOrderScope.SMCo, vSMWorkOrderScope.WorkOrder, vSMWorkOrderScope.Scope, vSMWorkOrderScope.Price
		HAVING vSMWorkOrderScope.Price <> ISNULL(SUM(vSMFlatPriceRevenueSplit.Amount), 0)
		IF @@rowcount <> 0
		BEGIN
			RETURN 1
		END

		--Capture flat price tax setup
		UPDATE InvoiceDetailToAdd
		SET TaxGroup = vSMWorkOrderScope.TaxGroup, TaxCode = vSMWorkOrderScope.TaxCode
		FROM @InvoiceDetailToAdd InvoiceDetailToAdd
			INNER JOIN vSMWorkOrderScope ON InvoiceDetailToAdd.SMCo = vSMWorkOrderScope.SMCo AND InvoiceDetailToAdd.WorkOrder = vSMWorkOrderScope.WorkOrder AND InvoiceDetailToAdd.Scope = vSMWorkOrderScope.Scope
		WHERE InvoiceDetailToAdd.InvoiceDetail IS NULL AND vSMWorkOrderScope.TaxGroup IS NOT NULL AND vSMWorkOrderScope.TaxCode IS NOT NULL

		--Capture the tax rate so that the tax amount can be calculated
		WHILE EXISTS(SELECT 1 FROM @InvoiceDetailToAdd WHERE TaxGroup IS NOT NULL AND TaxCode IS NOT NULL AND TaxRate IS NULL)
		BEGIN
			SELECT TOP 1 @TaxGroup = TaxGroup, @TaxCode = TaxCode
			FROM @InvoiceDetailToAdd
			WHERE TaxGroup IS NOT NULL AND TaxCode IS NOT NULL AND TaxRate IS NULL

			EXEC @rcode = dbo.vspHQTaxRateGet @taxgroup = @TaxGroup, @taxcode = @TaxCode, @compdate = @InvoiceDate, @taxrate = @TaxRate OUTPUT,
				 @valueadd = NULL , @gstrate = NULL, 
				 @crdGLAcct = NULL, @crdRetgGLAcct = NULL, @dbtGLAcct = NULL, 
				 @dbtRetgGLAcct = NULL, @crdGLAcctPST = NULL, @crdRetgGLAcctPST = NULL, 
				 @msg = @msg OUTPUT

			IF @rcode <> 0
			BEGIN
				RETURN 1
			END

			UPDATE @InvoiceDetailToAdd
			SET TaxRate = @TaxRate
			WHERE TaxGroup = @TaxGroup AND TaxCode = @TaxCode
		END

		DECLARE @AddInvoices bit, @BatchMonth bMonth,
			@ARCo bCompany, @InvoiceWorkOrder int, @InvoiceCustomer bCustomer, @InvoiceServiceSite varchar(20),
			@InvoiceGrouping char(1), @ReportID int, @InvoiceSummaryLevel char(1),
			@InvoiceCustGroup bGroup, @InvoiceBillToCustomer bCustomer, @InvoiceNumber varchar(10),
			@PayTerms bPayTerms, @DiscDate bDate, @DueDate bDate, @DiscRate bPct,
			@SMInvoiceID bigint

		SELECT @AddInvoices = 0, @BatchMonth = dbo.vfDateOnlyMonth()

		--Create the invoices and get back the SMInoviceIDs
		SELECT @ARCo = vSMCO.ARCo, @BatchMonth =
			CASE WHEN @BatchMonth >= DATEADD(month, 1, LastMthSubClsd) AND @BatchMonth <= DATEADD(month, MaxOpen, LastMthARClsd) THEN @BatchMonth
				WHEN @BatchMonth > DATEADD(month, MaxOpen, LastMthARClsd) THEN DATEADD(month, MaxOpen, LastMthARClsd)
				ELSE DATEADD(month, 1, LastMthSubClsd) END
		FROM dbo.vSMCO
			INNER JOIN dbo.bARCO ON vSMCO.ARCo = bARCO.ARCo
			INNER JOIN dbo.bGLCO ON bARCO.GLCo = bGLCO.GLCo
		WHERE vSMCO.SMCo = @SMCo

		BEGIN TRY
			BEGIN TRAN

			--Invoices may or may not exists that the detail can be added to. Any invoice detail that can't be
			--associated with an already existing invoice will have a new invoice created for it.
			WHILE EXISTS(SELECT 1 FROM @InvoiceDetailToAdd WHERE Invoice IS NULL)
			BEGIN
				SELECT TOP 1 @InvoiceCustGroup = InvoiceDetailToAdd.CustGroup, @InvoiceBillToCustomer = InvoiceDetailToAdd.BillToCustomer, @PayTerms = bARCM.PayTerms,
					@InvoiceWorkOrder = InvoiceDetailToAdd.WorkOrder, @InvoiceCustomer = InvoiceDetailToAdd.Customer, @InvoiceServiceSite = InvoiceDetailToAdd.ServiceSite,
					@InvoiceGrouping = InvoiceDetailToAdd.InvoiceGrouping, @ReportID = InvoiceDetailToAdd.ReportID, @InvoiceSummaryLevel = vSMCustomer.InvoiceSummaryLevel
				FROM @InvoiceDetailToAdd InvoiceDetailToAdd
					INNER JOIN dbo.bARCM ON InvoiceDetailToAdd.CustGroup = bARCM.CustGroup AND InvoiceDetailToAdd.BillToCustomer = bARCM.Customer
					INNER JOIN dbo.vSMCustomer ON InvoiceDetailToAdd.SMCo = vSMCustomer.SMCo AND InvoiceDetailToAdd.CustGroup = vSMCustomer.CustGroup AND InvoiceDetailToAdd.Customer = vSMCustomer.Customer
				WHERE InvoiceDetailToAdd.Invoice IS NULL

				--On the first loop pass no invoices should be created since invoices may exist
				--that the invoice detail can be added to
				IF @AddInvoices = 0
				BEGIN
					SET @AddInvoices = 1
				END
				ELSE
				BEGIN
					-- Get the next AR Invoice Number
					EXEC @rcode = dbo.bspARNextTrans @arco = @ARCo, @lastinvoice = @InvoiceNumber OUTPUT, @errmsg = @msg OUTPUT
					IF @rcode <> 0
					BEGIN
						ROLLBACK TRAN
						RETURN 1
					END
			
					IF @PayTerms IS NOT NULL
					BEGIN
						-- Look up the Due Date and Disc Date based on the PayTerms of the Bill To Customer
						EXEC @rcode = dbo.bspHQPayTermsDateCalc @payterms = @PayTerms, @invoicedate = @InvoiceDate, @discdate = @DiscDate OUTPUT, @duedate = @DueDate OUTPUT, @discrate = @DiscRate OUTPUT, @msg = @msg OUTPUT
						IF @rcode <> 0
						BEGIN
							ROLLBACK TRAN
							RETURN 1
						END
					END

					INSERT dbo.vSMInvoice (SMCo, Invoice, ARCo, InvoiceNumber, CustGroup, BillToARCustomer, Customer, BatchMonth, InvoiceDate, Invoiced, InvoiceType, InvoiceSummaryLevel, ReportID, PayTerms, DueDate, DiscDate, DiscRate, BillAddress, BillCity, BillState, BillZip, BillCountry, BillAddress2, WorkOrder, ServiceSite)
					SELECT @SMCo, ISNULL((SELECT MAX(Invoice) FROM dbo.vSMInvoice WHERE SMCo = @SMCo), 0) + 1,
						@ARCo, @InvoiceNumber, bARCM.CustGroup, bARCM.Customer, @InvoiceCustomer, @BatchMonth, @InvoiceDate, 0 Invoiced, 'W' InvoiceType,
						@InvoiceSummaryLevel, @ReportID, @PayTerms, @DueDate, @DiscDate, @DiscRate,
						CASE WHEN bARCM.BillAddress IS NULL THEN bARCM.[Address] ELSE bARCM.BillAddress END,
						CASE WHEN bARCM.BillAddress IS NULL THEN bARCM.City ELSE bARCM.BillCity END,
						CASE WHEN bARCM.BillAddress IS NULL THEN bARCM.[State] ELSE bARCM.BillState END,
						CASE WHEN bARCM.BillAddress IS NULL THEN bARCM.Zip ELSE bARCM.BillZip END,
						CASE WHEN bARCM.BillAddress IS NULL THEN bARCM.Country ELSE bARCM.BillCountry END,
						CASE WHEN bARCM.BillAddress IS NULL THEN bARCM.Address2 ELSE bARCM.BillAddress2 END,
						CASE WHEN @InvoiceGrouping = 'W' THEN @InvoiceWorkOrder END,
						CASE WHEN @InvoiceGrouping = 'S' THEN @InvoiceServiceSite END
					FROM dbo.bARCM
					WHERE bARCM.CustGroup = @InvoiceCustGroup AND bARCM.Customer = @InvoiceBillToCustomer

					SET @SMInvoiceID = SCOPE_IDENTITY()

					INSERT dbo.vSMInvoiceSession (SMInvoiceID, SMSessionID, SessionInvoice, VoidFlag)
					SELECT @SMInvoiceID, @SMSessionID, ISNULL((SELECT MAX(SessionInvoice) FROM vSMInvoiceSession WHERE SMSessionID = @SMSessionID), 0) + 1, 'N'
				END

				UPDATE InvoiceDetailToAdd
				SET Invoice = vSMInvoice.Invoice
				FROM dbo.vSMInvoiceSession
					INNER JOIN dbo.vSMInvoice ON vSMInvoiceSession.SMInvoiceID = vSMInvoice.SMInvoiceID
					INNER JOIN @InvoiceDetailToAdd InvoiceDetailToAdd ON vSMInvoice.SMCo = InvoiceDetailToAdd.SMCo AND
						vSMInvoice.CustGroup = InvoiceDetailToAdd.CustGroup AND vSMInvoice.BillToARCustomer = InvoiceDetailToAdd.BillToCustomer AND vSMInvoice.Customer = InvoiceDetailToAdd.Customer AND
						(
							(InvoiceDetailToAdd.InvoiceGrouping = 'S' AND vSMInvoice.ServiceSite = InvoiceDetailToAdd.ServiceSite) OR
							(InvoiceDetailToAdd.InvoiceGrouping = 'W' AND vSMInvoice.WorkOrder = InvoiceDetailToAdd.WorkOrder) OR
							(InvoiceDetailToAdd.InvoiceGrouping = 'C' AND vSMInvoice.ServiceSite IS NULL AND vSMInvoice.WorkOrder IS NULL)
						) AND
						(
							InvoiceDetailToAdd.ReportID = vSMInvoice.ReportID OR
							(InvoiceDetailToAdd.ReportID IS NULL AND vSMInvoice.ReportID IS NULL)
						)
				WHERE vSMInvoiceSession.SMSessionID = @SMSessionID AND vSMInvoice.InvoiceType = 'W'
			END

			--Increases to flat price billings should increase each invoice line
			;WITH FlatPriceInvoiceLineCTE
			AS
			(
				SELECT vSMInvoiceLine.*, InvoiceDetailToAdd.Amount NewAmount,
					SUM(vSMInvoiceLine.Amount) OVER(PARTITION BY vSMInvoiceLine.SMCo, vSMInvoiceLine.Invoice, vSMInvoiceLine.InvoiceDetail) DetailAmount,
					ROW_NUMBER() OVER(PARTITION BY vSMInvoiceLine.SMCo, vSMInvoiceLine.Invoice, vSMInvoiceLine.InvoiceDetail ORDER BY vSMInvoiceLine.InvoiceLine) RowNumber
				FROM @InvoiceDetailToAdd InvoiceDetailToAdd
					INNER JOIN dbo.vSMInvoiceLine ON InvoiceDetailToAdd.SMCo = vSMInvoiceLine.SMCo AND InvoiceDetailToAdd.Invoice = vSMInvoiceLine.Invoice AND InvoiceDetailToAdd.InvoiceDetail = vSMInvoiceLine.InvoiceDetail
			),
			InvoiceLineAdditionalAmountCTE
			AS
			(
				SELECT FlatPriceInvoiceLineCTE.*,
					CAST(CASE WHEN DetailAmount = 0 THEN 0 ELSE NewAmount * Amount / DetailAmount END AS numeric(12, 2)) LineNewAmount
				FROM FlatPriceInvoiceLineCTE
			)
			UPDATE InvoiceLineAdditionalAmountCTE
			SET Amount = LineNewAmount +
				--Handle rounding
				CASE
					WHEN RowNumber = 1 THEN NewAmount - (SELECT SUM(LineNewAmount) FROM InvoiceLineAdditionalAmountCTE CurrentTotal WHERE InvoiceLineAdditionalAmountCTE.SMCo = CurrentTotal.SMCo AND InvoiceLineAdditionalAmountCTE.Invoice = CurrentTotal.Invoice AND InvoiceLineAdditionalAmountCTE.InvoiceDetail = CurrentTotal.InvoiceDetail)
					ELSE 0
				END

			--Update taxes for exists flat price line
			UPDATE vSMInvoiceLine
			SET TaxAmount = CASE WHEN TaxBasis = 0 THEN 0 ELSE vSMInvoiceLine.Amount * TaxAmount / TaxBasis END, TaxBasis = vSMInvoiceLine.Amount
			FROM @InvoiceDetailToAdd InvoiceDetailToAdd
				INNER JOIN dbo.vSMInvoiceLine ON InvoiceDetailToAdd.SMCo = vSMInvoiceLine.SMCo AND InvoiceDetailToAdd.Invoice = vSMInvoiceLine.Invoice AND InvoiceDetailToAdd.InvoiceDetail = vSMInvoiceLine.InvoiceDetail
			WHERE vSMInvoiceLine.TaxCode IS NOT NULL

			DELETE @InvoiceDetailToAdd
			WHERE InvoiceDetail IS NOT NULL

			;WITH UpdateInvoiceDetailCTE
			AS
			(
				SELECT *, ISNULL((SELECT MAX(InvoiceDetail) FROM dbo.vSMInvoiceDetail WHERE vSMInvoiceDetail.SMCo = InvoiceDetailToAdd.SMCo AND vSMInvoiceDetail.Invoice = InvoiceDetailToAdd.Invoice), 0) + ROW_NUMBER() OVER(PARTITION BY Invoice ORDER BY WorkOrder) InvoiceDetailValue
				FROM @InvoiceDetailToAdd InvoiceDetailToAdd
			)
			UPDATE UpdateInvoiceDetailCTE
			SET InvoiceDetail = InvoiceDetailValue

			--Update vSMFlatPriceRevenueSplit with GL Account Information if no SM Invoice Lines exist for this Work Order Scope
			UPDATE vSMFlatPriceRevenueSplit 
				SET GLCo = vfSMGetAccountingTreatment.GLCo, 
					RevenueAccount = vfSMGetAccountingTreatment.RevenueGLAcct, 
					RevenueWIPAccount = vfSMGetAccountingTreatment.RevenueWIPGLAcct
			FROM @InvoiceDetailToAdd InvoiceDetailToAdd
			INNER JOIN dbo.vSMWorkOrderScope ON InvoiceDetailToAdd.SMCo = vSMWorkOrderScope.SMCo AND InvoiceDetailToAdd.WorkOrder = vSMWorkOrderScope.WorkOrder AND InvoiceDetailToAdd.Scope = vSMWorkOrderScope.Scope
			INNER JOIN dbo.vSMEntity ON vSMWorkOrderScope.SMCo = vSMEntity.SMCo AND vSMWorkOrderScope.WorkOrder = vSMEntity.WorkOrder AND vSMWorkOrderScope.Scope = vSMEntity.WorkOrderScope
			INNER JOIN dbo.vSMFlatPriceRevenueSplit ON vSMEntity.SMCo = vSMFlatPriceRevenueSplit.SMCo AND vSMEntity.EntitySeq = vSMFlatPriceRevenueSplit.EntitySeq
			CROSS APPLY dbo.vfSMGetAccountingTreatment(InvoiceDetailToAdd.SMCo, InvoiceDetailToAdd.WorkOrder, InvoiceDetailToAdd.Scope, CostTypeCategory, CostType)
			LEFT JOIN dbo.vSMInvoiceDetail ON vSMInvoiceDetail.SMCo = InvoiceDetailToAdd.SMCo
				AND vSMInvoiceDetail.WorkOrder = InvoiceDetailToAdd.WorkOrder
				AND vSMInvoiceDetail.Scope = InvoiceDetailToAdd.Scope
			WHERE vSMInvoiceDetail.Scope IS NULL

			INSERT dbo.vSMInvoiceDetail (SMCo, Invoice, InvoiceDetail, IsRemoved, WorkOrder, Scope, WorkCompleted)
			SELECT SMCo, Invoice, InvoiceDetail, 0 IsRemoved, WorkOrder, Scope, WorkCompleted
			FROM @InvoiceDetailToAdd

			--Add T&M work completed to the invoice
			INSERT dbo.vSMInvoiceLine (SMCo, InvoiceLine, Invoiced, Invoice, InvoiceDetail, NoCharge, [Description], GLCo, GLAccount, Amount, TaxGroup, TaxCode, TaxBasis, TaxAmount)
			SELECT InvoiceDetailToAdd.SMCo, ISNULL((SELECT MAX(InvoiceLine) FROM dbo.vSMInvoiceLine WHERE InvoiceDetailToAdd.SMCo = vSMInvoiceLine.SMCo), 0) + ROW_NUMBER() OVER (ORDER BY InvoiceDetail),
				0 Invoiced, InvoiceDetailToAdd.Invoice, InvoiceDetailToAdd.InvoiceDetail, SMWorkCompleted.NoCharge, SMWorkCompleted.[Description],
				vfSMGetWorkCompletedGL.GLCo, vfSMGetWorkCompletedGL.CurrentRevenueAccount, ISNULL(SMWorkCompleted.PriceTotal, 0),
				SMWorkCompleted.TaxGroup, SMWorkCompleted.TaxCode, ISNULL(SMWorkCompleted.TaxBasis, 0), ISNULL(SMWorkCompleted.TaxAmount, 0)
			FROM @InvoiceDetailToAdd InvoiceDetailToAdd
				INNER JOIN dbo.SMWorkCompleted ON InvoiceDetailToAdd.SMCo = SMWorkCompleted.SMCo AND InvoiceDetailToAdd.WorkOrder = SMWorkCompleted.WorkOrder AND InvoiceDetailToAdd.WorkCompleted = SMWorkCompleted.WorkCompleted
				CROSS APPLY dbo.vfSMGetWorkCompletedGL(SMWorkCompleted.SMWorkCompletedID)

			--Add flat price invoice lines
			;WITH AddFlatPriceLinesCTE
			AS
			(
				SELECT InvoiceDetailToAdd.*, vSMFlatPriceRevenueSplit.Seq InvoiceDetailSeq, vSMWorkOrderScope.[Description], vSMFlatPriceRevenueSplit.CostTypeCategory, vSMFlatPriceRevenueSplit.CostType,
					CAST(CASE WHEN vSMWorkOrderScope.Price = 0 THEN 0 ELSE InvoiceDetailToAdd.Amount * vSMFlatPriceRevenueSplit.Amount / vSMWorkOrderScope.Price END AS numeric(12, 2)) InvoiceLineAmount,
					vSMFlatPriceRevenueSplit.Taxable, vSMFlatPriceRevenueSplit.GLCo, 
					CASE WHEN vSMWorkOrderScope.IsTrackingWIP = 'Y' AND vSMWorkOrderScope.IsComplete = 'N' THEN vSMFlatPriceRevenueSplit.RevenueWIPAccount ELSE vSMFlatPriceRevenueSplit.RevenueAccount END RevenueGLAccount,
					ROW_NUMBER() OVER(PARTITION BY InvoiceDetailToAdd.SMCo, InvoiceDetailToAdd.Invoice, InvoiceDetailToAdd.InvoiceDetail ORDER BY vSMFlatPriceRevenueSplit.Seq) RowNumber
				FROM @InvoiceDetailToAdd InvoiceDetailToAdd
					INNER JOIN dbo.vSMWorkOrderScope ON InvoiceDetailToAdd.SMCo = vSMWorkOrderScope.SMCo AND InvoiceDetailToAdd.WorkOrder = vSMWorkOrderScope.WorkOrder AND InvoiceDetailToAdd.Scope = vSMWorkOrderScope.Scope
					INNER JOIN dbo.vSMEntity ON vSMWorkOrderScope.SMCo = vSMEntity.SMCo AND vSMWorkOrderScope.WorkOrder = vSMEntity.WorkOrder AND vSMWorkOrderScope.Scope = vSMEntity.WorkOrderScope
					INNER JOIN dbo.vSMFlatPriceRevenueSplit ON vSMEntity.SMCo = vSMFlatPriceRevenueSplit.SMCo AND vSMEntity.EntitySeq = vSMFlatPriceRevenueSplit.EntitySeq
			)
			INSERT dbo.vSMInvoiceLine (SMCo, InvoiceLine, Invoiced, Invoice, InvoiceDetail, InvoiceDetailSeq, NoCharge, [Description], GLCo, GLAccount, Amount, TaxGroup, TaxCode, TaxBasis, TaxAmount)
			SELECT SMCo, ISNULL((SELECT MAX(InvoiceLine) FROM dbo.vSMInvoiceLine WHERE SMCo = vSMInvoiceLine.SMCo), 0) + ROW_NUMBER() OVER (ORDER BY InvoiceDetail),
				0 Invoiced, Invoice, InvoiceDetail, InvoiceDetailSeq, 'N' NoCharge, AddFlatPriceLinesCTE.[Description],
				AddFlatPriceLinesCTE.GLCo, 
				RevenueGLAccount,
				CASE
					--Handle rounding
					WHEN RowNumber = 1 THEN InvoiceLineAmount + Amount - SUM(InvoiceLineAmount) OVER(PARTITION BY SMCo, Invoice, InvoiceDetail)
					ELSE InvoiceLineAmount
				END,
				CASE WHEN Taxable = 'Y' THEN TaxGroup END, CASE WHEN Taxable = 'Y' THEN TaxCode END, 0 TaxBasis, 0 TaxAmount
			FROM AddFlatPriceLinesCTE
				CROSS APPLY dbo.vfSMGetAccountingTreatment(SMCo, WorkOrder, Scope, CostTypeCategory, CostType)

			--Update taxes
			UPDATE vSMInvoiceLine
			SET TaxBasis = vSMInvoiceLine.Amount, TaxAmount = vSMInvoiceLine.Amount * TaxRate
			FROM @InvoiceDetailToAdd InvoiceDetailToAdd
				INNER JOIN dbo.vSMInvoiceLine ON InvoiceDetailToAdd.SMCo = vSMInvoiceLine.SMCo AND InvoiceDetailToAdd.Invoice = vSMInvoiceLine.Invoice AND InvoiceDetailToAdd.InvoiceDetail = vSMInvoiceLine.InvoiceDetail
			WHERE InvoiceDetailToAdd.Scope IS NOT NULL AND vSMInvoiceLine.TaxCode IS NOT NULL

			COMMIT TRAN
		END TRY
		BEGIN CATCH
			ROLLBACK TRAN
			SET @msg = ERROR_MESSAGE()
			RETURN 1
		END CATCH
	END

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMInvoiceUpdateDetail] TO [public]
GO
