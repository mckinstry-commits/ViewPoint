SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View [dbo].[vrvJBProgressBills]

/********
  Created:  10/20/10 DH
  Usage:  View selects JB measures for use in JB Progress Billing reports.  
		  Returns one row per JBCo/BillMonth/BillNumber/Contract Item.
		  
   Non-calculated view columns definitions:  All amounts stored in bJBIS table.
   
           
        Work Complete:  Work Complete from JB Progress Billing program.  
        Stored Material:  Net Invoice Stored Material (SM) from JB Progress Billing.  Previous SM for StoredMaterial_Previous.
        Amount Billed:  Amount Billed.  Includes retainage, excludes tax.  AmountBilled_Previous = Previous Amount from JB Progress Billing.
        Tax Amount:  From Tax Amount columns in JBIS (excludes Retainage Tax).  
        Amount Due:  Amount Billed + Tax Amount + Retainage Tax - Retainage.  
        
   Calculated view columns:  Logic uses existing values stored in bJBIS.
   
		Current Contract Dollars:  Current Contract + Change Orders on This Bill. 
		Retainage:  Retainage on this bill less retainage tax (tax on retainage).  Also subtract any retainage released on this bill.
	
	Modified Date:  08/09/2013  Sean O'Halloran		Added Joins to HQTX and JBIN.  Added RetainageReleased_ThisBill, RelRetainage_PlusTax
													TaxRate and appropriate groupings.  TFS 43633 - 'RPT - (AUS) JB Progress Payment Claim 
													report retention GST tax not displaying'.  Code reviewed by Huy Huynh.
        

**********/
  

as

Select	  JBIS.JBCo
		, JBIS.BillMonth
		, JBIS.BillNumber
		, JBIS.Contract
		, JBIS.Item
		/*Used to group variation type contract items for Australian Claim reports*/
		, case when max(OrigContractAmt) <> 0 then 0 else 1 end as AUS_VariationIndicator 
		, sum(JBIS.CurrContract+JBIS.ChgOrderAmt) as CurrentContractDollars
		, sum(JBIS.PrevWC) as WorkComplete_Previous
		, sum(JBIS.WC) as WorkComplete_ThisBill
		, sum(JBIS.PrevSM) as StoredMaterial_Previous
		, sum(JBIS.SM) as StoredMaterial_ThisBill
		, sum(JBIS.AmtBilled) as AmountBilled_ThisBill
		, sum(JBIS.PrevAmt) as AmountBilled_Previous
		, sum(JBIS.TaxAmount) as TaxAmount_ThisBill
		, sum(JBIS.PrevTax) as TaxAmount_Previous
		, sum(JBIS.AmountDue) as AmountDue_ThisBill
		, sum(JBIS.ContractUnits+JBIS.ChgOrderUnits) as CurrentContractUnits
		, sum(JBIS.PrevWCUnits) as Units_WorkComplete_Previous
		, sum(JBIS.WCUnits) as Units_WorkComplete_ThisBill
		, sum(JBIS.UnitsBilled) as Units_Billed_ThisBill
		, sum(JBIS.PrevUnits) as Units_Billed_Previous
		/*Retainage excludes tax and subtracts released retainage on bill*/
		, sum(JBIS.RetgRel) as RetainageReleased_ThisBill 
		, (sum(JBIS.RetgBilled - JBIS.RetgTax)) - (sum(JBIS.RetgRel - JBIS.RetgTaxRel)) as Retainage_ThisBill 
		, (sum(JBIS.PrevRetg - JBIS.PrevRetgTax)) - (sum(JBIS.PrevRetgReleased - JBIS.PrevRetgTaxRel)) as Retainage_Previous
		, JBIN.InvDate as InvoiceDate
		, case when JBIN.InvDate >= HQTX.EffectiveDate then
			HQTX.NewRate
			when JBIN.InvDate < HQTX.EffectiveDate then
			HQTX.OldRate
			else 0
			End as TaxRate
		, case when JBIN.InvDate >= HQTX.EffectiveDate and JBIS.AmtBilled <> 0 then
			(sum(JBIS.RetgRel) * HQTX.NewRate) + sum(JBIS.TaxAmount)
			when JBIN.InvDate < HQTX.EffectiveDate  and JBIS.AmtBilled <> 0 then
			(sum(JBIS.RetgRel) * HQTX.OldRate) + sum(JBIS.TaxAmount)
			-- case when we create an invoice only to release retension [no progress on contract]
			when JBIN.InvDate >= HQTX.EffectiveDate and JBIS.AmtBilled = 0 and JBIS.TaxAmount = 0 then
			sum(JBIS.RetgTaxRel)
			when JBIN.InvDate < HQTX.EffectiveDate  and JBIS.AmtBilled = 0  and JBIS.TaxAmount = 0 then
			sum(JBIS.RetgTaxRel)
			else 0
			End as RelRetainage_PlusTax
From JBIS
Join JCCI ON  JCCI.JCCo = JBIS.JBCo
		  AND JCCI.Contract = JBIS.Contract
		  AND JCCI.Item = JBIS.Item
	Left Join HQTX ON JBIS.TaxGroup = HQTX.TaxGroup
		and JBIS.TaxCode = HQTX.TaxCode
	Left Join JBIN ON JBIS.JBCo = JBIN.JBCo
		And JBIS.BillMonth = JBIN.BillMonth
		And JBIS.BillNumber = JBIN.BillNumber
Group By  JBIS.JBCo
		, JBIS.BillMonth
		, JBIS.BillNumber
		, JBIS.Contract
		, JBIS.Item
		, HQTX.NewRate
		, HQTX.OldRate
		, HQTX.EffectiveDate
		, JBIS.RetgRel		
		, JBIN.InvDate
		, JBIS.RetgRel
		, JBIS.TaxAmount
		, JBIS.AmtBilled

GO
GRANT SELECT ON  [dbo].[vrvJBProgressBills] TO [public]
GRANT INSERT ON  [dbo].[vrvJBProgressBills] TO [public]
GRANT DELETE ON  [dbo].[vrvJBProgressBills] TO [public]
GRANT UPDATE ON  [dbo].[vrvJBProgressBills] TO [public]
GRANT SELECT ON  [dbo].[vrvJBProgressBills] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvJBProgressBills] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvJBProgressBills] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvJBProgressBills] TO [Viewpoint]
GO
