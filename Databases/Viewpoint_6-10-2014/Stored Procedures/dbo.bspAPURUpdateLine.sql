SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspAPURUpdateLine]
   /*************************************************************
   *    Created by TV & GG 10/01/01
   *	 Modified by MV 09/15/03 - #21650 update Login Name of approver
   *    
   *    Purpose: To update all eligible lines in APUR when     
   *             line area on APUnappInRev form is clicked
   *
   *    Inputs: @apco
   *            @uimth
   *            @uiseq
   *            @line            
   *            @reviewer
   *            @jcco
   *            @job
   *            @showall
   *            @linetype
   *            @apprvdyn
   *            @rejected
   *            @rejreason
   *
   *
   *
   *
   *************************************************************/
   (@apco bCompany, @reviewer varchar(3), @jcco bCompany = null, @job bJob = null,
    @showall char(1) = 'N', @linetypes varchar(7),@apprvdyn char(1), @loginname bVPUserName = null,
    @rejected char(1),@rejreason varchar(20), @uimth bMonth, @uiseq int,@line int, @errmsg varchar(255)output)
   
   as
   
   update APUR
   set ApprvdYN = @apprvdyn, LoginName = @loginname, Rejected = @rejected, RejReason = @rejreason 
   from APUL l
   join APUR r on l.APCo = r.APCo and l.UIMth = r.UIMth and l.UISeq = r.UISeq and l.Line = r.Line
   where r.Reviewer = @reviewer 
   	and isnull(l.JCCo,0) = isnull(@jcco,isnull(l.JCCo,0))	-- optional restriction by JC Co#
   	and isnull(l.Job,'') = isnull(@job,isnull(l.Job,''))	-- optional restriction by Job
   	and charindex(convert(varchar,l.LineType),@linetypes) <> 0 	-- included Line Types
   	and ((r.ApprvdYN = 'N' and isnull(r.Rejected,'N') = 'N') or @showall = 'Y')	-- not yet approved or all
   	   -- only include invoices with lines ready for review
   	and (select count(*) from APUR r1 where l.APCo = r1.APCo and l.UIMth = r1.UIMth and l.UISeq = r1.UISeq
   							and l.Line = r1.Line and r1.ApprovalSeq < r.ApprovalSeq and r1.ApprvdYN = 'N') = 0
   	and r.APCo = @apco and r.UIMth = @uimth and r.UISeq = @uiseq and r.Line = @line
   
   
   return

GO
GRANT EXECUTE ON  [dbo].[bspAPURUpdateLine] TO [public]
GO
