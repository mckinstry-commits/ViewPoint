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
 
 CREATE PROCEDURE [dbo].MCKspGetDetailedProgressInvoices
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
	Modified:		11.22.2017
	Author:			Leo Gurdian
	11/08/2017 - L.Gurdian - Make BillMonth and SortBy optional
	11/21/2017 - L.Gurdian - Add Customer number from JCCM
	11/22/2017 - L.Gurdian - fix Sort by issue when Invoice is Alphanumeric
*/

 Begin

 	SET NOCOUNT ON;

	SELECT JBIN.JBCo --
	 , JBIS.Item As ItemJBIS
	 , JCCM.Description As DescriptionJCCM ---
	 , JBIN.BillMonth --
	 , {fn IFNULL(JBIN.Invoice,' ' )} As InvoiceJBIN --
	 , JCCM.Customer	 
	 , JBIS.BillNumber As BillNumberJBIS
	 , JBIS.CurrContract ---
	 , JBIS.ChgOrderAmt ---
	 , JBIS.UnitsBilled
	 , JBIS.PrevSM --
	 , JBIS.SM --
	 , JBIS.AmtBilled --
	 , JBIS.PrevAmt  --
	 , JCCI.Item As ItemJCCI ---
	 , JBIN.PrevAmt As PrevAmtJBIN
	 , JBIN.InvRetg --
	 , JBIN.PrevRetg As PrevRetgJBIN --
	 , JBIN.InvTotal --
	 , JBIN.InvDue --
	 , ARCM.Name --
	 , JBIN.BillAddress --
	 , JBIN.BillCity -- 
	 , JBIN.BillState --
	 , JBIN.BillZip --
	 , JCCM.Contract --
	 , JBIN.InvDate --
	 , JBIN.Application --
	 , JBIN.BillNumber As BillNumberJBIN
	 , JBIN.PrevDue --
	 , JBIN.PrevTax
	 , JBIN.PrevRRel --
	 , JBIN.RetgRel As RetgRelJBIN --
	 , JBBG.Description As DescriptionJBBG
	 , JBIN.InvTax --
	 , JCCI.BillGroup
	 , JBIN.BillAddress2 --
	 , JCCM.CustomerReference ---
	 , JBIN.DueDate	---
	 , HQPT.Description As DescriptionHQPT --
	 , JBIN.ProcessGroup 
	 , JBIN.RetgTax As RetgTaxJBIN --
	 , JBIN.PrevRetgTax As PrevRetgTaxJBIN --
	 , JBIN.RetgTaxRel As RetgTaxRelJBIN --
	 , JBIN.PrevRetgTaxRel As PrevRetgTaxRelJBIN --
	 , JBIS.Description As DescriptionJBIS ---
	 , JBIN.FromDate --
	 , JBIN.ToDate	--
	 , JBIS.WCRetg --
	 , JBIS.RetgBilled --
	 , JBIS.RetgRel As RetgRelJBIS --
	 , JBIS.PrevRetg As PrevRetgJBIS --
	 , JBIS.PrevRetgReleased --
	 , JBIS.RetgTax As RetgTaxJBIS --
	 , JBIS.PrevRetgTax As PrevRetgTaxJBIS --
	 , JBIS.RetgTaxRel As RetgTaxRelJBIS --
	 , JBIS.PrevRetgTaxRel As PrevRetgTaxRelJBIS --
	 , HQCO.FedTaxId
	 --, {fn IFNULL(JBIN.Invoice,' ' )} As InvoiceJBIN
	 , JCCM.BillNotes
	 , JBIN.Notes As NotesJBIN
	 , JCCI.Notes As NotesJCCI
	 , JBIT.Notes As NotesJBIT
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
				LEFT OUTER JOIN Viewpoint.dbo.JBBG JBBG 
					ON JCCI.JCCo=JBBG.JBCo 
					AND JCCI.Contract=JBBG.Contract 
					AND JCCI.BillGroup=JBBG.BillGroup 
				LEFT OUTER JOIN Viewpoint.dbo.JBIT JBIT 
					ON JBIS.JBCo=JBIT.JBCo 
					AND JBIS.BillMonth=JBIT.BillMonth 
					AND JBIS.BillNumber=JBIT.BillNumber 
					AND JBIS.Item=JBIT.Item 
				LEFT OUTER JOIN Viewpoint.dbo.JBIN JBIN 
					ON JBIS.JBCo=JBIN.JBCo 
					AND JBIS.BillMonth=JBIN.BillMonth 
					AND JBIS.BillNumber=JBIN.BillNumber 
				LEFT OUTER JOIN Viewpoint.dbo.ARCM ARCM 
					ON JBIN.CustGroup=ARCM.CustGroup 
					AND JBIN.Customer=ARCM.Customer 
				LEFT OUTER JOIN Viewpoint.dbo.HQPT HQPT 
					ON JBIN.PayTerms=HQPT.PayTerms
	 WHERE  JBIN.JBCo=@co
	 			 AND 
			 (	
				RTRIM(LTRIM(ISNULL(JBIN.Invoice,' '))) >= @InvoiceFrom -- '10008231' -- start invoice
				AND 
				RTRIM(LTRIM(ISNULL(JBIN.Invoice,' '))) <= @InvoiceTo   -- '10008231' -- end invoice
			 )
			 AND 
			 (
				JBIN.BillMonth >= ISNULL (@DateFrom, JBIN.BillMonth) 
				AND
				JBIN.BillMonth >= ISNULL (@DateTo, JBIN.BillMonth) 
			 )
			 --AND JBIN.BillNumber BETWEEN 
				--	IIF(ISNULL(JBIN.BillNumber,0) > 0,JBIN.BillNumber,0) -- start bill number
				--	AND 
				--	IIF(ISNULL(JBIN.BillNumber,0) > 0,JBIN.BillNumber,0) -- ending bill number
			--AND RTRIM(LTRIM(JCCM.Contract)) like '10175-'
	 ORDER BY JBIN.JBCo, ItemJBIS, Case When @SortBy = 'I' Then 5 Else 7 End;
	 
	SET NOCOUNT OFF;

 End
 

Grant EXECUTE ON dbo.MCKspGetDetailedProgressInvoices TO [MCKINSTRY\Viewpoint Users]


--select JBIN.Invoice from  Viewpoint.dbo.JBIN 
  --10026165

 