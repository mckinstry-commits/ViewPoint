SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPORHPost    Script Date: 8/28/99 9:36:29 AM ******/
     CREATE              procedure [dbo].[bspPORHPost]
     /************************************************************************
      * Created: DanF 07/22/02 
      * Modified by:	Danf 06/06/03 - 21376 Corrected EM interface level update.
	  *					GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
      *
      * Posts a validated batch of PO Receipt entries.  Updates
      * PO Company and Batch File.
      *
      * Inputs:
      *   @co             PO Company
      *   @mth            Batch month
      *   @batchid        Batch ID
      *   @source         Source - 'PO RecInit'
      *
      * returns 1 and message if error
      ************************************************************************/
     	(@co bCompany, @mth bMonth, @batchid bBatchID,
         @source bSource, @errmsg varchar(255) output)
   
     as
     set nocount on
   
     Declare @rcode int, @rows int,@Notes varchar(256)
   
     select @rcode = 0
   
     if @source <> 'PO InitRec' 
   	begin 
   		select @rcode = 1, @errmsg = ' Invalid source. ' 
          	goto bspexit
   	end
   
   
   
     -- Only run this bsp if no detail exist in PORS
     select @rows = isnull(count(*),0) from bPORS with (nolock) where Co= @co and Mth = @mth and BatchId=@batchid
     if @rows >0 
   	begin
   		select @errmsg = 'Detail exist ', @rcode =1 
   		goto bspexit
   	end
     
   --  Update POCo with New Receipt Update Levels.
   
	Update bPOCO
	Set ReceiptUpdate = h.ReceiptUpdate,
		GLAccrualAcct = h.GLAccrualAcct,
		GLRecExpInterfacelvl = h.GLRecExpInterfacelvl,
		GLRecExpSummaryDesc = h.GLRecExpSummaryDesc, 
		GLRecExpDetailDesc = h.GLRecExpDetailDesc,
		RecJCInterfacelvl = h.RecJCInterfacelvl,
		RecEMInterfacelvl = h.RecEMInterfacelvl,
		RecINInterfacelvl = h.RecINInterfacelvl
	from bPOCO 
	join bPORH h on POCo = h.Co
	where h.Co = @co and h.Mth = @mth and h.BatchId = @batchid
	if @@rowcount <> 1
		begin
		select @errmsg = ' Unable to update PO Company Interface levels!', @rcode = 1
		goto bspexit
		end
   
   -- set interface levels note string
       select @Notes=Notes from bHQBC
       where Co = @co and Mth = @mth and BatchId = @batchid
       if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
       select @Notes=@Notes +
           'EM Interface Level set at: ' + convert(char(1), a.RecEMInterfacelvl) + char(13) + char(10) +
           'GL Exp Interface Level set at: ' + convert(char(1), a.GLRecExpInterfacelvl) + char(13) + char(10) +
           'IN Interface Level set at: ' + convert(char(1), a.RecINInterfacelvl) + char(13) + char(10) +
           'JC Interface Level set at: ' + convert(char(1), a.RecJCInterfacelvl) + char(13) + char(10)
       from bPOCO a where POCo=@co
   
     -- delete PO Record Header entry
     delete bPORH where Co = @co and Mth = @mth and BatchId = @batchid
   
     -- delete HQ Close Control entries
     delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
     -- update HQ Batch status to 5 (posted)
     update bHQBC
     set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
     where Co = @co and Mth = @mth and BatchId = @batchid
     if @@rowcount = 0
     	begin
     	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
     	goto bspexit
     	end
   
     bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPORHPost] TO [public]
GO
