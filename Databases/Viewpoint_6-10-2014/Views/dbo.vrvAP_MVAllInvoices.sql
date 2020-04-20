SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vrvAP_MVAllInvoices] 
AS

/********************************************************************************************

   Created 03/30/06 NF
   
   This view returns all posted invoices and unapproved invoices by APVM.MasterVendor.
   
   Reports:  APMasterVendorDrilldown.rpt
   
   Revisions:
   12/08/2008 DML Added APVM.Country for APMasterVendorDrilldown.rpt
   04/23/2012 Czeslaw B-09175 (No CL issue) Added PayMethod 'S' (Credit Service) to case statements
   		Note: Like PayMethod 'E' (EFT), PayMethod 'S' is represented by CMTransType '4' in CMDT;
		necessarily distinct CMAcct value for 'S' transactions will insure referential integrity
   
********************************************************************************************/
   
--Posted invoices where vendor is a sub vendor (i.e., has a master vendor)
   
   SELECT Type='P', APCo=APTH.APCo, Mth=APTH.Mth, APTrans=APTH.APTrans, APTH.VendorGroup,
   	APTH.Vendor, VendorName=APVM.Name, APTH.APRef, APTH.InvDate, APTH.Description, APTH.DueDate, 
   	APTD.APLine, APTD.APSeq, APTD.PayType, Amount=APTD.Amount, APTD.DiscOffer, 
   	APTD.Status, APTD.PaidMth, APTD.PaidDate, APTD.CMCo, APTD.CMAcct, APTD.CMRef, APTD.CMRefSeq, 
          PayMethod = case when APTD.PayMethod='C' then 1 when APTD.PayMethod in ('E','S') then 4 else 9 end,
   	Line=APTL.APLine, APTL.LineType, LineDescription=APTL.Description, 
   	APTL.Supplier, SupplierName=APVM_Supplier.Name, APTL.JCCo, APTL.Job, APTL.PhaseGroup, APTL.Phase, 
          APTL.JCCType, APTL.INCo, APTL.Loc, APTL.MatlGroup, APTL.Material, APTL.GLCo, APTL.GLAcct, 
   	APTL.EMCo, APTL.EMGroup, APTL.Equip, APTL.CompType, APTL.Component, APTL.WO, APTL.WOItem, APTL.CostCode, APTL.EMCType,
   	APTL.PO, APTL.POItem, APTL.ItemType, APTL.SL, APTL.SLItem, APTL.UM, APTL.UnitCost, APTL.Units, 
          APTL.GrossAmt, APTL.MiscAmt, APTL.MiscYN, APTL.TaxGroup, APTL.TaxCode, APTL.TaxAmt, APTL.TaxType, 
   	APTH.UniqueAttchID, VendorNotes=APVM.Notes, HeaderNotes=NULL,
   	LineNotes=APTL.Notes, APVM.Address, APVM.City, APVM.State, APVM.Zip, APVM.Country, APVM.Phone, APVM.MasterVendor, 
          MVendName = vrvAPVM_MasterVendor.Name, MVendorNotes = vrvAPVM_MasterVendor.Notes, MVAdd = vrvAPVM_MasterVendor.Address, 
          MVCity=vrvAPVM_MasterVendor.City, MVState = vrvAPVM_MasterVendor.State, MVZip = vrvAPVM_MasterVendor.Zip, 
          MVPhone = vrvAPVM_MasterVendor.Phone, MVCountry = vrvAPVM_MasterVendor.Country, 
          HQCO.HQCo, CoName=HQCO.Name
   FROM APTH  
   INNER JOIN HQCO  ON APTH.APCo=HQCO.HQCo
   INNER JOIN APVM  ON APTH.VendorGroup=APVM.VendorGroup AND APTH.Vendor=APVM.Vendor
   INNER JOIN vrvAPVM_MasterVendor on APVM.VendorGroup = vrvAPVM_MasterVendor.VendorGroup and 
                                        APVM.MasterVendor = vrvAPVM_MasterVendor.MasterVend
   LEFT OUTER JOIN APTL ON APTH.APCo=APTL.APCo AND APTH.Mth=APTL.Mth AND APTH.APTrans=APTL.APTrans
   LEFT OUTER JOIN APTD ON APTL.APCo=APTD.APCo AND APTL.Mth=APTD.Mth AND APTL.APTrans=APTD.APTrans AND APTL.APLine=APTD.APLine 
   LEFT OUTER JOIN APVM APVM_Supplier ON APTL.VendorGroup=APVM_Supplier.VendorGroup AND APTL.Supplier=APVM_Supplier.Vendor

