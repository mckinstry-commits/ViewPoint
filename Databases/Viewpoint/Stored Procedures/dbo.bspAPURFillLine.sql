SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         proc [dbo].[bspAPURFillLine]
    /*******************************************************
    * Created: 9/17/02 TV
    * Modified: GG 09/26/02 - #18654 - rewritten
    *            TV 01/06/03 - #19648 - Orderby
    *            TV 02/04/03 - 19878
    *            TV 02/06/03 - Sort on Line is no nurmeric
    *			  MV 06/23/03 - #21533 - moved l.JCCo, l.EMCo, l.GLCo,
    *							changed Seq331 to Seq328
    *							changed OrderBy clause
    *           TV 08/04/03 - 21999 - redo Order by
    * Usage:
    *	Called by AP Unapproved Invoice Review form to return a resultset
    *	of invoice line level information.
    *
    * Inputs:
    *	@apco		AP Co#
    *	@reviewer	Reviewer restriction
    *	@jcco		JC Co# restriction - optional
    *	@job		Job restriction - optional
    *	@showall	'Y' = include all eligible invoices, 'N' = only include invoices with lines not yet approved
    *	@uimth		Unapproved Invoice Month
    *	@uiseq		Unapproved Invoice Seq#
    *	@linetypes	included Line Types '1234567' = all
    *
    * Output:
    *	@errmsg		error message
    *
    * Returns:
    *	resultset of invoice line information
    *
    ********************************************************/
    	(@apco bCompany = null, @reviewer varchar(3) = null, @jcco bCompany = null, @job bJob = null,
     	 @showall char(1), @uimth bMonth = null, @uiseq int = null, @linetypes varchar(20),@orderby int,
    	 @errmsg varchar(255) output)
    
   
   
    as
    
    set nocount on
   if @orderby in (4,5,6,7,8,9,41,43)
       begin
       select l.Line, l.LineType, l.Description, l.UM, l.GrossAmt, l.MiscAmt, l.TaxAmt, l.Retainage, l.Discount, 
    	(l.GrossAmt + (case l.MiscYN when 'Y' then l.MiscAmt else 0 end) + l.TaxAmt - l.Discount) as LineTotal,
        l.SL, l.SLItem, l.PO, l.POItem, l.ItemType, l.WO, l.WOItem, l.Material, 
        l.Units, l.UnitCost, l.ECM, l.Supplier, l.PayType, l.TaxCode, l.TaxType, 
        r.ApprvdYN, r.Rejected, r.RejReason, '' AS Seq328, l.APCo, l.UISeq, l.UIMth, 
        l.Line AS EXPR1, l.PhaseGroup, l.EMGroup,l.JCCo, l.Job, l.Phase, l.JCCType,l.EMCo, l.Equip, 
        l.CostCode, l.EMCType, l.INCo, l.Loc,l.GLCo, l.GLAcct, l.MatlGroup, l.Notes
        from APUL l
        join APUR r on l.APCo = r.APCo and l.UIMth = r.UIMth and l.UISeq = r.UISeq and l.Line = r.Line
        where l.APCo = @apco and l.UIMth = @uimth and l.UISeq = @uiseq and r.Reviewer = @reviewer 
        	and isnull(l.JCCo,0) = isnull(@jcco,isnull(l.JCCo,0))	-- optional restriction by JC Co#
        	and isnull(l.Job,'') = isnull(@job,isnull(l.Job,''))	-- optional restriction by Job
        	and charindex(convert(varchar,l.LineType),@linetypes) <> 0 	-- included Line Types
        	and ((r.ApprvdYN = 'N' and isnull(r.Rejected,'N') = 'N') or isnull(@showall, 'N') = 'Y')		-- not yet approved or rejected, or all
        	-- only include lines ready for review
        	and (select count(*) from APUR r1 where l.APCo = r1.APCo and l.UIMth = r1.UIMth and l.UISeq = r1.UISeq
        							and l.Line = r1.Line and r1.ApprovalSeq < r.ApprovalSeq and r1.ApprvdYN = 'N') = 0
       order by case @orderby --issue 19648 TV 01/07/03
                when 4 then l.GrossAmt
                when 5 then l.MiscAmt
                when 6 then l.TaxAmt
                when 7 then l.Retainage
                when 8 then l.Discount
                when 9 then (l.GrossAmt + (case l.MiscYN when 'Y' then l.MiscAmt else 0 end) + l.TaxAmt - l.Discount)
                when 41 /*42*/ then l.CostCode
                when 43 /*44*/ then l.INCo
                end
       end
   else  
        begin 
        select l.Line, l.LineType, l.Description, l.UM, l.GrossAmt, l.MiscAmt, l.TaxAmt, l.Retainage, l.Discount, 
        	(l.GrossAmt + (case l.MiscYN when 'Y' then l.MiscAmt else 0 end) + l.TaxAmt - l.Discount) as LineTotal,
            l.SL, l.SLItem, l.PO, l.POItem, l.ItemType, l.WO, l.WOItem, l.Material, 
            l.Units, l.UnitCost, l.ECM, l.Supplier, l.PayType, l.TaxCode, l.TaxType, 
            r.ApprvdYN, r.Rejected, r.RejReason, '' AS Seq328, l.APCo, l.UISeq, l.UIMth, 
            l.Line AS EXPR1, l.PhaseGroup, l.EMGroup,l.JCCo, l.Job, l.Phase, l.JCCType,l.EMCo, l.Equip, 
            l.CostCode, l.EMCType, l.INCo, l.Loc,l.GLCo, l.GLAcct, l.MatlGroup, l.Notes
        from APUL l
        join APUR r on l.APCo = r.APCo and l.UIMth = r.UIMth and l.UISeq = r.UISeq and l.Line = r.Line
        where l.APCo = @apco and l.UIMth = @uimth and l.UISeq = @uiseq and r.Reviewer = @reviewer 
        	and isnull(l.JCCo,0) = isnull(@jcco,isnull(l.JCCo,0))	-- optional restriction by JC Co#
        	and isnull(l.Job,'') = isnull(@job,isnull(l.Job,''))	-- optional restriction by Job
        	and charindex(convert(varchar,l.LineType),@linetypes) <> 0 	-- included Line Types
        	and ((r.ApprvdYN = 'N' and isnull(r.Rejected,'N') = 'N') or isnull(@showall, 'N') = 'Y')		-- not yet approved or rejected, or all
        	-- only include lines ready for review
        	and (select count(*) from APUR r1 where l.APCo = r1.APCo and l.UIMth = r1.UIMth and l.UISeq = r1.UISeq
        							and l.Line = r1.Line and r1.ApprovalSeq < r.ApprovalSeq and r1.ApprvdYN = 'N') = 0
       order by case @orderby --issue 19648 TV 01/07/03
                when 1 then convert(varchar,l.LineType)
                when 2 then convert(varchar,l.Description)
                when 3 then convert(varchar,l.UM)
                when 4 then convert(varchar,l.GrossAmt)
                when 5 then convert(varchar,l.MiscAmt)
                when 6 then convert(varchar,l.TaxAmt)
                when 7 then convert(varchar,l.Retainage)
                when 8 then convert(varchar,l.Discount)
                when 9 then convert(varchar,(l.GrossAmt + (case l.MiscYN when 'Y' then l.MiscAmt else 0 end) + l.TaxAmt - l.Discount))
                when 25 /*28*/ then convert(varchar,r.ApprvdYN)
                when 26 /*29*/ then convert(varchar,r.Rejected)
                when 27 /*30*/ then convert(varchar,r.RejReason)
                when 36 /*38*/ then convert(varchar,l.Job)
                when 37 /*39*/ then convert(varchar,l.Phase)
                when 38 /*40*/ then convert(varchar,l.JCCType)
                when 40 /*41*/ then convert(varchar,l.Equip)
                when 41 /*42*/ then convert(varchar,l.CostCode)
                when 42 /*43*/ then convert(varchar,l.EMCType)
                when 43 /*44*/ then convert(varchar,l.INCo)
                when 44 /*45*/ then convert(varchar,l.Loc)
                when 46 then convert(varchar,l.GLAcct)
                --else convert(varchar,l.Line)--02/06/03
                end
       end
    bspexit:
    	return

GO
GRANT EXECUTE ON  [dbo].[bspAPURFillLine] TO [public]
GO
