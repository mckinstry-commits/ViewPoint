SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   proc [dbo].[bspJBCDAttachments]
/************************************************
Created: RM 09/16/04
Modified:  TJL 02/07/08 - Issue #127029, Added "with recompile" to procedure
		   JonathanP 06/11/09 - 12600: Fixed PR Timecards code to pull the right attachments.


Usage: 
	Used to get the proper data to generate a CD of attachments
	associated with a JB Bill.  

Parameters:

@co - Company
@mth - Month
@billnum - Bill Number


*************************************************/
(@co int=null, @mth bMonth=null, @billnum int=null)
with recompile as
   
    
/***************************AP Invoices****************************************/
select HQAT.AttachmentID
from bJBIN JBIN
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
select distinct HQAT.AttachmentID
from JBIN JBIN
	join JBIL on JBIN.JBCo=JBIL.JBCo and JBIN.BillMonth=JBIL.BillMonth and JBIN.BillNumber=JBIL.BillNumber
	join JBID on JBIL.JBCo=JBID.JBCo and JBIL.BillMonth=JBID.BillMonth and JBIL.BillNumber=JBID.BillNumber and JBIL.Line=JBID.Line
	join JBIJ on JBID.JBCo=JBIJ.JBCo and JBID.BillMonth=JBIJ.BillMonth and JBID.BillNumber=JBIJ.BillNumber and JBID.Line=JBIJ.Line and JBID.Seq=JBIJ.Seq
	join -- derived table JCPR is a join of JCCD and PRJC providing the Pay Period values needed to join to PRTH
		(select distinct c.JCCo, c.Mth, c.CostTrans, p.PRCo, p.PRGroup, p.PREndDate, p.Employee, p.PaySeq, p.PostSeq
           from PRJC p (nolock)
           join JCCD c (nolock) on p.JCCo = c.JCCo and p.Job = c.Job and p.PhaseGroup = c.PhaseGroup and p.Phase = c.Phase and p.Mth = c.Mth)
      as JCPR on JBIJ.JBCo=JCPR.JCCo and JBIJ.JCMonth=JCPR.Mth and JBIJ.JCTrans=JCPR.CostTrans
 	join PRTH on JCPR.PRCo=PRTH.PRCo and JCPR.PRGroup=PRTH.PRGroup and JCPR.PREndDate=PRTH.PREndDate and JCPR.Employee=PRTH.Employee and JCPR.PaySeq=PRTH.PaySeq and JCPR.PostSeq=PRTH.PostSeq
	join HQAT on PRTH.UniqueAttchID=HQAT.UniqueAttchID
	join HQAI on HQAT.AttachmentID=HQAI.AttachmentID
where JBIN.JBCo=@co and JBIN.BillMonth=@mth and JBIN.BillNumber=@billnum

UNION

/***************************MS Tickets****************************************/
select HQAT.AttachmentID
from bJBIN JBIN
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
select HQAT.AttachmentID
from bJBIN JBIN
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
select HQAT.AttachmentID
from bJBIN JBIN
	join JBIL on JBIN.JBCo=JBIL.JBCo and JBIN.BillMonth=JBIL.BillMonth and JBIN.BillNumber=JBIL.BillNumber
	join JBID on JBIL.JBCo=JBID.JBCo and JBIL.BillMonth=JBID.BillMonth and JBIL.BillNumber=JBID.BillNumber and JBIL.Line=JBID.Line 
	join JBIJ on JBID.JBCo=JBIJ.JBCo and JBID.BillMonth=JBIJ.BillMonth and JBID.BillNumber=JBIJ.BillNumber and JBID.Line=JBIJ.Line  and JBID.Seq=JBIJ.Seq
      	join JCCD on JBIJ.JBCo=JCCD.JCCo and JBIJ.JCMonth=JCCD.Mth and JBIJ.JCTrans=JCCD.CostTrans
 	join INDT on JCCD.INCo=INDT.INCo and JCCD.Mth=INDT.Mth and JCCD.Loc=INDT.Loc and JCCD.MatlGroup=INDT.MatlGroup and JCCD.Material=INDT.Material
	join HQAT on INDT.UniqueAttchID=HQAT.UniqueAttchID
	join HQAI on HQAT.AttachmentID=HQAI.AttachmentID
where JBIN.JBCo=@co and JBIN.BillMonth=@mth and JBIN.BillNumber=@billnum


UNION

/***************************JC Cost Adjustments****************************************/
select HQAT.AttachmentID
from bJBIN JBIN
	join JBIL on JBIN.JBCo=JBIL.JBCo and JBIN.BillMonth=JBIL.BillMonth and JBIN.BillNumber=JBIL.BillNumber
	join JBID on JBIL.JBCo=JBID.JBCo and JBIL.BillMonth=JBID.BillMonth and JBIL.BillNumber=JBID.BillNumber and JBIL.Line=JBID.Line 
	join JBIJ on JBID.JBCo=JBIJ.JBCo and JBID.BillMonth=JBIJ.BillMonth and JBID.BillNumber=JBIJ.BillNumber and JBID.Line=JBIJ.Line  and JBID.Seq=JBIJ.Seq
    join JCCD on JBIJ.JBCo=JCCD.JCCo and JBIJ.JCMonth=JCCD.Mth and JBIJ.JCTrans=JCCD.CostTrans and JCCD.Source = 'JC CostAdj'
	join HQAT on JCCD.UniqueAttchID=HQAT.UniqueAttchID
	join HQAI on HQAT.AttachmentID=HQAI.AttachmentID
where JBIN.JBCo=@co and JBIN.BillMonth=@mth and JBIN.BillNumber=@billnum



GO
GRANT EXECUTE ON  [dbo].[bspJBCDAttachments] TO [public]
GO
