SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE View   
  
[dbo].[vrvPOTaxRates]  
  
/***  
 Created:  DH 6/17/2010  
 Modified:  
   
 Reports:  PO Purchase Order Form  
   
 View returns POIT (PO Itemts) linked to HQTaxCodes.  Multiply the CurCost by the tax rates to calculate   
 tax amounts for both multilevel and non-multilevel tax codes  
   
 ****/  
--  
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
  
select    POIT.POCo  
  , POIT.PO  
  , POIT.POItem  
  , POIT.OrigCost  
  , POIT.CurCost  
  , POIT.TaxCode 
  , POIT.TaxType 
  , POIT.TotalCost
  , POIT.TotalTax
  , POIT.InvCost
  , POIT.RemCost
  , POHD.OrderDate  --added
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
             
    
From POIT  
Left Join GST g  
  on  g.TaxGroup = POIT.TaxGroup  
  and g.MainTaxCode = POIT.TaxCode  
   
Join TaxCode t  
 on  t.TaxGroup = POIT.TaxGroup  
 and t.MainTaxCode = POIT.TaxCode

Left Join POHD 
	POHD on POIT.POCo = POHD.POCo
	and POIT.PO = POHD.PO



	




GO
GRANT SELECT ON  [dbo].[vrvPOTaxRates] TO [public]
GRANT INSERT ON  [dbo].[vrvPOTaxRates] TO [public]
GRANT DELETE ON  [dbo].[vrvPOTaxRates] TO [public]
GRANT UPDATE ON  [dbo].[vrvPOTaxRates] TO [public]
GO
