SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [dbo].[vrptSMInvoice]	@SessionId			INT				= 0,			-- Used to preview invoices from a billing session
										@Company			INT				= 0,			-- Invoice Numbers are company specific
										@SMInvoiceNumber	INT				= 0,			-- Used to reprint an invoice if needed
										@InvoiceBeginDate	SMALLDATETIME	= '1950-1-1',	-- Starting Date Range 
										@InvoiceEndDate		SMALLDATETIME	= '2050-12-31',	-- Ending Date Range

										-- These group parameters are included to allow users to select 
										-- additional group options at the report runtime.
										@Group1				VARCHAR(5)	= '',
										@Group2				VARCHAR(5)	= '',
										@Group3				VARCHAR(5)	= '',
										@Group4				VARCHAR(5)	= '',
										@Group5				VARCHAR(5)	= '' 

AS
/***********************************************************************
*	Created: 2/3/2011
*	Author : DK
*	Purpose: At the time of writing, this procedure was required because
*			Crystal Reports XI experienced recurring issues with a series
*			of static groupings when paired with a wide collection of 
*			dynamic groupings. The end result was an unstable report that
*			ran inconsistently. The solution was to push the majority of
*			work out of crystal and into a procedure.
*
*	Reports: SMInvoice.rpt
*
*	Test Statements: 
*		EXEC dbo.vrptSMInvoice NULL,1,0,'1950-1-1','2050-12-31',1,3,'','',''
*		EXEC dbo.vrptSMInvoice NULL,0,'2011-1-1','2011-1-15',1,3,'','',''
*
*	Revision History    
*	Date  Author  Issue     Description
*	2/21/11 - DK - Changes	: Added NoCharge from SMWorkCompleted 
*
*   04/12/2012	ScottAlvey	CL-????? / V1-B-08702: SM - Edit Taxes on SM Invoice
*   All the AR fields were removed from SMWorkCompleted and put into SMWorkCompletedARTL
*   This proc uses AR fields for some calculations. I joined in SMWorkCompletedARTL
*   (aliased as SMAR) to SMWorkCompleted (aliased as SMWC) and then changed all references 
*   of the AR fields from SMCW.FieldName to SMAR.FieldName
***********************************************************************/

 -- Handling NULLS up front helps to improve performance by not re-evaluating functions in the where clause. 
SET @SessionId			= ISNULL(@SessionId,0)
SET	@SMInvoiceNumber	= ISNULL(@SMInvoiceNumber,0)
SET @InvoiceBeginDate	= ISNULL(@InvoiceBeginDate,'1950-1-1')
SET @InvoiceEndDate		= ISNULL(@InvoiceEndDate,'2050-12-31')

