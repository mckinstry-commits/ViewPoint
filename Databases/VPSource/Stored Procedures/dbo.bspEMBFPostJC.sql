SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE             procedure [dbo].[bspEMBFPostJC]
    /***********************************************************
     * CREATED BY  : bc 03/19/99
     * MODIFIED By : rh 05/04/99 - added update of EMTrans to JCCD
     *				 TV 02/11/04 - 23061 added isnulls
     *				 TV 05/25/04 24667 need to change this to insert JCCH.UM Everytime
     *				 TV 06/11/04 24370 - if Work unit = 0 use JCCH UM and PerECM = 'E'
     *				 TV 11/16/04 24034  - Insert PRCrew into JC
     *				 DANF 08/31/05 29455 - Missing Actual Units and Actual Unit of measure in updating JCCD.
     * USAGE:
     * Posts a validated batch of bEMJC JC Amounts
     * and deletes successfully posted bEMJC rows
     *
     * INPUT PEMAMETERS
     *   EMCo        EM Co
     *   Month       Month of batch
     *   BatchId     Batch ID to validate
    
     *
     * OUTPUT PEMAMETERS
     *   @errmsg     if something went wrong
     * RETURN VALUE
     *   0   success
     *   1   fail
     *****************************************************/
    
    (@EMCo bCompany, @Mth bMonth, @BatchId bBatchID, @DatePosted bDate = null,@Source bSource,
      @errmsg varchar(60) output)
    as
    
    set nocount on
    declare @rcode int, @openEMJCcursor tinyint, @JCTrans bTrans
    
    declare @jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @jcct bJCCType, @seq int,
    	@oldnew tinyint, @emtrans bTrans, @equip bEquip, @transdesc varchar(60), @actualdate bDate,
    	@emgroup bGroup, @revcode bRevCode, @glco bCompany, @glacct bGLAcct, @prco bCompany,
    	@employee bEmployee, @workum bUM, @workunits bUnits, @timeum bUM, @timeunits bUnits,
      	@totalcost bDollar, @actualworkunits bUnits, @um bUM, @prcrew varchar(10)
    
    select @rcode=0, @openEMJCcursor = 0
    
    if @Source not in ('EMRev')
    	begin
    	select @errmsg = 'Invalid Source', @rcode = 1
    	goto bspexit
    	end
    
    /* check for date posted */
    if @DatePosted is null
    	begin
    	select @errmsg = 'Missing posting date!', @rcode = 1
    	goto bspexit
    	end
    
    /* update JC using entries from bEMBJ */
    /*****  update ******/
        declare bcEMJC cursor for
        select JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, OldNew, EMTrans, Equipment, TransDesc, ActualDate, 
   	EMGroup, RevCode, GLCo, GLAcct, PRCo, PREmployee, WorkUM, WorkUnits, TimeUM, TimeUnits,TotalCost,PRCrew
        from bEMJC where EMCo = @EMCo and Mth = @Mth and BatchId = @BatchId
    
        /* open cursor */
        open bcEMJC
        select @openEMJCcursor = 1
    
        /* loop through all rows in cursor */
            JC_posting_loop:
            fetch next from bcEMJC into @jcco, @job, @phasegroup, @phase, @jcct, @seq, @oldnew, @emtrans, @equip, @transdesc, @actualdate, 
   	@emgroup, @revcode, @glco, @glacct, @prco, @employee, @workum, @workunits, @timeum, @timeunits, @totalcost, @prcrew
    
            if @@fetch_status = -1 goto JC_posting_end
            if @@fetch_status <> 0 goto JC_posting_loop
   
   
   	exec @rcode = dbo.bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase, @jcct, 'N', @um = @um output, @msg = @errmsg output
   	if @rcode <> 0
   		begin
     	        select @errmsg = 'Phase Cost Type error in posting JC distributions.',@rcode = 1
      	        goto bspexit
   		end
   
   	if @workum = @um
   		select @actualworkunits = @workunits
   	else
   		select @actualworkunits = 0
   
   
   	 /* insert JCCD record */
   	/* Issue 17262 - Correct postings to Actual and Posted columns */
   	--if @workum = (select UM from bJCCH where JCCo = @jcco and Job = @job and PhaseGroup = @phasegroup 
   	--		and Phase = @phase and CostType = @jcct)
   	--	select @actualworkunits = WorkUnits from bEMJC where EMCo = @EMCo and Mth = @Mth and BatchId = @BatchId 
   	--		and JCCo = @jcco and Job = @job and PhaseGroup = @phasegroup and Phase = @phase and JCCType = @jcct 
   	--		and BatchSeq = @seq and OldNew = @oldnew
   	--else
   	--	select @actualworkunits = 0
   
   	--TV 05/25/04 24667 need to change this to insert JCCH.UM Everytime
   	--select @um = UM from bJCCH where JCCo = @jcco and Job = @job and PhaseGroup = @phasegroup 
   	--					and Phase = @phase and CostType = @jcct
   	
   	--TV 06/11/04 24370 - if Work unit = 0 use JCCH UM
   	if (select isnull(@workunits,0)) = 0 Select @workum = @um
   
    
    /* begin transaction */
        begin transaction
    
    /* get next available transaction # for JCCD */
        exec @JCTrans = bspHQTCNextTrans 'bJCCD', @jcco, @Mth, @errmsg output
        if @JCTrans = 0 goto JC_posting_error
   
   
   	insert into bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate, JCTransType, 
   		Source, Description, BatchId, GLCo, GLTransAcct, ReversalStatus, PRCo, Employee, EMCo, EMEquip, EMRevCode, 
   		EMGroup,UM, ActualHours, ActualUnits, ActualUnitCost, ActualCost, EMTrans, PostedUM, PostedUnits, PostedUnitCost,
   		PerECM, PostedECM, Crew)
   	values (@jcco, @Mth, @JCTrans, @job, @phasegroup, @phase, @jcct, @DatePosted, @actualdate,'EM', 
   		@Source, @transdesc, @BatchId, @glco, @glacct, 0,@prco, @employee, @EMCo, @equip, @revcode, 
   		@emgroup, @um, @timeunits, @actualworkunits, 0, @totalcost, @emtrans, @workum, @workunits, 0,
   		'E', 'E', @prcrew)
   	
   	
        if @@rowcount = 0 goto JC_posting_error
    
            /* delete current row from cursor */
      	delete from bEMJC
   
            where EMCo = @EMCo and Mth = @Mth and BatchId = @BatchId and JCCo = @jcco and Job = @job
                  and PhaseGroup = @phasegroup and Phase = @phase and JCCType = @jcct and
                  BatchSeq = @seq and OldNew = @oldnew
            if @@rowcount <> 1
                begin
     	        select @errmsg = 'Unable to remove posted distributions from EMJC.', @rcode = 1
      	        goto JC_posting_error
     	        end
    
        commit transaction
    
            goto JC_posting_loop
    
        JC_posting_error:
            rollback transaction
            goto bspexit
    
        JC_posting_end:       /* finished with JC interface level 1 - Line */
            close bcEMJC
            deallocate bcEMJC
            select @openEMJCcursor = 0
    
    
    /* make sure JC Audit is empty */
    if exists(select 1 from bEMJC where EMCo = @EMCo and Mth = @Mth and BatchId = @BatchId)
    	begin
    	select @errmsg = 'Not all updates to JC were posted - unable to close batch!', @rcode = 1
    	goto bspexit
    	end
    
    bspexit:
     	if @openEMJCcursor = 1
            begin
     	close bcEMJC
     	deallocate bcEMJC
     	end
    	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMBFPostJC]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMBFPostJC] TO [public]
GO
