SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   procedure [dbo].[bspPRTBVal]
/************************************************************
* CREATED:	kb	01/28/1998
* MODIFIED: GG	06/14/1999
*			EN	09/01/1999 <-- fixed rev code validation to check EMRR/EMRH
*			EN	09/14/1999 - validate cost code/labor cost type combo in EMCX
*			EN	10/18/1999 - if craft was selected, make sure class was entered also
*			EN	10/30/1999 - validate JC dept
*			EN	12/07/1999 - validate JC Cost Type associated with Earnings Code to Job/Phase
*			EN	07/19/2000 - validate that equipment cost type is not null
*			EN	08/03/2000 - adjust bspPRJobVal exec stmt to include one more output parameter
*			EN	11/06/2000 - issue #11281; equip cost type should only be validated for job timecards with equip posted
*			EN	02/08/2001 - issue #12131 - generate error if equip posted but jcco/job/phase not - can happen with auto earnings
*			kb	05/22/2001 - issue #13499
*			kb	05/28/2001 - issue #13502
*			EN	06/05/2001 - issue #13648 - allow equipment with status of either 'active' or 'down'
*			EN	06/19/2001 - issue #13759 - skip JCCostType validation if both hours and earnings are 0
*			GG	06/20/2001 - cleanup, include more info with error text updated to bHQBE (#12486)
*			EN	09/04/2001 - issue #13089 - add validation to check for null tax state
*			GG	12/19/2001 - #14497 - add validation to check for null unemployment state
*			EN	01/14/2002 - #15821 - only show Post Seq# in error message (@errorstart) if type<>'A' and show earnings code if job/phase/cost type validation returns error
*			EN	03/08/2002 - issue 14181  if equipphase is not null, validate and use it to validate usage cost type
*			EN	04/30/2002 - issue 15338  equipphase not getting read from bPRTB properly
*			SR	07/09/2002 - issue 17738 pass @phasegroup to bspJCVPHASE & bspJCVCOSTTYPE
*			SR	08/15/2002 - issue 18269 - validate shift
*			EN	10/04/2002 - issue 18814 - fix for blank error report problem
*			MV	01/10/2003 - 19779 - validate usage costtype with equipphase if type = 'j' or it throws an err for type 'm'
*			EN	01/14/2003 - issue 19929 changed word 'Costtype' to 'Cost Type' in 'Invalid Usage Costtype' message
*			EN	02/13/2003 - issue 19974 added two params to bspPRJobVal call
*			EN	05/30/2003 - issue 19807 fixed EM Component Type validation to include EMGroup
*			EN	12/08/2003 - issue 23061  added isnull check, with (nolock), and dbo and corrected an old syle join
*			TV	01/07/2004  26580 - Incorrect 'Rev Code Invalid' error when EM Revenue Rates by Category not setup
*			TV	11/16/2005 30371 - Invalid Revenue Code trigger error when posting equipment with attatchment
*			EN	12/04/2006 - issue 27864 changed HQBC TableName reference from 'PRTZGrid' to 'PRTB'
*			EN	03/07/2008 - #127081  in declare statements change State declarations to varchar(4)
*			EN	03/18/2008 - #127081  modify insurance state validation to take HQCO DefaultCountry into account
*			EN	08/12/2008 - #127169  include batch seq # in error messages to help locate timecards that generate an error
*			MH	01/07/2011 - #131640/142827 modifications to support SM\
*			ECV 02/22/2011 = #131640 Validate SM fields.
*			MH	03/12/2011 - #131640 Modified vspSMWorkCompletedScopeVal output param list
*			ECV 07/26/2011 - TK-07074 Changed routine to validate SM Scope.
*			CHS	08/22/2011	- D-02751 error in tax state validation.
*           ECV 08/23/2011 - Added SMCostType to WorkCompleted update.
*			GF 10/11/2011 TK-08968 added check for cancelled SM work order.
*			JG 02/09/2012 TK-12388 added SM JC Cost Type and SM Phase Group.
*			ECV 06/07/12 TK-14637 removed SMPhaseGroup. Use PhaseGroup instead.
*			ECV 07/23/12 TK-16105 Fixed validation or job phase on SM Job Work Orders.
*			TRL 07/23/12 TK-16481 Added code not validate Earn Code for SM Work Order Job postings.  
*
* USAGE:
* Validates each entry in a specified PR Timecard Batch - must be called
* prior to posting the batch.
*
* After initial Batch and PR checks, bHQBC Status set to 1 (validation in progress)
* bHQBE (Batch Errors)
*
* Creates a cursor on bPRTB to validate each entry individually
*
* Errors in batch added to bHQBE using bspHQBEInsert
*
* bHQBC Status updated to 2 if errors found, or 3 if OK to post
*
* INPUT PARAMETERS
*   @co           PR Co#
*   @mth          Batch Month
*   @batchid      Batch ID
*
* OUTPUT PARAMETERS
*   @errmsg       error message
*
* RETURN VALUE
*   0   success
*   1   fail
************************************************************/
  @co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output
    
    as
    set nocount on
    
    declare @rcode int, @errortext varchar(255), @status tinyint, @opencursorPRTB tinyint, @msg varchar(60),
        @errorstart varchar(255), @prgroup bGroup, @prenddate bDate
    
    -- PRTB variables
    declare @seq int, @batchtranstype char(1), @empl bEmployee, @payseq tinyint, @postseq smallint, @type char(1),
      	@postdate bDate, @jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @glco bCompany, @emco bCompany,
      	@wo bWO, @woitem bItem, @equip bEquip, @emgroup bGroup, @costcode bCostCode, @comptype varchar(10),
      	@component bEquip, @revcode bRevCode, @equipjcct bJCCType, @usageunits bHrs, @taxstate varchar(4),
        @local bLocalCode, @unempstate varchar(4), @insstate varchar(4), @inscode bInsCode, @prdept bDept, @crew varchar(10),
        @craft bCraft, @class bClass, @earncode bEDLCode, @hours bHrs, @rate bUnitCost, @amt bDollar,
        @oldemp bEmployee, @oldpayseq tinyint, @oldpostseq smallint, @valempl varchar(10), @retglco bCompany,
        @retemgroup bGroup, @retwocostcodechg bYN, @retemcosttype bEMCType, @retemctype bEMCType, @jcdept bDept,
        @dept bDept, @jccosttype bJCCType, @vct varchar(5), @equipphase bPhase, @usgphase bPhase, @shift tinyint,
        @smco bCompany, @smworkorder int, @smscope int, @smpaytype varchar(10), @smcosttype smallint, @smworkcompletedid bigint,
        @smjccosttype dbo.bJCCType,
        @oldtype char(1)
    
    -- PRCO variables
    declare @allownophase bYN
    
    select @rcode = 0, @opencursorPRTB = 0
    
    /* validate HQ Batch */
    exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'PR Entry', 'PRTB', @errmsg output, @status output
    if @rcode <> 0
        begin
        select @errmsg = @errmsg, @rcode = 1
        goto bspexit
        end
    if @status < 0 or @status > 3
      	begin
      	select @errmsg = 'Invalid Batch status!', @rcode = 1
      	goto bspexit
      	end
    -- get PR Group and PR End Date from Batch Control
    select @prgroup = PRGroup, @prenddate = PREndDate
    from dbo.bHQBC with (nolock)
    where Co=@co and Mth=@mth and BatchId=@batchid
    
    /* set HQ Batch status to 1 (validation in progress) */
    update dbo.bHQBC
    set Status = 1
    where Co = @co and Mth = @mth and BatchId = @batchid
    if @@rowcount = 0
      	begin
      	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
      	goto bspexit
      	end
    
    /* clear HQ Batch Errors */
    delete dbo.bHQBE where Co = @co and Mth = @mth and BatchId=@batchid
    
    -- get Phase posting option from PR Company
    select @allownophase = AllowNoPhase
    from dbo.bPRCO with (nolock) where PRCo=@co
    
    /* declare cursor on PR TimeCard Entry Batch for validation */
    declare bcPRTB cursor for
    select BatchSeq, BatchTransType, Employee, PaySeq, PostSeq, Type, PostDate, JCCo, Job,
        PhaseGroup, Phase, GLCo, EMCo, WO, WOItem, Equipment, EMGroup, CostCode, CompType, Component, RevCode,
      	EquipCType, UsageUnits, TaxState, LocalCode, UnempState, InsState, InsCode, PRDept, Crew, Craft,
      	Class, EarnCode, Hours, Rate, Amt, OldEmployee, OldPaySeq, OldPostSeq, EquipPhase, Shift,
       SMCo, SMWorkOrder, SMScope, SMPayType, SMCostType, SMJCCostType, OldType  
    from dbo.bPRTB with (nolock)
    where Co = @co and Mth = @mth and BatchId = @batchid
    
    open bcPRTB
    select @opencursorPRTB = 1
    
    PRTB_loop:
        fetch next from bcPRTB into @seq, @batchtranstype, @empl, @payseq, @postseq, @type, @postdate, @jcco, @job,
            @phasegroup, @phase, @glco, @emco, @wo, @woitem, @equip, @emgroup, @costcode, @comptype, @component,
            @revcode, @equipjcct, @usageunits, @taxstate, @local, @unempstate, @insstate, @inscode, @prdept, @crew,
            @craft, @class, @earncode, @hours, @rate, @amt, @oldemp, @oldpayseq, @oldpostseq, @equipphase, @shift,
   @smco, @smworkorder, @smscope, @smpaytype, @smcosttype, @smjccosttype, @oldtype  
			
        if @@fetch_status <> 0 goto PRTB_end
    
        -- include Employee #, Pay Seq, and Posting Seq in beginning of error text
        select @errorstart = ' Empl#:' + convert(varchar(6),@empl) + ' Pay Seq#:' + convert(varchar(3),@payseq) + ' Batch Seq#:' + convert(varchar,@seq) --#127169
    	--issue 15821 - only include Post Seq# if timecards type <> 'A' (Add)
    	if @batchtranstype<>'A'	select @errorstart = @errorstart + ' Post Seq#:' + convert(varchar(6),@postseq) + ' Batch Seq#:' + convert(varchar,@seq) --#127169
    
        -- validate transaction type
        if @batchtranstype not in ('A','C','D')
            begin
            select @errortext = @errorstart + ' -  Invalid transaction type, must be ''A'',''C'', or ''D''.'
            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
            if @rcode <> 0 goto bspexit
            goto PRTB_loop
            end
    
        -- validate 'add' timecards
        if @batchtranstype = 'A'
            begin
            -- validate Employee
            select @valempl = convert(varchar(15),@empl)
            exec @rcode = bspPREmplValwithGroup @co, @valempl, 'Y', @prgroup, @msg = @errmsg output
            if @rcode <> 0
                begin
      	        select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
      	        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      	        if @rcode <> 0 goto bspexit
                goto PRTB_loop
      	        end
      	    -- validate SM Work Completed record exists
	        IF @type = 'S'
			   BEGIN
					SELECT @smworkcompletedid=SMWorkCompletedID FROM vSMBC 
					WHERE PostingCo = @co and InUseMth = @mth and InUseBatchId = @batchid AND InUseBatchSeq = @seq
					
					IF (@smworkcompletedid IS NULL)
					BEGIN
      					select @errortext = @errorstart + ' - Link to SMWorkCompleted record missing.'
      					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      					if @rcode <> 0 goto bspexit
						goto PRTB_loop
					END
					IF NOT EXISTS(SELECT 1 FROM SMWorkCompleted WHERE SMWorkCompletedID = @smworkcompletedid)
					BEGIN
      					select @errortext = @errorstart + ' - SMWorkCompleted record missing.'
      					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      					if @rcode <> 0 goto bspexit
						goto PRTB_loop
					END
			   END
            end
    
        -- validate 'add' and 'change' timecards
        if @batchtranstype in ('A','C')
            begin
            /* validate pay sequence - must exist in PRPS */
            exec @rcode = bspPRPaySeqVal @co, @prgroup, @prenddate, @payseq, @msg = @errmsg output
            if @rcode <> 0
                begin
      	        select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
      	        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      	        if @rcode <> 0 goto bspexit
              goto PRTB_loop
      	        end
            if @type not in ('J','M','S') --Mark 142827    
        	   begin
        	   select @errortext = @errorstart + ' - Type must be either J, M or S'
      	       exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        	   if @rcode <> 0 goto bspexit
               goto PRTB_loop
        	   end
            if @jcco is null and @job is not null
                begin
     	        select @errortext = @errorstart + ' - Job Cost Company is missing.'
     	        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     	        if @rcode <> 0 goto bspexit
                goto PRTB_loop
     	        end
            if @jcco is not null
      	        begin
      	        exec @rcode = bspPRJCCompanyVal @jcco, @msg=@errmsg output
      	        if @rcode <> 0
      		        begin
      		        select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
      		        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		        if @rcode <> 0 goto bspexit
                    goto PRTB_loop
      		        end
      	        else
      		        begin
      		        if @job is not null and @phase is not null
      			       begin
      			       if @phasegroup is null
      				      begin
      				      select @errortext = @errorstart + ' - Phase group is missing'
      				      exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      				      if @rcode <> 0 goto bspexit
                          goto PRTB_loop
      				      end
      			       else
      				      begin
      				      if not exists(select * from dbo.HQGP with (nolock) where Grp=@phasegroup)
      					     begin
      					     select @errortext = @errorstart + ' - Invalid Phase Group'
      					     exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      					     if @rcode<>0 goto bspexit
                             goto PRTB_loop
      					     end
      				      end
      			       end
      		    if @job is not null
      			    begin
      			    exec @rcode = bspPRJobVal @co, @jcco, @job, null, null, null, null, null, null,
                        null, null, null, null, @msg = @errmsg output
                    if @rcode <> 0
                        begin
      				    select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
      				    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      				    if @rcode <> 0 goto bspexit
                        goto PRTB_loop
      				    end
      			    else
      				    begin
      				    if @phase is null and @allownophase = 'N' and @type IN ('J','S')
                            begin
      					    select @errortext = @errorstart + ' - Phase is missing'
      					    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      					    if @rcode <> 0 goto bspexit
                            goto PRTB_loop
      					    end
      			 	    if @phase is not null and @type IN ('J','S')
      					    begin
      					    exec @rcode = bspPRPhaseVal @co, @jcco, @job, @phasegroup, @phase, @msg=@errmsg output
      					    if @rcode <> 0
                                begin
      						    select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
      						    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      						    if @rcode <> 0 goto bspexit
                                goto PRTB_loop
      						    end
    						end
      			 	    if @equipphase is not null and @type = 'J'
      					    begin
      					    exec @rcode = bspPRPhaseVal @co, @jcco, @job, @phasegroup, @equipphase, @msg=@errmsg output
      					    if @rcode <> 0
                                begin
      						    select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
      						    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      						    if @rcode <> 0 goto bspexit
                                goto PRTB_loop
      						    end
      					    end
                        end
                    end
                end
      	    -- validate SM Work Completed record exists when it was an SM recor and it still is.
	        IF (@batchtranstype='C' AND @type = 'S' AND @oldtype='S')
			   BEGIN
					SELECT @smworkcompletedid=SMWorkCompletedID FROM SMWorkCompleted
					WHERE PRGroup = @prgroup and PREndDate = @prenddate and PREmployee = @empl AND PRPaySeq = @payseq AND PRPostSeq = @postseq AND PRPostDate=@postdate
					
					IF (@smworkcompletedid IS NULL)
					BEGIN
      					select @errortext = @errorstart + ' - SMWorkCompleted record missing.'
      					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      					if @rcode <> 0 goto bspexit
						goto PRTB_loop
					END
			   END
            end
    
        -- validate JC Department
        if @jcco is not null and @job is not null and @phase is not null
            begin
            select @jcdept = null
     	  exec @rcode = bspJCVPHASE @jcco, @job, @phase, @phasegroup,'N', @dept = @jcdept output, @msg = @errmsg output
      	    if not exists(select * from dbo.JCDM with (nolock) where JCCo = @jcco and Department = @jcdept)
      		    begin
      		    select @errortext = @errorstart + ' - JC Department (' + convert(varchar, @jcdept) + ') is invalid'
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      		    end
            end
        -- validate GL Company
        exec @rcode = bspPRGLCoVal @glco, @mth, @msg = @errmsg output
        if @rcode <> 0
            begin
            select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
      	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      	    if @rcode <> 0 goto bspexit
            goto PRTB_loop
      	    end
        -- validate EM Company
        if @emco is not null
        	begin
       	    exec @rcode = bspPREMCompanyVal @emco, @retglco output, @retemgroup output,
        		@retwocostcodechg output, @retemcosttype output, @msg = @errmsg output
        	if @rcode <> 0
      		    begin
      		    select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      		    end
            end
        -- validate EM Work Order
        if @wo is not null
            begin
      	    if not exists(select * from dbo.EMWH with (nolock) where EMCo = @emco and WorkOrder = @wo)
      		    begin
      		    select @errortext = @errorstart + ' - Work Order is invalid'
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      		    end
            if @woitem is null
      		    begin
      		    select @errortext = @errorstart + ' - Missing Work Order Item'
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      		    end
            if @woitem is not null
      		    begin
      		    if not exists(select * from dbo.EMWI with (nolock) where EMCo = @emco and WorkOrder = @wo and WOItem = @woitem)
                    begin
      			    select @errortext = @errorstart + ' - Work Order Item is invalid'
      			    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      			    if @rcode <> 0 goto bspexit
                    goto PRTB_loop
      			    end
      		    end
            end
        -- validate Equipment
        if @equip is not null
            begin
      	    if not exists(select * from dbo.EMEM with (nolock) where EMCo = @emco and Equipment = @equip and Status in ('A','D'))
      		    begin
      		    select @errortext = @errorstart + ' - Equipment is invalid'
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      		    end
            end
        if @emgroup is not null
            begin
      	    if not exists(select * from dbo.HQGP with (nolock) where Grp = @emgroup)
      		    begin
      		    select @errortext = @errorstart + ' - Equipment Group is invalid'
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      		    end
        	end
        if @costcode is not null and @type <> 'M'
        	begin
            select @errortext = @errorstart + ' - Cost Code is invalid in Job Timecards'
      	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      	    if @rcode <> 0 goto bspexit
            goto PRTB_loop
        	end
        if @costcode is not null and @type = 'M'
      	    begin
      	    if not exists(select * from dbo.EMCC with (nolock) where EMGroup = @emgroup and CostCode = @costcode)
      		    begin
      		    select @errortext = @errorstart + ' - Cost Code is invalid'
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      		    end
      	    end
        -- validate Mechanics timecard
        if @type = 'M'
            begin
            exec @rcode = bspEMCostTypeCostCodeVal @emgroup, @costcode, @retemcosttype,
        	    @retemctype output, @msg=@errmsg output
            if @rcode <> 0
                begin
      	        select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
      	        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      	        if @rcode <> 0 goto bspexit
                goto PRTB_loop
      	        end
            end
        -- validate Equipment Component
        if @comptype is not null
            begin
      	    if not exists(select * from dbo.EMTY with (nolock) where EMGroup = @emgroup and ComponentTypeCode = @comptype) --issue 19807
                begin
      		    select @errortext = @errorstart + ' - Component Type is invalid'
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      		    end
            if @component is null
      		    begin
      		    select @errortext = @errorstart + ' - Missing Component'
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      		    end
            if @component is not null
      		    begin
      		    if not exists(select * from dbo.EMEM with (nolock) where EMCo = @emco and Equipment = @component)
      			   begin
      			   select @errortext = @errorstart + ' - Component is invalid'
      			   exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      			   if @rcode <> 0 goto bspexit
                   goto PRTB_loop
      			   end
      		    end
            end
    
        if @equip is not null and @job is not null
        	begin
        	if @revcode is not null
  			begin
              -- validate EM Revenue Code
  			-- 1/07/04 TV 26580 - Incorrect 'Rev Code Invalid' error when EM Revenue Rates by Category not setup
              if not exists(select top 1 1 from dbo.bEMRC (nolock) where RevCode = @revcode)
  				begin 
  				select @errortext = @errorstart + ' - Revenue Code: ' + @revcode + ' is invalid'
      			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      			if @rcode <> 0 goto bspexit
  				goto PRTB_loop
  				end
  
  			if not exists(select top 1 1 from dbo.bEMRR r (nolock)
  							join dbo.bEMRC c (nolock) on c.EMGroup = r.EMGroup and c.RevCode = r.RevCode
  							join dbo.bEMEM e (nolock) on e.EMCo = r.EMCo and e.Category = r.Category
  							where r.EMCo = @emco and e.Equipment = @equip and r.EMGroup = @emgroup and c.RevCode = @revcode )--30371
 
 
  				begin
  	    		select @errortext = @errorstart + ' - Revenue Code: ' + @revcode + ' not set up by Category'
  	    		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  	    		if @rcode <> 0 goto bspexit
  	            goto PRTB_loop
  	    		end
  			end
            end
    
        if @type = 'J'
            begin
            if @equip is not null or (@usageunits is not null and @usageunits <> 0) or @revcode is not null
                begin
                if @emco is null -- issue #13502
                    begin
                    select @errortext = @errorstart + ' - EM Company is required when posting usage'
                    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
              		if @rcode <> 0 goto bspexit
                    goto PRTB_loop
                    end
                if @equip is null -- issue #13502
                    begin
                    select @errortext = @errorstart + ' - Equipment is required when posting usage'
                    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
              		if @rcode <> 0 goto bspexit
                    goto PRTB_loop
                    end
                if @revcode is null -- issue #13502
                    begin
                    select @errortext = @errorstart + ' - Revenue code is required when posting usage'
                    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
              		if @rcode <> 0 goto bspexit
                    goto PRTB_loop
                    end
                if @jcco is null or @job is null or (@phase is null and @equipphase is null) --issue 14181
                    begin
              		select @errortext = @errorstart + ' - Equipment posted but JC Co#, Job, and/or Phase is missing'
              		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
              		if @rcode <> 0 goto bspexit
                    goto PRTB_loop
              		end
                end
            end
    
        if @type = 'J' and @equip is not null	-- and @equipjcct is null
      		begin
   			if @equipjcct is null
   			begin
   	   		select @errortext = @errorstart + ' - Equipment Cost Type is missing'
   	   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	   		if @rcode <> 0 goto bspexit
   	          goto PRTB_loop
   	   		end
   
   	         if @equipjcct is not null -- issue #13499
   	         begin
   	 		  --issue 14181 - validate usage costtype with equipphase if one was selected
   	 		  select @usgphase = @phase
   	 		  if @equipphase is not null select @usgphase = @equipphase
   	 		
   	 		  select @phasegroup=PhaseGroup from dbo.JCJP with (nolock) where JCCo=@jcco and Job=@job and Phase=@usgphase
   	 
   	            select @vct = convert(varchar(5),@equipjcct)
   	            exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup,@usgphase, @vct, 'N', @msg = @errortext output
   	            if @rcode <> 0
   	               begin
   	               select @errortext = @errorstart + ' - Invalid Usage Cost Type: ' + isnull(@errortext,'')
   	               exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  	          if @rcode <> 0 goto bspexit
   	               goto PRTB_loop
   	               end
   	        end
    		end 
   
        -- validate Tax State
        if @taxstate is null --issue 13089
            begin
            --select @rcode = @errorstart + ' - Tax State is missing' -- D-02751 CHS - 08/22/2011
            select @errortext = @errorstart + ' - Tax State is missing'
            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    	    if @rcode <> 0 goto bspexit
            goto PRTB_loop
            end
        if @taxstate is not null
            begin
      	    if not exists(select * from dbo.PRSI with (nolock) where PRCo = @co and State = @taxstate)
                begin
      		    select @errortext = @errorstart + ' - Tax State not setup in Payroll'
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      		    end
            end
        -- validate Local code
        if @local is not null
            begin
      	    if not exists(select * from dbo.PRLI with (nolock) where PRCo=@co and LocalCode = @local)
      		    begin
      		    select @errortext = @errorstart + ' - Local Code is invalid'
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      		    end
      	    end
        -- validate Unemployment State
    	if @unempstate is null --issue #14497
            begin
            select @rcode = @errorstart + ' - Unemployment State is missing'
            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    	    if @rcode <> 0 goto bspexit
            goto PRTB_loop
            end
        if @unempstate is not null
            begin
      	    if not exists(select * from dbo.PRSI with (nolock) where PRCo = @co and State = @unempstate)
      		    begin
      		    select @errortext = @errorstart + ' - Unemployment State not setup in Payroll'
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      		    end
            end
        -- validate Insurance State
        if @insstate is not null
       	    begin
            if not exists(select * from dbo.HQST s with (nolock) 
						  join dbo.HQCO c with (nolock) on s.Country=c.DefaultCountry 
						  where c.HQCo=@co and s.State = @insstate)
      		    begin
      		    select @errortext = @errorstart + ' - Insurance State is invalid'
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      		    end
            end
        -- validate Insurance code
        if @inscode is not null
            begin
      	    if not exists(select * from dbo.PRIN with (nolock) where PRCo=@co and State = @insstate and InsCode=@inscode)
      		    begin
     		    select @errortext = @errorstart + ' - Insurance Code is invalid'
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      		    end
            end
        -- validate PR Department
        if not exists(select * from dbo.PRDP with (nolock) where PRCo=@co and PRDept=@prdept)
            begin
      	    select @errortext = @errorstart + ' - PR Department is invalid'
      	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      	    if @rcode <> 0 goto bspexit
            goto PRTB_loop
      	    end
        -- validate Crew
        if @crew is not null
            begin
      	    if not exists(select * from dbo.PRCR with (nolock) where PRCo=@co and Crew=@crew)
      		    begin
      		    select @errortext = @errorstart + ' - Crew not setup in Payroll'
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      		    end
      	    end
        -- validate Craft
        if @craft is not null
            begin
            if not exists(select * from dbo.PRCM with (nolock) where PRCo=@co and Craft=@craft)
      		    begin
      		    select @errortext = @errorstart + ' - Craft not setup in Payroll'
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      		    end
      	    if @class is not null
      		    begin
      		    if not exists(select * from dbo.PRCC with (nolock) where PRCo=@co and Craft=@craft and Class=@class)
                    begin
      			    select @errortext = @errorstart + ' - PR Craft/Class is invalid'
      			    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      			    if @rcode <> 0 goto bspexit
                    goto PRTB_loop
      			    end
      		    end
            end
        if @craft is null and @class is not null
            begin
      	    select @errortext = @errorstart + ' - PR Craft must be specified if Class is entered'
      	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      	    if @rcode <> 0 goto bspexit
            goto PRTB_loop
      	    end
        if @craft is not null and @class is null
            begin
      	    select @errortext = @errorstart + ' - PR Class is missing'
      	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      	    if @rcode <> 0 goto bspexit
            goto PRTB_loop
      	    end
        -- validate Earnings code
        if not exists(select * from dbo.PREC with (nolock) where PRCo=@co and EarnCode=@earncode)
            begin
      	    select @errortext = @errorstart + ' - Earnings code is invalid'
      	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      	    if @rcode <> 0 goto bspexit
            goto PRTB_loop
      	    end
    	/* validate shift */
     	if @shift < 1 or @shift > 255
     	begin
        select @errortext = @errorstart + ' - Shift must be a number from 1 through 255'
      	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      	if @rcode <> 0 goto bspexit
     	goto PRTB_loop
     	end
        -- validate JC Cost Type - only if hours or amount are not 0.00
        if @jcco is not null and @job is not null and @phase is not null and (@hours <> 0 or @amt <> 0) /* issue #13759*/ and @type <> 'S'
        begin
            select @jccosttype = JCCostType from dbo.bPREC with (nolock) where PRCo = @co and EarnCode = @earncode
            select @vct = convert(varchar(5),@jccosttype)
            exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup,@phase, @vct, 'N', @msg = @errortext output
            if @rcode <> 0
                begin
                select @errortext = @errorstart + ' - Earnings Code: ' + convert(varchar,@earncode) + ' ' + isnull(@errortext,'') --issue 15821 - earn code was not included in error message although text 'Earnings Code:' was
                exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     	        if @rcode <> 0 goto bspexit
                goto PRTB_loop
                end
        end

		--131640/142827 SM Changes            
        IF @type = 'S'
        BEGIN
			--Validate SMCo
			IF NOT EXISTS(SELECT 1 FROM SMCO WHERE SMCo = @smco)
			BEGIN
				SELECT @errortext = @errorstart + ' - SMCo has not been defined in SM Company'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      			IF @rcode <> 0 GOTO bspexit
      			goto PRTB_loop
			END
			
			--Validate Employee is an SM Technician.  Employee and Employee PR Group have 
			--already been validated against PREH.  Just want to make sure they are set up
			--in SM as a Technician.
			IF NOT EXISTS(SELECT 1 FROM SMTechnician WHERE SMCo = @smco and PRCo = @co and Employee = @empl)
			BEGIN
				SELECT @errortext = @errorstart + ' - Employee has not been set up as a Technician in SM Technician'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      			IF @rcode <> 0 GOTO bspexit
      			goto PRTB_loop
			END
      			
      		--Validate SM Work Order
			exec @rcode = vspSMWorkCompletedWorkOrderVal @SMCo=@smco, @WorkOrder=@smworkorder, @IsCancelledOK='N', @msg=@errmsg output
			IF NOT(@rcode=0)
			BEGIN
				SELECT @errortext = @errorstart + ' - SM Work Order ' +  convert(varchar,@smworkorder)  + ' does not validate: '+@errmsg
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      			IF @rcode <> 0 GOTO bspexit
      			goto PRTB_loop
			END	
      					 
			--Validate SM Work Scope
			exec @rcode = vspSMWorkOrderScopeVal @SMCo=@smco, @WorkOrder=@smworkorder, @Scope=@smscope, @MustExist='Y', @msg=@errmsg output
			IF NOT(@rcode=0)
			BEGIN
				SELECT @errortext = @errorstart + ' - Scope does not validate on SM Work Order ' + convert(varchar,@smworkorder) +': '+@errmsg
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      			IF @rcode <> 0 GOTO bspexit
      			goto PRTB_loop
			END
			
			--Validate Pay Type	
			IF NOT EXISTS(SELECT 1 FROM SMPayType where SMCo = @smco and PayType = @smpaytype and Active = 'Y')
			BEGIN
				SELECT @errortext = @errorstart + ' - Pay Type has not been defined or Pay Type is not active in SM Pay Type. '
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      			IF @rcode <> 0 GOTO bspexit
      			goto PRTB_loop
			END
			
			--Validate Cost Type
			IF (NOT @smcosttype IS NULL)
			BEGIN
				IF NOT EXISTS(SELECT 1 FROM SMCostType WHERE SMCo = @smco AND SMCostType=@smcosttype AND SMCostTypeCategory='L')
				BEGIN
					SELECT @errortext = @errorstart + ' - Cost Type has not been defined in SM Cost Type. '
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      				IF @rcode <> 0 GOTO bspexit
      				goto PRTB_loop
      				
      			END
      		END
      		
      		--Validate SM JC Cost Type  
			IF @job IS NOT NULL
			BEGIN
				DECLARE @smjcco dbo.bCompany, @smjob dbo.bJob, @smphase dbo.bPhase
				
				SELECT @smjcco = JCCo
					, @smjob = Job
					, @smphase = Phase
					, @phasegroup = ISNULL(@phasegroup, PhaseGroup)
				FROM dbo.SMWorkOrderScope
				WHERE SMCo = @smco
					AND WorkOrder = @smworkorder
					AND Scope = @smscope
					
				EXEC @rcode = dbo.bspJCVCOSTTYPE 
					@jcco = @smjcco, 
					@job = @smjob, 
					@PhaseGroup = @phasegroup, 
					@phase = @smphase,
					@costtype = @smjccosttype,
					@costtypeout = @smjccosttype OUTPUT,
					@msg = @errmsg OUTPUT
					
				IF NOT(@rcode=0)  
				BEGIN  
					SELECT @errortext = @errorstart + ' - SM JC Cost Type does not validate on SM Work Order ' + convert(varchar,@smworkorder) +': '+@errmsg  
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output  
					IF @rcode <> 0 GOTO bspexit  
					goto PRTB_loop  
				END  
			END
		END 
              
        end     -- finished with 'A' and 'C' entries  
      
        -- validate timecards flagged for 'change' or 'delete'
        if @batchtranstype in ('C','D')
            begin
      	    if @empl <> @oldemp
      		    begin
      	        select @errortext = @errorstart + ' - Employee cannot be changed'
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      	        end
      	    if @payseq <> @oldpayseq
      		    begin
      	        select @errortext = @errorstart + ' - Pay sequence cannot be changed'
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      	        end
            if @postseq <> @oldpostseq
      		    begin
      	        select @errortext = @errorstart + ' - Posting sequence cannot be changed'
      		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      		    if @rcode <> 0 goto bspexit
                goto PRTB_loop
      	        end
     			/* validate shift */
     			if @shift < 1 or @shift > 255
     			begin
        		select @errortext = @errorstart + ' - Shift must be a number from 1 through 255'
      			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      			if @rcode <> 0 goto bspexit
     			goto PRTB_loop
     			end
            end
    
    
    
        goto PRTB_loop
    
    PRTB_end:   -- finished validating all batch entries
        close bcPRTB
        deallocate bcPRTB
    
        select @opencursorPRTB = 0
    
        /* check HQ Batch Errors and update HQ Batch Control status */
        select @status = 3	/* valid - ok to post */
        if exists(select * from dbo.bHQBE with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
            begin
      	    select @status = 2	/* validation errors */
      	    end
        update dbo.bHQBC
      	set Status = @status
      	where Co = @co and Mth = @mth and BatchId = @batchid
        if @@rowcount <> 1
            begin
      	    select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
      	    goto bspexit
      	    end
    
    bspexit:
        if @opencursorPRTB = 1
            begin
            close bcPRTB
            deallocate bcPRTB
            end
    
        if @rcode <> 0 select @errmsg = isnull(@errmsg,'') --+ char(13) + char(10) + '[bspPRTBVal]'
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTBVal] TO [public]
GO
