SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspJBCDData]
/************************************************
Created:  RM 09/25/07
Modified: RM 10/19/07 - Add additional fields to HQAT selects to aid in associating data
		  TJL 03/06/08 - Issue #127077, International Addresses
		  JonathanP 06/08/09 - 126000: Changed DocName to OrigFileName to make sure the extention file 
									   was getting returned for attachments in the database.
		  JonathanP 06/11/09 - 126000: Fixed PR Timecards code and added JC Cost Adjustment code.
		  CC	08/13/09 - 128099: Add vendor name, phase description, contract item description, and bill group description to dataset
		  MV/AR	06/01/11 - #140134 - perf improvement - use temp table to store the query and join to it
		  AR 11/22/2011 - removing temp table adding better indexing.  Temp table causing bad plans to be picked with sub-query
		  AW 10/29/2013 - TFS 63624 Only show one instance of JBIL for APTH attachments removed 2nd Phase column.
							Note:  One JBIL record to many phase related records different phases cause duplicate results
	


Usage: 
	Used to get the proper data to generate a CD of attachments
	associated with a JB Bill.  

Parameters:

@co - Company
@mth - Month
@billnum - Bill Number


*************************************************/
    (
      @co INT = NULL,
      @mth bMonth = NULL,
      @billnum INT = NULL
    )
AS /*declare @co int, @mth bMonth, @billnum int

select @co = 1, @mth='08/01/2007', @billnum=1  */ 
   

--BEGIN HQCO
    SELECT  HQCO.HQCo,
            HQCO.Name
    FROM    HQCO
    WHERE   HQCO.HQCo = @co
--END HQCO

   
--BEGIN JBIN   
/***************************AP Invoices****************************************/
    SELECT  JBIN.JBCo,
            JBIN.BillMonth,
            JBIN.BillNumber,
            JBIN.Invoice,
            JBIN.Contract,
            JBIN.CustGroup,
            JBIN.Customer,
            JBIN.InvStatus,
            JBIN.Application,
            JBIN.ProcessGroup,
            JBIN.RestrictBillGroupYN,
            JBIN.BillGroup,
            JBIN.RecType,
            JBIN.DueDate,
            JBIN.InvDate,
            JBIN.PayTerms,
            JBIN.DiscDate,
            JBIN.FromDate,
            JBIN.ToDate,
            JBIN.BillAddress,
            JBIN.BillAddress2,
            JBIN.BillCity,
            JBIN.BillState,
            JBIN.BillZip,
            JBIN.BillCountry,
            JBIN.ARTrans,
            JBIN.InvTotal,
            JBIN.InvRetg,
            JBIN.RetgRel,
            JBIN.InvDisc,
            JBIN.TaxBasis,
            JBIN.InvTax,
            JBIN.InvDue,
            JBIN.PrevAmt,
            JBIN.PrevRetg,
            JBIN.PrevRRel,
            JBIN.PrevTax,
            JBIN.PrevDue,
            JBIN.ARRelRetgTran,
            JBIN.ARRelRetgCrTran,
            JBIN.ARGLCo,
            JBIN.JCGLCo,
            JBIN.CurrContract,
            JBIN.PrevWC,
            JBIN.WC,
            JBIN.PrevSM,
            JBIN.Installed,
            JBIN.Purchased,
            JBIN.SM,
            JBIN.SMRetg,
            JBIN.PrevSMRetg,
            JBIN.PrevWCRetg,
            JBIN.WCRetg,
            JBIN.PrevChgOrderAdds,
            JBIN.PrevChgOrderDeds,
            JBIN.ChgOrderAmt,
            JBIN.AutoInitYN,
            JBIN.InUseBatchId,
            JBIN.InUseMth,
            JBIN.BillOnCompleteYN,
            JBIN.BillType,
            JBIN.Template,
            JBIN.CustomerReference,
            JBIN.CustomerJob,
            JBIN.ACOThruDate,
            JBIN.Purge,
            JBIN.AuditYN,
            JBIN.OverrideGLRevAcctYN,
            JBIN.OverrideGLRevAcct,
            JBIN.UniqueAttchID,
            JBIN.RevRelRetgYN,
            dbo.JBBG.[Description]
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
            JOIN APTL ON APTL.APLine = JCCD.APLine
                         AND JCCD.APCo = APTL.APCo
                         AND JCCD.Mth = APTL.Mth
                         AND JCCD.APTrans = APTL.APTrans
            JOIN APTH ON APTL.APCo = APTH.APCo
                         AND APTL.APTrans = APTH.APTrans
                         AND APTL.Mth = APTH.Mth
            JOIN HQAT ON APTH.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
            LEFT OUTER JOIN JBBG ON JBBG.JBCo = JBIN.JBCo
                                    AND JBBG.[Contract] = JBIN.[Contract]
                                    AND JBBG.BillGroup = JBIN.BillGroup
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION
   
/***************************PR Timecards****************************************/
    SELECT 
            JBIN.JBCo,
            JBIN.BillMonth,
            JBIN.BillNumber,
            JBIN.Invoice,
            JBIN.Contract,
            JBIN.CustGroup,
            JBIN.Customer,
            JBIN.InvStatus,
            JBIN.Application,
            JBIN.ProcessGroup,
            JBIN.RestrictBillGroupYN,
            JBIN.BillGroup,
            JBIN.RecType,
            JBIN.DueDate,
            JBIN.InvDate,
            JBIN.PayTerms,
            JBIN.DiscDate,
            JBIN.FromDate,
            JBIN.ToDate,
            JBIN.BillAddress,
            JBIN.BillAddress2,
            JBIN.BillCity,
            JBIN.BillState,
            JBIN.BillZip,
            JBIN.BillCountry,
            JBIN.ARTrans,
            JBIN.InvTotal,
            JBIN.InvRetg,
            JBIN.RetgRel,
            JBIN.InvDisc,
            JBIN.TaxBasis,
            JBIN.InvTax,
            JBIN.InvDue,
            JBIN.PrevAmt,
            JBIN.PrevRetg,
            JBIN.PrevRRel,
            JBIN.PrevTax,
            JBIN.PrevDue,
            JBIN.ARRelRetgTran,
            JBIN.ARRelRetgCrTran,
            JBIN.ARGLCo,
            JBIN.JCGLCo,
            JBIN.CurrContract,
            JBIN.PrevWC,
            JBIN.WC,
            JBIN.PrevSM,
            JBIN.Installed,
            JBIN.Purchased,
            JBIN.SM,
            JBIN.SMRetg,
            JBIN.PrevSMRetg,
            JBIN.PrevWCRetg,
            JBIN.WCRetg,
            JBIN.PrevChgOrderAdds,
            JBIN.PrevChgOrderDeds,
            JBIN.ChgOrderAmt,
            JBIN.AutoInitYN,
            JBIN.InUseBatchId,
            JBIN.InUseMth,
            JBIN.BillOnCompleteYN,
            JBIN.BillType,
            JBIN.Template,
            JBIN.CustomerReference,
            JBIN.CustomerJob,
            JBIN.ACOThruDate,
            JBIN.Purge,
            JBIN.AuditYN,
            JBIN.OverrideGLRevAcctYN,
            JBIN.OverrideGLRevAcct,
            JBIN.UniqueAttchID,
            JBIN.RevRelRetgYN,
            dbo.JBBG.[Description]
    FROM    JBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN -- derived table JCPR is a join of JCCD and PRJC providing the Pay Period values needed to join to PRTH
            ( SELECT DISTINCT
                        c.JCCo,
                        c.Mth,
                        c.CostTrans,
                        p.PRCo,
                        p.PRGroup,
                        p.PREndDate,
                        p.Employee,
                        p.PaySeq,
                        p.PostSeq
              FROM      PRJC p ( NOLOCK )
                        JOIN JCCD c ( NOLOCK ) ON p.JCCo = c.JCCo
                                                  AND p.Job = c.Job
                                                  AND p.PhaseGroup = c.PhaseGroup
                                                  AND p.Phase = c.Phase
                                                  AND p.Mth = c.Mth
			WHERE p.JCCo = @co
				AND p.Mth = @mth
            ) AS JCPR ON JBIJ.JBCo = JCPR.JCCo
                         AND JBIJ.JCMonth = JCPR.Mth
                         AND JBIJ.JCTrans = JCPR.CostTrans
            JOIN PRTH ON JCPR.PRCo = PRTH.PRCo
                         AND JCPR.PRGroup = PRTH.PRGroup
                         AND JCPR.PREndDate = PRTH.PREndDate
                         AND JCPR.Employee = PRTH.Employee
                         AND JCPR.PaySeq = PRTH.PaySeq
                         AND JCPR.PostSeq = PRTH.PostSeq
            JOIN HQAT ON PRTH.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
            LEFT OUTER JOIN JBBG ON JBBG.JBCo = JBIN.JBCo
                                    AND JBBG.[Contract] = JBIN.[Contract]
                                    AND JBBG.BillGroup = JBIN.BillGroup
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION
   