SELECT
										-- these groups are used for dynamic grouping in crystal. 
										-- converts were required or the procedure errored out when trying to set 
										-- the width of the column to the smallest potential data type 
			Group1					= CASE
										WHEN @Group1 = '1' THEN CONVERT(VARCHAR(20),SMIL.ServiceSite)
										WHEN @Group1 = '2' THEN CONVERT(VARCHAR(20),SMWS.CallType)
										WHEN @Group1 = '3' THEN CONVERT(VARCHAR(20),SMWC.Technician)
										WHEN @Group1 = '4' THEN CONVERT(VARCHAR(20),SMWC.Type)
										WHEN @Group1 = '5' THEN CONVERT(VARCHAR(20),SMWC.Equipment)
										WHEN @Group1 = '6' THEN SMWC.Part
										WHEN @Group1 = '7' THEN CONVERT(VARCHAR(20),SMWC.Scope)
										ELSE ''
										END,
			Group2					= CASE
										WHEN @Group2 = '1' THEN CONVERT(VARCHAR(20),SMIL.ServiceSite)
										WHEN @Group2 = '2' THEN CONVERT(VARCHAR(20),SMWS.CallType)
										WHEN @Group2 = '3' THEN CONVERT(VARCHAR(20),SMWC.Technician)
										WHEN @Group2 = '4' THEN CONVERT(VARCHAR(20),SMWC.Type)
										WHEN @Group2 = '5' THEN CONVERT(VARCHAR(20),SMWC.Equipment)
										WHEN @Group2 = '6' THEN SMWC.Part
										WHEN @Group2 = '7' THEN CONVERT(VARCHAR(20),SMWC.Scope)
										ELSE ''
										END,
			Group3					= CASE
										WHEN @Group3 = '1' THEN CONVERT(VARCHAR(20),SMIL.ServiceSite)
										WHEN @Group3 = '2' THEN CONVERT(VARCHAR(20),SMWS.CallType)
										WHEN @Group3 = '3' THEN CONVERT(VARCHAR(20),SMWC.Technician)
										WHEN @Group3 = '4' THEN CONVERT(VARCHAR(20),SMWC.Type)
										WHEN @Group3 = '5' THEN CONVERT(VARCHAR(20),SMWC.Equipment)
										WHEN @Group3 = '6' THEN SMWC.Part
										WHEN @Group3 = '7' THEN CONVERT(VARCHAR(20),SMWC.Scope)
										ELSE ''
										END,
			Group4					= CASE
										WHEN @Group4 = '1' THEN CONVERT(VARCHAR(20),SMIL.ServiceSite)
										WHEN @Group4 = '2' THEN CONVERT(VARCHAR(20),SMWS.CallType)
										WHEN @Group4 = '3' THEN CONVERT(VARCHAR(20),SMWC.Technician)
										WHEN @Group4 = '4' THEN CONVERT(VARCHAR(20),SMWC.Type)
										WHEN @Group4 = '5' THEN CONVERT(VARCHAR(20),SMWC.Equipment)
										WHEN @Group4 = '6' THEN SMWC.Part
										WHEN @Group4 = '7' THEN CONVERT(VARCHAR(20),SMWC.Scope)
										ELSE ''
										END,
			Group5					= CASE
										WHEN @Group5 = '1' THEN CONVERT(VARCHAR(20),SMIL.ServiceSite)
										WHEN @Group5 = '2' THEN CONVERT(VARCHAR(20),SMWS.CallType)
										WHEN @Group5 = '3' THEN CONVERT(VARCHAR(20),SMWC.Technician)
										WHEN @Group5 = '4' THEN CONVERT(VARCHAR(20),SMWC.Type)
										WHEN @Group5 = '5' THEN CONVERT(VARCHAR(20),SMWC.Equipment)
										WHEN @Group5 = '6' THEN SMWC.Part
										WHEN @Group5 = '7' THEN CONVERT(VARCHAR(20),SMWC.Scope)
										ELSE ''
										END,
			SMIL.SMSessionID		AS SMSessionID,
			SMI.SMInvoiceID			AS SMInvoiceID,
			HQPT.Description		AS PayTermsDescr,
			SMI.DueDate				AS DueDate,
			SMI.DiscDate			AS DiscountDate,
			SMI.DiscRate			AS DiscountRate,
			ARCO.DiscTax			AS ARDiscTax,
			SMI.SMCo				AS SMCo,	
			SMI.CustGroup			AS SMCustGroup,
			SMI.BillToARCustomer	AS BillToCustomer,
			ARCM.Name				AS BillToName,
			ARCM.Address			AS BillToAddress1,
			ARCM.Address2			AS BillToAddress2,
			ARCM.City				AS BillToCity,
			ARCM.State				AS BillToState,
			ARCM.Zip				AS BillToZip,
			ARCM.Country			AS BillToCountry,
			SMI.Invoice				AS Invoice,
			SMI.InvoiceDate			AS InvoiceDate,
			SMI.Invoiced			AS Invoiced,
			SMI.BatchMonth			AS InvoiceBatchMonth,
			HQ.HQCo					AS HQCo,
			HQ.Name					AS HQName,
			HQ.Address				AS HQAddress,
			HQ.Address2				AS HQAddress2,
			HQ.City					AS HQCity,
			HQ.State				AS HQState,
			HQ.Zip					AS HQZip,
			SMIL.WorkOrder			AS WorkOrder,
			SMWO.Description		AS WorkOrderDescription,
			SMIL.TotalBilled		AS WOTotalBilled,
			SMIL.TotalTaxed			AS WOTotalTaxed,
			SMIL.TotalAmount		AS WOTotalAmount,
			SMIL.CustGroup			AS InvoiceCustGroup,
			SMIL.Customer			AS InvoiceCustomer, 
			SMIL.ServiceSite		AS ServiceSite,
			SMSS.Description		AS ServiceSiteDescription,
			SMSS.Address1			AS ServiceSiteAddress1,
			SMSS.Address2			AS ServiceSiteAddres2,
			SMSS.City				AS ServiceSiteCity,
			SMSS.State				AS ServiceSiteState,
			SMSS.Zip				AS ServiceSiteZip,
			SMSS.Country			AS ServiceSiteCountry,
			SMWC.Type				AS WorkCompletedType,
			TypeDescription			= CASE
										WHEN SMWC.Type = 1 THEN 'Equipment'
										WHEN SMWC.Type = 2 THEN 'Labor'
										WHEN SMWC.Type = 3 THEN 'Misc'
										WHEN SMWC.Type = 4 THEN 'Part'
										ELSE ''
									  END,
			SMWC.WorkCompleted		AS WorkCompletedLineNumber,
			SMWC.Description		AS WorkCompletedDescription,
			SMAR.ARCo				AS ARCo,
