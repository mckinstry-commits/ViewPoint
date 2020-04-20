SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE    view [dbo].[brvJCTax] as
    
    /**********************
    JC Tax View for JC Tax Report
    created 2/9/04
    
    modified 10/13/04 CR changed JCJM from Left outer to Inner for Job security #25343
    
    **********************/
    
    
    Select HQCO.Name,
       JCCD.JCCo,  JCCD.Mth, JCCD.JCTransType,  JCCD.Job, JCCD.Description, JCCD.TaxType,
       TaxCo = case when JCCD.TaxType in (1,3) then JCCD.APCo else JCCD.GLCo end, JCCD.GLCo,
       JCCD.TaxBasis, JCCD.TaxAmt,JCCD.Phase,JCCD.CostTrans,
       JobDesc = JCJM.Description,
       JCCD.ActualDate,  JCCD.Vendor, JCCD.APRef,JCCD.MSTicket,
       --VendorName=APVM.Name,
    	BaseTaxCode=base.TaxCode,
    	BaseTaxDesc=base.Description,
    	LocalTaxCode=case base.MultiLevel when 'Y' then local.TaxCode else base.TaxCode end,
    	LocalTaxDesc=case base.MultiLevel when 'Y' then local.Description else base.Description end,
    	GLAcct=case base.MultiLevel when 'Y' then local.GLAcct else base.GLAcct end,
    	TaxRate=case base.MultiLevel when 'Y'
    	      then (case when JCCD.ActualDate < isnull(local.EffectiveDate,'12/31/2070') then
    	                        isnull(local.OldRate,0) else isnull(local.NewRate,0) end)
    	               else
    	                         (case when JCCD.ActualDate < isnull(base.EffectiveDate,'12/31/2070') then
    	                                      isnull(base.OldRate,0) else isnull(base.NewRate,0) end)
    	      end
    
    FROM JCCD JCCD 
    Join HQCO on JCCD.JCCo=HQCO.HQCo 
    --Join APVM on APVM.VendorGroup=JCCD.VendorGroup and APVM.Vendor=JCCD.Vendor
    Inner Join JCJM on JCJM.JCCo=JCCD.JCCo and JCJM.Job=JCCD.Job
    Join HQTX base on base.TaxGroup=JCCD.TaxGroup and base.TaxCode=JCCD.TaxCode
    Full outer Join HQTL on HQTL.TaxGroup = JCCD.TaxGroup and HQTL.TaxCode = JCCD.TaxCode
    Full outer Join HQTX local on local.TaxGroup = HQTL.TaxGroup and local.TaxCode = HQTL.TaxLink
    
    
    
    
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvJCTax] TO [public]
GRANT INSERT ON  [dbo].[brvJCTax] TO [public]
GRANT DELETE ON  [dbo].[brvJCTax] TO [public]
GRANT UPDATE ON  [dbo].[brvJCTax] TO [public]
GO
