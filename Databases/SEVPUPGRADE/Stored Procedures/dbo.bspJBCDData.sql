SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[bspJBCDData]
   /************************************************
   	Created: RM 09/16/04
   	Modified:
   
   
   	Usage: 
   		Used to get the proper data to generate a CD of attachments
   		associated with a JB Bill.  
   
   	Parameters:
   
   	@co - Company
   	@mth - Month
   	@billnum - Bill Number
   
   
   
   
   *************************************************/
   (@co int=null, @mth bMonth=null, @billnum int=null)
   as
   
   
   
   /***************************AP Invoices****************************************/
   select HQCO.Name,
   
   
   
    JBIN.JBCo, JBIN.BillMonth, JBIN.BillNumber, JBIN.Invoice, JBIN.Contract, JBIN.CustGroup, JBIN.Customer, JBIN.InvStatus
   , JBIN.Application, JBIN.ProcessGroup, JBIN.RestrictBillGroupYN, JBIN.BillGroup, JBIN.RecType, JBIN.DueDate, JBIN.InvDate
   , JBIN.PayTerms, JBIN.DiscDate, JBIN.FromDate, JBIN.ToDate, JBIN.BillAddress, JBIN.BillAddress2, JBIN.BillCity, JBIN.BillState, JBIN.BillZip, JBIN.ARTrans, JBIN.InvTotal, JBIN.InvRetg, JBIN.RetgRel, JBIN.InvDisc, JBIN.TaxBasis, JBIN.InvTax
   , JBIN.InvDue, JBIN.PrevAmt, JBIN.PrevRetg, JBIN.PrevRRel, JBIN.PrevTax, JBIN.PrevDue, JBIN.ARRelRetgTran, JBIN.ARRelRetgCrTran, JBIN.ARGLCo, JBIN.JCGLCo, JBIN.CurrContract, JBIN.PrevWC, JBIN.WC, JBIN.PrevSM, JBIN.Installed, JBIN.Purchased, JBIN.SM, JBIN.SMRetg, JBIN.PrevSMRetg, JBIN.PrevWCRetg, JBIN.WCRetg, JBIN.PrevChgOrderAdds, JBIN.PrevChgOrderDeds, JBIN.ChgOrderAmt, JBIN.AutoInitYN, JBIN.InUseBatchId, JBIN.InUseMth,  JBIN.BillOnCompleteYN, JBIN.BillType, JBIN.Template
   , JBIN.CustomerReference, JBIN.CustomerJob, JBIN.ACOThruDate, JBIN.Purge, JBIN.AuditYN, JBIN.OverrideGLRevAcctYN, JBIN.OverrideGLRevAcct, JBIN.UniqueAttchID, JBIN.RevRelRetgYN,
   
   
   JBIL.JBCo, JBIL.BillMonth, JBIL.BillNumber, JBIL.Line, JBIL.Item, JBIL.Contract, JBIL.Job, JBIL.PhaseGroup, JBIL.Phase
   , JBIL.Date, JBIL.Template, JBIL.TemplateSeq, JBIL.TemplateSortLevel, JBIL.TemplateSeqSumOpt, JBIL.TemplateSeqGroup
   , JBIL.LineType, JBIL.Description, JBIL.TaxGroup, JBIL.TaxCode, JBIL.MarkupOpt, JBIL.MarkupRate, JBIL.Basis, JBIL.MarkupAddl, JBIL.MarkupTotal, JBIL.Total, JBIL.Retainage, JBIL.Discount, JBIL.NewLine, JBIL.ReseqYN, JBIL.LineKey
   , JBIL.TemplateGroupNum, JBIL.LineForAddon, JBIL.AuditYN, JBIL.Purge, JBIL.UniqueAttchID,
   
   HQAT.HQCo, HQAT.FormName, HQAT.KeyField, HQAT.Description, HQAT.AddedBy, HQAT.AddDate, HQAT.DocName,(convert(varchar(255),HQAT.AttachmentID) + Right(HQAT.DocName, CHARINDEX('.',Reverse(HQAT.DocName)))) as LocalDoc, HQAT.AttachmentID
   , HQAT.TableName, HQAT.UniqueAttchID,
   
   HQAI.AttachmentID, HQAI.IndexSeq, HQAI.IndexName, HQAI.APCo, HQAI.APVendorGroup, HQAI.APVendor, HQAI.APReference, HQAI.APCheckNumber
   , HQAI.ARCo, HQAI.ARCustomer, HQAI.ARInvoice, HQAI.JCCo, HQAI.JCJob, HQAI.JCPhaseGroup, HQAI.JCPhase, HQAI.JCCostType
   , HQAI.JCContract, HQAI.JCContractItem, HQAI.POCo, HQAI.POPurchaseOrder, HQAI.POItem, HQAI.EMCo, HQAI.EMEquipment, HQAI.EMCostCode, HQAI.EMCostType, HQAI.PRCo, HQAI.PREmployee, HQAI.HRCo, HQAI.HRReference, HQAI.MIMaterialGroup, HQAI.MIMaterial, HQAI.MIMonth
   , HQAI.MITransaction, HQAI.INCo, HQAI.INLoc, HQAI.MSCo, HQAI.MSTicket, HQAI.SLCo, HQAI.SLSubcontract, HQAI.SLSubcontractItem, HQAI.UniqueAttchID, HQAI.CustomYN, HQAI.UserCustom1, HQAI.UserCustom2, HQAI.UserCustom3, HQAI.UserCustom4, HQAI.UserCustom5, HQAI.PMIssue, HQAI.PMFirmNumber, HQAI.PMFirmType, HQAI.PMFirmContact, HQAI.PMSubmSrcFirm, HQAI.PMSubmSrcContact, HQAI.ARCustGroup, HQAI.EMGroup, HQAI.PMACO, HQAI.PMACOItem, HQAI.PMPCO, HQAI.PMPCOItem, HQAI.PMPCOType, HQAI.PMDocType, HQAI.PMSubmittal, HQAI.PMTransmittal
   , HQAI.PMRFQ, HQAI.PMRFI, HQAI.PMDocument, HQAI.PMInspectionCode, HQAI.PMTestCode, HQAI.PMDrawing, HQAI.PMMeeting, HQAI.PMPunchList, HQAI.PMLogDate, HQAI.PMDailyLog
   
   
   from bJBIN JBIN
   		join HQCO on JBIN.JBCo=HQCO.HQCo
   		join JBIL on JBIN.JBCo=JBIL.JBCo and JBIN.BillMonth=JBIL.BillMonth and JBIN.BillNumber=JBIL.BillNumber
   		join JBID on JBIL.JBCo=JBID.JBCo and JBIL.BillMonth=JBID.BillMonth and JBIL.BillNumber=JBID.BillNumber and JBIL.Line=JBID.Line 
   		join JBIJ on JBID.JBCo=JBIJ.JBCo and JBID.BillMonth=JBIJ.BillMonth and JBID.BillNumber=JBIJ.BillNumber and JBID.Line=JBIJ.Line  and JBID.Seq=JBIJ.Seq
   	      	join JCCD on JBIJ.JBCo=JCCD.JCCo and JBIJ.JCMonth=JCCD.Mth and JBIJ.JCTrans=JCCD.CostTrans
   	 	join APTL on APTL.APLine=JCCD.APLine and JCCD.APCo=APTL.APCo and JCCD.Mth=APTL.Mth and JCCD.APTrans=APTL.APTrans
   	      	join APTH on APTL.APCo=APTH.APCo and APTL.APTrans=APTH.APTrans and APTL.Mth=APTH.Mth
   		join HQAT on APTH.UniqueAttchID=HQAT.UniqueAttchID
   		join HQAI on HQAT.AttachmentID=HQAI.AttachmentID
   where JBIN.JBCo=@co and JBIN.BillMonth=@mth and JBIN.BillNumber=@billnum
   
   
   UNION
   
   
   /***************************PR Timecards****************************************/
   select HQCO.Name,
   
   
   
    JBIN.JBCo, JBIN.BillMonth, JBIN.BillNumber, JBIN.Invoice, JBIN.Contract, JBIN.CustGroup, JBIN.Customer, JBIN.InvStatus
   , JBIN.Application, JBIN.ProcessGroup, JBIN.RestrictBillGroupYN, JBIN.BillGroup, JBIN.RecType, JBIN.DueDate, JBIN.InvDate
   , JBIN.PayTerms, JBIN.DiscDate, JBIN.FromDate, JBIN.ToDate, JBIN.BillAddress, JBIN.BillAddress2, JBIN.BillCity, JBIN.BillState, JBIN.BillZip, JBIN.ARTrans, JBIN.InvTotal, JBIN.InvRetg, JBIN.RetgRel, JBIN.InvDisc, JBIN.TaxBasis, JBIN.InvTax
   , JBIN.InvDue, JBIN.PrevAmt, JBIN.PrevRetg, JBIN.PrevRRel, JBIN.PrevTax, JBIN.PrevDue, JBIN.ARRelRetgTran, JBIN.ARRelRetgCrTran, JBIN.ARGLCo, JBIN.JCGLCo, JBIN.CurrContract, JBIN.PrevWC, JBIN.WC, JBIN.PrevSM, JBIN.Installed, JBIN.Purchased, JBIN.SM, JBIN.SMRetg, JBIN.PrevSMRetg, JBIN.PrevWCRetg, JBIN.WCRetg, JBIN.PrevChgOrderAdds, JBIN.PrevChgOrderDeds, JBIN.ChgOrderAmt, JBIN.AutoInitYN, JBIN.InUseBatchId, JBIN.InUseMth,  JBIN.BillOnCompleteYN, JBIN.BillType, JBIN.Template
   , JBIN.CustomerReference, JBIN.CustomerJob, JBIN.ACOThruDate, JBIN.Purge, JBIN.AuditYN, JBIN.OverrideGLRevAcctYN, JBIN.OverrideGLRevAcct, JBIN.UniqueAttchID, JBIN.RevRelRetgYN,
   
   
   JBIL.JBCo, JBIL.BillMonth, JBIL.BillNumber, JBIL.Line, JBIL.Item, JBIL.Contract, JBIL.Job, JBIL.PhaseGroup, JBIL.Phase
   , JBIL.Date, JBIL.Template, JBIL.TemplateSeq, JBIL.TemplateSortLevel, JBIL.TemplateSeqSumOpt, JBIL.TemplateSeqGroup
   , JBIL.LineType, JBIL.Description, JBIL.TaxGroup, JBIL.TaxCode, JBIL.MarkupOpt, JBIL.MarkupRate, JBIL.Basis, JBIL.MarkupAddl, JBIL.MarkupTotal, JBIL.Total, JBIL.Retainage, JBIL.Discount, JBIL.NewLine, JBIL.ReseqYN, JBIL.LineKey
   , JBIL.TemplateGroupNum, JBIL.LineForAddon, JBIL.AuditYN, JBIL.Purge, JBIL.UniqueAttchID,
   
   HQAT.HQCo, HQAT.FormName, HQAT.KeyField, HQAT.Description, HQAT.AddedBy, HQAT.AddDate, HQAT.DocName,(convert(varchar(255),HQAT.AttachmentID) + Right(HQAT.DocName, CHARINDEX('.',Reverse(HQAT.DocName)))) as LocalDoc, HQAT.AttachmentID
   , HQAT.TableName, HQAT.UniqueAttchID,
   
   HQAI.AttachmentID, HQAI.IndexSeq, HQAI.IndexName, HQAI.APCo, HQAI.APVendorGroup, HQAI.APVendor, HQAI.APReference, HQAI.APCheckNumber
   , HQAI.ARCo, HQAI.ARCustomer, HQAI.ARInvoice, HQAI.JCCo, HQAI.JCJob, HQAI.JCPhaseGroup, HQAI.JCPhase, HQAI.JCCostType
   , HQAI.JCContract, HQAI.JCContractItem, HQAI.POCo, HQAI.POPurchaseOrder, HQAI.POItem, HQAI.EMCo, HQAI.EMEquipment, HQAI.EMCostCode, HQAI.EMCostType, HQAI.PRCo, HQAI.PREmployee, HQAI.HRCo, HQAI.HRReference, HQAI.MIMaterialGroup, HQAI.MIMaterial, HQAI.MIMonth
   , HQAI.MITransaction, HQAI.INCo, HQAI.INLoc, HQAI.MSCo, HQAI.MSTicket, HQAI.SLCo, HQAI.SLSubcontract, HQAI.SLSubcontractItem, HQAI.UniqueAttchID, HQAI.CustomYN, HQAI.UserCustom1, HQAI.UserCustom2, HQAI.UserCustom3, HQAI.UserCustom4, HQAI.UserCustom5, HQAI.PMIssue, HQAI.PMFirmNumber, HQAI.PMFirmType, HQAI.PMFirmContact, HQAI.PMSubmSrcFirm, HQAI.PMSubmSrcContact, HQAI.ARCustGroup, HQAI.EMGroup, HQAI.PMACO, HQAI.PMACOItem, HQAI.PMPCO, HQAI.PMPCOItem, HQAI.PMPCOType, HQAI.PMDocType, HQAI.PMSubmittal, HQAI.PMTransmittal
   , HQAI.PMRFQ, HQAI.PMRFI, HQAI.PMDocument, HQAI.PMInspectionCode, HQAI.PMTestCode, HQAI.PMDrawing, HQAI.PMMeeting, HQAI.PMPunchList, HQAI.PMLogDate, HQAI.PMDailyLog
   
   
   from JBIN JBIN
   		join HQCO on JBIN.JBCo=HQCO.HQCo
   		join JBIL on JBIN.JBCo=JBIL.JBCo and JBIN.BillMonth=JBIL.BillMonth and JBIN.BillNumber=JBIL.BillNumber
   		join JBID on JBIL.JBCo=JBID.JBCo and JBIL.BillMonth=JBID.BillMonth and JBIL.BillNumber=JBID.BillNumber and JBIL.Line=JBID.Line
   		join JBIJ on JBID.JBCo=JBIJ.JBCo and JBID.BillMonth=JBIJ.BillMonth and JBID.BillNumber=JBIJ.BillNumber and JBID.Line=JBIJ.Line and JBID.Seq=JBIJ.Seq
   		join /*Derived Table JCPR is a join of JCCR and PRJC*/
   			(Select JCCD.*,PRJC.PRGroup,PRJC.PREndDate,PRJC.PaySeq,PRJC.PostSeq from JCCD join PRJC on JCCD.JCCo=PRJC.JCCo and JCCD.Mth=PRJC.Mth and JCCD.Job=PRJC.Job and JCCD.PhaseGroup=PRJC.PhaseGroup and JCCD.Phase=PRJC.Phase and JCCD.CostType=PRJC.JCCostType and JCCD.ActualDate=PRJC.PostDate and JCCD.PRCo=PRJC.PRCo and JCCD.Employee=PRJC.Employee and JCCD.Craft=PRJC.Craft and JCCD.Class=PRJC.Class) 
   			as JCPR on JBIJ.JBCo=JCPR.JCCo and JBIJ.JCMonth=JCPR.Mth and JBIJ.JCTrans=JCPR.CostTrans
   	 	join PRTH on JCPR.PRCo=PRTH.PRCo and JCPR.PRGroup=PRTH.PRGroup and JCPR.PREndDate=PRTH.PREndDate and JCPR.Employee=PRTH.Employee and JCPR.PaySeq=PRTH.PaySeq and JCPR.PostSeq=PRTH.PostSeq
   		join HQAT on PRTH.UniqueAttchID=HQAT.UniqueAttchID
   		join HQAI on HQAT.AttachmentID=HQAI.AttachmentID
   
   where JBIN.JBCo=@co and JBIN.BillMonth=@mth and JBIN.BillNumber=@billnum
   
   UNION
   
   
   /***************************MS Tickets****************************************/
   select HQCO.Name,
   
   
   
    JBIN.JBCo, JBIN.BillMonth, JBIN.BillNumber, JBIN.Invoice, JBIN.Contract, JBIN.CustGroup, JBIN.Customer, JBIN.InvStatus
   , JBIN.Application, JBIN.ProcessGroup, JBIN.RestrictBillGroupYN, JBIN.BillGroup, JBIN.RecType, JBIN.DueDate, JBIN.InvDate
   , JBIN.PayTerms, JBIN.DiscDate, JBIN.FromDate, JBIN.ToDate, JBIN.BillAddress, JBIN.BillAddress2, JBIN.BillCity, JBIN.BillState, JBIN.BillZip, JBIN.ARTrans, JBIN.InvTotal, JBIN.InvRetg, JBIN.RetgRel, JBIN.InvDisc, JBIN.TaxBasis, JBIN.InvTax
   , JBIN.InvDue, JBIN.PrevAmt, JBIN.PrevRetg, JBIN.PrevRRel, JBIN.PrevTax, JBIN.PrevDue, JBIN.ARRelRetgTran, JBIN.ARRelRetgCrTran, JBIN.ARGLCo, JBIN.JCGLCo, JBIN.CurrContract, JBIN.PrevWC, JBIN.WC, JBIN.PrevSM, JBIN.Installed, JBIN.Purchased, JBIN.SM, JBIN.SMRetg, JBIN.PrevSMRetg, JBIN.PrevWCRetg, JBIN.WCRetg, JBIN.PrevChgOrderAdds, JBIN.PrevChgOrderDeds, JBIN.ChgOrderAmt, JBIN.AutoInitYN, JBIN.InUseBatchId, JBIN.InUseMth,  JBIN.BillOnCompleteYN, JBIN.BillType, JBIN.Template
   , JBIN.CustomerReference, JBIN.CustomerJob, JBIN.ACOThruDate, JBIN.Purge, JBIN.AuditYN, JBIN.OverrideGLRevAcctYN, JBIN.OverrideGLRevAcct, JBIN.UniqueAttchID, JBIN.RevRelRetgYN,
   
   
   JBIL.JBCo, JBIL.BillMonth, JBIL.BillNumber, JBIL.Line, JBIL.Item, JBIL.Contract, JBIL.Job, JBIL.PhaseGroup, JBIL.Phase
   , JBIL.Date, JBIL.Template, JBIL.TemplateSeq, JBIL.TemplateSortLevel, JBIL.TemplateSeqSumOpt, JBIL.TemplateSeqGroup
   , JBIL.LineType, JBIL.Description, JBIL.TaxGroup, JBIL.TaxCode, JBIL.MarkupOpt, JBIL.MarkupRate, JBIL.Basis, JBIL.MarkupAddl, JBIL.MarkupTotal, JBIL.Total, JBIL.Retainage, JBIL.Discount, JBIL.NewLine, JBIL.ReseqYN, JBIL.LineKey
   , JBIL.TemplateGroupNum, JBIL.LineForAddon, JBIL.AuditYN, JBIL.Purge, JBIL.UniqueAttchID,
   
   HQAT.HQCo, HQAT.FormName, HQAT.KeyField, HQAT.Description, HQAT.AddedBy, HQAT.AddDate, HQAT.DocName,(convert(varchar(255),HQAT.AttachmentID) + Right(HQAT.DocName, CHARINDEX('.',Reverse(HQAT.DocName)))) as LocalDoc, HQAT.AttachmentID
   , HQAT.TableName, HQAT.UniqueAttchID,
   
   HQAI.AttachmentID, HQAI.IndexSeq, HQAI.IndexName, HQAI.APCo, HQAI.APVendorGroup, HQAI.APVendor, HQAI.APReference, HQAI.APCheckNumber
   , HQAI.ARCo, HQAI.ARCustomer, HQAI.ARInvoice, HQAI.JCCo, HQAI.JCJob, HQAI.JCPhaseGroup, HQAI.JCPhase, HQAI.JCCostType
   , HQAI.JCContract, HQAI.JCContractItem, HQAI.POCo, HQAI.POPurchaseOrder, HQAI.POItem, HQAI.EMCo, HQAI.EMEquipment, HQAI.EMCostCode, HQAI.EMCostType, HQAI.PRCo, HQAI.PREmployee, HQAI.HRCo, HQAI.HRReference, HQAI.MIMaterialGroup, HQAI.MIMaterial, HQAI.MIMonth
   , HQAI.MITransaction, HQAI.INCo, HQAI.INLoc, HQAI.MSCo, HQAI.MSTicket, HQAI.SLCo, HQAI.SLSubcontract, HQAI.SLSubcontractItem, HQAI.UniqueAttchID, HQAI.CustomYN, HQAI.UserCustom1, HQAI.UserCustom2, HQAI.UserCustom3, HQAI.UserCustom4, HQAI.UserCustom5, HQAI.PMIssue, HQAI.PMFirmNumber, HQAI.PMFirmType, HQAI.PMFirmContact, HQAI.PMSubmSrcFirm, HQAI.PMSubmSrcContact, HQAI.ARCustGroup, HQAI.EMGroup, HQAI.PMACO, HQAI.PMACOItem, HQAI.PMPCO, HQAI.PMPCOItem, HQAI.PMPCOType, HQAI.PMDocType, HQAI.PMSubmittal, HQAI.PMTransmittal
   , HQAI.PMRFQ, HQAI.PMRFI, HQAI.PMDocument, HQAI.PMInspectionCode, HQAI.PMTestCode, HQAI.PMDrawing, HQAI.PMMeeting, HQAI.PMPunchList, HQAI.PMLogDate, HQAI.PMDailyLog
   
   
   from bJBIN JBIN
   		join HQCO on JBIN.JBCo=HQCO.HQCo
   		join JBIL on JBIN.JBCo=JBIL.JBCo and JBIN.BillMonth=JBIL.BillMonth and JBIN.BillNumber=JBIL.BillNumber
   		join JBID on JBIL.JBCo=JBID.JBCo and JBIL.BillMonth=JBID.BillMonth and JBIL.BillNumber=JBID.BillNumber and JBIL.Line=JBID.Line 
   		join JBIJ on JBID.JBCo=JBIJ.JBCo and JBID.BillMonth=JBIJ.BillMonth and JBID.BillNumber=JBIJ.BillNumber and JBID.Line=JBIJ.Line  and JBID.Seq=JBIJ.Seq
   	      	join JCCD on JBIJ.JBCo=JCCD.JCCo and JBIJ.JCMonth=JCCD.Mth and JBIJ.JCTrans=JCCD.CostTrans
   	 	join MSTD on JCCD.JCCo=MSTD.MSCo and JCCD.Mth=MSTD.Mth and JCCD.MSTrans=MSTD.MSTrans
   		join HQAT on MSTD.UniqueAttchID=HQAT.UniqueAttchID
   		join HQAI on HQAT.AttachmentID=HQAI.AttachmentID
   where JBIN.JBCo=@co and JBIN.BillMonth=@mth and JBIN.BillNumber=@billnum
   
   UNION
   
   
   /***************************EM Work Orders****************************************/
   select HQCO.Name,
   
   
   
    JBIN.JBCo, JBIN.BillMonth, JBIN.BillNumber, JBIN.Invoice, JBIN.Contract, JBIN.CustGroup, JBIN.Customer, JBIN.InvStatus
   , JBIN.Application, JBIN.ProcessGroup, JBIN.RestrictBillGroupYN, JBIN.BillGroup, JBIN.RecType, JBIN.DueDate, JBIN.InvDate
   , JBIN.PayTerms, JBIN.DiscDate, JBIN.FromDate, JBIN.ToDate, JBIN.BillAddress, JBIN.BillAddress2, JBIN.BillCity, JBIN.BillState, JBIN.BillZip, JBIN.ARTrans, JBIN.InvTotal, JBIN.InvRetg, JBIN.RetgRel, JBIN.InvDisc, JBIN.TaxBasis, JBIN.InvTax
   , JBIN.InvDue, JBIN.PrevAmt, JBIN.PrevRetg, JBIN.PrevRRel, JBIN.PrevTax, JBIN.PrevDue, JBIN.ARRelRetgTran, JBIN.ARRelRetgCrTran, JBIN.ARGLCo, JBIN.JCGLCo, JBIN.CurrContract, JBIN.PrevWC, JBIN.WC, JBIN.PrevSM, JBIN.Installed, JBIN.Purchased, JBIN.SM, JBIN.SMRetg, JBIN.PrevSMRetg, JBIN.PrevWCRetg, JBIN.WCRetg, JBIN.PrevChgOrderAdds, JBIN.PrevChgOrderDeds, JBIN.ChgOrderAmt, JBIN.AutoInitYN, JBIN.InUseBatchId, JBIN.InUseMth,  JBIN.BillOnCompleteYN, JBIN.BillType, JBIN.Template
   , JBIN.CustomerReference, JBIN.CustomerJob, JBIN.ACOThruDate, JBIN.Purge, JBIN.AuditYN, JBIN.OverrideGLRevAcctYN, JBIN.OverrideGLRevAcct, JBIN.UniqueAttchID, JBIN.RevRelRetgYN,
   
   
   JBIL.JBCo, JBIL.BillMonth, JBIL.BillNumber, JBIL.Line, JBIL.Item, JBIL.Contract, JBIL.Job, JBIL.PhaseGroup, JBIL.Phase
   , JBIL.Date, JBIL.Template, JBIL.TemplateSeq, JBIL.TemplateSortLevel, JBIL.TemplateSeqSumOpt, JBIL.TemplateSeqGroup
   , JBIL.LineType, JBIL.Description, JBIL.TaxGroup, JBIL.TaxCode, JBIL.MarkupOpt, JBIL.MarkupRate, JBIL.Basis, JBIL.MarkupAddl, JBIL.MarkupTotal, JBIL.Total, JBIL.Retainage, JBIL.Discount, JBIL.NewLine, JBIL.ReseqYN, JBIL.LineKey
   , JBIL.TemplateGroupNum, JBIL.LineForAddon, JBIL.AuditYN, JBIL.Purge, JBIL.UniqueAttchID,
   
   HQAT.HQCo, HQAT.FormName, HQAT.KeyField, HQAT.Description, HQAT.AddedBy, HQAT.AddDate, HQAT.DocName,(convert(varchar(255),HQAT.AttachmentID) + Right(HQAT.DocName, CHARINDEX('.',Reverse(HQAT.DocName)))) as LocalDoc, HQAT.AttachmentID
   , HQAT.TableName, HQAT.UniqueAttchID,
   
   HQAI.AttachmentID, HQAI.IndexSeq, HQAI.IndexName, HQAI.APCo, HQAI.APVendorGroup, HQAI.APVendor, HQAI.APReference, HQAI.APCheckNumber
   , HQAI.ARCo, HQAI.ARCustomer, HQAI.ARInvoice, HQAI.JCCo, HQAI.JCJob, HQAI.JCPhaseGroup, HQAI.JCPhase, HQAI.JCCostType
   , HQAI.JCContract, HQAI.JCContractItem, HQAI.POCo, HQAI.POPurchaseOrder, HQAI.POItem, HQAI.EMCo, HQAI.EMEquipment, HQAI.EMCostCode, HQAI.EMCostType, HQAI.PRCo, HQAI.PREmployee, HQAI.HRCo, HQAI.HRReference, HQAI.MIMaterialGroup, HQAI.MIMaterial, HQAI.MIMonth
   , HQAI.MITransaction, HQAI.INCo, HQAI.INLoc, HQAI.MSCo, HQAI.MSTicket, HQAI.SLCo, HQAI.SLSubcontract, HQAI.SLSubcontractItem, HQAI.UniqueAttchID, HQAI.CustomYN, HQAI.UserCustom1, HQAI.UserCustom2, HQAI.UserCustom3, HQAI.UserCustom4, HQAI.UserCustom5, HQAI.PMIssue, HQAI.PMFirmNumber, HQAI.PMFirmType, HQAI.PMFirmContact, HQAI.PMSubmSrcFirm, HQAI.PMSubmSrcContact, HQAI.ARCustGroup, HQAI.EMGroup, HQAI.PMACO, HQAI.PMACOItem, HQAI.PMPCO, HQAI.PMPCOItem, HQAI.PMPCOType, HQAI.PMDocType, HQAI.PMSubmittal, HQAI.PMTransmittal
   , HQAI.PMRFQ, HQAI.PMRFI, HQAI.PMDocument, HQAI.PMInspectionCode, HQAI.PMTestCode, HQAI.PMDrawing, HQAI.PMMeeting, HQAI.PMPunchList, HQAI.PMLogDate, HQAI.PMDailyLog
   
   
   
   
   from bJBIN JBIN
   		join HQCO on JBIN.JBCo=HQCO.HQCo
   		join JBIL on JBIN.JBCo=JBIL.JBCo and JBIN.BillMonth=JBIL.BillMonth and JBIN.BillNumber=JBIL.BillNumber
   		join JBID on JBIL.JBCo=JBID.JBCo and JBIL.BillMonth=JBID.BillMonth and JBIL.BillNumber=JBID.BillNumber and JBIL.Line=JBID.Line 
   		join JBIJ on JBID.JBCo=JBIJ.JBCo and JBID.BillMonth=JBIJ.BillMonth and JBID.BillNumber=JBIJ.BillNumber and JBID.Line=JBIJ.Line  and JBID.Seq=JBIJ.Seq
   	      	join JCCD on JBIJ.JBCo=JCCD.JCCo and JBIJ.JCMonth=JCCD.Mth and JBIJ.JCTrans=JCCD.CostTrans
   	 	join EMRD on JCCD.EMCo=EMRD.EMCo and JCCD.EMEquip=EMRD.Equipment and JCCD.Mth=EMRD.Mth and JCCD.EMTrans=EMRD.Trans 
   		join HQAT on EMRD.UniqueAttchID=HQAT.UniqueAttchID
   		join HQAI on HQAT.AttachmentID=HQAI.AttachmentID
   where JBIN.JBCo=@co and JBIN.BillMonth=@mth and JBIN.BillNumber=@billnum
   
   UNION
   
   /***************************IN Material Orders****************************************/
   select HQCO.Name,
   
   
   
    JBIN.JBCo, JBIN.BillMonth, JBIN.BillNumber, JBIN.Invoice, JBIN.Contract, JBIN.CustGroup, JBIN.Customer, JBIN.InvStatus
   , JBIN.Application, JBIN.ProcessGroup, JBIN.RestrictBillGroupYN, JBIN.BillGroup, JBIN.RecType, JBIN.DueDate, JBIN.InvDate
   , JBIN.PayTerms, JBIN.DiscDate, JBIN.FromDate, JBIN.ToDate, JBIN.BillAddress, JBIN.BillAddress2, JBIN.BillCity, JBIN.BillState, JBIN.BillZip, JBIN.ARTrans, JBIN.InvTotal, JBIN.InvRetg, JBIN.RetgRel, JBIN.InvDisc, JBIN.TaxBasis, JBIN.InvTax
   , JBIN.InvDue, JBIN.PrevAmt, JBIN.PrevRetg, JBIN.PrevRRel, JBIN.PrevTax, JBIN.PrevDue, JBIN.ARRelRetgTran, JBIN.ARRelRetgCrTran, JBIN.ARGLCo, JBIN.JCGLCo, JBIN.CurrContract, JBIN.PrevWC, JBIN.WC, JBIN.PrevSM, JBIN.Installed, JBIN.Purchased, JBIN.SM, JBIN.SMRetg, JBIN.PrevSMRetg, JBIN.PrevWCRetg, JBIN.WCRetg, JBIN.PrevChgOrderAdds, JBIN.PrevChgOrderDeds, JBIN.ChgOrderAmt, JBIN.AutoInitYN, JBIN.InUseBatchId, JBIN.InUseMth,  JBIN.BillOnCompleteYN, JBIN.BillType, JBIN.Template
   , JBIN.CustomerReference, JBIN.CustomerJob, JBIN.ACOThruDate, JBIN.Purge, JBIN.AuditYN, JBIN.OverrideGLRevAcctYN, JBIN.OverrideGLRevAcct, JBIN.UniqueAttchID, JBIN.RevRelRetgYN,
   
   
   JBIL.JBCo, JBIL.BillMonth, JBIL.BillNumber, JBIL.Line, JBIL.Item, JBIL.Contract, JBIL.Job, JBIL.PhaseGroup, JBIL.Phase
   , JBIL.Date, JBIL.Template, JBIL.TemplateSeq, JBIL.TemplateSortLevel, JBIL.TemplateSeqSumOpt, JBIL.TemplateSeqGroup
   , JBIL.LineType, JBIL.Description, JBIL.TaxGroup, JBIL.TaxCode, JBIL.MarkupOpt, JBIL.MarkupRate, JBIL.Basis, JBIL.MarkupAddl, JBIL.MarkupTotal, JBIL.Total, JBIL.Retainage, JBIL.Discount, JBIL.NewLine, JBIL.ReseqYN, JBIL.LineKey
   , JBIL.TemplateGroupNum, JBIL.LineForAddon, JBIL.AuditYN, JBIL.Purge, JBIL.UniqueAttchID,
   
   HQAT.HQCo, HQAT.FormName, HQAT.KeyField, HQAT.Description, HQAT.AddedBy, HQAT.AddDate, HQAT.DocName,(convert(varchar(255),HQAT.AttachmentID) + Right(HQAT.DocName, CHARINDEX('.',Reverse(HQAT.DocName)))) as LocalDoc, HQAT.AttachmentID
   , HQAT.TableName, HQAT.UniqueAttchID,
   
   HQAI.AttachmentID, HQAI.IndexSeq, HQAI.IndexName, HQAI.APCo, HQAI.APVendorGroup, HQAI.APVendor, HQAI.APReference, HQAI.APCheckNumber
   , HQAI.ARCo, HQAI.ARCustomer, HQAI.ARInvoice, HQAI.JCCo, HQAI.JCJob, HQAI.JCPhaseGroup, HQAI.JCPhase, HQAI.JCCostType
   , HQAI.JCContract, HQAI.JCContractItem, HQAI.POCo, HQAI.POPurchaseOrder, HQAI.POItem, HQAI.EMCo, HQAI.EMEquipment, HQAI.EMCostCode, HQAI.EMCostType, HQAI.PRCo, HQAI.PREmployee, HQAI.HRCo, HQAI.HRReference, HQAI.MIMaterialGroup, HQAI.MIMaterial, HQAI.MIMonth
   , HQAI.MITransaction, HQAI.INCo, HQAI.INLoc, HQAI.MSCo, HQAI.MSTicket, HQAI.SLCo, HQAI.SLSubcontract, HQAI.SLSubcontractItem, HQAI.UniqueAttchID, HQAI.CustomYN, HQAI.UserCustom1, HQAI.UserCustom2, HQAI.UserCustom3, HQAI.UserCustom4, HQAI.UserCustom5, HQAI.PMIssue, HQAI.PMFirmNumber, HQAI.PMFirmType, HQAI.PMFirmContact, HQAI.PMSubmSrcFirm, HQAI.PMSubmSrcContact, HQAI.ARCustGroup, HQAI.EMGroup, HQAI.PMACO, HQAI.PMACOItem, HQAI.PMPCO, HQAI.PMPCOItem, HQAI.PMPCOType, HQAI.PMDocType, HQAI.PMSubmittal, HQAI.PMTransmittal
   , HQAI.PMRFQ, HQAI.PMRFI, HQAI.PMDocument, HQAI.PMInspectionCode, HQAI.PMTestCode, HQAI.PMDrawing, HQAI.PMMeeting, HQAI.PMPunchList, HQAI.PMLogDate, HQAI.PMDailyLog
   
   
   
   
   from bJBIN JBIN
   		join HQCO on JBIN.JBCo=HQCO.HQCo
   		join JBIL on JBIN.JBCo=JBIL.JBCo and JBIN.BillMonth=JBIL.BillMonth and JBIN.BillNumber=JBIL.BillNumber
   		join JBID on JBIL.JBCo=JBID.JBCo and JBIL.BillMonth=JBID.BillMonth and JBIL.BillNumber=JBID.BillNumber and JBIL.Line=JBID.Line 
   		join JBIJ on JBID.JBCo=JBIJ.JBCo and JBID.BillMonth=JBIJ.BillMonth and JBID.BillNumber=JBIJ.BillNumber and JBID.Line=JBIJ.Line  and JBID.Seq=JBIJ.Seq
   	      	join JCCD on JBIJ.JBCo=JCCD.JCCo and JBIJ.JCMonth=JCCD.Mth and JBIJ.JCTrans=JCCD.CostTrans
   	 	join INDT on JCCD.INCo=INDT.INCo and JCCD.Mth=INDT.Mth and JCCD.Loc=INDT.Loc and JCCD.MatlGroup=INDT.MatlGroup and JCCD.Material=INDT.Material
   		join HQAT on INDT.UniqueAttchID=HQAT.UniqueAttchID
   		join HQAI on HQAT.AttachmentID=HQAI.AttachmentID
   where JBIN.JBCo=@co and JBIN.BillMonth=@mth and JBIN.BillNumber=@billnum
   
   
   for xml auto, elements

GO
GRANT EXECUTE ON  [dbo].[bspJBCDData] TO [public]
GO
