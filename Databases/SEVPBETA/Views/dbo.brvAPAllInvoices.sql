SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[brvAPAllInvoices] 
   AS

/********************************************************************************************

   Created 05/17/05 JH
   
   This view will return all posted invoices and unapproved invoices by vendor.
   
   Reports:  APVendorLookupMT.rpt, APMasterVendorDrilldown.rpt

   Issue 30320 changed Supplier to come from APTD instead of APTL CR
   Issue 129200 added TaxType 3 (VAT) to case statements - DML - 07/31/2008
   Issue 127224 added Country to case statements - DML - 12/08/2008 
   Issue 142824 added OpenYN and ApprovedHeaderNotes - CWW -07/08/2011
		Note: All unapproved invoices(Rec Type = U) are assumed opened (OpenYN ='Y')
   B-09175 (No CL issue) Added PayMethod 'S' (Credit Service) to case statement - Czeslaw - 04/19/2012
		Note: Like PayMethod 'E' (EFT), PayMethod 'S' is represented by CMTransType '4' in CMDT;
		necessarily distinct CMAcct value for 'S' transactions will insure referential integrity

********************************************************************************************/

   SELECT Type='P', APCo=h.APCo, Mth=h.Mth, APTrans=h.APTrans, h.VendorGroup,
   	h.Vendor, VendorName=v.Name, h.APRef, h.InvDate, h.Description, h.DueDate, h.OpenYN, 
   	d.APLine, d.APSeq, d.PayType, Amount=d.Amount, d.DiscOffer, 
   	d.Status, d.PaidMth, d.PaidDate, d.CMCo, d.CMAcct, d.CMRef, d.CMRefSeq, 
    PayMethod = case when d.PayMethod='C' then 1 when d.PayMethod in ('E','S') then 4 else 9 end,
   	Line=l.APLine, l.LineType, LineDescription=l.Description, 
   	d.Supplier, SupplierName=APVM_Supplier.Name, 
   	l.JCCo, l.Job, l.PhaseGroup, l.Phase, l.JCCType, 
   	l.INCo, l.Loc, l.MatlGroup, l.Material, 
   	l.GLCo, l.GLAcct, 
   	l.EMCo, l.EMGroup, l.Equip, l.CompType, l.Component, l.WO, l.WOItem, l.CostCode, l.EMCType,
   	l.PO, l.POItem, l.ItemType, 
   	l.SL, l.SLItem,
   	l.UM, l.UnitCost, l.Units, l.GrossAmt, l.MiscAmt, l.MiscYN, l.TaxGroup, l.TaxCode, l.TaxAmt, l.TaxType, 
   	h.UniqueAttchID, VendorNotes=v.Notes, HeaderNotes=NULL, ApprovedHeaderNotes=h.Notes,
   	LineNotes=l.Notes, v.Address, v.City, v.State, v.Zip, v.Phone, v.MasterVendor, v.Country, c.HQCo, c.Name
   FROM APTH h 
   INNER JOIN HQCO c ON h.APCo=c.HQCo
   INNER JOIN APVM v ON h.VendorGroup=v.VendorGroup AND h.Vendor=v.Vendor
   LEFT OUTER JOIN APTL l ON h.APCo=l.APCo AND h.Mth=l.Mth AND h.APTrans=l.APTrans
   LEFT OUTER JOIN APTD d ON l.APCo=d.APCo AND l.Mth=d.Mth AND l.APTrans=d.APTrans AND l.APLine=d.APLine 
   LEFT OUTER JOIN APVM APVM_Supplier ON d.VendorGroup=APVM_Supplier.VendorGroup AND d.Supplier=APVM_Supplier.Vendor
   
   UNION ALL
   
   SELECT Type='U', APCo=i.APCo, Mth=i.UIMth, APTrans=i.UISeq, i.VendorGroup,
   	i.Vendor, VendorName=v.Name, i.APRef, i.InvDate, i.Description, i.DueDate, OpenYN = 'Y', --Unapproved invoices are open
   	NULL, NULL, l.PayType, Amount=(case when l.MiscYN='Y' and l.TaxType in (1,3) then l.GrossAmt+l.MiscAmt+l.TaxAmt 
   	when l.MiscYN='N' and l.TaxType in (1,3)  then l.GrossAmt+l.TaxAmt when l.MiscYN='Y' and l.TaxType=2 then l.GrossAmt+l.MiscAmt else
   	l.GrossAmt end), l.Discount, 
   	NULL, NULL, NULL, i.CMCo, i.CMAcct, NULL, NULL, NULL,
   	Line=l.Line, l.LineType, LineDescription=l.Description,
   	l.Supplier,  SupplierName=APVM_Supplier.Name,  
   	l.JCCo, l.Job, l.PhaseGroup, l.Phase, l.JCCType, 
   	l.INCo, l.Loc, l.MatlGroup, l.Material, 
   	l.GLCo, l.GLAcct, 
   	l.EMCo, l.EMGroup, l.Equip, l.CompType, l.Component, l.WO, l.WOItem, l.CostCode, l.EMCType,
   	l.PO, l.POItem, l.ItemType, 
   	l.SL, l.SLItem,
   	l.UM, l.UnitCost, l.Units, l.GrossAmt, l.MiscAmt, l.MiscYN, l.TaxGroup, l.TaxCode, l.TaxAmt, l.TaxType, 
   	i.UniqueAttchID, VendorNotes=v.Notes, HeaderNotes=i.Notes, ApprovedHeaderNotes=Null, 
   	LineNotes=l.Notes, v.Address, v.City, v.State, v.Zip, v.Phone, v.MasterVendor,  v.Country, c.HQCo, c.Name
   FROM APUI i
   INNER JOIN HQCO c ON i.APCo=c.HQCo 
   INNER JOIN APVM v ON i.VendorGroup=v.VendorGroup AND i.Vendor=v.Vendor
   LEFT OUTER JOIN APUL l ON i.APCo=l.APCo AND i.UIMth=l.UIMth AND i.UISeq=l.UISeq
   LEFT OUTER JOIN APVM APVM_Supplier ON l.VendorGroup=APVM_Supplier.VendorGroup AND l.Supplier=APVM_Supplier.Vendor


GO
GRANT SELECT ON  [dbo].[brvAPAllInvoices] TO [public]
GRANT INSERT ON  [dbo].[brvAPAllInvoices] TO [public]
GRANT DELETE ON  [dbo].[brvAPAllInvoices] TO [public]
GRANT UPDATE ON  [dbo].[brvAPAllInvoices] TO [public]
GO
