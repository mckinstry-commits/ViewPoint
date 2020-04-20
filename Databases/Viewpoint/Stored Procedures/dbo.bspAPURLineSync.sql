SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspAPURLineSync]
   /***************************************************************
   *    Created 10/11/02 TV
   *	Modified: GF 09/05/2010 - issue #141031 use function vfDateOnly
   *				CHS 06/17/2011 - issue #143179 to undo issue #141031 
   *
   *    Purpose in life: To update line entries in APUR
   *	
   *    
   *    Inputs
   *            @apco
   *            @uimth
   *            @uiseq
   *            @line
   *
   *
   ***************************************************************/
   (@apco bCompany, @uimth bMonth, @uiseq int, @line int)
   
   as
   
   if @line = -1	-- -1 denotes Header
        begin
    	-- check to see if any Lines exist for the Invoice
        if exists (select 1 from bAPUL h where  h.APCo = @apco and h.UIMth = @uimth and h.UISeq = @uiseq)
            begin
            insert bAPUR (APCo, UIMth, UISeq, Reviewer, ApprvdYN, Memo, Line, ApprovalSeq, DateAssigned,
    			DateApproved, AmountApproved, Rejected, RejReason, APTrans, ExpMonth)
            select i.APCo, i.UIMth, i.UISeq, i.Reviewer, i.ApprvdYN, i.Memo, l.Line, i.ApprovalSeq,
				--#141031
				--dbo.vfDateOnly(),
				--#143179
				getdate(),
    			i.DateApproved, i.AmountApproved, i.Rejected, i.RejReason, i.APTrans, i.ExpMonth
            from APUR i
    		join bAPUL l
            on l.APCo = i.APCo and l.UIMth = i.UIMth and l.UISeq = i.UISeq  
            where i.Line = -1 and l.APCo = @apco and i.UIMth = @uimth and i.UISeq = @uiseq
            and not exists (select 1 from bAPUR r where l.APCo = r.APCo and l.UIMth = r.UIMth and 
                                              l.UISeq = r.UISeq and l.Line = r.Line and r.Reviewer = i.Reviewer and
                                              r.APTrans is null and r.ExpMonth is null)
                              
            end
        end

GO
GRANT EXECUTE ON  [dbo].[bspAPURLineSync] TO [public]
GO
