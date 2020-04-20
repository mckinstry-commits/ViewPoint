SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       procedure [dbo].[bspINMthRecBatchInit]
   /**********************************************************************************
   * Created By: GG 06/15/00
   * Modified  : DANF 02/14/03 - Issue #20127: Pass restricted batch default to bspHQBCInsert
   *	      DANF 12/21/04 - Issue #26577: Changed reference on DDUP
   *			GF 09/05/2010 - issue #141031 changed to use function vfDateOnly
   *
   *
   * This procedure creates a batch of adjustment entries for the difference between
   * posted and calculated ending values for all materials in stock.  Called
   * from the IN Monthly Reconciliation program after bINMA has been initialized.
   *
   * Inputs:
   *   @inco       IN Company
   *   @mth        Month used for reconciliation and batch entries
   *
   * Outputs:
   *   @batchid    Batch ID#
   *   @errmsg     Error message
   *
   * Return value:
   *   0 = success, 1 = error
   ***********************************************************************************/
   	(@inco tinyint = null, @mth smalldatetime = null, @batchid int output, @errmsg varchar(255) output)
   as
   set nocount on
   
   declare  @rcode int, @batchseq int, @glco bCompany, @lastmthsubclsd bMonth, @msg varchar(255),
   @openinma tinyint, @loc bLoc, @matlgroup bGroup, @material bMatl, @adjamt bDollar, @category varchar(10),
   @um bUM, @lmadjglacct bGLAcct, @loadjglacct bGLAcct, @glacct bGLAcct,
   @RestrictedBatchesDefault bYN
   
   select @rcode = 0, @batchseq = 0
   
   --get GL Company for this IN Company
   select @glco = GLCo from bINCO where INCo = @inco
   if @@rowcount = 0
       begin
       select @errmsg = 'Invalid IN Company!', @rcode = 1
       goto bspexit
       end
   
   --check for open month
   select @lastmthsubclsd = LastMthSubClsd
   from bGLCO where GLCo = @glco
   if @@rowcount=0
       begin
       select @errmsg = 'Invalid GL Company!', @rcode = 1
       goto bspexit
       end
   if @mth is null
       begin
       select @errmsg = 'Missing Batch Month!', @rcode = 1
       goto bspexit
       end
   if @mth <= @lastmthsubclsd
       begin
       select @errmsg = 'Not an open month within the subledgers in the IN GL Company!', @rcode = 1
       goto bspexit
       end
   
   /* Get Restricted batch default from DDUP */
   select @RestrictedBatchesDefault = isnull(RestrictedBatches,'N')
   from dbo.vDDUP with (nolock)
   where VPUserName = SUSER_SNAME() 
   if @@rowcount <> 1
    	begin
   	select @rcode = 1, @errmsg = 'Missing :' + SUSER_SNAME() + ' from vDDUP.'
   	goto bspexit
   	end
   --use bspHQBCInsert to create and lock a new batch
   exec @batchid = bspHQBCInsert @inco, @mth, 'IN Adj', 'INAB', @RestrictedBatchesDefault, 'N', null, null, @msg output
   if @batchid = 0
       begin
       select @errmsg = 'Unable to create HQ Batch Control entry!', @rcode = 1
       goto bspexit
       end
   
   -- use a cursor to process all Monthly Activity entries
   declare INMA_cursor cursor for
   select Loc, MatlGroup, Material,
       'AdjAmt' = (EndValue - (BeginValue + PurchaseCost + ProdCost + UsageCost + ARSalesCost + JCSalesCost + INSalesCost + EMSalesCost +
           TrnsfrInCost + TrnsfrOutCost + AdjCost + ExpCost))
   from bINMA
   where INCo = @inco and Mth = @mth
   
   open INMA_cursor
   select @openinma = 1
   
   INMA_loop:
       fetch next from INMA_cursor into @loc, @matlgroup, @material, @adjamt
       if @@fetch_status = -1 goto INMA_end
       if @@fetch_status <> 0 goto INMA_loop
   
       if @adjamt = 0 goto INMA_loop
   
       --get std u/m
       select @category = null, @um = null
       select @category = Category, @um = StdUM
       from bHQMT where MatlGroup = @matlgroup and Material = @material
   
       --get IN Adj GL Account from Location Master
       select @lmadjglacct
       select @lmadjglacct = AdjGLAcct
       from bINLM where INCo = @inco and Loc = @loc
       --check for IN Adj GL Account override
       select @loadjglacct = null
       select @loadjglacct = AdjGLAcct
       from bINLO
       where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Category = @category
   
       select @glacct = isnull(@loadjglacct,@lmadjglacct)  -- use Location Master Account unless overridden
   
       select @batchseq = @batchseq + 1    -- increment batch seq
   
       -- add entry to Adjustment Batch
       insert bINAB (Co, Mth, BatchId, BatchSeq, BatchTransType, Loc, MatlGroup, Material,
           ActDate, Description, GLCo, GLAcct, UM, Units, UnitCost, ECM, TotalCost)
       values (@inco, @mth, @batchid, @batchseq, 'A', @loc, @matlgroup, @material,
       ----#141031
           dbo.vfDateOnly(), 'Mthly Recon Adjustment', @glco, @glacct, @um, 0, 0, 'E', @adjamt)
   
       goto INMA_loop
   
   INMA_end:
       close INMA_cursor
       deallocate INMA_cursor
       select @openinma = 0
   
       --unlock batch
       update bHQBC set InUseBy = null
       where Co = @inco and Mth = @mth and BatchId = @batchid
       if @@rowcount = 0
           begin
    select @errmsg = 'Unable to unlock IN Adjustment Batch!', @rcode = 1
           goto bspexit
           end
   
   bspexit:
       if @openinma = 1
           begin
           close INMA_cursor
           deallocate INMA_cursor
           end
   
      -- if @rcode<>0 select @errmsg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMthRecBatchInit] TO [public]
GO
