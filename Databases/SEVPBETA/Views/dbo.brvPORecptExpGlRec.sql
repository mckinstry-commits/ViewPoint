SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--Drop view brvPORecptExpGlRec
   /***********************************************
    PO Receipt Expensed GL Reconciliation View 
    Created 11/20/2002 AA
     
	Added APTL.ECM for use in PO Receiving Accrual GL Rec Rpt (Issue 131649) 01/07/2009 DML  

	View performs two separate select statements for both PORD 
	and APTL information for Units only due to need for through month.
     
    Reports:  PO Receipt Expensed GL Reconciliation
     
   *************************************************/
  CREATE     view  [dbo].[brvPORecptExpGlRec] 
   AS 
  SELECT PORD.POCo, PORD.Mth, PORD.PO, PORD.POItem, PORD.RecvdUnits, InvUnits=0, 
 	isnull(dbo.vfHQTaxRate(POIT.TaxGroup,POIT.TaxCode, PORD.RecvdDate),0) as 'RecvdTaxRate',
          RecvdCost= PORD.RecvdCost, InvCost=0, InvTaxRate=0, Type='PORD', NULL as 'ECM' 
    FROM PORD
    INNER JOIN POIT  ON PORD.POCo=POIT.POCo AND PORD.PO=POIT.PO AND PORD.POItem=POIT.POItem     
        
    UNION ALL
        
    SELECT APTL.APCo, APTL.Mth, APTL.PO, APTL.POItem, RecvdUnits=0, APTL.Units, RecvdTaxRate = 0,
  	RecvdCost= 0, APTL.GrossAmt, 
 	isnull(dbo.vfHQTaxRate(POIT.TaxGroup,POIT.TaxCode, APTH.InvDate),0) as 'InvTaxRate', Type='APTL',APTL.ECM   
    FROM APTL 
 join APTH on APTL.APCo = APTH.APCo and APTL.Mth = APTH.Mth and APTL.APTrans=APTH.APTrans
join POIT on APTL.APCo = POIT.POCo and APTL.PO = POIT.PO and APTL.POItem = POIT.POItem

GO
GRANT SELECT ON  [dbo].[brvPORecptExpGlRec] TO [public]
GRANT INSERT ON  [dbo].[brvPORecptExpGlRec] TO [public]
GRANT DELETE ON  [dbo].[brvPORecptExpGlRec] TO [public]
GRANT UPDATE ON  [dbo].[brvPORecptExpGlRec] TO [public]
GO
