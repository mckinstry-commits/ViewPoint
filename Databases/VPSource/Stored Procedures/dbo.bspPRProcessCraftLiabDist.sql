SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspPRProcessCraftLiabDist]
   /***********************************************************
   * CREATED BY:  	GG  04/14/98
   * MODIFIED BY: 	GG  01/25/99
   *              	GG 09/15/99     Fixed cursor fetch for bcLiabDist1
   *				GG 01/11/00 - Fixed bcLiabDist2 cusror to include PostDate
   *             	GG 03/07/00 - Insert bPRTL entry if missing on final update
   *				EN 10/9/02 - issue 18877 change double quotes to single
   *				EN 3/24/03 - issue 11030 rate of earnings liability limit
   *				EN 4/16/04 - issue 24291 missing PRCo on select PRDL causing distribute liab code error
   *				EN 9/24/04 - issue 20562  change from using bPRCO_LiabDist to bPREC_IncldLiabDist to determine whether an earnings code is included in liab distribs
   *				GG 12/01/04 - #24696 - dist variable factored liab when basis = 0.00
   *				GG 09/21/05 - #29551 - exclude entries w/o earnings included in liab distributions from day and factor cursors
   *				CHS 10/15/2010 - #140541 - change bPRDB.EarnCode to EDLCode
   *				CHS	02/15/2011	- #142620 deal with divide by zero
   *
   * USAGE:
   * Distributes Craft liabilities
   * Called from bspPRProcessCraft procedure.
   *
   * INPUT PARAMETERS
   *   @prco              PR Company
   *   @prgroup	        PR Group
   *   @prenddate	        PR Ending Date
   *   @employee	        Employee to process
   *   @payseq	        Payment Sequence #
   *   @craft             Craft
   *   @class             Class
   *   @template          Craft Template
   *   @dlcode            Liability code
   *   @method            Calculation method
   *   @liabdistbasis     Basis for distributing liability amount
   *   @amt2dist          Amount to distribute
   *   @oldrate           Rate prior to Craft effective date
   *   @newrate           Rate used on and after Craft effective date
   *   @effectdate        Craft effective date
   *   @overrate          Employee override rate
   *   @posttoall         Earnings posted to all days in Pay Period (Y/N)
   *
   * OUTPUT PARAMETERS
   *   @errmsg  	Error message if something went wrong
   *
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/
    	@prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq tinyint,
        @craft bCraft, @class bClass, @template smallint, @dlcode bEDLCode,
        @method varchar(10), @liabdistbasis bDollar, @amt2dist bDollar, @oldrate bUnitCost,
        @newrate bUnitCost, @effectdate bDate, @overrate bUnitCost, @posttoall bYN, @errmsg varchar(255) output
   as
   set nocount on
   
   declare @rcode int, @amtdist bDollar, @lastpostseq smallint, @postseq smallint, @factor bRate, 
   @hrs bHrs, @amt bDollar, @distamt bDollar, @postdate bDate, @rate bUnitCost, @i bDollar, @earns bDollar, @limitbasis char(1)
   
   -- cursor flags
   declare @openLiabDist tinyint, @openLiabDist1 tinyint, @openDay tinyint, @openFactor tinyint, @openLiabDist2 tinyint
   
   -- initialize amount distributed and 'last posting seq#'
   select @rcode = 0, @amtdist = 0.00, @lastpostseq = 0
   
    if @method in ('A', 'R', 'G', 'H', 'F', 'S', 'DN')
        begin
   	 -- #11030 get DL limit basis for special handling of 'rate of earnings' 
   	select @limitbasis = LimitBasis from dbo.PRDL with (nolock) where PRCo=@prco and DLCode=@dlcode
   
   	-- create cursor to process earnings subject to the liability
   	declare bcLiabDist cursor for
   	select e.PostSeq, e.PostDate, e.Factor, e.Hours, e.Amt --issue 20562
   	from dbo.bPRPE e with (nolock)
   	join dbo.bPRDB b with (nolock) on b.EDLCode = e.EarnCode
   	where e.VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode
   		and e.IncldLiabDist = 'Y'	-- #20562 earnings must be included in liab dist
   		and ((@limitbasis = 'R' and b.SubjectOnly = 'Y') or @limitbasis <> 'R') -- #11030 earnings must be 'subject only' if limit basis is 'R'
   	order by e.PostSeq, e.EarnCode
   
        -- open distribution cursor
        open bcLiabDist
        select @openLiabDist = 1
   
        next_LiabDist:  -- loop through Liability Distribution cursor
            fetch next from bcLiabDist into @postseq, @postdate, @factor, @hrs, @amt --issue 20562
            if @@fetch_status = -1 goto end_LiabDist
            if @@fetch_status <> 0 goto next_LiabDist
   
            select @distamt = 0.00
   
            if @method in ('A', 'R', 'DN')
                begin
                select @rate = 0.00
                if @liabdistbasis <> 0.00 select @distamt = (@amt / @liabdistbasis) * @amt2dist
                end
                
            if @method in ('G', 'H', 'F', 'S')
                begin
                select @rate = @oldrate
                if @postdate >= @effectdate select @rate = @newrate
                if @overrate is not null select @rate = @overrate
                select @i = case @method
								when 'G' then @amt
								when 'H' then @hrs
								when 'F' then @hrs * @factor
								-- when 'S' then @amt / @factor
								when 'S' then (case when @factor = 0.00 then 0.00 else @amt / @factor end) -- CHS	02/15/2011	- #142620 deal with divide by zero
								end
                if @liabdistbasis = 0.00 select @distamt = @i * @rate
                if @liabdistbasis <> 0.00 select @distamt = ((@i * @rate) / @liabdistbasis) * @amt2dist
                end
   
    		if @lastpostseq = 0 select @lastpostseq = @postseq	-- save the first posting seq#
   
            if @distamt = 0.00 goto next_LiabDist
   
    		update dbo.bPRTL
    		set Amt = Amt + @distamt
    		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
    			and PaySeq = @payseq and PostSeq = @postseq and LiabCode = @dlcode
    		if @@rowcount = 0
    			begin
               insert dbo.bPRTL (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, LiabCode, Rate, Amt)
               values (@prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @dlcode, @rate, @distamt)
    			end
   
            -- accumulate amount distributed and save last posting seq#
    		select @amtdist = @amtdist + @distamt, @lastpostseq = @postseq
    		goto next_LiabDist
        end
   
    -- Rate per Day - this distribution works for both actual or std # of days
    if @method = 'D'
        begin
        -- create cursor for actual days worked
        declare bcDay cursor for
        select distinct e.PostDate
        from dbo.bPRPE e with (nolock)
        join dbo.bPRDB b with (nolock) on b.EDLCode = e.EarnCode
        where e.VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode
   		and e.IncldLiabDist = 'Y' -- only include days with earnings flagged for liab distribution
        order by e.PostDate
   
        -- open Day cursor
        open bcDay
        select @openDay = 1
   
        next_Day:  -- loop through each day
            fetch next from bcDay into @postdate
            if @@fetch_status = -1 goto end_LiabDist
            if @@fetch_status <> 0 goto next_Day
   
   		-- get sum of earnings for the day
            select @earns = isnull(sum(e.Amt),0.00)
            from dbo.bPRPE e with (nolock)
            join dbo.bPRDB b with (nolock) on b.EDLCode = e.EarnCode
            where VPUserName = SUSER_SNAME() and e.PostDate = @postdate and b.PRCo = @prco and b.DLCode = @dlcode
                and e.IncldLiabDist='Y' --issue 20562 must be included in liab distribution
   
            -- rate based on posted date
            select @rate = @oldrate
            if @postdate >= @effectdate select @rate = @newrate
            -- use Pay Period Ending date if posted to all
            if @posttoall = 'Y'
                begin
                select @rate = @oldrate
                if @prenddate >= @effectdate select @rate = @newrate
                end
            -- if override rate exists, use it
            if @overrate is not null select @rate = @overrate
   
            -- create cursor to process earnings subject to the liability
            declare bcLiabDist1 cursor for
            select e.PostSeq, e.Amt 
            from dbo.bPRPE e with (nolock)
            join dbo.bPRDB b with (nolock) on b.EDLCode = e.EarnCode
            where e.VPUserName = SUSER_SNAME() and e.PostDate = @postdate and b.PRCo = @prco and b.DLCode = @dlcode
                and e.IncldLiabDist = 'Y' -- must be included in liab distribution
            order by e.PostSeq, e.EarnCode
   
            -- open distribution cursor
            open bcLiabDist1
            select @openLiabDist1 = 1
   
            next_LiabDist1:  -- loop through Liability Distribution cursor
               fetch next from bcLiabDist1 into @postseq, @amt 
               if @@fetch_status = -1 goto end_LiabDist1
               if @@fetch_status <> 0 goto next_LiabDist1
   
   			if @lastpostseq = 0 select @lastpostseq = @postseq	-- save the first posting seq#
                
   			select @distamt = 0.00
   
               if @earns <> 0.00 and @liabdistbasis <> 0.00
                   begin
   				-- liability basis is actual days worked
                   select @distamt = (((@amt / @earns) * @rate) / @liabdistbasis) * @amt2dist
                   end
   
               if @distamt = 0.00 goto next_LiabDist1
   
    			update dbo.bPRTL
    			set Amt = Amt + @distamt
    			where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
    				and PaySeq = @payseq and PostSeq = @postseq and LiabCode = @dlcode
    			if @@rowcount = 0
    				begin
               	insert dbo.bPRTL (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, LiabCode, Rate, Amt)
                   values (@prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @dlcode, @rate, @distamt)
    				end
   
                -- accumulate amount distributed and save last posting seq#
                select @amtdist = @amtdist + @distamt, @lastpostseq = @postseq
                goto next_LiabDist1
   
        end_LiabDist1:
            close bcLiabDist1
            deallocate bcLiabDist1
            select @openLiabDist1 = 0
            goto next_Day
        end
   
    -- Variable Rate per Hour
    if @method = 'V'
        begin
        -- create cursor by Earnings Factor
        declare bcFactor cursor for
        select distinct e.Factor
        from dbo.bPRPE e with (nolock)
        join bPRDB b on b.EDLCode = e.EarnCode
        where e.VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode
   		and e.IncldLiabDist = 'Y' -- only include factors with earnings flagged for liab distribution 
        order by e.Factor
   
        -- open Factor cursor
        open bcFactor
        select @openFactor = 1
   
        next_Factor:  -- loop through each Factor
            fetch next from bcFactor into @factor
            if @@fetch_status = -1 goto end_LiabDist
            if @@fetch_status <> 0 goto next_Factor
   
            -- get old and new rates - check for overrides
            select @oldrate = 0.00, @newrate = 0.00
            select @oldrate = OldRate, @newrate = NewRate
            from dbo.bPRCI with (nolock)      -- Craft Items
            where PRCo = @prco and Craft = @craft and EDLType = 'L' and EDLCode = @dlcode and Factor = @factor
            select @oldrate = OldRate, @newrate = NewRate
            from dbo.bPRCD with (nolock)      -- Class Dedns/Liabs
            where PRCo = @prco and Craft = @craft and Class = @class and DLCode = @dlcode and Factor = @factor
            select @oldrate = OldRate, @newrate = NewRate
            from dbo.bPRTI with (nolock)      -- Template Items
            where PRCo = @prco and Craft = @craft and Template = @template and EDLType = 'L' and EDLCode = @dlcode and Factor = @factor
            select @oldrate = OldRate, @newrate = NewRate
            from dbo.bPRTD with (nolock)      -- Template Dedns/Liabs
            where PRCo = @prco and Craft = @craft and Class = @class and Template = @template and DLCode = @dlcode and Factor = @factor
   
            -- create cursor to process earnings subject to the liability
            declare bcLiabDist2 cursor for
            select e.PostSeq, e.PostDate, e.Hours, e.Amt 
            from dbo.bPRPE e with (nolock)
            join dbo.bPRDB b with (nolock) on b.EDLCode = e.EarnCode
            where e.VPUserName = SUSER_SNAME() and e.Factor = @factor and b.PRCo = @prco and b.DLCode = @dlcode
   				and e.IncldLiabDist = 'Y' -- must be included in liab distribution
            order by e.PostSeq, e.EarnCode
   
            -- open distribution cursor
            open bcLiabDist2
            select @openLiabDist2 = 1
   
            next_LiabDist2:  -- loop through Liability Distribution cursor
               fetch next from bcLiabDist2 into @postseq, @postdate, @hrs, @amt --issue 20562
               if @@fetch_status = -1 goto end_LiabDist2
               if @@fetch_status <> 0 goto next_LiabDist2
   
               -- rate based on posted date
               select @rate = @oldrate
               if @postdate >= @effectdate select @rate = @newrate
               -- if Employee override rate exists, use it
               if @overrate is not null select @rate = @overrate
   
               select @distamt = 0.00
   			if @liabdistbasis = 0.00 select @distamt = @hrs * @rate		-- #24696 dist liab when basis = 0.00
               if @liabdistbasis <> 0.00 select @distamt = ((@hrs * @rate) / @liabdistbasis) * @amt2dist
   
    	    	if @lastpostseq = 0 select @lastpostseq = @postseq	-- save the first posting seq#
   
               if @distamt = 0.00 goto next_LiabDist2
   
    			update dbo.bPRTL
    			set Amt = Amt + @distamt
    			where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
    				and PaySeq = @payseq and PostSeq = @postseq and LiabCode = @dlcode
    			if @@rowcount = 0
    				begin
               	insert dbo.bPRTL (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, LiabCode, Rate, Amt)
               	values (@prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @dlcode, @rate, @distamt)
    				end
   
           	-- accumulate amount distributed and save last posting seq#
               select @amtdist = @amtdist + @distamt, @lastpostseq = @postseq
               goto next_LiabDist2
   
        end_LiabDist2:
            close bcLiabDist2
            deallocate bcLiabDist2
            select @openLiabDist2 = 0
            goto next_Factor
        end
   
    end_LiabDist:
        if @amt2dist = @amtdist goto bspexit
        if @lastpostseq = 0
            begin
            select @errmsg = 'Unable to fully distribute liability ' + convert(varchar(6),@dlcode) + ' for Employee#' + convert(varchar(6),@employee) + ' in bspPRProcessCraftListDist.', @rcode = 1
            goto bspexit
            end
        -- update difference to last entry
        update dbo.bPRTL
        set Amt = Amt + @amt2dist - @amtdist
    	where  PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
            and Employee = @employee and PaySeq = @payseq and PostSeq = @lastpostseq
            and LiabCode = @dlcode
        if @@rowcount = 0
     		begin
           insert dbo.bPRTL (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, LiabCode, Rate, Amt)
            values (@prco, @prgroup, @prenddate, @employee, @payseq, @lastpostseq, @dlcode, @rate, (@amt2dist - @amtdist))
     		end
   
    bspexit:
        if @openLiabDist = 1
            begin
            close bcLiabDist
    	deallocate bcLiabDist
    	end
        if @openDay = 1
            begin
            close bcDay
            deallocate bcDay
            end
         if @openLiabDist1 = 1
            begin
            close bcLiabDist1
    	deallocate bcLiabDist1
    	end
         if @openFactor = 1
            begin
            close bcFactor
            deallocate bcFactor
            end
         if @openLiabDist2 = 1
            begin
            close bcLiabDist2
    	deallocate bcLiabDist2
    	end
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRProcessCraftLiabDist] TO [public]
GO
