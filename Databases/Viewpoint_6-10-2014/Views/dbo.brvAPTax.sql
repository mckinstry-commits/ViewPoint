SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





   /****** Object:  Stored Procedure dbo.brvAPTax    Script Date: 8/28/99 9:32:27 AM ******/    
   

CREATE   VIEW [dbo].[brvAPTax]        
   /* used in APTax.rpt */    
   /* NOTE: If this view requires maintenance, check view brvAPGSTTax for a simular change */
   /* Added InclGSTinPST from HQTX for APVAT.rpt - DML - 04/01/2009 */  
   /* Changed InclGSTinPST add from HQTX for APVAT.rpt and added HQTX.GST - DML - 02/22/2010 */
   /* Added Multi-Level processing to include GST in the Basis amount of PST - CWW - 05/05/2011 */
       
   AS    
       
   Select 
   HQCO.Name
   ,APTL.APCo
   ,APTL.Mth
   ,APTL.APTrans
   ,APTL.APLine
   ,APTL.Job
   ,APTL.Description
   ,APTL.TaxType
   ,TaxCo = CASE WHEN APTL.TaxType in (1,3) THEN APTL.APCo ELSE APTL.GLCo END
   ,APTL.GLCo
   ,APTL.TaxBasis
   ,APTL.TaxAmt
   ,JobDesc = JCJM.Description
   ,APTH.InvDate
   ,APTH.Vendor
   ,APTH.APRef
   ,VendorName=APVM.Name
   ,BaseTaxCode=base.TaxCode  
   ,BaseTaxDesc=base.Description
   ,BaseHQTXMultiLevel=base.MultiLevel
   ,LocalTaxCode=CASE base.MultiLevel WHEN 'Y' THEN local.TaxCode ELSE base.TaxCode END
   ,LocalTaxDesc=CASE base.MultiLevel WHEN 'Y' THEN local.Description ELSE base.Description END
   ,GLAcct=CASE base.MultiLevel WHEN 'Y' THEN local.DbtGLAcct ELSE base.DbtGLAcct END

   ,TaxRate=CASE base.MultiLevel WHEN 'Y'    
          THEN (CASE WHEN APTH.InvDate < ISNULL(local.EffectiveDate,'12/31/2070') THEN    
                            ISNULL(local.OldRate,0) ELSE ISNULL(local.NewRate,0) END)    
                   ELSE    
                             (CASE WHEN APTH.InvDate < ISNULL(base.EffectiveDate,'12/31/2070') THEN    
                                          ISNULL(base.OldRate,0) ELSE ISNULL(base.NewRate,0) END)    
          END  
   ,ISNULL(local.InclGSTinPST,base.InclGSTinPST) AS InclGSTinPST  
   ,ISNULL(local.GST,base.GST) AS GST 
   ,Tax = APTL.TaxBasis * CASE base.MultiLevel WHEN 'Y'    
          THEN (CASE WHEN APTH.InvDate < ISNULL(local.EffectiveDate,'12/31/2070') THEN    
                            ISNULL(local.OldRate,0) ELSE ISNULL(local.NewRate,0) END)    
                   ELSE    
                             (CASE WHEN APTH.InvDate < ISNULL(base.EffectiveDate,'12/31/2070') THEN    
                                          ISNULL(base.OldRate,0) ELSE ISNULL(base.NewRate,0) END)    
          END      
   ,GSTTax = e.GSTtaxAmtPRDT
   ,TaxBasisInculdesGSTTax = APTL.TaxBasis + e.GSTtaxAmtPRDT
   ,NonGSTTaxes = e.TotTaxAmountPRDT - e.GSTtaxAmtPRDT
   
   FROM APTL APTL    
   INNER JOIN APTH ON     
   APTH.APCo=APTL.APCo and     
   APTH.Mth=APTL.Mth and     
   APTH.APTrans=APTL.APTrans    
   INNER JOIN HQCO ON     
   APTL.APCo=HQCO.HQCo    
   INNER JOIN APVM ON     
   APVM.VendorGroup=APTH.VendorGroup and     
   APVM.Vendor=APTH.Vendor    
   LEFT OUTER JOIN JCJM ON     
   JCJM.JCCo=APTL.JCCo and JCJM.Job=APTL.Job    
   INNER JOIN HQTX base ON     
   base.TaxGroup=APTL.TaxGroup and base.TaxCode=APTL.TaxCode    
   FULL OUTER JOIN HQTL ON     
   HQTL.TaxGroup = APTL.TaxGroup and HQTL.TaxCode = APTL.TaxCode    
   FULL OUTER JOIN HQTX local ON local.TaxGroup = HQTL.TaxGroup and local.TaxCode = HQTL.TaxLink 
  
  LEFT OUTER JOIN brvAPTaxGST e
  ON   e.APCo=APTL.APCo AND     
   e.Mth=APTL.Mth AND     
   e.APTrans=APTL.APTrans  AND
   e.APLine=APTL.APLine 
   

       
       
       
       
      
     
    






GO
GRANT SELECT ON  [dbo].[brvAPTax] TO [public]
GRANT INSERT ON  [dbo].[brvAPTax] TO [public]
GRANT DELETE ON  [dbo].[brvAPTax] TO [public]
GRANT UPDATE ON  [dbo].[brvAPTax] TO [public]
GRANT SELECT ON  [dbo].[brvAPTax] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvAPTax] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvAPTax] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvAPTax] TO [Viewpoint]
GO
