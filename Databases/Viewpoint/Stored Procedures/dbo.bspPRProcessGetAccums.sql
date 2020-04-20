SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspPRProcessGetAccums]
   /***********************************************************
   * CREATED BY:	 GG  02/17/98
   * MODIFIED BY:   GG  06/17/99 - removed PR Group restriction
   *                GG 11/11/99 - fix to 'pay period' amount accumulations
   *	          GG 03/14/00 - fix to limit monthly and quarterly accums to a single year
   *               GG 01/03/01 - Issue #11777 - accum amounts for monthly limits based on Pay Periods with same Limit Mth
   *				GG 01/08/02 - #15818 - use @limitmth for monthly limits, @paidmth for all others
   *				EN 10/9/02 - issue 18877 change double quotes to single
   *				GG 08/20/04 - #25392 - fix YTD amts to exclude current payroll
   *				EN 8/11/05 - #28609  removed dependency on employee being assigned to a specific PR Group when applying month limit
   *				mh 02/19/2010 #137971 - modified to allow date compares to use other then calendar year.
   *
   * USAGE:
   * Accumulates an Employee's actual, subject, and eligible amounts based on limit period.
   * Accumulates year-to-date actual and eligible amounts for year-to-date corrections.
   * Called from various bspPRProcess procedures.
   *
   * INPUT PARAMETERS
   *   @prco	        PR Company
   *   @prgroup	    PR Group
   *   @prenddate	    PR Ending Date
   *   @employee	    Employee to process
   *   @payseq	    	Payment Sequence #
   *   @dlcode	    	Dedn/liab code
   *   @dltype	    	Dedn/liab type ('D', 'L')
   *   @limitperiod	Limit period ('P','M','Q','A','L')
   *   @limitmth	    Limit month
   *   @ytdcorrect		Year-to-date correction flag ('Y','N')
   *
   * OUTPUT PARAMETERS
   *   @accumamt	    Accumulated dedn/liab amount based on limit period
   *   @accumsubj 		Accumulated dedn/liab subject amount based on limit period
   *   @accumelig	    Accumulated dedn/liab eligible amount based on limit period
   *   @ytdamt	    	Year-to-date dedn/liab amount
   *   @ytdelig	    Year-to-date dedn/liab eligible amount
   *   @errmsg  	    Error message if something went wrong
   *
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/
    @prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq tinyint,
    @dlcode bEDLCode, @dltype char(1), @limitperiod char(1), @limitmth bMonth, @ytdcorrect char(1),
    @accumamt bDollar output, @accumsubj bDollar output, @accumelig bDollar output, @ytdamt bDollar output,
    @ytdelig bDollar output, @errmsg varchar(255) output
    as
    set nocount on
    
    declare @rcode int, @a1 bDollar, @a2 bDollar, @a3 bDollar, @a4 bDollar, @s1 bDollar, @s2 bDollar, @s3 bDollar,
    @s4 bDollar, @e1 bDollar, @e2 bDollar, @e3 bDollar, @e4 bDollar, @paidmth bMonth
    
    select @rcode = 0, @accumamt = 0.00, @accumsubj = 0.00, @accumelig = 0.00, @ytdamt = 0.00, @ytdelig = 0.00
    
    -- if exists, get paid month to be used for non-monthly limits
    select @paidmth = PaidMth
    from dbo.bPRSQ
    where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate 
    	and Employee = @employee and PaySeq = @payseq
    if @paidmth is null
    	begin
    	-- use expected paid month 
    	select @paidmth = case MultiMth when 'Y' then EndMth else BeginMth end
    	from dbo.bPRPC
    	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
    	end
    
    
    --137971
	declare @yearendmth tinyint, @accumbeginmth bMonth, @accumendmth bMonth

	select @yearendmth = case h.DefaultCountry when 'AU' then 6 else 12 end
	from bHQCO h with (nolock) 
	where h.HQCo = @prco

	exec vspPRGetMthsForAnnualCalcs @yearendmth, @paidmth, @accumbeginmth output, @accumendmth output, @errmsg output
	-- end  137971

	-- Pay Period Limits - accum amounts from previous Pay Seqs in the current Pay Period
	if @limitperiod = 'P'
	begin
		select @accumamt = isnull(sum( case UseOver	when 'Y' then OverAmt else Amount end),0.00),
		@accumsubj = isnull(sum(SubjectAmt),0.00), @accumelig = isnull(sum(EligibleAmt),0.00)
		from dbo.bPRDT with (nolock)
		where PRCo = @prco /*and PRGroup = @prgroup*/ and PREndDate = @prenddate --issue 28609 removed PRGroup check form Where clause
		and Employee = @employee and PaySeq <= @payseq and EDLType = @dltype and EDLCode = @dlcode
	end
        
    -- Monthly Limits - accum amounts from previous Pay Periods using the same Limit Mth
    if @limitperiod = 'M'
	begin
		select @accumamt = isnull(sum( case d.UseOver when 'Y' then d.OverAmt else d.Amount end),0.00),
		@accumsubj = isnull(sum(d.SubjectAmt),0.00), @accumelig = isnull(sum(d.EligibleAmt),0.00)
		from dbo.bPRDT d with (nolock)
		join dbo.bPRPC p with (nolock) on d.PRCo = p.PRCo and d.PRGroup = p.PRGroup and d.PREndDate = p.PREndDate
		where d.PRCo = @prco /*and d.PRGroup = @prgroup*/ --issue 28609 removed PRGroup check from Where clause
		and ((d.PREndDate < @prenddate and p.LimitMth = @limitmth) or (d.PREndDate = @prenddate and d.PaySeq <= @payseq))
		and d.Employee = @employee and d.EDLType = @dltype and d.EDLCode = @dlcode
	end
	
    -- Other Limits - use amounts from Accums and Detail

	if @limitperiod in ('Q','A','L')
	begin