/***************************MS Tickets****************************************/
    SELECT  JBIN.JBCo,
            JBIN.BillMonth,
            JBIN.BillNumber,
            JBIN.Invoice,
            JBIN.Contract,
            JBIN.CustGroup,
            JBIN.Customer,
            JBIN.InvStatus,
            JBIN.Application,
            JBIN.ProcessGroup,
            JBIN.RestrictBillGroupYN,
            JBIN.BillGroup,
            JBIN.RecType,
            JBIN.DueDate,
            JBIN.InvDate,
            JBIN.PayTerms,
            JBIN.DiscDate,
            JBIN.FromDate,
            JBIN.ToDate,
            JBIN.BillAddress,
            JBIN.BillAddress2,
            JBIN.BillCity,
            JBIN.BillState,
            JBIN.BillZip,
            JBIN.BillCountry,
            JBIN.ARTrans,
            JBIN.InvTotal,
            JBIN.InvRetg,
            JBIN.RetgRel,
            JBIN.InvDisc,
            JBIN.TaxBasis,
            JBIN.InvTax,
            JBIN.InvDue,
            JBIN.PrevAmt,
            JBIN.PrevRetg,
            JBIN.PrevRRel,
            JBIN.PrevTax,
            JBIN.PrevDue,
            JBIN.ARRelRetgTran,
            JBIN.ARRelRetgCrTran,
            JBIN.ARGLCo,
            JBIN.JCGLCo,
            JBIN.CurrContract,
            JBIN.PrevWC,
            JBIN.WC,
            JBIN.PrevSM,
            JBIN.Installed,
            JBIN.Purchased,
            JBIN.SM,
            JBIN.SMRetg,
            JBIN.PrevSMRetg,
            JBIN.PrevWCRetg,
            JBIN.WCRetg,
            JBIN.PrevChgOrderAdds,
            JBIN.PrevChgOrderDeds,
            JBIN.ChgOrderAmt,
            JBIN.AutoInitYN,
            JBIN.InUseBatchId,
            JBIN.InUseMth,
            JBIN.BillOnCompleteYN,
            JBIN.BillType,
            JBIN.Template,
            JBIN.CustomerReference,
            JBIN.CustomerJob,
            JBIN.ACOThruDate,
            JBIN.Purge,
            JBIN.AuditYN,
            JBIN.OverrideGLRevAcctYN,
            JBIN.OverrideGLRevAcct,
            JBIN.UniqueAttchID,
            JBIN.RevRelRetgYN,
            dbo.JBBG.[Description]
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
            JOIN MSTD ON JCCD.JCCo = MSTD.MSCo
                         AND JCCD.Mth = MSTD.Mth
                         AND JCCD.MSTrans = MSTD.MSTrans
            JOIN HQAT ON MSTD.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
            LEFT OUTER JOIN JBBG ON JBBG.JBCo = JBIN.JBCo
                                    AND JBBG.[Contract] = JBIN.[Contract]
                                    AND JBBG.BillGroup = JBIN.BillGroup
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION
   
/***************************EM Work Orders****************************************/
    SELECT  JBIN.JBCo,
            JBIN.BillMonth,
            JBIN.BillNumber,
            JBIN.Invoice,
            JBIN.Contract,
            JBIN.CustGroup,
            JBIN.Customer,
            JBIN.InvStatus,
            JBIN.Application,
            JBIN.ProcessGroup,
            JBIN.RestrictBillGroupYN,
            JBIN.BillGroup,
            JBIN.RecType,
            JBIN.DueDate,
            JBIN.InvDate,
            JBIN.PayTerms,
            JBIN.DiscDate,
            JBIN.FromDate,
            JBIN.ToDate,
            JBIN.BillAddress,
            JBIN.BillAddress2,
            JBIN.BillCity,
            JBIN.BillState,
            JBIN.BillZip,
            JBIN.BillCountry,
            JBIN.ARTrans,
            JBIN.InvTotal,
            JBIN.InvRetg,
            JBIN.RetgRel,
            JBIN.InvDisc,
            JBIN.TaxBasis,
            JBIN.InvTax,
            JBIN.InvDue,
            JBIN.PrevAmt,
            JBIN.PrevRetg,
            JBIN.PrevRRel,
            JBIN.PrevTax,
            JBIN.PrevDue,
            JBIN.ARRelRetgTran,
            JBIN.ARRelRetgCrTran,
            JBIN.ARGLCo,
            JBIN.JCGLCo,
            JBIN.CurrContract,
            JBIN.PrevWC,
            JBIN.WC,
            JBIN.PrevSM,
            JBIN.Installed,
            JBIN.Purchased,
            JBIN.SM,
            JBIN.SMRetg,
            JBIN.PrevSMRetg,
            JBIN.PrevWCRetg,
            JBIN.WCRetg,
            JBIN.PrevChgOrderAdds,
            JBIN.PrevChgOrderDeds,
            JBIN.ChgOrderAmt,
            JBIN.AutoInitYN,
            JBIN.InUseBatchId,
            JBIN.InUseMth,
            JBIN.BillOnCompleteYN,
            JBIN.BillType,
            JBIN.Template,
            JBIN.CustomerReference,
            JBIN.CustomerJob,
            JBIN.ACOThruDate,
            JBIN.Purge,
            JBIN.AuditYN,
            JBIN.OverrideGLRevAcctYN,
            JBIN.OverrideGLRevAcct,
            JBIN.UniqueAttchID,
            JBIN.RevRelRetgYN,
            dbo.JBBG.[Description]
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
            JOIN EMRD ON JCCD.EMCo = EMRD.EMCo
                         AND JCCD.EMEquip = EMRD.Equipment
                         AND JCCD.Mth = EMRD.Mth
                         AND JCCD.EMTrans = EMRD.Trans
            JOIN HQAT ON EMRD.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
            LEFT OUTER JOIN JBBG ON JBBG.JBCo = JBIN.JBCo
                                    AND JBBG.[Contract] = JBIN.[Contract]
                                    AND JBBG.BillGroup = JBIN.BillGroup
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION
   
/***************************IN Material Orders****************************************/
    SELECT  JBIN.JBCo,
            JBIN.BillMonth,
            JBIN.BillNumber,
            JBIN.Invoice,
            JBIN.Contract,
            JBIN.CustGroup,
            JBIN.Customer,
            JBIN.InvStatus,
            JBIN.Application,
            JBIN.ProcessGroup,
            JBIN.RestrictBillGroupYN,
            JBIN.BillGroup,
            JBIN.RecType,
            JBIN.DueDate,
            JBIN.InvDate,
            JBIN.PayTerms,
            JBIN.DiscDate,
            JBIN.FromDate,
            JBIN.ToDate,
            JBIN.BillAddress,
            JBIN.BillAddress2,
            JBIN.BillCity,
            JBIN.BillState,
            JBIN.BillZip,
            JBIN.BillCountry,
            JBIN.ARTrans,
            JBIN.InvTotal,
            JBIN.InvRetg,
            JBIN.RetgRel,
            JBIN.InvDisc,
            JBIN.TaxBasis,
            JBIN.InvTax,
            JBIN.InvDue,
            JBIN.PrevAmt,
            JBIN.PrevRetg,
            JBIN.PrevRRel,
            JBIN.PrevTax,
            JBIN.PrevDue,
            JBIN.ARRelRetgTran,
            JBIN.ARRelRetgCrTran,
            JBIN.ARGLCo,
            JBIN.JCGLCo,
            JBIN.CurrContract,
            JBIN.PrevWC,
            JBIN.WC,
            JBIN.PrevSM,
            JBIN.Installed,
            JBIN.Purchased,
            JBIN.SM,
            JBIN.SMRetg,
            JBIN.PrevSMRetg,
            JBIN.PrevWCRetg,
            JBIN.WCRetg,
            JBIN.PrevChgOrderAdds,
            JBIN.PrevChgOrderDeds,
            JBIN.ChgOrderAmt,
            JBIN.AutoInitYN,
            JBIN.InUseBatchId,
            JBIN.InUseMth,
            JBIN.BillOnCompleteYN,
            JBIN.BillType,
            JBIN.Template,
            JBIN.CustomerReference,
            JBIN.CustomerJob,
            JBIN.ACOThruDate,
            JBIN.Purge,
            JBIN.AuditYN,
            JBIN.OverrideGLRevAcctYN,
            JBIN.OverrideGLRevAcct,
            JBIN.UniqueAttchID,
            JBIN.RevRelRetgYN,
            dbo.JBBG.[Description]
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
            JOIN INDT ON JCCD.INCo = INDT.INCo
                         AND JCCD.Mth = INDT.Mth
                         AND JCCD.Loc = INDT.Loc
                         AND JCCD.MatlGroup = INDT.MatlGroup
                         AND JCCD.Material = INDT.Material
            JOIN HQAT ON INDT.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
            LEFT OUTER JOIN JBBG ON JBBG.JBCo = JBIN.JBCo
                                    AND JBBG.[Contract] = JBIN.[Contract]
                                    AND JBBG.BillGroup = JBIN.BillGroup
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION

/***************************JC Cost Adjustments****************************************/
    SELECT  JBIN.JBCo,
            JBIN.BillMonth,
            JBIN.BillNumber,
            JBIN.Invoice,
            JBIN.Contract,
            JBIN.CustGroup,
            JBIN.Customer,
            JBIN.InvStatus,
            JBIN.Application,
            JBIN.ProcessGroup,
            JBIN.RestrictBillGroupYN,
            JBIN.BillGroup,
            JBIN.RecType,
            JBIN.DueDate,
            JBIN.InvDate,
            JBIN.PayTerms,
            JBIN.DiscDate,
            JBIN.FromDate,
            JBIN.ToDate,
            JBIN.BillAddress,
            JBIN.BillAddress2,
            JBIN.BillCity,
            JBIN.BillState,
            JBIN.BillZip,
            JBIN.BillCountry,
            JBIN.ARTrans,
            JBIN.InvTotal,
            JBIN.InvRetg,
            JBIN.RetgRel,
            JBIN.InvDisc,
            JBIN.TaxBasis,
            JBIN.InvTax,
            JBIN.InvDue,
            JBIN.PrevAmt,
            JBIN.PrevRetg,
            JBIN.PrevRRel,
            JBIN.PrevTax,
            JBIN.PrevDue,
            JBIN.ARRelRetgTran,
            JBIN.ARRelRetgCrTran,
            JBIN.ARGLCo,
            JBIN.JCGLCo,
            JBIN.CurrContract,
            JBIN.PrevWC,
            JBIN.WC,
            JBIN.PrevSM,
            JBIN.Installed,
            JBIN.Purchased,
            JBIN.SM,
            JBIN.SMRetg,
            JBIN.PrevSMRetg,
            JBIN.PrevWCRetg,
            JBIN.WCRetg,
            JBIN.PrevChgOrderAdds,
            JBIN.PrevChgOrderDeds,
            JBIN.ChgOrderAmt,
            JBIN.AutoInitYN,
            JBIN.InUseBatchId,
            JBIN.InUseMth,
            JBIN.BillOnCompleteYN,
            JBIN.BillType,
            JBIN.Template,
            JBIN.CustomerReference,
            JBIN.CustomerJob,
            JBIN.ACOThruDate,
            JBIN.Purge,
            JBIN.AuditYN,
            JBIN.OverrideGLRevAcctYN,
            JBIN.OverrideGLRevAcct,
            JBIN.UniqueAttchID,
            JBIN.RevRelRetgYN,
            dbo.JBBG.[Description]
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
                         AND JCCD.Source = 'JC CostAdj'
            JOIN HQAT ON JCCD.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
            LEFT OUTER JOIN JBBG ON JBBG.JBCo = JBIN.JBCo
                                    AND JBBG.[Contract] = JBIN.[Contract]
                                    AND JBBG.BillGroup = JBIN.BillGroup
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum

--END JBIN 
 
--BEGIN JBIL

/***************************AP Invoices****************************************/
    SELECT  JBIL.JBCo,
            JBIL.BillMonth,
            JBIL.BillNumber,
            JBIL.Line,
            JBIL.Item,
            JCCI.[Description] AS ItemDescription,
            JBIL.Contract,
            JBIL.Job,
            JBIL.PhaseGroup,
            JBIL.Phase,
            dbo.JCPM.[Description] AS PhaseDescription,
            JBIL.Date,
            JBIL.Template,
            JBIL.TemplateSeq,
            JBIL.TemplateSortLevel,
            JBIL.TemplateSeqSumOpt,
            JBIL.TemplateSeqGroup,
            JBIL.LineType,
            JBIL.Description,
            JBIL.TaxGroup,
            JBIL.TaxCode,
            JBIL.MarkupOpt,
            JBIL.MarkupRate,
            JBIL.Basis,
            JBIL.MarkupAddl,
            JBIL.MarkupTotal,
            JBIL.Total,
            JBIL.Retainage,
            JBIL.Discount,
            JBIL.NewLine,
            JBIL.ReseqYN,
            JBIL.LineKey,
            JBIL.TemplateGroupNum,
            JBIL.LineForAddon,
            JBIL.AuditYN,
            JBIL.Purge,
            JBIL.UniqueAttchID
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
            JOIN APTL ON APTL.APLine = JCCD.APLine
                         AND JCCD.APCo = APTL.APCo
                         AND JCCD.Mth = APTL.Mth
                         AND JCCD.APTrans = APTL.APTrans
            JOIN APTH ON APTL.APCo = APTH.APCo
                         AND APTL.APTrans = APTH.APTrans
                         AND APTL.Mth = APTH.Mth
            JOIN HQAT ON APTH.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
            LEFT OUTER JOIN dbo.JCCI ON JBIL.[Contract] = dbo.JCCI.[Contract]
                                        AND dbo.JBIL.Item = dbo.JCCI.Item
                                        AND dbo.JBIL.JBCo = dbo.JCCI.JCCo
            LEFT OUTER JOIN dbo.JCPM ON dbo.JBIL.Phase = dbo.JCPM.Phase
                                        AND dbo.JBIL.PhaseGroup = dbo.JCPM.PhaseGroup
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION

