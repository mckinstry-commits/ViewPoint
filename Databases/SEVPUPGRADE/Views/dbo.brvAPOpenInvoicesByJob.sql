SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     view [dbo].[brvAPOpenInvoicesByJob] 
   as 
   select 	APTH.APCo, APTH.Mth, APTH.APTrans, APTH.VendorGroup, APTH.Vendor, APVM.SortName, APVM.Name, APTH.APRef, APTL.Description,  APTH.InvDate, 
    	APTD.APLine, APTD.PayType, APTL.JCCo, APTL.Job, APTD.Status, APTD.Amount, UnapprovedYN = 'N'
    		
    from APTH
           left outer join APTD on APTH.APCo = APTD.APCo and APTH.Mth = APTD.Mth and APTH.APTrans = APTD.APTrans
   	left outer join APTL on APTH.APCo = APTL.APCo and APTH.Mth = APTL.Mth and APTH.APTrans = APTL.APTrans and APTL.APLine=APTD.APLine
           left outer join APVM on APTH.VendorGroup = APVM.VendorGroup and APTH.Vendor = APVM.Vendor
           join HQCO on APTH.APCo = HQCO.HQCo
           
    
    UNION All
    
   select 	APUI.APCo, APUI.UIMth, APUI.UISeq, APUI.VendorGroup, APUI.Vendor, APVM.SortName, APVM.Name, APUI.APRef, APUL.Description,  APUI.InvDate, 
    	APUL.Line, APUL.PayType, APUL.JCCo, APUL.Job, '9', (APUL.GrossAmt+APUL.MiscAmt+APUL.TaxAmt/*-APUL.Retainage*/), UnapprovedYN = 'Y'
   from dbo.bAPUI APUI
           left outer join dbo.bAPUL APUL on APUI.APCo = APUL.APCo and APUI.UIMth = APUL.UIMth and APUI.UISeq = APUL.UISeq
           Left outer join APVM on APUI.VendorGroup = APVM.VendorGroup and APUI.Vendor = APVM.Vendor
           join HQCO on APUI.APCo = HQCO.HQCo

GO
GRANT SELECT ON  [dbo].[brvAPOpenInvoicesByJob] TO [public]
GRANT INSERT ON  [dbo].[brvAPOpenInvoicesByJob] TO [public]
GRANT DELETE ON  [dbo].[brvAPOpenInvoicesByJob] TO [public]
GRANT UPDATE ON  [dbo].[brvAPOpenInvoicesByJob] TO [public]
GO