/*137971
    	-- start with existing accums
        select @a1 = isnull(sum(Amount),0.00), @s1 = isnull(sum(SubjectAmt),0.00), @e1 = isnull(sum(EligibleAmt),0.00)
        from dbo.bPREA     -- updated accumulations
        where PRCo = @prco and Employee = @employee
            and ((@limitperiod = 'Q' and datepart(quarter,Mth) = datepart(quarter,@paidmth) and datepart(year,Mth) = datepart(year,@paidmth))
         	or (@limitperiod = 'A' and datepart(year,Mth) = datepart(year,@paidmth))
         	or (@limitperiod = 'L' and Mth <= @paidmth))
         	and EDLType = @dltype and EDLCode = @dlcode
*/         	

		-- start with existing accums
		select @a1 = isnull(sum(Amount),0.00), @s1 = isnull(sum(SubjectAmt),0.00), @e1 = isnull(sum(EligibleAmt),0.00)
		from dbo.bPREA     -- updated accumulations
		where PRCo = @prco and Employee = @employee
		and ((@limitperiod = 'Q' and datepart(quarter,Mth) = datepart(quarter,@paidmth) and Mth between @accumbeginmth and @accumendmth)
		or (@limitperiod = 'A' and Mth between @accumbeginmth and @accumendmth)
		or (@limitperiod = 'L' and Mth <= @paidmth))
		and EDLType = @dltype and EDLCode = @dlcode
--137971
         	         	
		-- current amounts from current and earlier Pay Periods where Final Accum update has not been run
