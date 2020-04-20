SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPRUpdatePostJC]
/***********************************************************
 * CREATED BY: GG 07/10/98
 * MODIFIED By : GG 10/14/98
 *              GG 08/17/99 - Added updates for EM
 *              GG 09/24/99 - Pull Equipment Category from EMEM
 *              GG 05/18/00 - Interface Shift to JCCD
 *              bc 08/29/00 -  update HourReading in EMRD
 *              GG 06/12/01 - update PreviousHourReading in bEMRD (#13727)
 *				EN 10/9/02 - issue 18877 change double quotes to single
 *				EN 5/8/03 - issue 20751 set EM batch DatePosted value and set Status to 'posting in progress' until done updating EM
 *				TV 03/03/04 - issue 23957 Not updating Hour meter in EMRD correctly
 *				EN 4/27/04 - issue 24389 Marking PR EM Revenue batch with source 'PR Entry' ... s/b 'PR Update'
 *				EN 6/4/04 - issue 24712  populate UM in equipment type JCCD entries using PRJC_JCUM
 *				EN 6/21/04 - issue 24795  read UM values for posting labor
 *				EN 3/23/05 - issue 17292  optionally include Factor and Shift with burden
 *				EN 8/16/05 - issue 29473  corrected length of EMGroup and start location of RevCode when parsing out jcfields string
 *				GG 10/17/06 - #120831 use local fast_forward cursors
 *				GG 10/25/07 - #125476 - update bPRJC, bPRER, and bPRRB old amts even if no change in total
 *				GG 04/18/08 - #127804 - add order by following grouping
 *				JayR 08/09/2012 TK-14356 Fix an Insert were the columns were not fully specified.
 *
 * USAGE:
 * Called from bspPRUpdatePost procedure to perform JC
 * and EM revenue updates.
 *
 * INPUT PARAMETERS
 *   @prco   		PR Company
 *   @prgroup  		PR Group to validate
 *   @prenddate		Pay Period Ending Date
 *   @postdate		Posting Date used for transaction detail
 *   @status		Pay Period status 0 = open, 1 = closed
 *
 * OUTPUT PARAMETERS
 *   @errmsg      error message if error occurs
 *
 * RETURN VALUE
 *   0         success
 *   1         failure
 *****************************************************/
	(@prco bCompany, @prgroup bGroup, @prenddate bDate, @postdate bDate,
	 @status tinyint, @errmsg varchar(255) output)
    as
    set nocount on
    
    declare @rcode int, @jcinterface bYN, @batchmth bMonth, @openJC tinyint, @jcco bCompany, @job bJob, @phasegroup bGroup,
    @phase bPhase, @jcctype bJCCType, @type char(1), @jcfields varchar(70), @jcglco bCompany, @jcglacct bGLAcct, @workum bUM,
    @workunits bUnits, @hrs bHrs, @amt bDollar, @jcum bUM, @jcunits bUnits, @oldworkunits bUnits, @oldhrs bHrs, @oldamt bDollar,
    @oldjcunits bUnits, @batchid int, @employee bEmployee, @factor bRate, @earntype bEarnType, @liabtype bLiabilityType,
    @emco bCompany, @mth bMonth, @equip bEquip, @emgroup bGroup, @revcode bRevCode, @a varchar(30), @actualdate bDate,
    @craft bCraft, @class bClass, @crew varchar(10), @jctrans int, @openEM tinyint, @emfields char(54), @emglco bCompany,
    @revglacct bGLAcct, @jcexpglacct bGLAcct, @timeum bUM, @timeunits bUnits, @rate bDollar, @revenue bDollar, @oldtimeunits bUnits,
    @oldrevenue bDollar, @emtrans bTrans, @category varchar(10), @shift tinyint, @ememhrs bHrs, @emrcflag bYN,
    @oldemmrhrs bHrs, @newemmrhrs bHrs, @emfactor bHrs, @updatehours char
    
    select @rcode = 0
    
    -- get PR Company info
    select @jcinterface = JCInterface
    from bPRCO where PRCo = @prco
    if @@rowcount = 0
        begin
        select @errmsg = 'Invalid PR Company!', @rcode = 1
        goto bspexit
        end
    
    -- update JC with Labor and Equipment Costs, EM with Usage Revenue
    if @jcinterface = 'Y'
    	begin
        select @batchmth = null
    	-- cursor on PR JC interface table - #120831 use local, fast_forward cursor
    	declare bcJC cursor local fast_forward for
        select Mth, JCCo, Job, PhaseGroup, Phase, JCCostType, Type, JCFields, WorkUM, JCUM,
            convert(numeric(12,3),sum(WorkUnits)), convert(numeric(10,2),sum(Hrs)), convert(numeric(12,2),sum(Amt)),
            convert(numeric(12,3),sum(JCUnits)), convert(numeric(12,3),sum(OldWorkUnits)),
            convert(numeric(10,2),sum(OldHrs)), convert(numeric(12,2),sum(OldAmt)), convert(numeric(12,3),sum(OldJCUnits))
        from bPRJC
        where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
        group by Mth, JCCo, Job, PhaseGroup, Phase, JCCostType, Type, JCFields, WorkUM, JCUM
        order by Mth, JCCo, Job, PhaseGroup, Phase, JCCostType, Type, JCFields, WorkUM, JCUM	-- #127804 - add order by
    
   
        open bcJC
        select @openJC = 1
    
        next_JC:
    		fetch next from bcJC into @mth, @jcco, @job, @phasegroup, @phase, @jcctype, @type, @jcfields, @workum, @jcum,
                @workunits, @hrs, @amt, @jcunits, @oldworkunits, @oldhrs, @oldamt, @oldjcunits
            if @@fetch_status <> 0 goto end_JC_update
    
            if @workunits = @oldworkunits and @hrs = @oldhrs and @amt = @oldamt and @jcunits = @oldjcunits goto JC_update_old 	-- #125476, skip JC update, but update 'old' amounts in bPRJC
    
            if @batchmth is null or @batchmth <> @mth
    
            	begin
                -- add a Batch for each month updated in JC - created as 'open', and 'in use'
                exec @batchid = bspHQBCInsert @prco, @mth, 'PR Update', 'bPRJC', 'N', 'N', @prgroup, @prenddate, @errmsg output
                if @batchid = 0
    	        	begin
    				select @errmsg = 'Unable to add a Batch to update JC!', @rcode = 1
    		       	goto bspexit
    	            end
				--- update batch status as 'posting in progress'
                update bHQBC set Status = 4, DatePosted = @postdate
                 where Co = @prco and Mth = @mth and BatchId = @batchid
    
                select @batchmth = @mth
				end
    
            -- parse @jcfields
            select @employee = null, @factor = null, @earntype = null, @shift = null, @liabtype = null
            select @emco = null, @equip = null, @emgroup = null, @revcode = null
            select @jcglco = null, @jcglacct = null --, @workum = null, @jcum = null --issue 24795 changed to read this info during fetch
    
            select @a = substring(@jcfields,5,2)
            select @a = @a + '/' + substring(@jcfields,7,2)
            select @a = @a + '/' + substring(@jcfields,3,2)
            select @actualdate = @a
    	  	select @craft = substring(@jcfields,9,10)
    	   	select @class = substring(@jcfields,19,10)
    	   	select @crew = substring(@jcfields,29,10)
    	   	select @a = substring(@jcfields,39,6)
    	   	if isnumeric(@a) = 1 select @employee = convert(int,@a)
    
        	if @type = 'L' 	-- labor
    	   		begin
    	   		select @a = substring(@jcfields,45,5)
    	   		if isnumeric(@a) = 1 select @factor = convert(numeric(8,6),@a)
    	   		select @a = substring(@jcfields,50,4)
    	   		if isnumeric(@a) = 1 select @earntype = convert(smallint,@a)
                select @a = substring(@jcfields,54,3)
                if isnumeric(@a) = 1 select @shift = convert(tinyint,@a)
    	   		end
    	   	if @type = 'B'	-- burden
    	   		begin
        		select @a = substring(@jcfields,45,4)
           		if isnumeric(@a) = 1 select @liabtype = convert(smallint,@a)
   				--#17292 optional factor and/or shift
    	   		select @a = substring(@jcfields,49,5)
    	   		if isnumeric(@a) = 1 select @factor = convert(numeric(8,6),@a)
               select @a = substring(@jcfields,54,3)
               if isnumeric(@a) = 1 select @shift = convert(tinyint,@a)
    	   		end
   
   --             -- issue 24795  get UM info for update **didn't work ... changed to read info during fetch
   --		if @type = 'L' or @type = 'B'
   --			begin
   --	             select @workum = WorkUM, @jcum = JCUM
   --	             from bPRJC
   --	             where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   --	             	and Mth = @mth and JCCo = @jcco and Job = @job and PhaseGroup = @phasegroup
   --	 	   		and Phase = @phase and JCCostType = @jcctype and Type = @type and JCFields = @jcfields
   --			end
   
        	if @type = 'E'	-- equipment usage
        		begin
    	   		select @a = substring(@jcfields,45,3)
    	   		if isnumeric(@a) = 1 select @emco = convert(tinyint,@a)
        		select @equip = substring(@jcfields,48,10)
        		select @a = substring(@jcfields,58,3) --issue 29473 changed # of chars from 2 to 3
        		if isnumeric(@a) = 1 select @emgroup = convert(tinyint,@a)
        		select @revcode = substring(@jcfields,61,10) --issue 29473 changed start location from 60 to 61
    
                -- get other Equipment related info for update
                select @jcglco = JCGLCo, @jcglacct = JCGLAcct --, @workum = WorkUM, @jcum = JCUM --issue 24795 changed to get UM info during fetch
                from bPRJC
                where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
                    and Mth = @mth and JCCo = @jcco and Job = @job and PhaseGroup = @phasegroup
    	   		    and Phase = @phase and JCCostType = @jcctype and Type = @type and JCFields = @jcfields
    
                if @equip = ''  or @revcode = '' select @workum = null      -- don't interface Work UM if not sending Equip and Rev Code
        		end
    
        	if @craft = '' select @craft = null
    	   	if @class = '' select @class = null
    	   	if @crew = '' select @crew = null
        	if @equip = '' select @equip = null
        	if @revcode = '' select @revcode = null
    
        	begin transaction
            -- back out 'old - previously interfaced' amounts
            if @oldhrs <> 0 or @oldjcunits <> 0 or @oldamt <> 0 or @oldworkunits <> 0
                begin
                -- get next available transaction # for JCCD
    	        exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @errmsg output
    	        if @jctrans = 0
                    begin
      	            select @errmsg = 'Unable to get another transaction # for JC Cost Detail!', @rcode=1
                    goto JC_posting_error
      	            end
     	        insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
                    JCTransType, Source, BatchId, GLCo, GLTransAcct, ReversalStatus, ActualHours, ActualUnits,
                    ActualCost, PostedUM, PostedUnits, PRCo, Employee, Craft, Class, Crew, EarnFactor, EarnType,
                    Shift, LiabilityType, EMCo, EMEquip, EMRevCode, EMGroup, UM)
    	        values (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @postdate, @actualdate,
    		    	'PR', 'PR Entry', @batchid, @jcglco, @jcglacct, 0, -(@oldhrs), -(@oldjcunits), -(@oldamt), @workum, -(@oldworkunits),
                    @prco, @employee, @craft, @class, @crew, @factor, @earntype, @shift, @liabtype, @emco, @equip, @revcode, @emgroup, @jcum) --issue 24712
    	   		end
    		-- add in 'new - current value' amounts
    		if @hrs <> 0 or @jcunits <> 0 or @amt <> 0 or @workunits <> 0
            	begin
                -- get next available transaction # for JCCD
    	        exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @errmsg output
				if @jctrans = 0
                    begin
      	            select @errmsg = 'Unable to get another transaction # for JC Cost Detail!', @rcode = 1
                    goto JC_posting_error
      	            end
     	        insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
                    JCTransType, Source, BatchId, GLCo, GLTransAcct, ReversalStatus, ActualHours, ActualUnits,
                    ActualCost, PostedUM, PostedUnits, PRCo, Employee, Craft, Class, Crew, EarnFactor, EarnType,
                    Shift, LiabilityType, EMCo, EMEquip, EMRevCode, EMGroup, UM)
    	        values (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @postdate, @actualdate,
    		    	'PR', 'PR Entry', @batchid, @jcglco, @jcglacct, 0, @hrs, @jcunits, @amt, @workum, @workunits,
                    @prco, @employee, @craft, @class, @crew, @factor, @earntype, @shift, @liabtype, @emco, @equip, @revcode, @emgroup, @jcum) --issue 24712
    	   		end
    
		JC_update_old:		-- replace 'old' with 'current' to keep track of interfaced amounts
    		update bPRJC set OldWorkUnits = WorkUnits, OldHrs = Hrs, OldAmt = Amt, OldJCUnits = JCUnits
    		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
    	   		and Mth = @mth and JCCo = @jcco and Job = @job and PhaseGroup = @phasegroup
    	   		and Phase = @phase and JCCostType = @jcctype and Type = @type and JCFields = @jcfields
   		
    
            if @@trancount > 0 commit transaction	-- #125476 - only commit if needed, no trans if old = current 
       		goto next_JC
    
        	JC_posting_error:
          		rollback transaction
         		goto bspexit
    
    		end_JC_update:
    			close bcJC
    			deallocate bcJC
    			select @openJC = 0
    
                -- close the Batch Control entries
                update bHQBC set Status = 5, DateClosed = getdate()
    	        where Co = @prco and  TableName = 'bPRJC' and PRGroup = @prgroup and PREndDate = @prenddate
    
    		-- EM Revenue Update
    		select @batchmth = null
         	-- cursor on PR EM Revenue interface table - #120831 use local, fast_forward cursor
            declare bcEM cursor local fast_forward for
            select Mth, EMCo, Equipment, EMGroup, RevCode, EMFields, convert(numeric(12,3),sum(TimeUnits)),
                convert(numeric(12,3),sum(WorkUnits)), convert(numeric(12,2),sum(Revenue)), convert(numeric(12,3),sum(OldTimeUnits)),
                convert(numeric(12,3),sum(OldWorkUnits)), convert(numeric(12,2),sum(OldRevenue))
            from bPRER
            where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
            group by Mth, EMCo, Equipment, EMGroup, RevCode, EMFields
            order by Mth, EMCo, Equipment, EMGroup, RevCode, EMFields	 -- #127804 - add order by
    
            open bcEM
            select @openEM = 1
    
            next_EM:
                fetch next from bcEM into @mth, @emco, @equip, @emgroup, @revcode, @emfields,
                    @timeunits, @workunits, @revenue, @oldtimeunits, @oldworkunits, @oldrevenue
    
                if @@fetch_status <> 0 goto end_EM_update
    
                if @timeunits = @oldtimeunits and @workunits = @oldworkunits and @revenue = @oldrevenue goto EM_update_old     --- #125476, skip EM update, but update 'old' amounts in bPRER
    
                if @batchmth is null or @batchmth <> @mth
                    begin
                    -- add a Batch for each month updated in EM
                    exec @batchid = bspHQBCInsert @prco, @mth, 'PR Update', 'bPRER', 'N', 'N', @prgroup, @prenddate, @errmsg output
                    if @batchid = 0
    	               begin
    		       select @errmsg = 'Unable to add a Batch to update EM Revenue!', @rcode = 1
    		       goto bspexit
    	               end
      				--- issue 20751  update batch status as 'posting in progress' and set DatePosted
                	update bHQBC set Status = 4, DatePosted = @postdate
                	where Co = @prco and Mth = @mth and BatchId = @batchid
    
                    select @batchmth = @mth
                    end
    
                -- parse @emfields
                select @jcco = null, @phasegroup = null, @jcctype = null, @employee = null
                select @a = substring(@emfields,5,2)
                select @a = @a + '/' + substring(@emfields,7,2)
                select @a = @a + '/' + substring(@emfields,3,2)
				select @actualdate = @a
				select @a = substring(@emfields,9,3)
                if isnumeric(@a) = 1 select @jcco = convert(tinyint,@a)
    	  	    select @job = substring(@emfields,12,10)
                select @a = substring(@emfields,22,3)
              if isnumeric(@a) = 1 select @phasegroup = convert(tinyint,@a)
				select @phase = substring(@emfields,25,20)
    	   	   	select @a = substring(@emfields,45,3)
    	   	    if isnumeric(@a) = 1 select @jcctype = convert(tinyint,@a)
                select @a = substring(@emfields,49,6)
    	   	    if isnumeric(@a) = 1 select @employee = convert(int,@a)
    
                if @job = '' select @job = null
                if @phase = '' select @phase = null
    
                -- get Equipment Category and current Hour Meter reading
                select @category = Category, @ememhrs = isnull(HourReading,0)
                from bEMEM where EMCo = @emco and Equipment = @equip
           
    	          -- get other Equipment related info for update
                select @emglco = EMGLCo, @revglacct = RevGLAcct, @jcglco = JCGLCo, @jcexpglacct = JCExpGLAcct,
                    @workum = WorkUM, @timeum = TimeUM, @rate = Rate
                from bPRER
                where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
                    and Mth = @mth and EMCo = @emco and Equipment = @equip and EMGroup = @emgroup
    	   		    and RevCode = @revcode and EMFields = @emfields
    
                if @phase is null select @jcexpglacct = null     -- don't reference Job Expense GL Acct unless interfacing by Phase
    	 			
    			
    			--Check to see if we are updating the Meter hours
    			--TV 03/03/04 - issue 23957 Not updating Hour meter in EMRD correctly
   			select @updatehours = UpdtHrMeter from bEMRH with (nolock)
    			where EMCo = @emco and EMGroup = @emgroup and  Equipment = @equip and RevCode = @revcode
     			if @@rowcount = 0
     				begin
     				select @updatehours = UpdtHrMeter from bEMRR with (nolock)
     				where EMCo = @emco and EMGroup = @emgroup and Category = @category and RevCode = @revcode
     				end
   
    			if @updatehours = 'Y'
    				begin 
    
    				select @emfactor = HrsPerTimeUM from bEMRC with (nolock)
     				where EMGroup = @emgroup and RevCode = @revcode
    		
    				--needs to convert the time units back to hours TV
    				select @oldemmrhrs = @ememhrs -(isnull(@emfactor,0) * @oldtimeunits),
    					   @newemmrhrs = @ememhrs + (isnull(@emfactor,0) * @timeunits)
    				end 
    			else
    				begin
    				select @oldemmrhrs = @ememhrs,
    					   @newemmrhrs = @ememhrs 
    				end 
    
            	begin transaction
                -- back out 'old - previously interfaced' amounts from EM Revenue Detail
                if @oldtimeunits <> 0 or @oldworkunits <> 0 or @oldrevenue <> 0
                    begin
                    -- get next available transaction # for bEMRD
    	            exec @emtrans = bspHQTCNextTrans 'bEMRD', @emco, @mth, @errmsg output
    	            if @emtrans = 0
                        begin
      	                select @errmsg = 'Unable to get another transaction # for EM Revenue Detail!', @rcode=1
                        goto EM_posting_error
      	                end
     	            insert bEMRD (EMCo, Mth, Trans, BatchID, EMGroup, Equipment, RevCode, Source, TransType, PostDate, ActualDate,
                        JCCo, Job, PhaseGroup, JCPhase, JCCostType, PRCo, Employee, GLCo, RevGLAcct, ExpGLCo, ExpGLAcct, Category,
                        UM, WorkUnits, TimeUM, TimeUnits, Dollars, RevRate, HourReading, PreviousHourReading)
    	            values (@emco, @mth, @emtrans, @batchid, @emgroup, @equip, @revcode, 'PR', 'J', @postdate, @actualdate,
                        @jcco, @job, @phasegroup, @phase, @jcctype, @prco, @employee, @emglco, @revglacct, @jcglco, @jcexpglacct,
                        @category, @workum, -(@oldworkunits), @timeum, -(@oldtimeunits), -(@oldrevenue), @rate, 
    					@oldemmrhrs, @ememhrs)
    
                    -- add Revenue Breakdown entries
                    insert bEMRB (EMCo, Mth, Trans, EMGroup, RevBdownCode, Equipment, RevCode, Amount)
                    select @emco, @mth, @emtrans, @emgroup, RevBdownCode, @equip, @revcode, sum(-(OldAmt))
                    from bPRRB
                    where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
                        and Mth = @mth and EMCo = @emco and Equipment = @equip and EMGroup = @emgroup
    	   		        and RevCode = @revcode and EMFields = @emfields
                    group by RevBdownCode
    
    	   		    end
    
                -- add in new units and revenue to EM Revenue Detail
                if @timeunits <> 0 or @workunits <> 0 or @revenue <> 0
                    begin
                    -- get next available transaction # for bEMRD
    	            exec @emtrans = bspHQTCNextTrans 'bEMRD', @emco, @mth, @errmsg output
                    if @emtrans = 0
                        begin
      	                select @errmsg = 'Unable to get another transaction # for EM Revenue Detail!', @rcode=1
                        goto EM_posting_error
      	                end
     	            insert bEMRD (EMCo, Mth, Trans, BatchID, EMGroup, Equipment, RevCode, Source, TransType, PostDate, ActualDate,
                        JCCo, Job, PhaseGroup, JCPhase, JCCostType, PRCo, Employee, GLCo, RevGLAcct, ExpGLCo, ExpGLAcct,
                        Category, UM, WorkUnits, TimeUM, TimeUnits, Dollars, RevRate, 
    					HourReading, PreviousHourReading)
    	            values (@emco, @mth, @emtrans, @batchid, @emgroup, @equip, @revcode, 'PR', 'J', @postdate, @actualdate,
                        @jcco, @job, @phasegroup, @phase, @jcctype, @prco, @employee, @emglco, @revglacct, @jcglco, @jcexpglacct,
                        @category, @workum, @workunits, @timeum, @timeunits, @revenue, @rate,
    					@newemmrhrs, @ememhrs)
    
   
                    -- add Revenue Breakdown entries
                    insert bEMRB (EMCo, Mth, Trans, EMGroup, RevBdownCode, Equipment, RevCode, Amount)
                    select @emco, @mth, @emtrans, @emgroup, RevBdownCode, @equip, @revcode, sum(Amt)
                    from bPRRB
                    where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
                        and Mth = @mth and EMCo = @emco and Equipment = @equip and EMGroup = @emgroup
    	   		        and RevCode = @revcode and EMFields = @emfields
                    group by RevBdownCode
                    end
    
                EM_update_old:	-- replace old values with current ones in bPRER and bRPRB
					update bPRER set OldTimeUnits = TimeUnits, OldWorkUnits = WorkUnits, OldRevenue = Revenue
    				where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
    	   			and Mth = @mth and EMCo = @emco and Equipment = @equip and EMGroup = @emgroup
    	   			and RevCode = @revcode and EMFields = @emfields
	    
					-- replace old values with current ones in bPRRB
					update bPRRB set OldAmt = Amt
					where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
    	   			and Mth = @mth and EMCo = @emco and Equipment = @equip and EMGroup = @emgroup
    	   			and RevCode = @revcode and EMFields = @emfields
    
                if @@trancount > 0 commit transaction	-- #125476 - only commit if needed, no trans if old = current 
       		    goto next_EM
    
        	    EM_posting_error:
          		    rollback transaction
         		    goto bspexit
    
                end_EM_update:
                    close bcEM
    			    deallocate bcEM
    			    select @openEM = 0
    
                    -- close the Batch Control entries
                    update bHQBC set Status = 5, DateClosed = getdate()
    	            where Co = @prco and  TableName = 'bPRER' and PRGroup = @prgroup and PREndDate = @prenddate
    
    		end
    
    -- if Pay Period is closed, update Control entry
    if @status = 1
        begin
        update bPRPC set JCInterface = 'Y' 	-- final JC interface is complete
        where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
        end
    
    bspexit:
    	if @openJC = 1
    		begin
    		close bcJC
    		deallocate bcJC
    		end
    	if @openEM = 1
    		begin
    		close bcEM
    		deallocate bcEM
    		end
    
        --select @errmsg = @errmsg + char(13) + char(10) + '[bspPRUpdatePostJC]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUpdatePostJC] TO [public]
GO
