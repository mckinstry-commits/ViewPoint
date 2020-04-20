SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspINPhyCntBatchInit]
   /**********************************************************************************
   * Created: GR 02/19/00
   * Modified: ae 04/28/00  clear out gl accts after each loop
   *			RM 03/30/01 Set @rcode to 0 if no error finding batchid
   *			RM  09/06/01 Wrapped Add/Delete in transaction, and put in fix for double posted batches.
   *           RM 09/07/01 Changed Batch Source to 'IN Count'
   *           RM 09/13/01 - Removed Source 'IN Count' - insert BatchType into bINAB as 'IN Count'
   *			RM 12/10/01 - Restrict batch to be by user.
   *			DANF 02/14/03 - Issue #20127: Pass restricted batch default to bspHQBCInsert
   *			RM 04/03/03 - Issue #16659: Return BatchID so that we can popup the batch process form.
   *	        DANF 12/21/04 - Issue #26577: Changed reference on DDUP
   *           TERRYL  03/04/05 - Issue #27248:  Added variable, error routine, error message to keep from creating blank batch.
   *			GG 03/23/05 - #27248 - cleanup
   *
   * This procedure executed from the IN Physical Count Worksheet to create an Adjustment batch from
   * entries in the worksheet (bINCW) that have been flagged as Ready. As an entry is added to the
   * Adjustment Batch (bINAB), it is deleted from the worksheet (bINCW). Month passed
   * in must be an open month within the subledgers on the IN GL Company.
   *
   * Inputs:
   *	@inco		current IN Company #
   *	@mth		batch month - must be open in GL
   *
   * Output:
   *	@batchid	batch id# created for the adjustments
   *	@errmsg		error message if error occurs
   *
   * Return code:
   *	0 = success, 1 = failure
   *
   ***********************************************************************************/
    	(@inco bCompany = null, @mth bMonth = null, @batchid bBatchID = null output, @errmsg varchar(100) output)
   as
   set nocount on
   
   declare @rcode int, @matlgroup bGroup, @lastmthsubclsd bMonth, @glco bCompany,
   	@opencursor int, @um bUM, @adjunits bUnits, @unitcost bUnitCost, @ecm bECM, @totalcost bDollar,
   	@glacct bGLAcct, @loc bLoc, @material bMatl, @ready bYN, @cntdate bDate, @description bDesc,  
       @batchseq int, @RestrictedBatchesDefault bYN, @inloglacct bGLAcct, @inlmglacct bGLAcct,
   	@matlcategory varchar(10)
    
   select @rcode = 0, @batchid = 0, @opencursor = 0, @batchseq = 0
   
   -- check for missing input parameters
   if @inco is null
   	begin
       select @errmsg = 'Missing IN Company', @rcode=1
       goto bspexit
       end
   if @mth is null
       begin
       select @errmsg = 'Missing Batch Month!', @rcode=1
       goto bspexit
       end
   
   --get GL Company 
   select @glco = GLCo
   from dbo.bINCO (nolock)
   where INCo = @inco
   if @@rowcount=0
   	begin
       select @errmsg = 'Not a valid IN Company!', @rcode=1
       goto bspexit
       end
    
   --check for open month
   select @lastmthsubclsd = LastMthSubClsd
   from dbo.bGLCO (nolock)
   where GLCo = @glco
   if @@rowcount=0
   	begin
       select @errmsg = 'Not a valid GL Company!', @rcode=1
       goto bspexit
       end
   if @mth <= @lastmthsubclsd
       begin
       select @errmsg = 'Month is not open in the subledgers of the IN GL Company!', @rcode=1
       goto bspexit
       end
    
   --get users restricted batch default 
   select @RestrictedBatchesDefault = isnull(RestrictedBatches,'N')
   from dbo.vDDUP with (nolock)
   where VPUserName = SUSER_SNAME()
   if @@rowcount <> 1
     	begin
    	select @errmsg = 'Invalid user: ' + SUSER_SNAME(), @rcode = 1
    	goto bspexit
    	end
   
   --#27248 - Stops blank batch from being created
   if (select count(*) from dbo.bINCW (nolock) where INCo = @inco and Ready = 'Y' and UserName = suser_sname()) = 0
      begin
      select @errmsg = 'No Material has been marked as Ready on the current Worksheet', @rcode = 1
      goto bspexit
      end
   
   --create and lock a new IN Adjustment batch
   exec @batchid = bspHQBCInsert @inco, @mth, 'IN Adj', 'INAB', @RestrictedBatchesDefault, 'N', null, null, @errmsg output
   if @batchid = 0	-- error if 0 batchid# returned
        begin
        select @rcode = 1
        goto bspexit
        end
   
   --create cursor on materials in the worksheet flagged as ready 
   declare INCW_cursor cursor LOCAL FAST_FORWARD for
   select Loc, MatlGroup, Material, UM, CntDate, AdjUnits, UnitCost, ECM, Description
   from dbo.bINCW
   where INCo = @inco and Ready = 'Y' and UserName = suser_sname()
   order by INCo, Loc, MatlGroup, Material
   
   -- open cursor 
   open INCW_cursor
   select @opencursor = 1
    
   INCW_loop:                      --loop through all the records
   	fetch next from INCW_cursor into
       	@loc, @matlgroup, @material, @um, @cntdate, @adjunits, @unitcost, @ecm, @description
   
   	if @@fetch_status <> 0 goto INCW_end
   
   	-- get material category, needed for GL Account
   	select @matlcategory = null
   	select @matlcategory = Category 
   	from dbo.bHQMT (nolock)
   	where MatlGroup = @matlgroup and Material = @material
   	
   	-- get override Adj GL Account
   	select @inloglacct = null
   	select @inloglacct = AdjGLAcct
   	from dbo.bINLO (nolock)
   	where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Category = @matlcategory
   
   	-- get default Adj GL Account
   	select @inlmglacct = null
   	select @inlmglacct = AdjGLAcct
   	from dbo.INLM (nolock)
   	where INCo = @inco and Loc = @loc
   	
   	-- assign Adj GL Account
   	select @glacct = isnull(@inloglacct, @inlmglacct)
   
   	-- calculate total cost
       select @totalcost = case @ecm when 'E' then @adjunits * @unitcost
   						when 'C' then @adjunits * @unitcost/100
                    		when 'M' then @adjunits * @unitcost/1000 end
              
    	-- increment batch sequence #
       select @batchseq = @batchseq + 1
    
   	-- start a transaction to update batch and delete worksheet entry
   	begin transaction
   
   	-- add a batch record
   	insert dbo.bINAB (Co, Mth, BatchId, BatchSeq, BatchTransType, Loc, MatlGroup, Material,
           ActDate, Description, GLCo, GLAcct, UM, Units, UnitCost, ECM, TotalCost, BatchType)
       values (@inco, @mth, @batchid, @batchseq, 'A', @loc, @matlgroup, @material,
   		@cntdate, @description, @glco, @glacct, @um, isnull(@adjunits, 0),
   		isnull(@unitcost, 0), isnull(@ecm, 'E'), isnull(@totalcost, 0),'IN Count')
   
   	if @@rowcount = 0 or @@error <> 0 goto INCW_error
   
       -- delete entry from worksheet
       delete dbo.bINCW
   	where INCo = @inco and UserName = suser_sname() and Loc = @loc and MatlGroup = @matlgroup and Material = @material
    
   	if @@rowcount = 0 or @@error <> 0 goto INCW_error
   
     	commit transaction
   	goto INCW_loop
   
   INCW_error:
    	rollback transaction
   	select @errmsg = 'Error updating IN Adjustment batch or deleting Worksheet entry.', @rcode = 1
   	goto bspexit
   
   INCW_end:
   	close INCW_cursor
       deallocate INCW_cursor
       select @opencursor = 0
   
   bspexit:
   	if @opencursor = 1
   		begin
           close INCW_cursor
           deallocate INCW_cursor
           end
   
   	if @batchid <> 0
   		begin
   		--unlock the batch
   		update dbo.bHQBC set InUseBy = null
   		where Co = @inco and Mth = @mth and BatchId = @batchid
   		end
    
      -- if @rcode <> 0 select @errmsg
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINPhyCntBatchInit] TO [public]
GO