/*137971		
		select @a2 = isnull(sum( case d.UseOver when 'Y' then d.OverAmt else d.Amount end),0.00),
		@s2 = isnull(sum(SubjectAmt),0.00), @e2 = isnull(sum(EligibleAmt),0.00)
		from dbo.bPRDT d
		join dbo.bPRSQ s on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
		and s.Employee = d.Employee and s.PaySeq = d.PaySeq
		join dbo.bPRPC c on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
		where d.PRCo = @prco and d.Employee = @employee
		and d.EDLType = @dltype and d.EDLCode = @dlcode
		and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq <= @payseq))
		and ((s.PaidMth is null and (@limitperiod = 'Q' and datepart(quarter,case c.MultiMth when 'Y' then c.EndMth else c.BeginMth end) = datepart(quarter,@paidmth)
		and datepart(year,case c.MultiMth when 'Y' then c.EndMth else c.BeginMth end) = datepart(year,@paidmth))
		or (@limitperiod = 'A' and datepart(year,case c.MultiMth when 'Y' then c.EndMth else c.BeginMth end) = datepart(year,@paidmth))
		or (@limitperiod = 'L' and case c.MultiMth when 'Y' then c.EndMth else c.BeginMth end <= @paidmth))
		or ((@limitperiod = 'Q' and datepart(quarter,s.PaidMth) = datepart(quarter,@paidmth)
		and datepart(year,s.PaidMth) = datepart(year,@paidmth))
		or (@limitperiod = 'A' and datepart(year,s.PaidMth) = datepart(year,@paidmth))
		or (@limitperiod = 'L' and s.PaidMth <= @paidmth)))
		and c.GLInterface = 'N'
*/         	

		select @a2 = isnull(sum( case d.UseOver when 'Y' then d.OverAmt else d.Amount end),0.00),
		@s2 = isnull(sum(SubjectAmt),0.00), @e2 = isnull(sum(EligibleAmt),0.00)
		from dbo.bPRDT d
		join dbo.bPRSQ s on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
		and s.Employee = d.Employee and s.PaySeq = d.PaySeq
		join dbo.bPRPC c on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
		where d.PRCo = @prco and d.Employee = @employee
		and d.EDLType = @dltype and d.EDLCode = @dlcode
		and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq <= @payseq))
		and ((s.PaidMth is null and (@limitperiod = 'Q' and datepart(quarter,case c.MultiMth when 'Y' then c.EndMth else c.BeginMth end) = datepart(quarter,@paidmth)
		and case c.MultiMth when 'Y' then c.EndMth else c.BeginMth end between @accumbeginmth and @accumendmth)
		or (@limitperiod = 'A' and case c.MultiMth when 'Y' then c.EndMth else c.BeginMth end between @accumbeginmth and @accumendmth)
		or (@limitperiod = 'L' and case c.MultiMth when 'Y' then c.EndMth else c.BeginMth end <= @paidmth))
		or ((@limitperiod = 'Q' and datepart(quarter,s.PaidMth) = datepart(quarter,@paidmth)
		and s.PaidMth between @accumbeginmth and @accumendmth)
		or (@limitperiod = 'A' and s.PaidMth between @accumbeginmth and @accumendmth)
		or (@limitperiod = 'L' and s.PaidMth <= @paidmth)))
		and c.GLInterface = 'N'
--137971		         	

        -- old amounts from earlier Pay Periods where Final Accum update has not been run
