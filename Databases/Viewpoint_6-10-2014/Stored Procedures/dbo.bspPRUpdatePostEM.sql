SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspPRUpdatePostEM]
/***********************************************************
* CREATED: GG 11/04/98
* MODIFIED: GG 08/12/99
*			GG 09/23/99    Add 0.00 values for meter readings in bEMCD
*			EN 10/9/02 - issue 18877 change double quotes to single
*			GG 10/17/06 - #120831 use local fast_forward cursors
*			GG 04/18/08 - #127804 - add order by following grouping
*			EN 9/18/08 - #124353  add 1 to length of WO Item in PREM_EMFields
*
* USAGE:
* Called from bspPRUpdatePost procedure to perform EM
* cost updates.
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
   
   declare @rcode int, @eminterface bYN, @batchmth bMonth, @openEM tinyint, @emco bCompany, @equip bEquip,
   @emgroup bGroup, @costcode bCostCode, @emctype bEMCType, @emfields varchar(39), @hrs bHrs, @amt bDollar,
   @oldhrs bHrs, @oldamt bDollar, @batchid int, @wo bWO, @woitem bItem, @component bEquip, @employee bEmployee,
   @mth bMonth, @a varchar(30), @actualdate bDate, @emtrans int, @emdept bDept, @emglco bCompany, @emglacct bGLAcct,
   @comptype varchar(10)
   
   select @rcode = 0
   
   -- get PR Company info
   select @eminterface = EMInterface
   from bPRCO where PRCo = @prco
   if @@rowcount = 0
       begin
       select @errmsg = 'Invalid PR Company!', @rcode = 1
       goto bspexit
       end
   
   -- update EM cost
   if @eminterface = 'Y'
       begin
       select @batchmth = null
   
    	-- cursor on PR EM interface table - #120831 use local, fast_forward cursor
    	declare bcEM cursor local fast_forward for
       select Mth, EMCo, Equipment, EMGroup, CostCode, EMCType, EMFields, convert(numeric(10,2),sum(Hrs)),
    	convert(numeric(12,2),sum(Amt)), convert(numeric(10,2),sum(OldHrs)), convert(numeric(12,2),sum(OldAmt))
       from bPREM
       where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
       group by Mth, EMCo, Equipment, EMGroup, CostCode, EMCType, EMFields
       order by Mth, EMCo, Equipment, EMGroup, CostCode, EMCType, EMFields	-- #127804 - add order by
   
       open bcEM
       select @openEM = 1
   
       next_EM:
    		fetch next from bcEM into @mth, @emco, @equip, @emgroup, @costcode, @emctype, @emfields, @hrs,
               @amt, @oldhrs, @oldamt
   
           if @@fetch_status = -1 goto end_EM_update
           if @@fetch_status <> 0 goto next_EM
   
           if @hrs = @oldhrs and @amt = @oldamt goto next_EM     -- skip if no change
   
           if @batchmth is null or @batchmth <> @mth
               begin
               -- add a Batch for each month updated in EM - created as 'open', and 'in use'
               exec @batchid = bspHQBCInsert @prco, @mth, 'PR Update', 'bPREM', 'N', 'N', @prgroup, @prenddate, @errmsg output
               if @batchid = 0
                   begin
    				select @errmsg = 'Unable to add a Batch to update EM Costs!', @rcode = 1
    		       	goto bspexit
    	            end
               -- update batch status as 'posting in progress'
               update bHQBC set Status = 4, DatePosted = @postdate
               where Co = @prco and Mth = @mth and BatchId = @batchid
               select @batchmth = @mth
               end
   
           -- parse @emfields
           select @employee = null, @wo = null, @woitem = null, @component = null
           select @a = substring(@emfields,5,2)
           select @a = @a + '/' + substring(@emfields,7,2)
           select @a = @a + '/' + substring(@emfields,3,2)
           select @actualdate = @a
    		select @wo = substring(@emfields,9,10)
    		select @a = substring(@emfields,19,5) --#124353
    		if isnumeric(@a) = 1 select @woitem = convert(int,@a)
    		select @component = substring(@emfields,24,10) --#124353
    		select @a = substring(@emfields,34,6) --#124353
    		if isnumeric(@a) = 1 select @employee = convert(int,@a)
   
        	if @wo = '' select @wo = null
    		if @component = '' select @component = null
   
           -- get Component Type from 1st entry of current set
           select @comptype = CompType
           from bPREM
           where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
    	   		and Mth = @mth and EMCo = @emco and Equipment = @equip and EMGroup = @emgroup
    	   		and CostCode = @costcode and EMCType = @emctype and EMFields = @emfields
   
   	    -- get EM Department for Equipment
           select @emdept = null, @emglco = null, @emglacct = null
           select @emdept = Department
           from bEMEM where EMCo = @emco and Equipment = @equip
           -- get Equipment Expense GL Account
           select @emglco = GLCo, @emglacct = GLAcct
           from bEMDG
           where EMCo = @emco and Department = @emdept and EMGroup = @emgroup and CostType = @emctype
           -- check for Cost Code override
           select @emglco = GLCo, @emglacct = GLAcct
           from bEMDO
           where EMCo = @emco and Department = @emdept and EMGroup = @emgroup and CostCode = @costcode
   
           begin transaction
           -- back out 'old - previously interfaced' amounts
           if @oldhrs <> 0 or @oldamt <> 0
               begin
               -- get next available transaction # for EMCD
    	        exec @emtrans = bspHQTCNextTrans 'bEMCD', @emco, @mth, @errmsg output
    	        if @emtrans = 0
                   begin
      	            select @errmsg = 'Unable to get another transaction # for EM Cost Detail!', @rcode=1
                   goto EM_posting_error
      	            end
     	        insert bEMCD (EMCo, Mth, EMTrans, BatchId, EMGroup, Equipment, Component, ComponentTypeCode,
                   WorkOrder, WOItem, CostCode, EMCostType, PostedDate, ActualDate, Source, EMTransType,
                   GLCo, GLTransAcct, ReversalStatus, PRCo, PREmployee, UM, Units, Dollars,
                   CurrentHourMeter, CurrentTotalHourMeter, CurrentOdometer, CurrentTotalOdometer)
    	        values (@emco, @mth, @emtrans, @batchid, @emgroup, @equip, @component, @comptype,
                   @wo, @woitem, @costcode, @emctype, @postdate, @actualdate, 'PR', 'PR Entry',
                   @emglco, @emglacct, 0, @prco, @employee, 'HRS', -(@oldhrs), -(@oldamt),0,0,0,0)
    	   		if @@rowcount = 0
    	      			begin
    	       			select @errmsg = 'Unable to add EM Cost Detail entry!', @rcode = 1
    	      			goto EM_posting_error
      	      			end
    	   		end
    		-- add in 'new - current value' amounts
    		if @hrs <> 0 or @amt <> 0
               begin
               -- get next available transaction # for EMCD
    	        exec @emtrans = bspHQTCNextTrans 'bEMCD', @emco, @mth, @errmsg output
    	        if @emtrans = 0
                   begin
      	            select @errmsg = 'Unable to get another transaction # for EM Cost Detail!', @rcode = 1
                   goto EM_posting_error
      	            end
               insert bEMCD (EMCo, Mth, EMTrans, BatchId, EMGroup, Equipment, Component, ComponentTypeCode,
                   WorkOrder, WOItem, CostCode, EMCostType, PostedDate, ActualDate, Source, EMTransType,
                   GLCo, GLTransAcct, ReversalStatus, PRCo, PREmployee, UM, Units, Dollars,
                   CurrentHourMeter, CurrentTotalHourMeter, CurrentOdometer, CurrentTotalOdometer)
    	        values (@emco, @mth, @emtrans, @batchid, @emgroup, @equip, @component, @comptype,
                   @wo, @woitem, @costcode, @emctype, @postdate, @actualdate, 'PR', 'PR Entry',
                   @emglco, @emglacct, 0, @prco, @employee, 'HRS', @hrs, @amt,0,0,0,0)
    	        if @@rowcount = 0
    	      		begin
    	       		select @errmsg = 'Unable to add EM Cost Detail entry!', @rcode = 1
    	      		goto EM_posting_error
      	      		end
   		end
    		-- replace 'old' with 'current' to keep track of interfaced amounts
    		update bPREM set OldHrs = Hrs, OldAmt = Amt
    		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
    	   		and Mth = @mth and EMCo = @emco and Equipment = @equip and EMGroup = @emgroup
    	   		and CostCode = @costcode and EMCType = @emctype and EMFields = @emfields
   
           commit transaction
       	goto next_EM
   
       EM_posting_error:
          	rollback transaction
         	goto bspexit
   
    	end_EM_update:
    		close bcEM
    		deallocate bcEM
    		select @openEM = 0
   
           -- close the Batch Control entries
    update bHQBC
           set Status = 5, DateClosed = getdate()
    		where Co = @prco and  TableName = 'bPREM' and PRGroup = @prgroup and PREndDate = @prenddate
       end
   
   -- if Pay Period is closed, update Control entry
   if @status = 1
       begin
       update bPRPC set EMInterface = 'Y' 	-- final EM interface is complete
       where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
       end
   bspexit:
       if @openEM = 1
    		begin
    		close bcEM
    		deallocate bcEM
    		end
   
       --select @errmsg = @errmsg + char(13) + char(10) + '[bspPRUpdatePostEM]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUpdatePostEM] TO [public]
GO