UNION ALL

--Posted invoices where vendor is a master vendor
   
   SELECT Type='P', APCo=APTH.APCo, Mth=APTH.Mth, APTrans=APTH.APTrans, APTH.VendorGroup,
   	APTH.Vendor, VendorName=APVM.Name, APTH.APRef, APTH.InvDate, APTH.Description, APTH.DueDate, 
   	APTD.APLine, APTD.APSeq, APTD.PayType, Amount=APTD.Amount, APTD.DiscOffer, 
   	APTD.Status, APTD.PaidMth, APTD.PaidDate, APTD.CMCo, APTD.CMAcct, APTD.CMRef, APTD.CMRefSeq, 
          PayMethod = case when APTD.PayMethod='C' then 1 when APTD.PayMethod in ('E','S') then 4 else 9 end,
   	Line=APTL.APLine, APTL.LineType, LineDescription=APTL.Description, 
   	APTL.Supplier, SupplierName=APVM_Supplier.Name, APTL.JCCo, APTL.Job, APTL.PhaseGroup, APTL.Phase, 
          APTL.JCCType, APTL.INCo, APTL.Loc, APTL.MatlGroup, APTL.Material, APTL.GLCo, APTL.GLAcct, 
   	APTL.EMCo, APTL.EMGroup, APTL.Equip, APTL.CompType, APTL.Component, APTL.WO, APTL.WOItem, APTL.CostCode, APTL.EMCType,
   	APTL.PO, APTL.POItem, APTL.ItemType, APTL.SL, APTL.SLItem, APTL.UM, APTL.UnitCost, APTL.Units, 
          APTL.GrossAmt, APTL.MiscAmt, APTL.MiscYN, APTL.TaxGroup, APTL.TaxCode, APTL.TaxAmt, APTL.TaxType, 
   	APTH.UniqueAttchID, VendorNotes=APVM.Notes, HeaderNotes=NULL,
   	LineNotes=APTL.Notes, APVM.Address, APVM.City, APVM.State, APVM.Zip, APVM.Country, APVM.Phone, IsNull(APVM.MasterVendor,APTH.Vendor),
          MVendName = vrvAPVM_MasterVendor.Name, MVendorNotes = vrvAPVM_MasterVendor.Notes, MVAdd = vrvAPVM_MasterVendor.Address, 
          MVCity=vrvAPVM_MasterVendor.City, MVState = vrvAPVM_MasterVendor.State, MVZip = vrvAPVM_MasterVendor.Zip, 
          MVPhone = vrvAPVM_MasterVendor.Phone, MVCountry = vrvAPVM_MasterVendor.Country, 
          HQCO.HQCo, CoName=HQCO.Name
   FROM APTH  
   INNER JOIN HQCO  ON APTH.APCo=HQCO.HQCo
   INNER JOIN APVM  ON APTH.VendorGroup=APVM.VendorGroup AND APTH.Vendor=APVM.Vendor
   INNER JOIN vrvAPVM_MasterVendor on APTH.VendorGroup = vrvAPVM_MasterVendor.VendorGroup and 
                                        APTH.Vendor = vrvAPVM_MasterVendor.MasterVend
   LEFT OUTER JOIN APTL ON APTH.APCo=APTL.APCo AND APTH.Mth=APTL.Mth AND APTH.APTrans=APTL.APTrans
   LEFT OUTER JOIN APTD ON APTL.APCo=APTD.APCo AND APTL.Mth=APTD.Mth AND APTL.APTrans=APTD.APTrans AND APTL.APLine=APTD.APLine 
   LEFT OUTER JOIN APVM APVM_Supplier ON APTL.VendorGroup=APVM_Supplier.VendorGroup AND APTL.Supplier=APVM_Supplier.Vendor
   
