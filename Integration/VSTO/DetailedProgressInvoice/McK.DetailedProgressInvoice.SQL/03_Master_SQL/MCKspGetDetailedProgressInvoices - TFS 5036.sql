USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKspGetDetailedProgressInvoices' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKspGetDetailedProgressInvoices'
	DROP PROCEDURE dbo.MCKspGetDetailedProgressInvoices
End
GO

Print 'CREATE PROCEDURE dbo.MCKspGetDetailedProgressInvoices'
GO
 
 CREATE PROCEDURE [dbo].[MCKspGetDetailedProgressInvoices]
 (
	@co bCompany,
	@InvoiceFrom varchar(10),
	@InvoiceTo varchar(10),
	@DateFrom bMonth	=null,
	@DateTo bMonth		=null,
	@SortBy varchar(1)		=null
 )
 AS
 /* 
	Purpose:			Retrieve JB Detailed Progress Invoices 
	Logging:			mspLogDetailInvoiceAction, mckDetailInvoiceLog
	Viewpoint:		JBIN, JBIS, JCCM, ARCM, JCCI, HQPT, HQCO, JBIT, JBBG
	Created:			10.06.2017
	Author:			Leo Gurdian

	09.11.19 - TFS 5036 - return % complete value and CurrContract from JBIS - Leo Gurdian
	09.04.19 - TFS 5036 - breakdown retention so subtotal add correctly
	08.26.19 - Correct Current Contract Amt to include Change Orders - Leo Gurdian
	04.12.18	- Added Released Retention (RetgRelJBIS) and tax (TaxAmtJBIT) to breakdown contract item sub-invoice
	11.22.17 - Fix Sort by issue when Invoice is Alphanumeric - L.Gurdian
	11.21.17 - Add Customer number from JCCM - L.Gurdian
	11.08.17 - Make BillMonth and SortBy optional - L.Gurdian
*/

 Begin

 	SET NOCOUNT ON;
	
	SELECT DISTINCT JBIN.JBCo 
	 , JBIS.Item As ItemJBIS
	 , JCCM.Description As DescriptionJCCM -- contract description
	 , JBIN.BillMonth 
	 , ISNULL(JBIN.Invoice,'' ) As InvoiceJBIN 
	 , JBIN.InvDescription
	 , JCCM.Customer  
	 , JBIS.BillNumber As BillNumberJBIS
	 --, JCCI.ContractAmt AS CurrContract
	 --, JCCM.ContractAmt  AS CurrContract 
	 , JBIS.CurrContract CurrContract -- what is in PROD as of 9.10.19
	 --, JBITProgGrid.CurrContract + JBIS.ChgOrderAmt AS CurrContract -- considers change orders
	 , JBIS.ChgOrderAmt 
	 , JBIS.PrevSM 
	 , JBIS.SM

	 --TotalComplToDate
	 , JBIS.AmtBilled 
	 , JBIS.PrevAmt  

	 , JCCI.Item As ItemJCCI 
	 , JBIN.PrevAmt As PrevAmtJBIN 
	 --, JBIS.InvRetg --TFS 5036 instead of JBIN.InvRetg (total), use retanaige breakdown (RetgBilled)
	 , JBIN.PrevRetg As PrevRetgJBIN 
	 , JBIN.InvTotal 
	 , JBIN.InvDue 
	 , ARCM.Name 
	 , JBIN.BillAddress 
	 , JBIN.BillCity  
	 , JBIN.BillState 
	 , JBIN.BillZip 
	 , JCCM.Contract 
	 , JBIN.InvDate 
	 , JBIN.Application 
	 , JBIN.BillNumber As BillNumberJBIN
	 , JBIN.PrevDue 
	 , JBIN.PrevTax
	 , JBIN.PrevRRel 
	 , JBIN.RetgRel As RetgRelJBIN 
	 --, JBBG.Description As DescriptionJBBG
	 , JBIN.InvTax 
	 , (SELECT TOP 1 CAST(ROUND(JBITProgGrid.PctComplete, 5,1)  AS DECIMAL(12,4)) FROM JBITProgGrid WHERE BillNumber = JBIN.BillNumber AND Contract = JBIN.Contract AND BillMonth = JBIN.BillMonth AND Item = JCCI.Item) AS PctComplete
	 , JBIT.TaxAmount  As TaxAmtJBIT 
	 , JCCI.BillGroup
	 , JBIN.BillAddress2 
	 , JCCM.CustomerReference 
	 , JBIN.DueDate	
	 , HQPT.Description As DescriptionHQPT 
	 , JBIN.ProcessGroup 
	 , JBIN.RetgTax As RetgTaxJBIN 
	 , JBIN.PrevRetgTax As PrevRetgTaxJBIN 
	 , JBIN.RetgTaxRel As RetgTaxRelJBIN 
	 , JBIN.PrevRetgTaxRel As PrevRetgTaxRelJBIN 
	 , JBIS.Description As DescriptionJBIS 
	 , JBIN.FromDate 
	 , JBIN.ToDate	
	 , JBIS.WCRetg 
	 , JBIS.RetgBilled --TFS 5036 instead of JBIN.InvRetg (total), use retanaige breakdown (RetgBilled)
	 , JBIS.RetgRel As RetgRelJBIS 
	 , JBIS.PrevRetg As PrevRetgJBIS 
	 , JBIS.PrevRetgReleased 
	 , JBIS.RetgTax As RetgTaxJBIS 
	 , JBIS.PrevRetgTax As PrevRetgTaxJBIS 
	 , JBIS.RetgTaxRel As RetgTaxRelJBIS 
	 , JBIS.PrevRetgTaxRel As PrevRetgTaxRelJBIS 
	 , HQCO.FedTaxId 
	 , JCCM.BillNotes 
	 -- these below no longer needed on next VSTO code release 9.10.19
	 --, JBIN.Notes As NotesJBIN 
	 --, JCCI.Notes As NotesJCCI 
	 --, JBIT.Notes As NotesJBIT 
	 FROM   Viewpoint.dbo.HQCO HQCO 
			  INNER JOIN Viewpoint.dbo.JCCM JCCM 
					ON HQCO.HQCo=JCCM.JCCo 
				LEFT OUTER JOIN Viewpoint.dbo.JCCI JCCI 
					ON JCCM.JCCo=JCCI.JCCo 
					AND JCCM.Contract=JCCI.Contract 
				LEFT OUTER JOIN Viewpoint.dbo.JBIS JBIS 
					ON JCCI.JCCo=JBIS.JBCo 
					AND JCCI.Item=JBIS.Item 
					AND JCCI.Contract=JBIS.Contract 
				--LEFT OUTER JOIN Viewpoint.dbo.JBBG JBBG 
				--	ON JCCI.JCCo=JBBG.JBCo 
				--	AND JCCI.Contract=JBBG.Contract 
				--	AND JCCI.BillGroup=JBBG.BillGroup 
				LEFT OUTER JOIN Viewpoint.dbo.JBIT JBIT 
					ON JBIS.JBCo=JBIT.JBCo 
					AND JBIS.BillMonth=JBIT.BillMonth 
					AND JBIS.BillNumber=JBIT.BillNumber 
					AND JBIS.Item=JBIT.Item 
				LEFT OUTER JOIN Viewpoint.dbo.JBIN JBIN 
					ON JBIS.JBCo=JBIN.JBCo 
					AND JBIS.BillMonth=JBIN.BillMonth 
					AND JBIS.BillNumber=JBIN.BillNumber 
				LEFT OUTER JOIN Viewpoint.dbo.JBITProgGrid JBITProgGrid  ON
					JBITProgGrid.BillNumber = JBIN.BillNumber and
					JBITProgGrid.Contract = JBIN.Contract AND
					JBITProgGrid.BillMonth = JBIN.BillMonth	
				LEFT OUTER JOIN Viewpoint.dbo.ARCM ARCM 
					ON JBIN.CustGroup=ARCM.CustGroup 
					AND JBIN.Customer=ARCM.Customer 
				LEFT OUTER JOIN Viewpoint.dbo.HQPT HQPT 
					ON JBIN.PayTerms=HQPT.PayTerms
	 WHERE  JBIN.JBCo=@co
	 			 AND 
			 (	
				RTRIM(LTRIM(ISNULL(JBIN.Invoice,' '))) >= RTRIM(LTRIM(ISNULL(@InvoiceFrom,' '))) -- '10008231'  start invoice
				AND 
				RTRIM(LTRIM(ISNULL(JBIN.Invoice,' '))) <= RTRIM(LTRIM(ISNULL(@InvoiceTo,' ')))   --- '10008231'  end invoice
			 )
			 AND 
			 (
				JBIN.BillMonth >= ISNULL (@DateFrom, JBIN.BillMonth) 
				AND
				JBIN.BillMonth >= ISNULL (@DateTo, JBIN.BillMonth) 
			 )
			-- AND JBIN.BillNumber BETWEEN 
			--		IIF(ISNULL(JBIN.BillNumber,0) > 0,JBIN.BillNumber,0) --  start bill number
			--		AND 
			--		IIF(ISNULL(JBIN.BillNumber,0) > 0,JBIN.BillNumber,0) -- ending bill number
			--AND RTRIM(LTRIM(JCCM.Contract)) like '10175-'
	 --ORDER BY JBIN.JBCo, ItemJBIS, Case When @SortBy = 'I' Then 5 Else 7 End;
