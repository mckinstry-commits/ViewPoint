SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/*

	Purpose: For Canada Multi-Level tax processing, Calculate the posted GST for each line on the invoice.
	
	
	This view will calculate the GST tax for each line on the an invoice.  It 
	will be joined with view --brvAPTax so the tax can be reported. -AR don't remove the -- for it screws up refreshviews
		
	Maintenance Log
	Issue	Date		Coder		Description
	129452 	05/05/2011	C Wirtz		New
	
*/

CREATE   VIEW [dbo].[brvAPTaxGST]        

      
   AS  
	SELECT    APCo,Mth,APTrans,APLine ,Sum(GSTtaxAmt)as GSTtaxAmtPRDT,sum(TotTaxAmount)AS TotTaxAmountPRDT 
	FROM APTD
	GROUP BY APCo,Mth,APTrans,APLine




GO
GRANT SELECT ON  [dbo].[brvAPTaxGST] TO [public]
GRANT INSERT ON  [dbo].[brvAPTaxGST] TO [public]
GRANT DELETE ON  [dbo].[brvAPTaxGST] TO [public]
GRANT UPDATE ON  [dbo].[brvAPTaxGST] TO [public]
GO