/***************************PR Timecards****************************************/
    SELECT  JBIL.JBCo,
            JBIL.BillMonth,
            JBIL.BillNumber,
            JBIL.Line,
            JBIL.Item,
            JCCI.[Description] AS ItemDescription,
            JBIL.Contract,
            JBIL.Job,
            JBIL.PhaseGroup,
            JBIL.Phase,
            dbo.JCPM.[Description] AS PhaseDescription,
            JBIL.Date,
            JBIL.Template,
            JBIL.TemplateSeq,
            JBIL.TemplateSortLevel,
            JBIL.TemplateSeqSumOpt,
            JBIL.TemplateSeqGroup,
            JBIL.LineType,
            JBIL.Description,
            JBIL.TaxGroup,
            JBIL.TaxCode,
            JBIL.MarkupOpt,
            JBIL.MarkupRate,
            JBIL.Basis,
            JBIL.MarkupAddl,
            JBIL.MarkupTotal,
            JBIL.Total,
            JBIL.Retainage,
            JBIL.Discount,
            JBIL.NewLine,
            JBIL.ReseqYN,
            JBIL.LineKey,
            JBIL.TemplateGroupNum,
            JBIL.LineForAddon,
            JBIL.AuditYN,
            JBIL.Purge,
            JBIL.UniqueAttchID
    FROM    JBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN -- derived table JCPR is a join of JCCD and PRJC providing the Pay Period values needed to join to PRTH
            ( SELECT DISTINCT
                        c.JCCo,
                        c.Mth,
                        c.CostTrans,
                        p.PRCo,
                        p.PRGroup,
                        p.PREndDate,
                        p.Employee,
                        p.PaySeq,
                        p.PostSeq,
                        c.Phase
              FROM      PRJC p ( NOLOCK )
                        JOIN JCCD c ( NOLOCK ) ON p.JCCo = c.JCCo
                                                  AND p.Job = c.Job
                                                  AND p.PhaseGroup = c.PhaseGroup
                                                  AND p.Phase = c.Phase
                                                  AND p.Mth = c.Mth
				WHERE p.JCCo = @co
					AND p.Mth = @mth
            ) AS JCPR ON JBIJ.JBCo = JCPR.JCCo
                         AND JBIJ.JCMonth = JCPR.Mth
                         AND JBIJ.JCTrans = JCPR.CostTrans
            JOIN PRTH ON JCPR.PRCo = PRTH.PRCo
                         AND JCPR.PRGroup = PRTH.PRGroup
                         AND JCPR.PREndDate = PRTH.PREndDate
                         AND JCPR.Employee = PRTH.Employee
                         AND JCPR.PaySeq = PRTH.PaySeq
                         AND JCPR.PostSeq = PRTH.PostSeq
            JOIN HQAT ON PRTH.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
            LEFT OUTER JOIN dbo.JCCI ON JBIL.[Contract] = dbo.JCCI.[Contract]
                                        AND dbo.JBIL.Item = dbo.JCCI.Item
                                        AND dbo.JBIL.JBCo = dbo.JCCI.JCCo
            LEFT OUTER JOIN dbo.JCPM ON dbo.JBIL.Phase = dbo.JCPM.Phase
                                        AND dbo.JBIL.PhaseGroup = dbo.JCPM.PhaseGroup
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION
   
   
/***************************MS Tickets****************************************/
    SELECT  JBIL.JBCo,
            JBIL.BillMonth,
            JBIL.BillNumber,
            JBIL.Line,
            JBIL.Item,
            JCCI.[Description] AS ItemDescription,
            JBIL.Contract,
            JBIL.Job,
            JBIL.PhaseGroup,
            JBIL.Phase,
            dbo.JCPM.[Description] AS PhaseDescription,
            JBIL.Date,
            JBIL.Template,
            JBIL.TemplateSeq,
            JBIL.TemplateSortLevel,
            JBIL.TemplateSeqSumOpt,
            JBIL.TemplateSeqGroup,
            JBIL.LineType,
            JBIL.Description,
            JBIL.TaxGroup,
            JBIL.TaxCode,
            JBIL.MarkupOpt,
            JBIL.MarkupRate,
            JBIL.Basis,
            JBIL.MarkupAddl,
            JBIL.MarkupTotal,
            JBIL.Total,
            JBIL.Retainage,
            JBIL.Discount,
            JBIL.NewLine,
            JBIL.ReseqYN,
            JBIL.LineKey,
            JBIL.TemplateGroupNum,
            JBIL.LineForAddon,
            JBIL.AuditYN,
            JBIL.Purge,
            JBIL.UniqueAttchID
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
            JOIN MSTD ON JCCD.JCCo = MSTD.MSCo
                         AND JCCD.Mth = MSTD.Mth
                         AND JCCD.MSTrans = MSTD.MSTrans
            JOIN HQAT ON MSTD.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
            LEFT OUTER JOIN dbo.JCCI ON JBIL.[Contract] = dbo.JCCI.[Contract]
                                        AND dbo.JBIL.Item = dbo.JCCI.Item
                                        AND dbo.JBIL.JBCo = dbo.JCCI.JCCo
            LEFT OUTER JOIN dbo.JCPM ON dbo.JBIL.Phase = dbo.JCPM.Phase
                                        AND dbo.JBIL.PhaseGroup = dbo.JCPM.PhaseGroup
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION
   
   
/***************************EM Work Orders****************************************/
    SELECT  JBIL.JBCo,
            JBIL.BillMonth,
            JBIL.BillNumber,
            JBIL.Line,
            JBIL.Item,
            JCCI.[Description] AS ItemDescription,
            JBIL.Contract,
            JBIL.Job,
            JBIL.PhaseGroup,
            JBIL.Phase,
            dbo.JCPM.[Description] AS PhaseDescription,
            JBIL.Date,
            JBIL.Template,
            JBIL.TemplateSeq,
            JBIL.TemplateSortLevel,
            JBIL.TemplateSeqSumOpt,
            JBIL.TemplateSeqGroup,
            JBIL.LineType,
            JBIL.Description,
            JBIL.TaxGroup,
            JBIL.TaxCode,
            JBIL.MarkupOpt,
            JBIL.MarkupRate,
            JBIL.Basis,
            JBIL.MarkupAddl,
            JBIL.MarkupTotal,
            JBIL.Total,
            JBIL.Retainage,
            JBIL.Discount,
            JBIL.NewLine,
            JBIL.ReseqYN,
            JBIL.LineKey,
            JBIL.TemplateGroupNum,
            JBIL.LineForAddon,
            JBIL.AuditYN,
            JBIL.Purge,
            JBIL.UniqueAttchID
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
            JOIN EMRD ON JCCD.EMCo = EMRD.EMCo
                         AND JCCD.EMEquip = EMRD.Equipment
                         AND JCCD.Mth = EMRD.Mth
                         AND JCCD.EMTrans = EMRD.Trans
            JOIN HQAT ON EMRD.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
            LEFT OUTER JOIN dbo.JCCI ON JBIL.[Contract] = dbo.JCCI.[Contract]
                                        AND dbo.JBIL.Item = dbo.JCCI.Item
                                        AND dbo.JBIL.JBCo = dbo.JCCI.JCCo
            LEFT OUTER JOIN dbo.JCPM ON dbo.JBIL.Phase = dbo.JCPM.Phase
                                        AND dbo.JBIL.PhaseGroup = dbo.JCPM.PhaseGroup
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION
   
/***************************IN Material Orders****************************************/
    SELECT  JBIL.JBCo,
            JBIL.BillMonth,
            JBIL.BillNumber,
            JBIL.Line,
            JBIL.Item,
            JCCI.[Description] AS ItemDescription,
            JBIL.Contract,
            JBIL.Job,
            JBIL.PhaseGroup,
            JBIL.Phase,
            dbo.JCPM.[Description] AS PhaseDescription,
            JBIL.Date,
            JBIL.Template,
            JBIL.TemplateSeq,
            JBIL.TemplateSortLevel,
            JBIL.TemplateSeqSumOpt,
            JBIL.TemplateSeqGroup,
            JBIL.LineType,
            JBIL.Description,
            JBIL.TaxGroup,
            JBIL.TaxCode,
            JBIL.MarkupOpt,
            JBIL.MarkupRate,
            JBIL.Basis,
            JBIL.MarkupAddl,
            JBIL.MarkupTotal,
            JBIL.Total,
            JBIL.Retainage,
            JBIL.Discount,
            JBIL.NewLine,
            JBIL.ReseqYN,
            JBIL.LineKey,
            JBIL.TemplateGroupNum,
            JBIL.LineForAddon,
            JBIL.AuditYN,
            JBIL.Purge,
            JBIL.UniqueAttchID
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
            JOIN INDT ON JCCD.INCo = INDT.INCo
                         AND JCCD.Mth = INDT.Mth
                         AND JCCD.Loc = INDT.Loc
                         AND JCCD.MatlGroup = INDT.MatlGroup
                         AND JCCD.Material = INDT.Material
            JOIN HQAT ON INDT.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
            LEFT OUTER JOIN dbo.JCCI ON JBIL.[Contract] = dbo.JCCI.[Contract]
                                        AND dbo.JBIL.Item = dbo.JCCI.Item
                                        AND dbo.JBIL.JBCo = dbo.JCCI.JCCo
            LEFT OUTER JOIN dbo.JCPM ON dbo.JBIL.Phase = dbo.JCPM.Phase
                                        AND dbo.JBIL.PhaseGroup = dbo.JCPM.PhaseGroup
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION

/***************************JC Cost Adjustments****************************************/
    SELECT  JBIL.JBCo,
            JBIL.BillMonth,
            JBIL.BillNumber,
            JBIL.Line,
            JBIL.Item,
            JCCI.[Description] AS ItemDescription,
            JBIL.Contract,
            JBIL.Job,
            JBIL.PhaseGroup,
            JBIL.Phase,
            dbo.JCPM.[Description] AS PhaseDescription,
            JBIL.Date,
            JBIL.Template,
            JBIL.TemplateSeq,
            JBIL.TemplateSortLevel,
            JBIL.TemplateSeqSumOpt,
            JBIL.TemplateSeqGroup,
            JBIL.LineType,
            JBIL.Description,
            JBIL.TaxGroup,
            JBIL.TaxCode,
            JBIL.MarkupOpt,
            JBIL.MarkupRate,
            JBIL.Basis,
            JBIL.MarkupAddl,
            JBIL.MarkupTotal,
            JBIL.Total,
            JBIL.Retainage,
            JBIL.Discount,
            JBIL.NewLine,
            JBIL.ReseqYN,
            JBIL.LineKey,
            JBIL.TemplateGroupNum,
            JBIL.LineForAddon,
            JBIL.AuditYN,
            JBIL.Purge,
            JBIL.UniqueAttchID
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
                         AND JCCD.Source = 'JC CostAdj'
            JOIN HQAT ON JCCD.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
            LEFT OUTER JOIN dbo.JCCI ON JBIL.[Contract] = dbo.JCCI.[Contract]
                                        AND dbo.JBIL.Item = dbo.JCCI.Item
                                        AND dbo.JBIL.JBCo = dbo.JCCI.JCCo
            LEFT OUTER JOIN dbo.JCPM ON dbo.JBIL.Phase = dbo.JCPM.Phase
                                        AND dbo.JBIL.PhaseGroup = dbo.JCPM.PhaseGroup
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum

--END JBIL

--BEGIN HQAT

/***************************AP Invoices****************************************/
    SELECT  JBIL.JBCo,
            JBIL.BillMonth,
            JBIL.BillNumber,
            JBIL.Line,
            HQAT.HQCo,
            HQAT.FormName,
            HQAT.KeyField,
            HQAT.Description,
            HQAT.AddedBy,
            HQAT.AddDate,
            HQAT.DocName,
            ( CONVERT(VARCHAR(255), HQAT.AttachmentID)
              + RIGHT(HQAT.OrigFileName,
                      CHARINDEX('.', REVERSE(HQAT.OrigFileName))) ) AS LocalDoc,
            HQAT.AttachmentID,
            HQAT.TableName,
            HQAT.UniqueAttchID
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
            JOIN APTL ON APTL.APLine = JCCD.APLine
                         AND JCCD.APCo = APTL.APCo
                         AND JCCD.Mth = APTL.Mth
                         AND JCCD.APTrans = APTL.APTrans
            JOIN APTH ON APTL.APCo = APTH.APCo
                         AND APTL.APTrans = APTH.APTrans
                         AND APTL.Mth = APTH.Mth
            JOIN HQAT ON APTH.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION
   
   
/***************************PR Timecards****************************************/
    SELECT  JBIL.JBCo,
            JBIL.BillMonth,
            JBIL.BillNumber,
            JBIL.Line,
            HQAT.HQCo,
            HQAT.FormName,
            HQAT.KeyField,
            HQAT.Description,
            HQAT.AddedBy,
            HQAT.AddDate,
            HQAT.DocName,
            ( CONVERT(VARCHAR(255), HQAT.AttachmentID)
              + RIGHT(HQAT.OrigFileName,
                      CHARINDEX('.', REVERSE(HQAT.OrigFileName))) ) AS LocalDoc,
            HQAT.AttachmentID,
            HQAT.TableName,
            HQAT.UniqueAttchID
    FROM    JBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN -- derived table JCPR is a join of JCCD and PRJC providing the Pay Period values needed to join to PRTH
            ( SELECT DISTINCT
                        c.JCCo,
                        c.Mth,
                        c.CostTrans,
                        p.PRCo,
                        p.PRGroup,
                        p.PREndDate,
                        p.Employee,
                        p.PaySeq,
                        p.PostSeq
              FROM      PRJC p ( NOLOCK )
                        JOIN JCCD c ( NOLOCK ) ON p.JCCo = c.JCCo
                                                  AND p.Job = c.Job
                                                  AND p.PhaseGroup = c.PhaseGroup
                                                  AND p.Phase = c.Phase
                                                  AND p.Mth = c.Mth
			WHERE p.JCCo = @co
				AND p.Mth = @mth                                                  
            ) AS JCPR ON JBIJ.JBCo = JCPR.JCCo
                         AND JBIJ.JCMonth = JCPR.Mth
                         AND JBIJ.JCTrans = JCPR.CostTrans
            JOIN PRTH ON JCPR.PRCo = PRTH.PRCo
                         AND JCPR.PRGroup = PRTH.PRGroup
                         AND JCPR.PREndDate = PRTH.PREndDate
                         AND JCPR.Employee = PRTH.Employee
                         AND JCPR.PaySeq = PRTH.PaySeq
                         AND JCPR.PostSeq = PRTH.PostSeq
            JOIN HQAT ON PRTH.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION
   
   
/***************************MS Tickets****************************************/
    SELECT  JBIL.JBCo,
            JBIL.BillMonth,
            JBIL.BillNumber,
            JBIL.Line,
            HQAT.HQCo,
            HQAT.FormName,
            HQAT.KeyField,
            HQAT.Description,
            HQAT.AddedBy,
            HQAT.AddDate,
            HQAT.DocName,
            ( CONVERT(VARCHAR(255), HQAT.AttachmentID)
              + RIGHT(HQAT.OrigFileName,
                      CHARINDEX('.', REVERSE(HQAT.OrigFileName))) ) AS LocalDoc,
            HQAT.AttachmentID,
            HQAT.TableName,
            HQAT.UniqueAttchID
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
            JOIN MSTD ON JCCD.JCCo = MSTD.MSCo
                         AND JCCD.Mth = MSTD.Mth
                         AND JCCD.MSTrans = MSTD.MSTrans
            JOIN HQAT ON MSTD.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION
   
   
/***************************EM Work Orders****************************************/
    SELECT  JBIL.JBCo,
            JBIL.BillMonth,
            JBIL.BillNumber,
            JBIL.Line,
            HQAT.HQCo,
            HQAT.FormName,
            HQAT.KeyField,
            HQAT.Description,
            HQAT.AddedBy,
            HQAT.AddDate,
            HQAT.DocName,
            ( CONVERT(VARCHAR(255), HQAT.AttachmentID)
              + RIGHT(HQAT.OrigFileName,
                      CHARINDEX('.', REVERSE(HQAT.OrigFileName))) ) AS LocalDoc,
            HQAT.AttachmentID,
            HQAT.TableName,
            HQAT.UniqueAttchID
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
            JOIN EMRD ON JCCD.EMCo = EMRD.EMCo
                         AND JCCD.EMEquip = EMRD.Equipment
                         AND JCCD.Mth = EMRD.Mth
                         AND JCCD.EMTrans = EMRD.Trans
            JOIN HQAT ON EMRD.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION
   
/***************************IN Material Orders****************************************/
    SELECT  JBIL.JBCo,
            JBIL.BillMonth,
            JBIL.BillNumber,
            JBIL.Line,
            HQAT.HQCo,
            HQAT.FormName,
            HQAT.KeyField,
            HQAT.Description,
            HQAT.AddedBy,
            HQAT.AddDate,
            HQAT.DocName,
            ( CONVERT(VARCHAR(255), HQAT.AttachmentID)
              + RIGHT(HQAT.OrigFileName,
                      CHARINDEX('.', REVERSE(HQAT.OrigFileName))) ) AS LocalDoc,
            HQAT.AttachmentID,
            HQAT.TableName,
            HQAT.UniqueAttchID
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
            JOIN INDT ON JCCD.INCo = INDT.INCo
                         AND JCCD.Mth = INDT.Mth
                         AND JCCD.Loc = INDT.Loc
                         AND JCCD.MatlGroup = INDT.MatlGroup
                         AND JCCD.Material = INDT.Material
            JOIN HQAT ON INDT.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION

