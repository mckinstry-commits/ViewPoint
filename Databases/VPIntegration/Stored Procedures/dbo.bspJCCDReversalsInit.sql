SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       procedure [dbo].[bspJCCDReversalsInit]
    /***********************************************************
     * CREATED BY: SE   1/16/97
     * MODIFIED By :SE 9/26/97  (made reversal amt - instead of switching glaccts
     * MODIFIED By :SE 10/10/97  (added transaction date as input parameter
     * MODIFIED By :DANF 05/18/2000 ( ADDED ADDITIONAL COULMNS)
     *             :DANF 05/23/00 Added Source
     *				GG 11/27/00 - changed datatype from bAPRef to bAPReference
     *              DANF 04/09/01 - Corrected units and hours.
     *  			DANF 02/03/03 - 20124 Added To JC Company for reversal entry.
     *              DANF 04/03/2003 - 20824 Changed to using cursor.
     *				DANF 11/03/2003 - 22765 Changed cursor to use view instead of table for query.
     *				TV - 23061 added isnulls
     *				DANF 05/01/2005 - Issue 121037 Added Allocation code to reversal initialization process.
	 *			    DANF 05/24/06 - #30710 - Correct Error when Initializing more than 256 reversals.
	 *				GF  06/25/2010  - issue #135813 - expanded SL to varchar(30)
	 *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
     *
     * USAGE:
     * This procedure is used by the JC Post Outstanding entries to initialize
     * reversal transactions from bJCCD into bJCCB for editing.
     *
     * Checks batch info in bHQBC, and transaction info in bJCCD.
     * Adds entry to next available Seq# in bJCCB
     *
     * Pulls transaction in the OrigMth that are marked 1(reversal), and aren't
     * already in a batch.
     *
     * JCCB insert trigger will update InUseBatchId in bJCCD
     *
     * INPUT PARAMETERS
     *   Co         JC Co to pull from
     *   Mth        Month of batch
     *   BatchId    Batch ID to insert transaction into
     *   OrigMth    Original month to pull reversal transactions from.
     *   TransDate  Transaction date to add new entries with
     * OUTPUT PARAMETERS
     *
     * RETURN VALUE
     *   0   success
     *   1   fail
     *****************************************************/
    
    	@co bCompany, @mth bMonth, @batchid bBatchID,
    	@origmth bMonth, @transdate bDate, @errmsg varchar(200) output
    
    as
    set nocount on
    declare @rcode int, @inuseby bVPUserName, @status tinyint,
    	@dtsource bSource, @inusebatchid bBatchID, @seq int, @errtext varchar(60),
    	@job bJob, @PhaseGroup tinyint, @phase bPhase, @costtype bJCCType, @actualdate bDate,
        @jctranstype varchar(2), @description bTransDesc, @glco bCompany, @gltransacct bGLAcct,
        @gloffsetacct bGLAcct, @reversalstatus tinyint, @um bUM, @hours bHrs, @units bUnits,
        @cost bDollar, @numrows int, @originalmth bMonth, @origcosttrans bTrans,
    	@prco bCompany,@employee bEmployee,@craft bCraft,@class bClass,@crew varchar(10),@earnfactor bRate,
    	@earntype bEarnType,@shift tinyint, @liabilitytype bLiabilityType,@vendorgroup bGroup,@vendor bVendor,
    	@apco bCompany,@aptrans bTrans,@apline smallint,@apref bAPReference,@po varchar(30),@poitem bItem,@sl VARCHAR(30),
    	@slitem bItem,@mo int,@moitem bItem,@matlgroup bGroup,@material bMatl,@inco bCompany,
    	@loc bLoc,@mstrans bTrans,@msticket varchar(30),@emco bCompany,@emequip bEquip,
    	@emrevcode bRevCode,@emgroup bGroup, @opencursor int, @alloccode tinyint
    
    select @rcode = 0, @numrows = 0
    
    /* make sure that the original month is less than the reversal month */
    if @origmth >= @mth
    	begin
    	select @errmsg = 'Original month must come before batch month!', @rcode = 1
    	goto error
    	end
    
    /* validate HQ Batch */
    exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'JC CostAdj', 'JCCB', @errtext output, @status output
    if @rcode <> 0
    	begin
        	select @errmsg = @errtext, @rcode = 1
        	goto error
       	end
    
    if @status <> 0
    	begin
    	select @errmsg = 'Invalid Batch status -  must be (open)!', @rcode = 1
    	goto error
    	end
    
    /* spin through JCCD using cursor */
   
   Declare bcJCCD cursor local fast_forward for
   select JCCo, Mth, CostTrans
   from JCCD WITH (NOLOCK) 
   where JCCo=@co  and
    	  Mth<=@origmth and
   	  InUseBatchId is null and 
   	  Source='JC CostAdj' and 
   	  ReversalStatus=1
   
   -- open cursor
   open bcJCCD
   select @opencursor = 1
   -- loop through bcJCCD cursor
   JCCD_loop:
       fetch next from bcJCCD into @co, @originalmth, @origcosttrans
       if @@fetch_status <> 0 goto JCCD_end
   
    
   	 select @dtsource=Source, @inusebatchid=InUseBatchId, @job=Job, @PhaseGroup=PhaseGroup,
   	       	@phase=Phase, @costtype=CostType, @actualdate=ActualDate, @jctranstype=JCTransType,
   	 	@description=Description, @glco=GLCo, @gltransacct=GLTransAcct,@gloffsetacct=GLOffsetAcct,
   	 	@reversalstatus=ReversalStatus, @um=UM, @hours=ActualHours, @units=ActualUnits, @cost=ActualCost,
   	 	@prco=PRCo,@employee=Employee,
   	 	@craft=Craft,@class=Class,@crew=Crew,@earnfactor=EarnFactor,@earntype=EarnType,@shift=Shift, @liabilitytype=LiabilityType,
   	 	@vendorgroup=VendorGroup,@vendor=Vendor,@apco=APCo,@aptrans=APTrans,@apline=APLine,@apref=APRef,
   	 	@po=PO,@poitem=POItem,@sl=SL,@slitem=SLItem,@mo=MO,@moitem=MOItem,@matlgroup=MatlGroup,
   	 	@material=Material,@inco=INCo,@loc=Loc,@mstrans=MSTrans,@msticket=MSTicket,@emco=EMCo,@emequip=EMEquip,
   	 	@emrevcode=EMRevCode,@emgroup=EMGroup,@alloccode=AllocCode
        from JCCD where JCCo=@co and Mth=@originalmth and CostTrans=@origcosttrans
    
   	 if @@rowcount = 0
   	 	 goto bspexit
    
   	 /* get next available sequence # for this batch */
   	 select @seq = isnull(max(BatchSeq),0)+1 from bJCCB where Co = @co and Mth = @mth and BatchId = @batchid
   	 
   	 /*
   	  * add a new JC transaction to batch with same GLAccts but negative amt and reversataus of 2(Reversing)
   	 
   	  * all old values should be set to 0 and transaction should be setup as an add
   	  */
   	 insert into bJCCB (Co, Mth, BatchId, BatchSeq, Source, TransType, CostTrans, Job, PhaseGroup, Phase,
   	 	CostType, ActualDate, JCTransType, Description, GLCo, GLTransAcct, GLOffsetAcct,
   	 	ReversalStatus, OrigMth, OrigCostTrans, UM, Hours, Units, Cost,PRCo,Employee,
   	 		Craft,Class,Crew,EarnFactor,EarnType,Shift,LiabilityType,VendorGroup,Vendor,APCo,
   	 		APTrans,APLine,APRef,PO,POItem,SL,SLItem,MO,MOItem,MatlGroup,Material,INCo,Loc,
   	 		MSTrans,MSTicket,EMCo,EMEquip,EMRevCode,EMGroup, ToJCCo, AllocCode)
   	 values (@co, @mth, @batchid, @seq, @dtsource, 'A', null, @job, @PhaseGroup, @phase, @costtype,
   	         @transdate, @jctranstype, @description, @glco, @gltransacct, @gloffsetacct, 2,
   	 	@originalmth, @origcosttrans, @um, (-1*@hours),(-1* @units), (-1*@cost),@prco, @employee, @craft, @class,
   	 	@crew,@earnfactor,@earntype,@shift,@liabilitytype,@vendorgroup,@vendor,@apco,@aptrans,@apline,
   	 	@apref,	@po,@poitem,@sl,@slitem,@mo,@moitem,@matlgroup,@material,@inco,@loc,
   	 	@mstrans,@msticket,@emco,@emequip,@emrevcode,@emgroup, @co, @alloccode)
   	 
   	 select @numrows = @numrows + @@rowcount
   
   goto JCCD_loop
   
   JCCD_end:
    
    
    bspexit:
   
        if @opencursor = 1
         begin
           close bcJCCD
           deallocate bcJCCD
           end
    
      select @rcode = 0, @errmsg = isnull(convert(varchar(10), @numrows),'') + ' entries reversed!'
      return @rcode
    
    error:
   
        if @opencursor = 1
         begin
           close bcJCCD
           deallocate bcJCCD
           end
   
      select @errmsg = isnull(@errmsg,'') + ' - reversals not initialized.'
      return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCDReversalsInit] TO [public]
GO
