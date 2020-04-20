SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[brvAPCashReq] as select 	APTH.APCo, 
    	APTH.Mth, 
    	APTH.APTrans,
    	APTH.VendorGroup, 
    	APTH.Vendor,
    	APTH.APRef, 
    	APTH.Description, 
    	APTH.InvDate, 
    	APTH.DiscDate, 
    	H_DueDate = APTH.DueDate,
    	APTD.APLine, 
    	APTD.APSeq, 
    	APTD.PayType,
   	APTD.PayCategory, 
    	APTD.Amount, 
    	APTD.DiscTaken,
    	D_DueDate = APTD.DueDate, 
    	APTD.Status, 
    	APVM.SortName,
    	V_Name = APVM.Name,
    	HQCO.HQCo,
    	HQ_Name = HQCO.Name,
    	PT_Description = APPT.Description,
    	Apprvd = 'Y'
    		
    from APTH
           left outer join APTD 
           	on APTH.APCo = APTD.APCo
           	and APTH.Mth = APTD.Mth
           	and APTH.APTrans = APTD.APTrans
           join APPT
    	on APTD.APCo = APPT.APCo
    	and APTD.PayType = APPT.PayType
           left outer join APVM
    	on APTH.VendorGroup = APVM.VendorGroup
    	and APTH.Vendor = APVM.Vendor
           join HQCO
    	on APTH.APCo = HQCO.HQCo
           
    
    UNION
    
    select 	APUI.APCo, 
    	APUI.UIMth, 
    	APUI.UISeq, 
    	APUI.VendorGroup, 
    	APUI.Vendor, 
    	APUI.APRef, 
    	APUI.Description, 
    	APUI.InvDate, 
    	APUI.DiscDate, 
    	APUI.DueDate,
    	APUL.Line, 
    	'1', 
    	APUL.PayType, 
   	APUL.PayCategory,
    	(APUL.GrossAmt+APUL.MiscAmt+APUL.TaxAmt-APUL.Retainage),  
    	APUL.Discount, 
    	APUI.DueDate, 	
    	'9', 
    	APVM.SortName,
    	V_Name = APVM.Name,
    	HQCO.HQCo,
    	HQ_Name = HQCO.Name,
    	PT_Description = APPT.Description,
    	'N'
    	
    from dbo.APUI APUI
           left outer join dbo.APUL APUL
             	on APUI.APCo = APUL.APCo
            	and APUI.UIMth = APUL.UIMth
            	and APUI.UISeq = APUL.UISeq
           join APPT
    	on APUL.APCo = APPT.APCo
    	and APUL.PayType = APPT.PayType
           left outer join APVM
    	on APUI.VendorGroup = APVM.VendorGroup
    	and APUI.Vendor = APVM.Vendor
           join HQCO
    	on APUI.APCo = HQCO.HQCo

GO
GRANT SELECT ON  [dbo].[brvAPCashReq] TO [public]
GRANT INSERT ON  [dbo].[brvAPCashReq] TO [public]
GRANT DELETE ON  [dbo].[brvAPCashReq] TO [public]
GRANT UPDATE ON  [dbo].[brvAPCashReq] TO [public]
GO