/***************************JC Cost Adjustments****************************************/
    SELECT  JBIL.JBCo,
            JBIL.BillMonth,
            JBIL.BillNumber,
            JBIL.Line,
            HQAT.HQCo,
            HQAT.FormName,
            HQAT.KeyField,
            HQAT.Description,
            HQAT.AddedBy,
            HQAT.AddDate,
            HQAT.DocName,
            ( CONVERT(VARCHAR(255), HQAT.AttachmentID)
              + RIGHT(HQAT.OrigFileName,
                      CHARINDEX('.', REVERSE(HQAT.OrigFileName))) ) AS LocalDoc,
            HQAT.AttachmentID,
            HQAT.TableName,
            HQAT.UniqueAttchID
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
                         AND JCCD.Source = 'JC CostAdj'
            JOIN HQAT ON JCCD.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum

   
--END HQAT

--BEGIN HQAI

/***************************AP Invoices****************************************/
    SELECT  HQAI.AttachmentID,
            HQAI.IndexSeq,
            HQAI.IndexName,
            HQAI.APCo,
            HQAI.APVendorGroup,
            HQAI.APVendor,
            dbo.APVM.[Name] AS APVendorName,
            HQAI.APReference,
            HQAI.APCheckNumber,
            HQAI.ARCo,
            HQAI.ARCustomer,
            HQAI.ARInvoice,
            HQAI.JCCo,
            HQAI.JCJob,
            HQAI.JCPhaseGroup,
            HQAI.JCPhase,
            dbo.JCPM.Description AS PhaseDescription,
            HQAI.JCCostType,
            HQAI.JCContract,
            HQAI.JCContractItem,
            JCCI.Description AS ItemDescription,
            HQAI.POCo,
            HQAI.POPurchaseOrder,
            HQAI.POItem,
            HQAI.EMCo,
            HQAI.EMEquipment,
            HQAI.EMCostCode,
            HQAI.EMCostType,
            HQAI.PRCo,
            HQAI.PREmployee,
            HQAI.HRCo,
            HQAI.HRReference,
            HQAI.MIMaterialGroup,
            HQAI.MIMaterial,
            HQAI.MIMonth,
            HQAI.MITransaction,
            HQAI.INCo,
            HQAI.INLoc,
            HQAI.MSCo,
            HQAI.MSTicket,
            HQAI.SLCo,
            HQAI.SLSubcontract,
            HQAI.SLSubcontractItem,
            HQAI.UniqueAttchID,
            HQAI.CustomYN,
            HQAI.UserCustom1,
            HQAI.UserCustom2,
            HQAI.UserCustom3,
            HQAI.UserCustom4,
            HQAI.UserCustom5,
            HQAI.PMIssue,
            HQAI.PMFirmNumber,
            HQAI.PMFirmType,
            HQAI.PMFirmContact,
            HQAI.PMSubmSrcFirm,
            HQAI.PMSubmSrcContact,
            HQAI.ARCustGroup,
            HQAI.EMGroup,
            HQAI.PMACO,
            HQAI.PMACOItem,
            HQAI.PMPCO,
            HQAI.PMPCOItem,
            HQAI.PMPCOType,
            HQAI.PMDocType,
            HQAI.PMSubmittal,
            HQAI.PMTransmittal,
            HQAI.PMRFQ,
            HQAI.PMRFI,
            HQAI.PMDocument,
            HQAI.PMInspectionCode,
            HQAI.PMTestCode,
            HQAI.PMDrawing,
            HQAI.PMMeeting,
            HQAI.PMPunchList,
            HQAI.PMLogDate,
            HQAI.PMDailyLog
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
            JOIN APTL ON APTL.APLine = JCCD.APLine
                         AND JCCD.APCo = APTL.APCo
                         AND JCCD.Mth = APTL.Mth
                         AND JCCD.APTrans = APTL.APTrans
            JOIN APTH ON APTL.APCo = APTH.APCo
                         AND APTL.APTrans = APTH.APTrans
                         AND APTL.Mth = APTH.Mth
            JOIN HQAT ON APTH.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
            LEFT OUTER JOIN dbo.JCCI ON HQAI.JCContract = dbo.JCCI.[Contract]
                                        AND HQAI.JCContractItem = dbo.JCCI.Item
            LEFT OUTER JOIN dbo.JCPM ON dbo.HQAI.JCPhase = dbo.JCPM.Phase
                                        AND dbo.HQAI.JCPhaseGroup = dbo.JCPM.PhaseGroup
            LEFT OUTER JOIN dbo.APVM ON dbo.HQAI.APVendorGroup = dbo.APVM.VendorGroup
                                        AND dbo.HQAI.APVendor = dbo.APVM.Vendor
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION
   
