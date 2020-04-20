SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View       
      
[dbo].[vrvARTaxRates]      
      
/***      
 Created:  DH 6/17/2010      
 Modified: MB 8/12/2010     
       
 Reports:  AR Canadian Tax Invoice    
  
 View returns ARTL (Invoice Items) linked to HQTaxCodes.  Multiply the (Tax Basis) by the tax rates to calculate       
 tax amounts for both multilevel and non-multilevel tax codes      
       
 ****/      
  
    
as      
      
With GST       
      
as      
      
(select   m.TaxGroup as TaxGroup       
  , m.TaxCode as MainTaxCode      
  , l.TaxLink as GSTTaxCode      
  , lx.OldRate as GSTTaxOldRate      
  , lx.NewRate as GSTTaxNewRate      
  , lx.EffectiveDate as GSTEffectiveDate      
From HQTX m      
Join HQTL l on  l.TaxGroup = m.TaxGroup and l.TaxCode = m.TaxCode      
Join HQTX lx on lx.TaxGroup = m.TaxGroup and l.TaxLink = lx.TaxCode      
Where lx.GST = 'Y')      
      
,TaxCode      
      
as      
      
(select   m.TaxGroup as TaxGroup       
  , m.TaxCode as MainTaxCode      
  , m.Description as MainTaxCodeDesc      
  , m.MultiLevel     
  , l.TaxLink as SubTaxCode      
  , lx.Description SubTaxCodeDesc      
  , m.OldRate as MainTaxOldRate      
  , m.NewRate as MainTaxNewRate      
  , m.EffectiveDate as MainTaxEffectiveDate      
  , lx.OldRate as SubCodeTaxOldRate      
  , lx.NewRate as SubCodeTaxNewRate      
  , lx.EffectiveDate as SubCodeEffectiveDate      
  , lx.GST      
  , lx.InclGSTinPST      
From HQTX m      
Left Join HQTL l on  l.TaxGroup = m.TaxGroup and l.TaxCode = m.TaxCode      
Left Join HQTX lx on lx.TaxGroup = m.TaxGroup and l.TaxLink = lx.TaxCode      
)      
      
select      
    ARTL.ARCo  
  , ARTL.Mth  
  , ARTL.ARTrans  
  , ARTL.Amount  
  , ARTL.TaxGroup  
  , ARTL.TaxCode  
  , ARTL.TaxAmount  
  , ARTL.TaxBasis  
  , ARTL.ApplyMth  
  , ARTL.ApplyTrans  
  , ARTH.TransDate  
  , ARTH.Invoice
  , t.MultiLevel    
  , isnull(t.MainTaxEffectiveDate, t.SubCodeEffectiveDate) as TaxEffectiveDate      
  , t.SubTaxCode      
  , isnull(t.MainTaxOldRate,t.SubCodeTaxOldRate) as TaxOldRate      
  , isnull(t.MainTaxNewRate,t.SubCodeTaxNewRate) as TaxNewRate      
  , t.GST      
  , t.InclGSTinPST      
  , g.GSTTaxOldRate       
  , g.GSTTaxNewRate      
  , g.GSTEffectiveDate    
                 
        
From ARTL      
  
Left Join GST g      
  on  g.TaxGroup = ARTL.TaxGroup      
  and g.MainTaxCode = ARTL.TaxCode    
       
Join TaxCode t      
 on  t.TaxGroup = ARTL.TaxGroup      
 and t.MainTaxCode = ARTL.TaxCode    
    
left join ARTH  
 on  ARTL.ARCo = ARTH.ARCo  
 and ARTL.Mth = ARTH.Mth  
 and ARTL.ARTrans = ARTH.ARTrans  
    
  

GO
GRANT SELECT ON  [dbo].[vrvARTaxRates] TO [public]
GRANT INSERT ON  [dbo].[vrvARTaxRates] TO [public]
GRANT DELETE ON  [dbo].[vrvARTaxRates] TO [public]
GRANT UPDATE ON  [dbo].[vrvARTaxRates] TO [public]
GRANT SELECT ON  [dbo].[vrvARTaxRates] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvARTaxRates] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvARTaxRates] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvARTaxRates] TO [Viewpoint]
GO