UNION ALL

--Unapproved invoices where vendor is a sub vendor (i.e., has a master vendor)
   
   SELECT Type='U', APCo=APUI.APCo, Mth=APUI.UIMth, APTrans=APUI.UISeq, APUI.VendorGroup, 
   	APUI.Vendor, VendorName=APVM.Name, APUI.APRef, APUI.InvDate, APUI.Description, APUI.DueDate, 
   	NULL, NULL, APUL.PayType, 
          Amount=(case when APUL.MiscYN='Y' and APUL.TaxType in (1,3) then APUL.GrossAmt+APUL.MiscAmt+APUL.TaxAmt 
   	             when APUL.MiscYN='N' and APUL.TaxType in (1,3) then APUL.GrossAmt+APUL.TaxAmt 
                       when APUL.MiscYN='Y' and APUL.TaxType=2 then APUL.GrossAmt+APUL.MiscAmt else APUL.GrossAmt end), 
          APUL.Discount, 
   	NULL, NULL, NULL, APUI.CMCo, APUI.CMAcct, NULL, NULL, NULL,
   	Line=APUL.Line, APUL.LineType, LineDescription=APUL.Description,
   	APUL.Supplier,  SupplierName=APVM_Supplier.Name,  
   	APUL.JCCo, APUL.Job, APUL.PhaseGroup, APUL.Phase, APUL.JCCType, 
   	APUL.INCo, APUL.Loc, APUL.MatlGroup, APUL.Material, 
   	APUL.GLCo, APUL.GLAcct, 
   	APUL.EMCo, APUL.EMGroup, APUL.Equip, APUL.CompType, APUL.Component, APUL.WO, APUL.WOItem, APUL.CostCode, APUL.EMCType,
   	APUL.PO, APUL.POItem, APUL.ItemType, 
   	APUL.SL, APUL.SLItem,
   	APUL.UM, APUL.UnitCost, APUL.Units, APUL.GrossAmt, APUL.MiscAmt, APUL.MiscYN, 
          APUL.TaxGroup, APUL.TaxCode, APUL.TaxAmt, APUL.TaxType, 
   	APUI.UniqueAttchID, VendorNotes=APVM.Notes, HeaderNotes=APUI.Notes, 
   	LineNotes=APUL.Notes, APVM.Address, APVM.City, APVM.State, APVM.Zip, APVM.Country, APVM.Phone, APVM.MasterVendor, 
        MVendName = vrvAPVM_MasterVendor.Name, MVendorNotes = vrvAPVM_MasterVendor.Notes, MVAdd = vrvAPVM_MasterVendor.Address, 
        MVCity=vrvAPVM_MasterVendor.City, MVState = vrvAPVM_MasterVendor.State, MVZip =vrvAPVM_MasterVendor.Zip, MVPhone = vrvAPVM_MasterVendor.Phone,
        MVCountry = vrvAPVM_MasterVendor.Country, HQCO.HQCo, HQCO.Name
   FROM APUI 
   INNER JOIN HQCO  ON APUI.APCo=HQCO.HQCo 
   INNER JOIN APVM  ON APUI.VendorGroup=APVM.VendorGroup AND APUI.Vendor=APVM.Vendor
   INNER JOIN vrvAPVM_MasterVendor  on APVM.VendorGroup = vrvAPVM_MasterVendor.VendorGroup and APVM.MasterVendor = vrvAPVM_MasterVendor.MasterVend
   LEFT OUTER JOIN APUL  ON APUI.APCo=APUL.APCo AND APUI.UIMth=APUL.UIMth AND APUI.UISeq=APUL.UISeq
   LEFT OUTER JOIN APVM APVM_Supplier ON APUL.VendorGroup=APVM_Supplier.VendorGroup AND APUL.Supplier=APVM_Supplier.Vendor

UNION ALL

--Unapproved invoices where vendor is a master vendor