/***************************PR Timecards****************************************/
    SELECT  HQAI.AttachmentID,
            HQAI.IndexSeq,
            HQAI.IndexName,
            HQAI.APCo,
            HQAI.APVendorGroup,
            HQAI.APVendor,
            dbo.APVM.[Name] AS APVendorName,
            HQAI.APReference,
            HQAI.APCheckNumber,
            HQAI.ARCo,
            HQAI.ARCustomer,
            HQAI.ARInvoice,
            HQAI.JCCo,
            HQAI.JCJob,
            HQAI.JCPhaseGroup,
            HQAI.JCPhase,
            dbo.JCPM.Description AS PhaseDescription,
            HQAI.JCCostType,
            HQAI.JCContract,
            HQAI.JCContractItem,
            JCCI.Description AS ItemDescription,
            HQAI.POCo,
            HQAI.POPurchaseOrder,
            HQAI.POItem,
            HQAI.EMCo,
            HQAI.EMEquipment,
            HQAI.EMCostCode,
            HQAI.EMCostType,
            HQAI.PRCo,
            HQAI.PREmployee,
            HQAI.HRCo,
            HQAI.HRReference,
            HQAI.MIMaterialGroup,
            HQAI.MIMaterial,
            HQAI.MIMonth,
            HQAI.MITransaction,
            HQAI.INCo,
            HQAI.INLoc,
            HQAI.MSCo,
            HQAI.MSTicket,
            HQAI.SLCo,
            HQAI.SLSubcontract,
            HQAI.SLSubcontractItem,
            HQAI.UniqueAttchID,
            HQAI.CustomYN,
            HQAI.UserCustom1,
            HQAI.UserCustom2,
            HQAI.UserCustom3,
            HQAI.UserCustom4,
            HQAI.UserCustom5,
            HQAI.PMIssue,
            HQAI.PMFirmNumber,
            HQAI.PMFirmType,
            HQAI.PMFirmContact,
            HQAI.PMSubmSrcFirm,
            HQAI.PMSubmSrcContact,
            HQAI.ARCustGroup,
            HQAI.EMGroup,
            HQAI.PMACO,
            HQAI.PMACOItem,
            HQAI.PMPCO,
            HQAI.PMPCOItem,
            HQAI.PMPCOType,
            HQAI.PMDocType,
            HQAI.PMSubmittal,
            HQAI.PMTransmittal,
            HQAI.PMRFQ,
            HQAI.PMRFI,
            HQAI.PMDocument,
            HQAI.PMInspectionCode,
            HQAI.PMTestCode,
            HQAI.PMDrawing,
            HQAI.PMMeeting,
            HQAI.PMPunchList,
            HQAI.PMLogDate,
            HQAI.PMDailyLog
    FROM    JBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN -- derived table JCPR is a join of JCCD and PRJC providing the Pay Period values needed to join to PRTH
            ( SELECT DISTINCT
                        c.JCCo,
                        c.Mth,
                        c.CostTrans,
                        p.PRCo,
                        p.PRGroup,
                        p.PREndDate,
                        p.Employee,
                        p.PaySeq,
                        p.PostSeq
              FROM      PRJC p ( NOLOCK )
                        JOIN JCCD c ( NOLOCK ) ON p.JCCo = c.JCCo
                                                  AND p.Job = c.Job
                                                  AND p.PhaseGroup = c.PhaseGroup
                                                  AND p.Phase = c.Phase
                                                  AND p.Mth = c.Mth
				WHERE p.JCCo = @co
					AND p.Mth = @mth
            ) AS JCPR ON JBIJ.JBCo = JCPR.JCCo
                         AND JBIJ.JCMonth = JCPR.Mth
                         AND JBIJ.JCTrans = JCPR.CostTrans
            JOIN PRTH ON JCPR.PRCo = PRTH.PRCo
                         AND JCPR.PRGroup = PRTH.PRGroup
                         AND JCPR.PREndDate = PRTH.PREndDate
                         AND JCPR.Employee = PRTH.Employee
                         AND JCPR.PaySeq = PRTH.PaySeq
                         AND JCPR.PostSeq = PRTH.PostSeq
            JOIN HQAT ON PRTH.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
            LEFT OUTER JOIN dbo.JCCI ON HQAI.JCContract = dbo.JCCI.[Contract]
                                        AND HQAI.JCContractItem = dbo.JCCI.Item
            LEFT OUTER JOIN dbo.JCPM ON dbo.HQAI.JCPhase = dbo.JCPM.Phase
                                        AND dbo.HQAI.JCPhaseGroup = dbo.JCPM.PhaseGroup
            LEFT OUTER JOIN dbo.APVM ON dbo.HQAI.APVendorGroup = dbo.APVM.VendorGroup
                                        AND dbo.HQAI.APVendor = dbo.APVM.Vendor
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION
   
   
/***************************MS Tickets****************************************/
    SELECT  HQAI.AttachmentID,
            HQAI.IndexSeq,
            HQAI.IndexName,
            HQAI.APCo,
            HQAI.APVendorGroup,
            HQAI.APVendor,
            dbo.APVM.[Name] AS APVendorName,
            HQAI.APReference,
            HQAI.APCheckNumber,
            HQAI.ARCo,
            HQAI.ARCustomer,
            HQAI.ARInvoice,
            HQAI.JCCo,
            HQAI.JCJob,
            HQAI.JCPhaseGroup,
            HQAI.JCPhase,
            dbo.JCPM.Description AS PhaseDescription,
            HQAI.JCCostType,
            HQAI.JCContract,
            HQAI.JCContractItem,
            JCCI.Description AS ItemDescription,
            HQAI.POCo,
            HQAI.POPurchaseOrder,
            HQAI.POItem,
            HQAI.EMCo,
            HQAI.EMEquipment,
            HQAI.EMCostCode,
            HQAI.EMCostType,
            HQAI.PRCo,
            HQAI.PREmployee,
            HQAI.HRCo,
            HQAI.HRReference,
            HQAI.MIMaterialGroup,
            HQAI.MIMaterial,
            HQAI.MIMonth,
            HQAI.MITransaction,
            HQAI.INCo,
            HQAI.INLoc,
            HQAI.MSCo,
            HQAI.MSTicket,
            HQAI.SLCo,
            HQAI.SLSubcontract,
            HQAI.SLSubcontractItem,
            HQAI.UniqueAttchID,
            HQAI.CustomYN,
            HQAI.UserCustom1,
            HQAI.UserCustom2,
            HQAI.UserCustom3,
            HQAI.UserCustom4,
            HQAI.UserCustom5,
            HQAI.PMIssue,
            HQAI.PMFirmNumber,
            HQAI.PMFirmType,
            HQAI.PMFirmContact,
            HQAI.PMSubmSrcFirm,
            HQAI.PMSubmSrcContact,
            HQAI.ARCustGroup,
            HQAI.EMGroup,
            HQAI.PMACO,
            HQAI.PMACOItem,
            HQAI.PMPCO,
            HQAI.PMPCOItem,
            HQAI.PMPCOType,
            HQAI.PMDocType,
            HQAI.PMSubmittal,
            HQAI.PMTransmittal,
            HQAI.PMRFQ,
            HQAI.PMRFI,
            HQAI.PMDocument,
            HQAI.PMInspectionCode,
            HQAI.PMTestCode,
            HQAI.PMDrawing,
            HQAI.PMMeeting,
            HQAI.PMPunchList,
            HQAI.PMLogDate,
            HQAI.PMDailyLog
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
            JOIN MSTD ON JCCD.JCCo = MSTD.MSCo
                         AND JCCD.Mth = MSTD.Mth
                         AND JCCD.MSTrans = MSTD.MSTrans
            JOIN HQAT ON MSTD.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
            LEFT OUTER JOIN dbo.JCCI ON HQAI.JCContract = dbo.JCCI.[Contract]
                                        AND HQAI.JCContractItem = dbo.JCCI.Item
            LEFT OUTER JOIN dbo.JCPM ON dbo.HQAI.JCPhase = dbo.JCPM.Phase
                                        AND dbo.HQAI.JCPhaseGroup = dbo.JCPM.PhaseGroup
            LEFT OUTER JOIN dbo.APVM ON dbo.HQAI.APVendorGroup = dbo.APVM.VendorGroup
                                        AND dbo.HQAI.APVendor = dbo.APVM.Vendor
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION
   
   
/***************************EM Work Orders****************************************/
    SELECT  HQAI.AttachmentID,
            HQAI.IndexSeq,
            HQAI.IndexName,
            HQAI.APCo,
            HQAI.APVendorGroup,
            HQAI.APVendor,
            dbo.APVM.[Name] AS APVendorName,
            HQAI.APReference,
            HQAI.APCheckNumber,
            HQAI.ARCo,
            HQAI.ARCustomer,
            HQAI.ARInvoice,
            HQAI.JCCo,
            HQAI.JCJob,
            HQAI.JCPhaseGroup,
            HQAI.JCPhase,
            dbo.JCPM.Description AS PhaseDescription,
            HQAI.JCCostType,
            HQAI.JCContract,
            HQAI.JCContractItem,
            JCCI.Description AS ItemDescription,
            HQAI.POCo,
            HQAI.POPurchaseOrder,
            HQAI.POItem,
            HQAI.EMCo,
            HQAI.EMEquipment,
            HQAI.EMCostCode,
            HQAI.EMCostType,
            HQAI.PRCo,
            HQAI.PREmployee,
            HQAI.HRCo,
            HQAI.HRReference,
            HQAI.MIMaterialGroup,
            HQAI.MIMaterial,
            HQAI.MIMonth,
            HQAI.MITransaction,
            HQAI.INCo,
            HQAI.INLoc,
            HQAI.MSCo,
            HQAI.MSTicket,
            HQAI.SLCo,
            HQAI.SLSubcontract,
            HQAI.SLSubcontractItem,
            HQAI.UniqueAttchID,
            HQAI.CustomYN,
            HQAI.UserCustom1,
            HQAI.UserCustom2,
            HQAI.UserCustom3,
            HQAI.UserCustom4,
            HQAI.UserCustom5,
            HQAI.PMIssue,
            HQAI.PMFirmNumber,
            HQAI.PMFirmType,
            HQAI.PMFirmContact,
            HQAI.PMSubmSrcFirm,
            HQAI.PMSubmSrcContact,
            HQAI.ARCustGroup,
            HQAI.EMGroup,
            HQAI.PMACO,
            HQAI.PMACOItem,
            HQAI.PMPCO,
            HQAI.PMPCOItem,
            HQAI.PMPCOType,
            HQAI.PMDocType,
            HQAI.PMSubmittal,
            HQAI.PMTransmittal,
            HQAI.PMRFQ,
            HQAI.PMRFI,
            HQAI.PMDocument,
            HQAI.PMInspectionCode,
            HQAI.PMTestCode,
            HQAI.PMDrawing,
            HQAI.PMMeeting,
            HQAI.PMPunchList,
            HQAI.PMLogDate,
            HQAI.PMDailyLog
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
            JOIN EMRD ON JCCD.EMCo = EMRD.EMCo
                         AND JCCD.EMEquip = EMRD.Equipment
                         AND JCCD.Mth = EMRD.Mth
                         AND JCCD.EMTrans = EMRD.Trans
            JOIN HQAT ON EMRD.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
            LEFT OUTER JOIN dbo.JCCI ON HQAI.JCContract = dbo.JCCI.[Contract]
                                        AND HQAI.JCContractItem = dbo.JCCI.Item
            LEFT OUTER JOIN dbo.JCPM ON dbo.HQAI.JCPhase = dbo.JCPM.Phase
                                        AND dbo.HQAI.JCPhaseGroup = dbo.JCPM.PhaseGroup
            LEFT OUTER JOIN dbo.APVM ON dbo.HQAI.APVendorGroup = dbo.APVM.VendorGroup
                                        AND dbo.HQAI.APVendor = dbo.APVM.Vendor
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION

/***************************IN Material Orders****************************************/
    SELECT  HQAI.AttachmentID,
            HQAI.IndexSeq,
            HQAI.IndexName,
            HQAI.APCo,
            HQAI.APVendorGroup,
            HQAI.APVendor,
            dbo.APVM.[Name] AS APVendorName,
            HQAI.APReference,
            HQAI.APCheckNumber,
            HQAI.ARCo,
            HQAI.ARCustomer,
            HQAI.ARInvoice,
            HQAI.JCCo,
            HQAI.JCJob,
            HQAI.JCPhaseGroup,
            HQAI.JCPhase,
            dbo.JCPM.Description AS PhaseDescription,
            HQAI.JCCostType,
            HQAI.JCContract,
            HQAI.JCContractItem,
            JCCI.Description AS ItemDescription,
            HQAI.POCo,
            HQAI.POPurchaseOrder,
            HQAI.POItem,
            HQAI.EMCo,
            HQAI.EMEquipment,
            HQAI.EMCostCode,
            HQAI.EMCostType,
            HQAI.PRCo,
            HQAI.PREmployee,
            HQAI.HRCo,
            HQAI.HRReference,
            HQAI.MIMaterialGroup,
            HQAI.MIMaterial,
            HQAI.MIMonth,
            HQAI.MITransaction,
            HQAI.INCo,
            HQAI.INLoc,
            HQAI.MSCo,
            HQAI.MSTicket,
            HQAI.SLCo,
            HQAI.SLSubcontract,
            HQAI.SLSubcontractItem,
            HQAI.UniqueAttchID,
            HQAI.CustomYN,
            HQAI.UserCustom1,
            HQAI.UserCustom2,
            HQAI.UserCustom3,
            HQAI.UserCustom4,
            HQAI.UserCustom5,
            HQAI.PMIssue,
            HQAI.PMFirmNumber,
            HQAI.PMFirmType,
            HQAI.PMFirmContact,
            HQAI.PMSubmSrcFirm,
            HQAI.PMSubmSrcContact,
            HQAI.ARCustGroup,
            HQAI.EMGroup,
            HQAI.PMACO,
            HQAI.PMACOItem,
            HQAI.PMPCO,
            HQAI.PMPCOItem,
            HQAI.PMPCOType,
            HQAI.PMDocType,
            HQAI.PMSubmittal,
            HQAI.PMTransmittal,
            HQAI.PMRFQ,
            HQAI.PMRFI,
            HQAI.PMDocument,
            HQAI.PMInspectionCode,
            HQAI.PMTestCode,
            HQAI.PMDrawing,
            HQAI.PMMeeting,
            HQAI.PMPunchList,
            HQAI.PMLogDate,
            HQAI.PMDailyLog
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
            JOIN INDT ON JCCD.INCo = INDT.INCo
                         AND JCCD.Mth = INDT.Mth
                         AND JCCD.Loc = INDT.Loc
                         AND JCCD.MatlGroup = INDT.MatlGroup
                         AND JCCD.Material = INDT.Material
            JOIN HQAT ON INDT.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
            LEFT OUTER JOIN dbo.JCCI ON HQAI.JCContract = dbo.JCCI.[Contract]
                                        AND HQAI.JCContractItem = dbo.JCCI.Item
            LEFT OUTER JOIN dbo.JCPM ON dbo.HQAI.JCPhase = dbo.JCPM.Phase
                                        AND dbo.HQAI.JCPhaseGroup = dbo.JCPM.PhaseGroup
            LEFT OUTER JOIN dbo.APVM ON dbo.HQAI.APVendorGroup = dbo.APVM.VendorGroup
                                        AND dbo.HQAI.APVendor = dbo.APVM.Vendor
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum
    UNION

/***************************JC Cost Adjustments****************************************/
    SELECT  HQAI.AttachmentID,
            HQAI.IndexSeq,
            HQAI.IndexName,
            HQAI.APCo,
            HQAI.APVendorGroup,
            HQAI.APVendor,
            dbo.APVM.[Name] AS APVendorName,
            HQAI.APReference,
            HQAI.APCheckNumber,
            HQAI.ARCo,
            HQAI.ARCustomer,
            HQAI.ARInvoice,
            HQAI.JCCo,
            HQAI.JCJob,
            HQAI.JCPhaseGroup,
            HQAI.JCPhase,
            dbo.JCPM.Description AS PhaseDescription,
            HQAI.JCCostType,
            HQAI.JCContract,
            HQAI.JCContractItem,
            JCCI.Description AS ItemDescription,
            HQAI.POCo,
            HQAI.POPurchaseOrder,
            HQAI.POItem,
            HQAI.EMCo,
            HQAI.EMEquipment,
            HQAI.EMCostCode,
            HQAI.EMCostType,
            HQAI.PRCo,
            HQAI.PREmployee,
            HQAI.HRCo,
            HQAI.HRReference,
            HQAI.MIMaterialGroup,
            HQAI.MIMaterial,
            HQAI.MIMonth,
            HQAI.MITransaction,
            HQAI.INCo,
            HQAI.INLoc,
            HQAI.MSCo,
            HQAI.MSTicket,
            HQAI.SLCo,
            HQAI.SLSubcontract,
            HQAI.SLSubcontractItem,
            HQAI.UniqueAttchID,
            HQAI.CustomYN,
            HQAI.UserCustom1,
            HQAI.UserCustom2,
            HQAI.UserCustom3,
            HQAI.UserCustom4,
            HQAI.UserCustom5,
            HQAI.PMIssue,
            HQAI.PMFirmNumber,
            HQAI.PMFirmType,
            HQAI.PMFirmContact,
            HQAI.PMSubmSrcFirm,
            HQAI.PMSubmSrcContact,
            HQAI.ARCustGroup,
            HQAI.EMGroup,
            HQAI.PMACO,
            HQAI.PMACOItem,
            HQAI.PMPCO,
            HQAI.PMPCOItem,
            HQAI.PMPCOType,
            HQAI.PMDocType,
            HQAI.PMSubmittal,
            HQAI.PMTransmittal,
            HQAI.PMRFQ,
            HQAI.PMRFI,
            HQAI.PMDocument,
            HQAI.PMInspectionCode,
            HQAI.PMTestCode,
            HQAI.PMDrawing,
            HQAI.PMMeeting,
            HQAI.PMPunchList,
            HQAI.PMLogDate,
            HQAI.PMDailyLog
    FROM    bJBIN JBIN
            JOIN HQCO ON JBIN.JBCo = HQCO.HQCo
            JOIN JBIL ON JBIN.JBCo = JBIL.JBCo
                         AND JBIN.BillMonth = JBIL.BillMonth
                         AND JBIN.BillNumber = JBIL.BillNumber
            JOIN JBID ON JBIL.JBCo = JBID.JBCo
                         AND JBIL.BillMonth = JBID.BillMonth
                         AND JBIL.BillNumber = JBID.BillNumber
                         AND JBIL.Line = JBID.Line
            JOIN JBIJ ON JBID.JBCo = JBIJ.JBCo
                         AND JBID.BillMonth = JBIJ.BillMonth
                         AND JBID.BillNumber = JBIJ.BillNumber
                         AND JBID.Line = JBIJ.Line
                         AND JBID.Seq = JBIJ.Seq
            JOIN JCCD ON JBIJ.JBCo = JCCD.JCCo
                         AND JBIJ.JCMonth = JCCD.Mth
                         AND JBIJ.JCTrans = JCCD.CostTrans
                         AND JCCD.Source = 'JC CostAdj'
            JOIN HQAT ON JCCD.UniqueAttchID = HQAT.UniqueAttchID
            JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID
            LEFT OUTER JOIN dbo.JCCI ON HQAI.JCContract = dbo.JCCI.[Contract]
                                        AND HQAI.JCContractItem = dbo.JCCI.Item
            LEFT OUTER JOIN dbo.JCPM ON dbo.HQAI.JCPhase = dbo.JCPM.Phase
                                        AND dbo.HQAI.JCPhaseGroup = dbo.JCPM.PhaseGroup
            LEFT OUTER JOIN dbo.APVM ON dbo.HQAI.APVendorGroup = dbo.APVM.VendorGroup
                                        AND dbo.HQAI.APVendor = dbo.APVM.Vendor
    WHERE   JBIN.JBCo = @co
            AND JBIN.BillMonth = @mth
            AND JBIN.BillNumber = @billnum

GO
GRANT EXECUTE ON  [dbo].[vspJBCDData] TO [public]
GO