GROUP BY	
		JBIN.JBCo 
	 , JBIS.Item 
	 , JCCM.Description
	 , JBIN.BillMonth 
	 , JBIN.Invoice
	 , JBIN.InvDescription
	 , JCCM.Customer  
	 , JBIS.BillNumber
	 , JBIS.CurrContract
	 , JBIS.ChgOrderAmt 
	 , JBIS.PrevSM 
	 , JBIS.SM 
	 , JBIS.AmtBilled 
	 , JBIS.PrevAmt  
	 , JCCI.Item 
	 , JBIN.PrevAmt 
	 , JBIS.RetgBilled
	 , JBIN.PrevRetg
	 , JBIN.InvTotal 
	 , JBIN.InvDue 
	 , ARCM.Name 
	 , JBIN.BillAddress 
	 , JBIN.BillCity  
	 , JBIN.BillState 
	 , JBIN.BillZip 
	 , JCCM.Contract 
	 , JBIN.InvDate 
	 , JBIN.Application 
	 , JBIN.BillNumber 
	 , JBIN.PrevDue 
	 , JBIN.PrevTax
	 , JBIN.PrevRRel 
	 , JBIN.RetgRel 
	 , JBIN.InvTax 
	 , JBIT.TaxAmount  
	 , JCCI.BillGroup
	 , JBIN.BillAddress2 
	 , JCCM.CustomerReference 
	 , JBIN.DueDate	
	 , HQPT.Description 
	 , JBIN.ProcessGroup 
	 , JBIN.RetgTax 
	 , JBIN.PrevRetgTax
	 , JBIN.RetgTaxRel 
	 , JBIN.PrevRetgTaxRel
	 , JBIS.Description 
	 , JBIN.FromDate 
	 , JBIN.ToDate	
	 , JBIS.WCRetg 
	 , JBIS.RetgBilled 
	 , JBIS.RetgRel 
	 , JBIS.PrevRetg
	 , JBIS.PrevRetgReleased 
	 , JBIS.RetgTax 
	 , JBIS.PrevRetgTax 
	 , JBIS.RetgTaxRel 
	 , JBIS.PrevRetgTaxRel 
	 , HQCO.FedTaxId 
	 , JCCM.BillNotes 
	 , JBIN.Contract
 End

GO
 

Grant EXECUTE ON dbo.MCKspGetDetailedProgressInvoices TO [MCKINSTRY\Viewpoint Users]