SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRUpdateValEMCost    Script Date: 8/28/99 9:36:35 AM ******/
     CREATE        procedure [dbo].[bspPRUpdateValEMCost]
     /***********************************************************
      * Created: GG 06/19/98
      * Last Modified: GG 08/12/99
      *                GG 09/23/99  Fixed error message update to PRUR
      *                GG 10/11/99 Fixed EM burden calculations
      *                GG 06/11/01 validate Work Order #13552
      *				GG 02/18/02 #11997 - EM burden by Liability Type
      *				EN 10/9/02 - issue 18877 change double quotes to single
      *                TV 12/2/03 22593-commented out code in case Component was transfered before PR posting   
      *				EN 2/6/04 - issue 22936  check for existence of fiscal year in GL
	  *				EN 9/18/08 - #124353  add 1 to length of WO Item in PREM_EMFields
      *
      * Called from main bspPRUpdateVal procedure to validate and load
      * equipment cost distributions into bPREM prior to a Pay Period update.
      *
      * Errors are written to bPRUR unless fatal.
      *
      * Inputs:
      *   @prco   		PR Company
      *   @prgroup  		PR Group to validate
      *   @prenddate		Pay Period Ending Date
      *   @beginmth		Pay Period Beginning Month
      *   @endmth		Pay Period Ending Month
      *   @cutoffdate	Pay Period Cutoff Date
      *
      * Output:
      *   @errmsg      error message if error occurs
      *
      * Return Value:
      *   0         success
      *   1         failure
      *****************************************************/
     	(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @beginmth bMonth = null,
          @endmth bMonth = null, @cutoffdate bDate = null, @errmsg varchar(255) = null output)
     as
   
     set nocount on
   
     declare @rcode int, @errortext varchar(255), @openEmplSeq tinyint, @openEMTime tinyint,
     @emiemployee bYN, @employee bEmployee, @payseq tinyint, @emrate bUnitCost, @postseq smallint,
     @postdate bDate, @emco bCompany, @equip bEquip, @emgroup bGroup, @emctype bEMCType,
     @hours bHrs, @amt bDollar, @mth bMonth, @msg varchar(30), @emamt bDollar, @emfields varchar(39),
     @glco bCompany, @burdenrate bRate, @type char(1), @status char(1), @component bEquip,
     @compofequip bEquip, @wo bWO, @woitem bItem, @emum bUM, @costcode bCostCode, @addonamt bDollar,
     @liabamt bDollar, @earncode bEDLCode, @addonrate bRate, @comptype varchar(10), @burdenopt char(1),
     @validcnt int, @openLiabType tinyint, @emliabamt bDollar, @liabtype bLiabilityType
   
     select @rcode = 0
   
     -- get EM Cost Interface options from the PR Company
     select @emiemployee = EMCostEmployee from bPRCO where PRCo = @prco
     if @@rowcount = 0
         begin
         select @errmsg = 'Missing PR Company!', @rcode = 1
         goto bspexit
         end
     -- remove entries from bPREM interface table where 'old' values equal 0.00
     delete bPREM
     where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
     	and OldHrs = 0 and OldAmt = 0
     -- reset 'current' values on remaining entries
     update bPREM set Hrs = 0, Amt = 0
     where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   
     /* cycle through all Employees in the Pay Period */
     -- create cursor on Employee Pay Seqs
     declare bcEmplSeq cursor for
     select Employee, PaySeq
     from bPRSQ
     where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   
     open bcEmplSeq
     select @openEmplSeq = 1
   
     -- loop through all Employee Sequences - even unprocessed ones
     next_EmplSeq:
     	fetch next from bcEmplSeq into @employee, @payseq
   
         if @@fetch_status = -1 goto bspexit
         if @@fetch_status <> 0 goto next_EmplSeq
   
         -- get Employee Header info
         select @emrate = EMFixedRate
         from bPREH
         where PRCo = @prco and Employee = @employee
         if @@rowcount = 0
         	begin
         	select @errortext = 'Missing Header record for Employee#. '
         	exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
         	if @rcode = 1 goto bspexit
         	goto next_EmplSeq	-- skip this Employee
         	end
   
     	-- create Equipment Timecard cursor
     	declare bcEMTime cursor for
     	select PostSeq, PostDate, GLCo, EMCo, WO, WOItem, Equipment, EMGroup, CostCode, CompType, Component, EarnCode,
             Hours, Amt
     	from bPRTH 	-- Timecards
     	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
     		and PaySeq = @payseq and Equipment is not null and CostCode is not null
     	order by EMCo, Equipment
     	-- open cursor
     	open bcEMTime
     	select @openEMTime = 1
   
    	-- loop through all Timecards
     	next_EMTime:
         	fetch next from bcEMTime into @postseq, @postdate, @glco, @emco, @wo, @woitem, @equip, @emgroup,
                 @costcode, @comptype, @component, @earncode, @hours, @amt
   
         	if @@fetch_status = -1 goto end_EMTime
         	if @@fetch_status <> 0 goto next_EMTime
   
             -- get EM Company info
     		select @emctype = LaborCT
     		from bEMCO where EMCo = @emco
     		if @@rowcount = 0
                 begin
     			select @errortext = 'Missing EM Company #: ' + convert(varchar(4),@emco)
     			exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
                 if @rcode = 1 goto bspexit
         		goto next_EMTime	-- skip this Time Card Header
         		end
   
             -- validate expense month based on posting date
             select @mth = @beginmth
             if @endmth is not null and @cutoffdate is not null and @postdate > @cutoffdate select @mth = @endmth
   
             -- validate 'posted to' GL Company and Month
      	    if not exists(select * from bGLCO where GLCo = @glco and @mth > LastMthSubClsd and
                 @mth <= dateadd(month, MaxOpen, LastMthSubClsd))
                 begin
     		    select @errortext = substring(convert(varchar(8),@mth,3),4,5) + 'is not an open Month in GL Co# ' + convert(varchar(4),@glco)
     		    exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
     		    if @rcode = 1 goto bspexit
                 goto next_EMTime
     		    end
   		 -- issue 22936  validate Fiscal Year 
   		 select * from dbo.bGLFY with (nolock)
   		 where GLCo = @glco and @mth >= BeginMth and @mth <= FYEMO
   		 if @@rowcount = 0
   		 	 begin
   		 	 select @errortext = 'Missing Fiscal Year for month ' + substring(convert(varchar(8),@mth,3),4,5) + ' to GL Co# ' + convert(varchar(4),@glco)
       		 exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
       		 if @rcode = 1 goto bspexit
   		 	 goto next_EMTime
   		 	 end
   
             -- validate Equipment info
     		select @type = Type, @status = Status
     		from bEMEM where EMCo = @emco and Equipment = @equip
     		if @@rowcount = 0
                 begin
     			select @errortext = 'Invalid Equipment ' + @equip
     			exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
     			if @rcode = 1 goto bspexit
                 goto next_EMTime
     			end
             if @type <> 'E'
        			begin
     			select @errortext = 'Equipment ' + @equip + ' must be type ''E''.'
     			exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
     			if @rcode = 1 goto bspexit
                 goto next_EMTime
     			end
     		if @status = 'I'
        			begin
     			select @errortext = 'Equipment ' + @equip + ' is Inactive.'
     			exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
     			if @rcode = 1 goto bspexit
                 goto next_EMTime
     			end
   
             -- validate Component
             if @component is not null
                 begin
                 select @compofequip = CompOfEquip
                 from bEMEM
                 where EMCo = @emco and Equipment = @component and Type = 'C'
                 if @@rowcount = 0
                     begin
                     select @errortext = 'Component: ' + @component + ' is invalid!'
                     exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
     			    if @rcode = 1 goto bspexit
                     goto next_EMTime
                     end
                 -- commented out code in case Component was transfered before PR posting TV 12/2/03 22593  
                 /*if (@compofequip <> @equip) or 
                     begin
                     select @errortext = @component + 'is a component of Equipment: ' + @compofequip
                     exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
     			    if @rcode = 1 goto bspexit
                     goto next_EMTime
                     end*/
                 end
             -- validate Cost Code and Cost Type - get EM unit of measure
             select @emum = UM
             from bEMCH
             where EMCo = @emco and Equipment = @equip and EMGroup = @emgroup
             and CostCode = @costcode and CostType = @emctype
             if @@rowcount = 0
                 begin
                 select @emum = UM
               from bEMCX
                 where EMGroup = @emgroup and CostCode = @costcode and CostType = @emctype
                 if @@rowcount = 0
                     begin
                     select @errortext = 'Cost code: ' + @costcode + ' and Cost Type: ' + convert(varchar(3),@emctype) +
                         ' is invalid for Equipment: ' + @equip
                     exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
     			    if @rcode = 1 goto bspexit
                     goto next_EMTime
                     end
                 end
             -- validate Work Order (added for #13552)
             if @wo is not null
                 begin
                 select @validcnt = count(*) from bEMWH where EMCo = @emco and WorkOrder = @wo
                 if @validcnt = 0
                     begin
                     select @errortext = 'Work Order:' + @wo + ' is not setup in EM Co#: ' + convert(varchar(3),@emco)
                     exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
     			      if @rcode = 1 goto bspexit
                     goto next_EMTime
                     end
                 end
   
             -- using EM fixed rate - ignore overtime and burden
             if @emrate <> 0
                 begin
                 select @emamt = @hours * @emrate
                 goto EM_fields
                 end
   
           -- get add-on earnngs earnings
           select @addonamt = isnull(sum(Amt),0)
           from bPRTA
           where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
               and PaySeq = @payseq and PostSeq = @postseq
   
   		-- create cursor to process by Liability Type - #11997
   		-- Liability Types must be setup in EM to be interfaced
     		declare bcLiabType cursor for
     		select LiabType, BurdenType, BurdenRate, AddonRate
   		from bEMPB where EMCo = @emco
   
     		open bcLiabType
     		select @openLiabType = 1, @emliabamt = 0
   
     		-- loop through all Liability Types interfacing to EM - rates applied to all earnings
     		next_LiabType:
     			fetch next from bcLiabType into @liabtype, @burdenopt, @burdenrate, @addonrate
   
         		if @@fetch_status = -1 goto end_LiabType
         		if @@fetch_status <> 0 goto next_LiabType
   
   			if @burdenopt = 'A' -- addon burden includes actual liab 
   				begin
   				select @liabamt = isnull(sum(t.Amt),0)	
   				from bPRTL t
   				join bPRDL d on d.PRCo = t.PRCo and d.DLCode = t.LiabCode
     				where t.PRCo = @prco and t.PRGroup = @prgroup and t.PREndDate = @prenddate and t.Employee = @employee
           			and t.PaySeq = @payseq and t.PostSeq = @postseq and d.LiabType = @liabtype
   				-- actual liability plus rate of earnings
   				select @emliabamt = @emliabamt + @liabamt + (@addonrate * (@amt + @addonamt))
   				end
   			if @burdenopt = 'R'	-- interface burden as rate of earnings
   				begin
   				-- rate of earnings
   				select @emliabamt = @emliabamt + (@burdenrate * (@amt + @addonamt))
   				end
   			goto next_LiabType
   
   		end_LiabType:	-- finished with Liability Types
   			close bcLiabType
   			deallocate bcLiabType
   			select @openLiabType = 0
   
   			select @emamt = @amt + @addonamt + @emliabamt
   
             EM_fields:
                 -- assign EM interface fields
                 select @emfields = convert(char(8),@postdate,112) -- 'yyyymmdd' format
                 if @wo is not null select @emfields = @emfields + convert(char(10),@wo)
                 if @wo is null select @emfields = @emfields + '          '  -- 10 spaces
                 if @woitem is not null select @emfields = @emfields + convert(char(5),@woitem) --#124353
                 if @woitem is null select @emfields = @emfields + '     '    -- 5 spaces --#124353
                 if @component is not null  select @emfields = @emfields + convert(char(10),@component)
                 if @component is null select @emfields = @emfields + '          '   -- 10 spaces
                 if @emiemployee = 'Y' select @emfields = @emfields + convert(char(6),@employee)
                 if @emiemployee = 'N' select @emfields = @emfields + '      '   -- 6 spaces
   
                 -- update PR/EM interface table with posted earnings
                 if @hours <> 0 or @emamt <> 0
                     begin
                     update bPREM set Hrs = Hrs + @hours, Amt = Amt + @emamt
                     where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Mth = @mth
                         and EMCo = @emco and Equipment = @equip and EMGroup = @emgroup and CostCode = @costcode
                         and EMCType = @emctype and EMFields = @emfields and Employee = @employee and PaySeq = @payseq
                         and PostSeq = @postseq
                     if @@rowcount = 0
                         begin
                         insert bPREM (PRCo, PRGroup, PREndDate, Mth, EMCo, Equipment, EMGroup, CostCode, EMCType,
                             EMFields, Employee, PaySeq, PostSeq, PostDate, WO, WOItem, CompType, Component, Hrs, Amt,
                             OldHrs, OldAmt)
                         values (@prco, @prgroup, @prenddate, @mth, @emco, @equip, @emgroup, @costcode, @emctype,
                             @emfields, @employee, @payseq, @postseq, @postdate, @wo, @woitem, @comptype, @component,
                             @hours, @emamt, 0, 0)
          end
                     end
   
                 goto next_EMTime
   
             end_EMTime:     -- finished with timecards for the Employee/Pay Seq
     			close bcEMTime
     		    deallocate bcEMTime
     		    select @openEMTime = 0
     		    goto next_EmplSeq
   
    bspexit:    -- clean up all cursors
         if @openEMTime = 1
             begin
             close bcEMTime
             deallocate bcEMTime
             end
         if @openEmplSeq = 1
             begin
             close bcEmplSeq
             deallocate bcEmplSeq
             end
   	if @openLiabType = 1
             begin
             close bcLiabType
             deallocate bcLiabType
             end
   
         --select @errmsg = @errmsg + char(13) + char(10) + 'bspPRUpdateValEMCost'
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUpdateValEMCost] TO [public]
GO