/*137971        
        select @a3 = isnull(sum(OldAmt),0.00), @s3 = isnull(sum(OldSubject),0.00), @e3 = isnull(sum(OldEligible),0.00)
        from dbo.bPRDT d
        join dbo.bPRPC c on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
        where d.PRCo = @prco and d.Employee = @employee	and d.EDLType = @dltype and d.EDLCode = @dlcode
            and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq < @payseq))
         	and ((@limitperiod = 'Q' and datepart(quarter,d.OldMth) = datepart(quarter,@paidmth)
                and datepart(year,d.OldMth) = datepart(year,@paidmth))
         		or (@limitperiod = 'A' and datepart(year,d.OldMth) = datepart(year,@paidmth))
         		or (@limitperiod = 'L' and d.OldMth <= @paidmth))
         	and c.GLInterface = 'N'
*/

        select @a3 = isnull(sum(OldAmt),0.00), @s3 = isnull(sum(OldSubject),0.00), @e3 = isnull(sum(OldEligible),0.00)
        from dbo.bPRDT d
        join dbo.bPRPC c on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
        where d.PRCo = @prco and d.Employee = @employee	and d.EDLType = @dltype and d.EDLCode = @dlcode
            and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq < @payseq))
         	and ((@limitperiod = 'Q' and datepart(quarter,d.OldMth) = datepart(quarter,@paidmth)
                and d.OldMth between @accumbeginmth and @accumendmth)
         		or (@limitperiod = 'A' and d.OldMth between @accumbeginmth and @accumendmth)
         		or (@limitperiod = 'L' and d.OldMth <= @paidmth))
         	and c.GLInterface = 'N'
--end 137971         	
         	
        -- old amounts from current and later Pay Periods - need to back out of accums
/*137971
        select @a4 = isnull(sum(OldAmt),0.00), @s4 = isnull(sum(OldSubject),0.00), @e4 = isnull(sum(OldEligible),0.00)
        from dbo.bPRDT
        where PRCo = @prco and Employee = @employee	and EDLType = @dltype and EDLCode = @dlcode
         	and (PREndDate > @prenddate or (PREndDate = @prenddate and PaySeq >= @payseq))
         	and ((@limitperiod = 'Q' and datepart(quarter,OldMth) = datepart(quarter,@paidmth)
                and datepart(year,OldMth) = datepart(year,@paidmth))
   
         		or (@limitperiod = 'A' and datepart(year,OldMth) = datepart(year,@paidmth))
         		or (@limitperiod = 'L' and OldMth <= @paidmth))
*/        
        
        select @a4 = isnull(sum(OldAmt),0.00), @s4 = isnull(sum(OldSubject),0.00), @e4 = isnull(sum(OldEligible),0.00)
        from dbo.bPRDT
        where PRCo = @prco and Employee = @employee	and EDLType = @dltype and EDLCode = @dlcode
         	and (PREndDate > @prenddate or (PREndDate = @prenddate and PaySeq >= @payseq))
         	and ((@limitperiod = 'Q' and datepart(quarter,OldMth) = datepart(quarter,@paidmth)
                and OldMth between @accumbeginmth and @accumendmth)
           		or (@limitperiod = 'A' and OldMth between @accumbeginmth and @accumendmth)
         		or (@limitperiod = 'L' and OldMth <= @paidmth))
--137971         		
         		
        /* period totals is updated accums + net from earlier Pay Pds - old from later Pay Pds */
        select @accumamt = @a1 + (@a2 - @a3) - @a4
        select @accumsubj = @s1 + (@s2 - @s3) - @s4
        select @accumelig = @e1 + (@e2 - @e3) - @e4
        
	end
        
        
    -- Year-To-Date Corrections require YTD Amt and YTD Eligible
    if @ytdcorrect = 'Y'
        begin
        /* year-to-date accums */
        
/*137971        
        select @a1 = isnull(sum(Amount),0.00), @e1 = isnull(sum(EligibleAmt),0.00)
        from bPREA
        where PRCo = @prco and Employee = @employee and datepart(year,Mth) = datepart(year,@paidmth)
         		and EDLType = @dltype and EDLCode = @dlcode
*/         		

        select @a1 = isnull(sum(Amount),0.00), @e1 = isnull(sum(EligibleAmt),0.00)
        from bPREA
        where PRCo = @prco and Employee = @employee and Mth between @accumbeginmth and @accumendmth
         		and EDLType = @dltype and EDLCode = @dlcode
--end 137971         		         		
         		
        /* current amounts from earlier Pay Periods where Final Accum update has not been run */
