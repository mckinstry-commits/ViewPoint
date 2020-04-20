SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       PROC [dbo].[bspJCIRPost]
   /****************************************************************************
   * CREATED BY: 	DANF 0
   * MODIFIED BY:	GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
   *				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-
   *			
   *
   * USAGE:
   * 	Posts JCIR batch table to JCID
   *
   * INPUT PARAMETERS:
   *
   *
   * OUTPUT PARAMETERS:
   *
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   *****************************************************************************/
(
  @co bCompany,
  @mth bMonth,
  @batchid bBatchID,
  @dateposted bDate = NULL,
  @errmsg varchar(255) OUTPUT
)
AS 
SET NOCOUNT ON
   --   #142350 removing , @uniqueattchid uniqueidentifier
	DECLARE @rcode int,
			@opencursor tinyint,
			@source bSource,
			@tablename char(20),
			@status tinyint,
			@validcnt int,
			@jctrans bTrans,
			@oldplugged bYN,
			@um bUM,
			@postedum bUM,
			@plugged bYN,
			@netchange tinyint,
			@Notes varchar(256)
   
   declare @Contract bContract, @Item bContractItem, @ActualDate bDate, 
   		@RevProjUnits bUnits, @RevProjDollars bDollar, 
   		@PrevRevProjUnits bUnits, @PrevRevProjDollars bDollar, 
   		@RevProjPlugged bYN, @UniqueAttchID uniqueidentifier,
   		@projunits bUnits, @projdollars bDollar,
   		@prevprojunits bUnits, @prevprojdollars bDollar
   
   select @rcode=0
   
   -- set open cursor flags to false
   select @opencursor = 0
   
   if @co is null
     	begin
       select @errmsg = 'Missing JC Company!', @rcode = 1
       goto bspexit
       end
   
   -- check for date posted
   if @dateposted is null
     	begin
     	select @errmsg = 'Missing posting date!', @rcode = 1
     	goto bspexit
     	end
   
   -- validate HQ Batch
   select @source = 'JC RevProj'
   exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, @source, 'JCIR', @errmsg output, @status output
   if @rcode <> 0 goto bspexit
   
   if @status <> 3 and @status <> 4	-- valid - OK to post, or posting in progress
     	begin
       select @errmsg = 'Invalid Batch status -  must be valid - OK to post or posting in progress!', @rcode = 1
     	goto bspexit
     	end
   
   -- set HQ Batch status to 4 (posting in progress)
   update dbo.bHQBC
     set Status = 4, DatePosted = @dateposted
     where Co = @co and Mth = @mth and BatchId = @batchid
     if @@rowcount = 0
     	begin
     	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
     	goto bspexit
     	end
   
   -- declare cursor on JC Projection Batch for posting
   declare bcJCIR cursor local fast_forward for
   select 	Contract, Item, ActualDate, 
   		RevProjUnits, RevProjDollars, 
   		PrevRevProjUnits, PrevRevProjDollars, 
   		RevProjPlugged, UniqueAttchID
   from bJCIR where Co=@co and Mth=@mth and BatchId=@batchid
   
   -- open cursor
   open bcJCIR
   select @opencursor = 1
   
   -- loop through all rows in this batch
   JCIR_posting_loop:
   fetch next from bcJCIR into 
   		@Contract, @Item, @ActualDate, 
   		@RevProjUnits, @RevProjDollars, 
   		@PrevRevProjUnits, @PrevRevProjDollars, 
   		@RevProjPlugged, @UniqueAttchID
   
   if (@@fetch_status <> 0) goto JCIR_posting_end
   
   begin transaction
   
   -- get UM from bJCCI
   select @um=UM, @postedum=UM, @oldplugged=ProjPlug
   from bJCCI where JCCo=@co and Contract=@Contract and Item=@Item
   
   -- delete future projections in bJCID
   delete from dbo.bJCID 
   where JCCo=@co and Contract=@Contract and Item=@Item and Mth>=@mth 
   and TransSource='JC RevProj' and JCTransType='RP'and ActualDate>=@ActualDate
   
   --ProjUnits, ProjDollars, ProjPlug, @RevProjUnits, @RevProjDollars
   -- get sum of previous projections and forecasts
   select @prevprojunits = isnull(Sum(ProjUnits),0),
          @prevprojdollars = isnull(Sum(ProjDollars),0)
   from dbo.bJCIP where JCCo=@co and Contract=@Contract and Item=@Item and Mth<=@mth
   if @@rowcount = 0
       begin
       -- no previous projections, so use final
       select 	@projunits=@RevProjUnits, 
   			@projdollars=@RevProjDollars
       end
   else
       begin
       -- calculate projections and forecasts variance
       select @projunits=@RevProjUnits-@prevprojunits,
              @projdollars=@RevProjDollars-@prevprojdollars
       end
   
   -- check if something to update
   select @netchange = 0
   if @projunits <> 0 or @projdollars <> 0 select @netchange = 1
   -- -- if abs(@forecasthours) + abs(@forecastunits) + abs(@forecastcost) <> 0 select @netchange = 1 --ignore forecast
   if @RevProjPlugged = 'Y' and @oldplugged = 'N' select @netchange = 1
   if @RevProjPlugged = 'N' and @oldplugged = 'Y' select @netchange = 1
   
   -- get next available transaction # for JCCD
   select @tablename = 'bJCID'
   exec @jctrans = bspHQTCNextTrans @tablename, @co, @mth, @errmsg output
   if @jctrans = 0 goto JCIR_posting_error
   
   if @netchange = 1
   BEGIN
       -- insert JC Detail
   
    		insert dbo.bJCID (JCCo, Mth, ItemTrans, Contract, Item, PostedDate, ActualDate, JCTransType,
    			TransSource, Description, BatchId, GLCo, GLTransAcct, GLOffsetAcct,
    			ReversalStatus, BilledUnits, BilledAmt, ARCo, ARInvoice, ARCheck, UniqueAttchID, SrcJCCo,
   			ProjUnits, ProjDollars)
   
       	values	(@co, @mth, @jctrans, @Contract, @Item, @dateposted, @ActualDate, 'RP',
       			'JC RevProj', null, @batchid, null, null, null,
    				0, 0, 0, null, null, null, @UniqueAttchID, null,
   				@projunits, @projdollars)
   
       if @@rowcount = 0 goto JCIR_posting_error
   
       -- update bJCCI LastProjPlug
       update dbo.bJCCI set ProjPlug=@RevProjPlugged
       where JCCo=@co and Contract=@Contract and Item=@Item
       if @@rowcount = 0 goto JCIR_posting_error
   
       -- update bJCIP LastProjPlug
       update dbo.bJCIP set ProjPlug=@RevProjPlugged
       where JCCo=@co and Contract=@Contract and Item=@Item and Mth = @mth 
       if @@rowcount = 0 goto JCIR_posting_error
   END
   
   
   -- delete current row from cursor
   delete from dbo.bJCIR where Co=@co and Mth=@mth and BatchId=@batchid and Contract=@Contract
   and Item=@Item
   
   commit transaction
   
   
   --Refresh indexes for this transaction if attachments exist
   if @UniqueAttchID is not null
   	begin
   	exec dbo.bspHQRefreshIndexes null, null, @UniqueAttchID, null
   	end
   
   goto JCIR_posting_loop
   
   
   
   JCIR_posting_error:	-- error occured within transaction - rollback any updates and continue
       rollback transaction
       goto JCIR_posting_loop
   
   JCIR_posting_end:    -- no more rows to process
      -- make sure batch is empty
      select @validcnt=count(*) from dbo.bJCIR
      where Co=@co and Mth=@mth and BatchId=@batchid
      if @validcnt <> 0
         begin
         select @errmsg = 'Not all JC Projection batch entries were posted - unable to close batch!', @rcode = 1
     	  goto bspexit
     	  end
   
       -- set interface levels note string
       select @Notes=Notes from dbo.bHQBC
       where Co = @co and Mth = @mth and BatchId = @batchid
       if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
       select @Notes=@Notes +
           'GL Cost Interface Level set at: ' + isnull(convert(char(1), a.GLCostLevel),'') + char(13) + char(10) +
           'GL Revenue Interface Level set at: ' + isnull(convert(char(1), a.GLRevLevel),'') + char(13) + char(10) +
           'GL Close Interface Level set at: ' + isnull(convert(char(1), a.GLCloseLevel),'') + char(13) + char(10) +
           'GL Material Interface Level set at: ' + isnull(convert(char(1), a.GLMaterialLevel),'') + char(13) + char(10)
       from dbo.bJCCO a where JCCo=@co
   
      -- delete HQ Close Control entries
      delete dbo.bHQCC where Co=@co and Mth=@mth and BatchId=@batchid
   
      -- set HQ Batch status to 5 (posted)
      update dbo.bHQBC
      set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
      where Co = @co and Mth = @mth and BatchId = @batchid
           if @@rowcount = 0
     		begin
     		select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
     		goto bspexit
     		end
   
   bspexit:
       if @opencursor = 1
     	   begin
     	   close bcJCIR
     	   deallocate bcJCIR
     	   end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCIRPost] TO [public]
GO
