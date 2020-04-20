SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*******************************************************
   *	Created:	Allen Newton
   *	Modified:	MV 01/21/05 - with (nolock)	
   *
   *	Used by the DTS package created within Form APInvoiceExport
   *
   ********************************************************/
    
    CREATE      view [dbo].[APExport]
    as
    select distinct hqco.[Name] as hqco_Name, apvm.[Name] as apvm_Name, aptd.PaidDate, aptd.CMRef,
   	 aptd.Status, apth.APCo, apth.Mth, apth.APTrans, apth.VendorGroup, apth.Vendor, apth.APRef,
   	 apth.[Description] as apth_Description, apth.InvDate, apth.InvTotal, aptl.PO, aptl.POItem, 
   	 aptl.SL, aptl.SLItem, aptl.JCCo, aptl.Job, aptl.PhaseGroup, aptl.Phase, aptl.JCCType,
   	 aptl.EMCo, aptl.WO, aptl.WOItem, aptl.Equip, aptl.EMGroup, aptl.CostCode, aptl.EMCType,
   	 aptl.CompType, aptl.Component, aptl.INCo, aptl.Loc, aptl.MatlGroup, aptl.Material, aptl.GLCo,
   	 aptd.Amount, aptl.GLAcct, aptl.[Description] as aptl_Description, aptl.TaxGroup, aptl.TaxCode,
   	 aptl.TaxType, preh.FirstName, preh.MidName, preh.LastName
    from bAPTH as apth with (nolock) 
   	join bAPVM as apvm with (nolock) on apvm.VendorGroup = apth.VendorGroup and apvm.Vendor = apth.Vendor 
   	join bAPTL as aptl with (nolock) on aptl.APCo = apth.APCo and aptl.Mth = apth.Mth and aptl.APTrans = apth.APTrans 
   	join bAPTD as aptd with (nolock) on aptd.APCo = aptl.APCo and aptd.Mth = aptl.Mth and aptd.APTrans = aptl.APTrans and aptd.APLine = aptl.APLine 
   	left join bJCJM as jcjm with (nolock) on jcjm.JCCo = aptl.JCCo 	and jcjm.Job = aptl.Job 
   	left join bPREH as preh with (nolock) on jcjm.JCCo = preh.JCCo 	and jcjm.Job = preh.Job
   	left join bHQCO as hqco with (nolock) on hqco.HQCo = aptd.APCo

GO
GRANT SELECT ON  [dbo].[APExport] TO [public]
GRANT INSERT ON  [dbo].[APExport] TO [public]
GRANT DELETE ON  [dbo].[APExport] TO [public]
GRANT UPDATE ON  [dbo].[APExport] TO [public]
GRANT SELECT ON  [dbo].[APExport] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APExport] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APExport] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APExport] TO [Viewpoint]
GO
