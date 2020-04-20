SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
 CREATE view [dbo].[brvJBTaxRate] as
 
 Select JBIL.JBCo,
 TaxGroup=case base.MultiLevel when 'Y' then local.TaxGroup else base.TaxGroup end,
 TaxCode=case base.MultiLevel when 'Y' then local.TaxCode else base.TaxCode end,
 
 TaxRate=case base.MultiLevel when 'Y'
  	      then (case when JBIN.InvDate < isnull(local.EffectiveDate,'12/31/2070') then
  	                        isnull(local.OldRate,0) else isnull(local.NewRate,0) end)
  	               else
  	                         (case when JBIN.InvDate < isnull(base.EffectiveDate,'12/31/2070') then
  	                                      isnull(base.OldRate,0) else isnull(base.NewRate,0) end)
  	      end
 from JBIL
 
 join JBIN on JBIL.JBCo=JBIN.JBCo and JBIL.BillMonth=JBIN.BillMonth and JBIL.BillNumber=JBIN.BillNumber
 Join HQTX base on base.TaxGroup=JBIL.TaxGroup and base.TaxCode=JBIL.TaxCode
 Full outer Join HQTL on 
  HQTL.TaxGroup = JBIL.TaxGroup and HQTL.TaxCode = JBIL.TaxCode
 Full outer Join HQTX local on local.TaxGroup = HQTL.TaxGroup and local.TaxCode = HQTL.TaxLink
 
 



GO
GRANT SELECT ON  [dbo].[brvJBTaxRate] TO [public]
GRANT INSERT ON  [dbo].[brvJBTaxRate] TO [public]
GRANT DELETE ON  [dbo].[brvJBTaxRate] TO [public]
GRANT UPDATE ON  [dbo].[brvJBTaxRate] TO [public]
GRANT SELECT ON  [dbo].[brvJBTaxRate] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvJBTaxRate] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvJBTaxRate] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvJBTaxRate] TO [Viewpoint]
GO