--			SMAR.ARBatchId			AS ARBatchID,
			SMAR.Mth				AS ARPostedMonth,
			SMAR.ARTrans			AS ARTrans,
			SMWC.SMWorkCompletedID	AS WorkCompletedID,
			SMWC.SMCo				AS WOScopeSMCo,
			SMWC.WorkOrder			AS ScopeWO,
			SMWC.Scope				AS Scope,
			SMWC.Date				AS WorkCompletedDate,
			SMWC.ServiceItem		AS ServiceItem,
			SMWC.TaxType			AS TaxType,
			SMWC.TaxGroup			AS TaxGroup,
			SMWC.TaxCode			AS TaxCode,
			SMWC.TaxBasis			AS TaxBasis,
			SMWC.TaxAmount			AS TaxAmount,
			SMWC.Quantity			AS Quantity,
			SMWC.CostQuantity		AS CostQuantity,
			SMWC.CostRate			AS CostRate,
			SMWC.CostTotal			AS CostTotal,
			SMWC.PriceQuantity		AS PriceQuantity,
			SMWC.PriceRate			AS PriceRate,
			SMWC.PriceTotal			AS PriceTotal,
			SMWC.NoCharge			AS NoCharge,
			SMWC.Technician			AS TechnicianID,
			SMTI.FullName			AS TechnicianFullName,
			SMWC.EMCo				AS EMCo,
			SMWC.Equipment			AS Equipment,
			SMWC.Description		AS EquipDesc,
			SMWC.EMGroup			AS EMGroup,
			SMWC.RevCode			AS RevCode,
			SMWC.PayType			AS PayType,
			SMWC.StandardItem		AS StandardItem,
			SMWC.INCo				AS INCo,
			SMWC.INLocation			AS INLocation,
			SMWC.POCo				AS POCo,
			SMWC.PONumber			AS PONumber,
			SMWC.POItem				AS POItem,
			SMWC.MatlGroup			AS MatlGroup,
			SMWC.Part				AS Part,
			HQMT.Description		AS PartDescription,
			SMWC.UM					AS UM,
			CASE
				WHEN	SMWC.Type = 4 THEN SMWC.PriceUM
				WHEN	SMWC.Type = 1 THEN 
					CASE 
						WHEN	EMRC.Basis = 'H' THEN EMRC.TimeUM 
						ELSE	EMRC.WorkUM 
					END
				WHEN	SMWC.Type = 2 THEN 'HR'
				ELSE 'EA'
			END						AS PriceUM,
			--SMWC.POPostedMth		AS POPostedMth,
			--SMWC.POTrans			AS POTrans,
			EMRC.Description		AS EMDescription,		
			EMRC.Basis				AS EMBasis,
			EMRC.HaulBased			AS HaulBased
			
 
FROM		SMInvoice			SMI
LEFT JOIN	HQCO				HQ
		ON	HQ.HQCo = SMI.SMCo
LEFT JOIN	HQPT
		ON	HQPT.PayTerms		= SMI.PayTerms
INNER JOIN	SMInvoiceList		SMIL
		ON	SMIL.SMInvoiceID	= SMI.SMInvoiceID
		AND	SMIL.SMCo			= SMI.SMCo
LEFT JOIN	SMServiceSite		SMSS                                      
		ON	SMSS.ServiceSite	= SMIL.ServiceSite
		AND	SMSS.SMCo			= SMI.SMCo
LEFT JOIN	SMWorkCompleted		SMWC
		ON	SMWC.SMCo			= SMI.SMCo
LEFT JOIN	SMWorkCompletedARTL SMAR 
		ON	SMWC.SMWorkCompletedARTLID = SMAR.SMWorkCompletedARTLID
		AND	SMWC.SMInvoiceID	= SMI.SMInvoiceID
LEFT JOIN	SMWorkOrder			SMWO
		ON	SMWO.WorkOrder		= SMWC.WorkOrder
		AND	SMWO.SMCo			= SMWC.SMCo
LEFT JOIN	SMWorkOrderScope	SMWS
		ON	SMWS.SMCo			= SMI.SMCo
		AND	SMWS.WorkOrder	= SMWC.WorkOrder
		AND SMWS.Scope			= SMWC.Scope
LEFT JOIN	EMEM
		ON	EMEM.EMCo			= SMWC.EMCo
		AND	EMEM.Equipment		= SMWC.Equipment
LEFT JOIN	EMRC 
		ON	EMRC.EMGroup		= SMWC.EMGroup 
		AND EMRC.RevCode		= SMWC.RevCode
LEFT JOIN	ARCO
		ON	ARCO.ARCo			= SMAR.ARCo
LEFT JOIN	ARCM
		ON	ARCM.CustGroup		= SMIL.BillToCustGroup
		AND ARCM.Customer		= SMIL.BillToARCustomer
LEFT JOIN	SMTechnicianInfo	SMTI
		ON	SMTI.SMCo			= SMI.SMCo
		AND SMTI.Technician		= SMWC.Technician
LEFT JOIN	HQMT
		ON	HQMT.MatlGroup		= SMWC.MatlGroup
		AND	HQMT.Material		= SMWC.Part

WHERE	SMI.SMCo = @Company
	AND (	@SessionId = SMIL.SMSessionID OR @SessionId = 0	)
	AND	(	@SMInvoiceNumber = SMI.Invoice OR @SMInvoiceNumber = 0)
	AND (		@InvoiceBeginDate <= SMI.InvoiceDate 	
			AND @InvoiceEndDate >= SMI.InvoiceDate		)




GO
GRANT EXECUTE ON  [dbo].[vrptSMInvoice] TO [public]
GO
