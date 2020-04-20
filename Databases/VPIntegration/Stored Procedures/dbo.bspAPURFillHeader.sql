SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                   Proc [dbo].[bspAPURFillHeader]
    /***********************************************
    * Created: TV 09/13/02
    * Modified: GG 09/26/02 - #18654 - rewritten
    *            TV 01/07/03 -#19648 - Order by
    *            TV 02/04/03 - 19878
    *            TV 08/04/03 - 21999 - redo Order by
    *			  MV 08/10/05 - #29517 don't isnull wrap DiscDate
    * Usage:
    *	Called by AP Unapproved Invoice Review form to return a resultset
    *	of unapproved invoice header information.
    *
    *
    * Inputs:
    *	@apco		AP Co#
    *	@reviewer	Reviewer restriction
    *	@jcco		JC Co# restriction - optional
    *	@job		Job restriction - optional
    *	@showall	'Y' = include all eligible invoices, 'N' = only include invoices with lines not yet approved
    *	@linetypes	included Line Types '1234567' = all
    *     
    *
    ************************************************/
    (@apco bCompany, @reviewer varchar(3), @jcco bCompany = null, @job bJob = null,
     @showall char(1) = 'N', @linetypes varchar(20), @orderby int, @errmsg varchar(255)output)
    
    as
    
    set nocount on
    
    -- create temp table and fill with invoice header info
    create table #UITemp(APCo tinyint, UIMth smalldatetime, UISeq int, Vendor int, Name varchar(60), APRef varchar(15),
    		InvTotal numeric(12,2), ReviewTotal numeric(12,2), Approved varchar(1), Rejected varchar(1),
    		Description varchar(30), InvDate smalldatetime, DiscDate smalldatetime, DueDate smalldatetime,
    		HoldCode varchar(10), PayControl varchar(10), Notes varchar(2000))
    CREATE  UNIQUE  CLUSTERED  INDEX bi#UITemp ON dbo.#UITemp(APCo, UIMth, UISeq)
    
    insert #UITemp
    select distinct i.APCo, i.UIMth, i.UISeq, i.Vendor, v.Name, i.APRef, i.InvTotal, 0, 'Y', 'N',
    	isnull(i.Description,''), isnull(i.InvDate,''),i.DiscDate /*isnull(i.DiscDate, '')*/, i.DueDate, isnull(i.HoldCode, ''), 
        isnull(i.PayControl,''), isnull(i.Notes, '')
    from APUI i (nolock)
    left join APVM v (nolock) on i.VendorGroup = v.VendorGroup and i.Vendor = v.Vendor
    join APUL l (nolock) on i.APCo = l.APCo and i.UIMth = l.UIMth and i.UISeq = l.UISeq
    join APUR r (nolock) on l.APCo = r.APCo and l.UIMth = r.UIMth and l.UISeq = r.UISeq and l.Line = r.Line
    where i.APCo = @apco and r.Reviewer = @reviewer		-- restrict by AP Co# and Reviewer
    	and i.InUseBatchId is null		-- restrict to invoices not in a batch
    	and isnull(l.JCCo,0) = isnull(@jcco,isnull(l.JCCo,0))	-- optional restriction by JC Co#
    	and isnull(l.Job,'') = isnull(@job,isnull(l.Job,''))	-- optional restriction by Job
    	and charindex(convert(varchar,l.LineType),@linetypes) <> 0 	-- included Line Types
    	and ((r.ApprvdYN = 'N' and isnull(r.Rejected,'N') = 'N') or @showall = 'Y')				-- not yet approved or all
    	-- only include invoices with lines ready for review
    	and (select count(*) from APUR r1 (nolock) where l.APCo = r1.APCo and l.UIMth = r1.UIMth and l.UISeq = r1.UISeq
    							and l.Line = r1.Line and r1.ApprovalSeq < r.ApprovalSeq and r1.ApprvdYN = 'N') = 0
    order by i.APCo, i.UIMth, i.UISeq
    
    
    
    -- determine Reviewer's Total (included lines only)
    update #UITemp
    set ReviewTotal = (select sum(l.GrossAmt + (case l.MiscYN when 'Y' then l.MiscAmt else 0 end) + l.TaxAmt - l.Discount)
    from APUL l (nolock)
    join APUR r (nolock)on l.APCo = r.APCo and l.UIMth = r.UIMth and l.UISeq = r.UISeq and l.Line = r.Line
    where r.Reviewer = @reviewer 
    	and isnull(l.JCCo,0) = isnull(@jcco,isnull(l.JCCo,0))	-- optional restriction by JC Co#
    	and isnull(l.Job,'') = isnull(@job,isnull(l.Job,''))	-- optional restriction by Job
    	and charindex(convert(varchar,l.LineType),@linetypes) <> 0 	-- included Line Types
    	and ((r.ApprvdYN = 'N' and isnull(r.Rejected,'N') = 'N') or @showall = 'Y')		-- not yet approved or rejected, or all
    	-- only include invoices with lines ready for review
    	and (select count(*) from APUR r1 (nolock) where l.APCo = r1.APCo and l.UIMth = r1.UIMth and l.UISeq = r1.UISeq
    							and l.Line = r1.Line and r1.ApprovalSeq < r.ApprovalSeq and r1.ApprvdYN = 'N') = 0
    	and t.APCo = l.APCo and t.UIMth = l.UIMth and t.UISeq = l.UISeq)
    from #UITemp t, APUL l
    
    -- determine Reviewer's Approved status based on displayed lines only
    update #UITemp
    set Approved = (select case when (sum(case r.ApprvdYN when 'Y' then 0 else 1 end)= 0) then 'Y' else 'N' end
    from APUL l (nolock)
    join APUR r (nolock) on l.APCo = r.APCo and l.UIMth = r.UIMth and l.UISeq = r.UISeq and l.Line = r.Line
    where r.Reviewer = @reviewer 
    	and isnull(l.JCCo,0) = isnull(@jcco,isnull(l.JCCo,0))	-- optional restriction by JC Co#
    	and isnull(l.Job,'') = isnull(@job,isnull(l.Job,''))	-- optional restriction by Job
    	and charindex(convert(varchar,l.LineType),@linetypes) <> 0 	-- included Line Types
    	and ((r.ApprvdYN = 'N' and isnull(r.Rejected,'N') = 'N') or @showall = 'Y')		-- not yet approved or rejected, or all
    	-- only include invoices with lines ready for review
    	and (select count(*) from APUR r1 (nolock) where l.APCo = r1.APCo and l.UIMth = r1.UIMth and l.UISeq = r1.UISeq
    							and l.Line = r1.Line and r1.ApprovalSeq < r.ApprovalSeq and r1.ApprvdYN = 'N') = 0
    	and t.APCo = l.APCo and t.UIMth = l.UIMth and t.UISeq = l.UISeq)
    from #UITemp t, APUL l
    
    -- determine Reviewer's Rejected status based on displayed lines only
    update #UITemp
    set Rejected = (select case when (sum(case when isnull(r.Rejected,'N') = 'Y' then 0 else 1 end)= 0) then 'Y' else 'N' end
    from APUL l (nolock)
    join APUR r (nolock) on l.APCo = r.APCo and l.UIMth = r.UIMth and l.UISeq = r.UISeq and l.Line = r.Line
    where r.Reviewer = @reviewer 
    	and isnull(l.JCCo,0) = isnull(@jcco,isnull(l.JCCo,0))	-- optional restriction by JC Co#
    	and isnull(l.Job,'') = isnull(@job,isnull(l.Job,''))	-- optional restriction by Job
    	and charindex(convert(varchar,l.LineType),@linetypes) <> 0 	-- included Line Types
    	and ((r.ApprvdYN = 'N' and isnull(r.Rejected,'N') = 'N') or @showall = 'Y')		-- not yet approved or rejected, or all
    	-- only include invoices with lines ready for review
    	and (select count(*) from APUR r1 (nolock) where l.APCo = r1.APCo and l.UIMth = r1.UIMth and l.UISeq = r1.UISeq
    							and l.Line = r1.Line and r1.ApprovalSeq < r.ApprovalSeq and r1.ApprvdYN = 'N') = 0
    	and t.APCo = l.APCo and t.UIMth = l.UIMth and t.UISeq = l.UISeq)
    from #UITemp t, APUL l
    
    
    -- return info 
   if @orderby in (0,1,3,6,7)
       begin
       select UIMth, UISeq, @reviewer as Reviewer, Vendor, Name, APRef, InvTotal,ReviewTotal,Approved, Rejected,
    	       null as RejReason, Notes, Description, InvDate, DiscDate, DueDate, HoldCode, PayControl
       from #UITemp
       order by case @orderby  --issue 19648 TV 01/07/03
            when 1 then UISeq
            when 3 then Vendor
            when 6 then InvTotal
            when 7 then ReviewTotal
            else convert(int,UIMth)
            end
       end
   else
       begin
       select UIMth, UISeq, @reviewer as Reviewer, Vendor, Name, APRef, InvTotal,ReviewTotal,Approved, Rejected,
    	       null as RejReason, Notes, Description, InvDate, DiscDate, DueDate, HoldCode, PayControl
       from #UITemp
       order by case @orderby  --issue 19648 TV 01/07/03
            when 4 then convert(varchar,Name)
            when 5 then convert(varchar,APRef)
            when 8 then convert(varchar,Approved)
            when 9 then convert(varchar,Rejected)
            end
        end
   
    drop table #UITemp
    
    bspexit:
    	return

GO
GRANT EXECUTE ON  [dbo].[bspAPURFillHeader] TO [public]
GO
