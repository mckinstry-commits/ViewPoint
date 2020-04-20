SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspPRProcessCraftAccums]
   /***********************************************************
    * CREATED BY: 	GG  01/30/01
    * MODIFIED BY: GG 01/11/02 - #15279 update bPRCA.EligibleAmt
    *
    * USAGE:
    * Called from bspPRProcess to update Craft report tables with
    * posted and addon earnings for a specific Employee and Pay Seq.
    *
    * INPUT PARAMETERS
    *   @prco	     PR Company
    *   @prgroup	 PR Group
    *   @prenddate	 PR Ending Date
    *   @employee	 Employee
    *   @payseq	 Payment Sequence #
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
   	(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null,
        @employee bEmployee = null, @payseq tinyint = null, @errmsg varchar(255) = null output)
   as
   
   set nocount on
   
   declare @rcode int, @postseq smallint, @craft bCraft, @class bClass, @earncode bEDLCode, @hrs bHrs,
       @rate bUnitCost, @amt bDollar, @openCraftEarning tinyint, @openCraftAddon tinyint
   
   select @rcode = 0
   
   -- update Earnings to Craft Report tables
   declare bcCraftEarning cursor for
   select PostSeq, Craft, Class, EarnCode, Hours, Rate, Amt
   from bPRTH  -- Timecards
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
   	and PaySeq = @payseq and Craft is not null and Class is not null
   
   open bcCraftEarning
   select @openCraftEarning = 1
   
   -- loop through Earnings posted to a Craft and Class
   next_CraftEarning:
   	fetch next from bcCraftEarning into @postseq, @craft, @class, @earncode, @hrs, @rate, @amt
   
       if @@fetch_status = -1 goto end_CraftEarning
   	if @@fetch_status <> 0 goto next_CraftEarning
   
       if @hrs <> 0.00 or @amt <> 0.00
   		begin
   		update bPRCA -- Craft Accums
           set Basis = Basis + @hrs, Amt = Amt + @amt
   		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
               and PaySeq = @payseq and Craft = @craft and Class = @class and EDLType = 'E' and EDLCode = @earncode
   		if @@rowcount = 0
   			insert bPRCA (PRCo, PRGroup, PREndDate, Employee, PaySeq, Craft, Class, EDLType, EDLCode, Basis, Amt, EligibleAmt)
    			values (@prco, @prgroup, @prenddate, @employee, @payseq, @craft, @class, 'E', @earncode, @hrs, @amt, 0)
   		end
   
       if @rate <> 0.00 or @hrs <> 0.00 or @amt <> 0
           begin
           update bPRCX    -- Craft Rate Detail
           set Basis = Basis + @hrs, Amt = Amt + @amt
   		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
               and PaySeq = @payseq and Craft = @craft and Class = @class and EDLType = 'E' and EDLCode = @earncode
               and Rate = @rate
   		if @@rowcount = 0
   			insert bPRCX (PRCo, PRGroup, PREndDate, Employee, PaySeq, Craft, Class, EDLType, EDLCode, Rate, Basis, Amt)
    			values (@prco, @prgroup, @prenddate, @employee, @payseq, @craft, @class, 'E', @earncode, @rate, @hrs, @amt)
   		end
   
       -- update Addon Earnings to Craft Report tables
   	declare bcCraftAddon cursor for
   	select EarnCode, Rate, Amt
   	from bPRTA
   	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
           and PaySeq = @payseq and PostSeq = @postseq
   
   	open bcCraftAddon
   	select @openCraftAddon = 1
   
       -- loop through Addons for the posted sequence
   	next_CraftAddon:
   	   fetch next from bcCraftAddon into @earncode, @rate, @amt
   
           if @@fetch_status = -1 goto end_CraftAddon
   		if @@fetch_status <> 0 goto next_CraftAddon
   
   		if @rate <> 0.00 or @amt <> 0.00
   			begin
   			update bPRCA -- Craft Accums
               set Amt = Amt + @amt
   			where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
                   and PaySeq = @payseq and Craft = @craft and Class = @class and EDLType = 'E' and EDLCode = @earncode
   			if @@rowcount = 0
   				insert bPRCA (PRCo, PRGroup, PREndDate, Employee, PaySeq, Craft, Class, EDLType, EDLCode, Basis, Amt, EligibleAmt)
    				values (@prco, @prgroup, @prenddate, @employee, @payseq, @craft, @class, 'E', @earncode, 0, @amt, 0)
   			end
           if @rate <> 0.00 or @amt <> 0
               begin
               update bPRCX    -- Craft Rate Detail
               set Amt = Amt + @amt
   			where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
                   and PaySeq = @payseq and Craft = @craft and Class = @class and EDLType = 'E' and EDLCode = @earncode
                   and Rate = @rate
   			if @@rowcount = 0
   				insert bPRCX (PRCo, PRGroup, PREndDate, Employee, PaySeq, Craft, Class, EDLType, EDLCode, Rate, Basis, Amt)
    				values (@prco, @prgroup, @prenddate, @employee, @payseq, @craft, @class, 'E', @earncode, @rate, 0, @amt)
   			end
   
           goto next_CraftAddon
   
       end_CraftAddon:
           close bcCraftAddon
           deallocate bcCraftAddon
   		select @openCraftAddon = 0
           goto next_CraftEarning
   
   end_CraftEarning:
   	close bcCraftEarning
   	deallocate bcCraftEarning
   	select @openCraftEarning = 0
   
   bspexit:
   	if @openCraftAddon = 1
           begin
           close bcCraftAddon
           deallocate bcCraftAddon
   		end
       if @openCraftEarning = 1
   		begin
   		close bcCraftEarning
   		deallocate bcCraftEarning
   		end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRProcessCraftAccums] TO [public]
GO