SELECT Type='U', APCo=APUI.APCo, Mth=APUI.UIMth, APTrans=APUI.UISeq, APUI.VendorGroup, 
   	APUI.Vendor, VendorName=APVM.Name, APUI.APRef, APUI.InvDate, APUI.Description, APUI.DueDate, 
   	NULL, NULL, APUL.PayType, 
          Amount=(case when APUL.MiscYN='Y' and APUL.TaxType in (1,3) then APUL.GrossAmt+APUL.MiscAmt+APUL.TaxAmt 
   	             when APUL.MiscYN='N' and APUL.TaxType in (1,3) then APUL.GrossAmt+APUL.TaxAmt 
                       when APUL.MiscYN='Y' and APUL.TaxType=2 then APUL.GrossAmt+APUL.MiscAmt else APUL.GrossAmt end), 
          APUL.Discount, 
   	NULL, NULL, NULL, APUI.CMCo, APUI.CMAcct, NULL, NULL, NULL,
   	Line=APUL.Line, APUL.LineType, LineDescription=APUL.Description,
   	APUL.Supplier,  SupplierName=APVM_Supplier.Name,  
   	APUL.JCCo, APUL.Job, APUL.PhaseGroup, APUL.Phase, APUL.JCCType, 
   	APUL.INCo, APUL.Loc, APUL.MatlGroup, APUL.Material, 
   	APUL.GLCo, APUL.GLAcct, 
   	APUL.EMCo, APUL.EMGroup, APUL.Equip, APUL.CompType, APUL.Component, APUL.WO, APUL.WOItem, APUL.CostCode, APUL.EMCType,
   	APUL.PO, APUL.POItem, APUL.ItemType, 
   	APUL.SL, APUL.SLItem,
   	APUL.UM, APUL.UnitCost, APUL.Units, APUL.GrossAmt, APUL.MiscAmt, APUL.MiscYN, 
          APUL.TaxGroup, APUL.TaxCode, APUL.TaxAmt, APUL.TaxType, 
   	APUI.UniqueAttchID, VendorNotes=APVM.Notes, HeaderNotes=APUI.Notes, 
   	LineNotes=APUL.Notes, APVM.Address, APVM.City, APVM.State, APVM.Zip, APVM.Country, APVM.Phone, IsNull(APVM.MasterVendor, APUI.Vendor), 
        MVendName = vrvAPVM_MasterVendor.Name, MVendorNotes = vrvAPVM_MasterVendor.Notes, MVAdd = vrvAPVM_MasterVendor.Address, 
        MVCity=vrvAPVM_MasterVendor.City, MVState = vrvAPVM_MasterVendor.State, MVZip =vrvAPVM_MasterVendor.Zip, MVPhone = vrvAPVM_MasterVendor.Phone,
        MVCountry = vrvAPVM_MasterVendor.Country, HQCO.HQCo, HQCO.Name
   FROM APUI 
   INNER JOIN HQCO  ON APUI.APCo=HQCO.HQCo 
   INNER JOIN APVM  ON APUI.VendorGroup=APVM.VendorGroup AND APUI.Vendor=APVM.Vendor
   INNER JOIN vrvAPVM_MasterVendor  on APUI.VendorGroup = vrvAPVM_MasterVendor.VendorGroup and APUI.Vendor = vrvAPVM_MasterVendor.MasterVend
   LEFT OUTER JOIN APUL  ON APUI.APCo=APUL.APCo AND APUI.UIMth=APUL.UIMth AND APUI.UISeq=APUL.UISeq
   LEFT OUTER JOIN APVM APVM_Supplier ON APUL.VendorGroup=APVM_Supplier.VendorGroup AND APUL.Supplier=APVM_Supplier.Vendor
GO
GRANT SELECT ON  [dbo].[vrvAP_MVAllInvoices] TO [public]
GRANT INSERT ON  [dbo].[vrvAP_MVAllInvoices] TO [public]
GRANT DELETE ON  [dbo].[vrvAP_MVAllInvoices] TO [public]
GRANT UPDATE ON  [dbo].[vrvAP_MVAllInvoices] TO [public]
GRANT SELECT ON  [dbo].[vrvAP_MVAllInvoices] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvAP_MVAllInvoices] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvAP_MVAllInvoices] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvAP_MVAllInvoices] TO [Viewpoint]
GO
