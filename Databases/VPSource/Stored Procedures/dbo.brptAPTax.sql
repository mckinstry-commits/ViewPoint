SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptAPTax    Script Date: 8/28/99 9:32:27 AM ******/
   CREATE    proc [dbo].[brptAPTax]
   (@APCo bCompany, @BeginTaxCode bTaxCode ='', @EndTaxCode bTaxCode= 'zzzzzzzzz',
   @BeginMth bMonth= '01/01/50',@EndMth bMonth= '01/01/49')
   /* created 10/7/97 Tracy*/
   /* used in APTax.rpt */
   /* Issue 25855 add with (nolock) DW 10/22/04*/
   as
   
   Select HQCO.Name,APTL.APCo,APTL.Mth, APTL.APTrans, APTL.APLine, APTL.Job, JCJM.Description,
           APTH.InvDate, APTH.Vendor,VendorName=APVM.Name,
   	APTH.APRef,  APTL.Description,APTL.TaxType,
   	BaseTaxCode=base.TaxCode,
   	BaseTaxDesc=base.Description,
   	LocalTaxCode=case base.MultiLevel when 'Y' then tlocal.TaxCode else base.TaxCode end,
   
   
   	LocalTaxDesc=case base.MultiLevel when 'Y' then tlocal.Description else base.Description end,
   	GLAcct=case base.MultiLevel when 'Y' then tlocal.GLAcct else base.GLAcct end,
   	APTL.TaxBasis,
   	APTL.TaxAmt,
   	TaxRate=case base.MultiLevel when 'Y'
   	      then
   	       (case when APTH.InvDate < isnull(tlocal.EffectiveDate,'12/31/2070') then
   	         isnull(tlocal.OldRate,0) else isnull(tlocal.NewRate,0) end)
   	      else
   	        (case when APTH.InvDate < isnull(base.EffectiveDate,'12/31/2070') then
   	         isnull(base.OldRate,0) else isnull(base.NewRate,0) end)
   	      end,
   	 BeginTaxCode=@BeginTaxCode, EndTaxCode=@EndTaxCode, BeginMth=@BeginMth, EndMth=@EndMth
   FROM APTL APTL with(nolock) 
   Join APTH with (nolock) 
   	on APTH.APCo=APTL.APCo and APTH.Mth=APTL.Mth and APTH.APTrans=APTL.APTrans
   Join HQCO with(nolock)on APTL.APCo=HQCO.HQCo
   Join APVM with(nolock)on APVM.VendorGroup=APTH.VendorGroup and APVM.Vendor=APTH.Vendor
   Left Outer Join JCJM with(nolock)on JCJM.JCCo=APTL.JCCo and JCJM.Job=APTL.Job
   Join HQTX base with(nolock)on base.TaxGroup=APTL.TaxGroup and base.TaxCode=APTL.TaxCode
   Full outer Join HQTL with(nolock)on HQTL.TaxGroup = APTL.TaxGroup and HQTL.TaxCode = APTL.TaxCode
   Full outer Join HQTX tlocal with(nolock)on tlocal.TaxGroup = HQTL.TaxGroup and tlocal.TaxCode = HQTL.TaxLink
   
   where APTL.APCo=@APCo and APTL.TaxCode>=@BeginTaxCode and APTL.TaxCode<=@EndTaxCode
     and APTL.Mth>=@BeginMth and APTL.Mth<=@EndMth
     and APTH.APCo=@APCo and APTH.Mth>=@BeginMth and APTH.Mth<=@EndMth
   
   
   /*
   order by APTL.APCo, APTL.Mth, APTL.APTrans,APTL.APLine, APTH.InvDate,APTH.Vendor,APVM.Name
   	APTH.APRef,  APTL.Description, APTL.TaxCode, HQTL.TaxCode,
   	APTL.TaxBasis,APTL.TaxAmt,HQTL.TaxLink **
   */
GO
GRANT EXECUTE ON  [dbo].[brptAPTax] TO [public]
GO
