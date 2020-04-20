SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   CREATE     view [dbo].[brvEMTax] as
    
    /**********************
    EM Tax View for EM Tax Report
    created 1/11/05
    
    
    
    **********************/
    
    
    Select HQCO.Name,
       EMCD.EMCo,  EMCD.Mth, EMCD.EMTrans, EMCD.EMTransType,  EMCD.Equipment, EMCD.Description, EMCD.TaxType,
       TaxCo = case when EMCD.TaxType in (1,3) then EMCD.APCo else EMCD.GLCo end, EMCD.GLCo,
       EMCD.TaxBasis, EMCD.TaxAmount,--JCCD.Phase,JCCD.CostTrans,
       EMDesc = EMEM.Description,
       EMCD.ActualDate,  EMCD.APVendor, EMCD.APRef,--JCCD.MSTicket,
       --VendorName=APVM.Name,
    	BaseTaxCode=base.TaxCode,
    	BaseTaxDesc=base.Description,
    	LocalTaxCode=case base.MultiLevel when 'Y' then local.TaxCode else base.TaxCode end,
    	LocalTaxDesc=case base.MultiLevel when 'Y' then local.Description else base.Description end,
    	GLAcct=case base.MultiLevel when 'Y' then local.GLAcct else base.GLAcct end,
    	TaxRate=case base.MultiLevel when 'Y'
    	      then (case when EMCD.ActualDate < isnull(local.EffectiveDate,'12/31/2070') then
    	                        isnull(local.OldRate,0) else isnull(local.NewRate,0) end)
    	               else
    	                         (case when EMCD.ActualDate < isnull(base.EffectiveDate,'12/31/2070') then
    	                                      isnull(base.OldRate,0) else isnull(base.NewRate,0) end)
    	      end
    
    FROM EMCD EMCD 
    Join HQCO on EMCD.EMCo=HQCO.HQCo 
    --Join APVM on APVM.VendorGroup=JCCD.VendorGroup and APVM.Vendor=JCCD.Vendor
    Inner Join EMEM on EMEM.EMCo=EMCD.EMCo and EMEM.Equipment=EMCD.Equipment
    Join HQTX base on base.TaxGroup=EMCD.TaxGroup and base.TaxCode=EMCD.TaxCode
    Full outer Join HQTL on HQTL.TaxGroup = EMCD.TaxGroup and HQTL.TaxCode = EMCD.TaxCode
    Full outer Join HQTX local on local.TaxGroup = HQTL.TaxGroup and local.TaxCode = HQTL.TaxLink
   
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvEMTax] TO [public]
GRANT INSERT ON  [dbo].[brvEMTax] TO [public]
GRANT DELETE ON  [dbo].[brvEMTax] TO [public]
GRANT UPDATE ON  [dbo].[brvEMTax] TO [public]
GRANT SELECT ON  [dbo].[brvEMTax] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvEMTax] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvEMTax] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvEMTax] TO [Viewpoint]
GO
