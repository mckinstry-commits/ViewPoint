SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[brvSLClaimTaxInvoice]
AS 

/*************************************************************************************************
* Author	: DanK
* Created	: 12/03/2012
* Issue		: TK-19957
*
* Useage	: SLClaimTaxInvoice
*				This view powers the SLClaimTaxInvoice report. It is intended to aggregate the claim 
*			details for easier reporting. It is to include a precalculated Invoice Due Date to reduce 
*			the need formula work in Crystal. 
*
*************************************************************************************************/


	SELECT			SLCH.SLCo				AS SLCo,
					SLCH.SL					AS ClaimSL,
					SLCH.ClaimNo			AS ClaimNo, 
					SLCH.Description		AS ClaimDescription,
					SLCH.ClaimDate			AS ClaimDate,
					SLCH.InvoiceDate		AS ClaimInvoiceDate,
					CASE DueOpt 
						-- 1: days until due. Add the given number of days until due to the invoice date. 
						WHEN 1 THEN	DATEADD(D, HQPT.DaysTillDue, SLCH.InvoiceDate)
						-- 2: set day due. 
						WHEN 2 THEN 
							CASE 
								WHEN DAY(SLCH.InvoiceDate) >= DueDay 
									-- Concatenate a date string and then add 1 month to it 
									THEN DATEADD(M, 1, CONVERT(VARCHAR(10), CONVERT(VARCHAR(2), MONTH(SLCH.InvoiceDate)) + '/' + CONVERT(VARCHAR(2), DueDay) + '/' + CONVERT(VARCHAR(4), YEAR(SLCH.InvoiceDate)), 121))
								WHEN DAY(SLCH.InvoiceDate) < DueDay
									THEN CONVERT(VARCHAR(10), CONVERT(VARCHAR(2), MONTH(SLCH.InvoiceDate)) + '/' + CONVERT(VARCHAR(2), DueDay) + '/' + CONVERT(VARCHAR(4), YEAR(SLCH.InvoiceDate)), 121)
							END 
						-- 3: Due Upon Receipt
						WHEN 3 THEN		SLCH.InvoiceDate
						ELSE			SLCH.InvoiceDate
					END						AS ClaimInvoiceDueDate,
					SLCH.APRef				AS ClaimInvoice,
					SLCH.InvoiceDesc		AS ClaimInvoiceDesc,
					SLCI.SLItem				AS ClaimItem,
					SLCI.Description		AS ClaimItemDescription, 
					SLCI.ApproveAmount	+ PT.PrevApproveAmt	AS CLaimItemToDateAmount,
					SLCI.ApproveAmount		AS ClaimItemApproveAmount,
					SLCI.TaxAmount			AS ClaimItemTaxAmount,
					SLCI.ApproveRetention	AS ClaimItemApproveRetention,
					SLCI.ApproveUnits		AS ClaimItemApproveUnits,
					PT.PrevApproveAmt		AS ClaimItemPreviousApprovedAmt, 
					PT.PrevApproveRet		AS ClaimItemPreviousApprovedRet,
					PT.PrevClaimAmt			AS ClaimItemPreviousApprovedClaimAmt,
					
					-- PayTerms order of Preference: 1. SLHD; 2. APVM; 3. Default to Upon Receipt
					CASE ISNULL(SLHD.PayTerms, '') 
						WHEN '' THEN CASE ISNULL(APVM.PayTerms, '') 
										WHEN '' THEN 'Due Upon Receipt'
										ELSE APVM.PayTerms
									 END 
						ELSE SLHD.PayTerms
					END						AS PayTerms, 
					
					-- Vendor Specifics
					APVM.Vendor				AS VendorId,
					APVM.Name				AS VendorName,
					APVM.Address			AS VendorAddress, 
					APVM.Address2			AS VendorAddress2,
					APVM.City				AS VendorCity,
					APVM.State				AS VendorState, 
					APVM.Zip				AS VendorZip,
					APVM.AusBusNbr			AS VendorABN,
					APVM.AddnlInfo			AS AdditionalInfo,
					
					-- Company Specifics
					HQCO.Name				AS CompanyName, 
					HQCO.Address			AS CompanyAddress, 
					HQCO.Address2			AS CompanyAddress2, 
					HQCO.City				AS CompanyCity, 
					HQCO.State				AS CompanyState, 
					HQCO.Zip				AS CompanyZip,
					HQCO.FedTaxId			AS CompanyABN
		
		FROM		SLClaimHeader		SLCH 
		
		-- Claim Items
		INNER JOIN	SLClaimItem			SLCI
				ON	SLCI.SLCo				= SLCH.SLCo 
				AND SLCI.SL					= SLCH.SL
				AND SLCI.ClaimNo			= SLCH.ClaimNo
				AND SLCH.ClaimStatus		= 30			-- Only showing "Certified Claims" as they are the ones that will have GST Applied

		-- Subcontract Header
		INNER JOIN	SLHD				SLHD
				ON	SLHD.SLCo				= SLCH.SLCo 
				AND SLHD.SL					= SLCH.SL
		
		LEFT JOIN	HQPT				HQPT
				ON	HQPT.PayTerms			= SLHD.PayTerms 
		
		-- Vendor Details			
		INNER JOIN	APVM				APVM
				ON	SLHD.VendorGroup		= APVM.VendorGroup
				AND SLHD.Vendor				= APVM.Vendor
		
		-- Company Details 
		INNER JOIN	HQCO
				ON	SLCH.SLCo				= HQCO.HQCo
		
		-- SL Items to get the GST Rate
		LEFT JOIN	SLIT
				ON	SLIT.SLCo				= SLHD.SLCo
				AND SLIT.SL					= SLHD.SL
				AND SLIT.SLItem				= SLCI.SLItem
				
				
		OUTER APPLY vfSLClaimItemPriorTotals(	SLCH.SLCo, 
												SLCH.SL, 
												SLCH.ClaimNo, 
												SLCI.SLItem, 
												SLCH.ClaimDate) PT
GO
GRANT SELECT ON  [dbo].[brvSLClaimTaxInvoice] TO [public]
GRANT INSERT ON  [dbo].[brvSLClaimTaxInvoice] TO [public]
GRANT DELETE ON  [dbo].[brvSLClaimTaxInvoice] TO [public]
GRANT UPDATE ON  [dbo].[brvSLClaimTaxInvoice] TO [public]
GO