/*137971        
        select @a2 = isnull(sum( case d.UseOver when 'Y' then d.OverAmt else d.Amount end),0.00),
            @e2 = isnull(sum(EligibleAmt),0.00)
        from bPRDT d
        join bPRSQ s on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
         	and s.Employee = d.Employee and s.PaySeq = d.PaySeq
        join bPRPC c on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
        where d.PRCo = @prco and d.Employee = @employee	and d.EDLType = @dltype and d.EDLCode = @dlcode
         	and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq < @payseq))
         	and ((s.PaidMth is null and datepart(year,case c.MultiMth when 'Y' then c.EndMth else c.BeginMth end) = datepart(year,@paidmth))
         		or (datepart(year,s.PaidMth) = datepart(year,@paidmth)))
         	and c.GLInterface = 'N'
*/         	

        select @a2 = isnull(sum( case d.UseOver when 'Y' then d.OverAmt else d.Amount end),0.00),
            @e2 = isnull(sum(EligibleAmt),0.00)
        from bPRDT d
        join bPRSQ s on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
         	and s.Employee = d.Employee and s.PaySeq = d.PaySeq
        join bPRPC c on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
        where d.PRCo = @prco and d.Employee = @employee	and d.EDLType = @dltype and d.EDLCode = @dlcode
         	and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq < @payseq))
         	and ((s.PaidMth is null and case c.MultiMth when 'Y' then c.EndMth else c.BeginMth end between @accumbeginmth and @accumendmth)
         		or (s.PaidMth between @accumbeginmth and @accumendmth))
         	and c.GLInterface = 'N'
--end 137971         	         	
         	
        /* old amounts from earlier Pay Periods where Final Accum update has not been run */
/*137971        
        select @a3 = isnull(sum(OldAmt),0.00), @e3 = isnull(sum(OldEligible),0.00)
        from bPRDT d
        join bPRPC c on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
        where d.PRCo = @prco and d.Employee = @employee	and d.EDLType = @dltype and d.EDLCode = @dlcode
            and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq < @payseq))
         	and datepart(year,d.OldMth) = datepart(year,@paidmth)
         	and c.GLInterface = 'N'
*/         	
        select @a3 = isnull(sum(OldAmt),0.00), @e3 = isnull(sum(OldEligible),0.00)
        from bPRDT d
        join bPRPC c on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
        where d.PRCo = @prco and d.Employee = @employee	and d.EDLType = @dltype and d.EDLCode = @dlcode
            and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq < @payseq))
         	and d.OldMth between @accumbeginmth and @accumendmth
         	and c.GLInterface = 'N'
--137971
         	    
        /* get old amount from later Pay Periods - need to back out of accums */
/*137971        
        select @a4 = isnull(sum(OldAmt),0.00), @e4 = isnull(sum(OldEligible),0.00)
        from bPRDT
        where PRCo = @prco and Employee = @employee and EDLType = @dltype
            and EDLCode = @dlcode and datepart(year,OldMth) = datepart(year,@paidmth)
   		and (PREndDate > @prenddate or (PREndDate = @prenddate and PaySeq >= @payseq))	-- #25392 - include current payroll to correct ytd amts
*/
        select @a4 = isnull(sum(OldAmt),0.00), @e4 = isnull(sum(OldEligible),0.00)
        from bPRDT
        where PRCo = @prco and Employee = @employee and EDLType = @dltype
            and EDLCode = @dlcode and OldMth between @accumbeginmth and @accumendmth
   		and (PREndDate > @prenddate or (PREndDate = @prenddate and PaySeq >= @payseq))	-- #25392 - include current payroll to correct ytd amts
--137971
   		   
        /* year-to-date is accums + net from earlier Pay Pds - old from later Pay Pds */
        select @ytdamt = @a1 + (@a2 - @a3) - @a4
        select @ytdelig = @e1 + (@e2 - @e3) - @e4
        end
    
    bspexit:
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRProcessGetAccums] TO [public]
GO
