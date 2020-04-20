SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMPost_Meters_Main    Script Date: 8/28/99 9:36:44 AM ******/
   CREATE    procedure [dbo].[bspEMPost_Meters_Main]
   /***********************************************************
    * CREATED BY: JM 5/23/99
    * MODIFIED By : CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
    *                TV 03/13/03 Clean up
    *				TV 02/11/04 - 23061 added isnulls
    *
    * USAGE:
    * 	Posts a validated batch of bEMBF entries to bEMMR, deletes
    *	successfully posted bEMBF rows, clears bHQCC when complete.
    *
    * INPUT PARAMETERS
    *   	EMCo        	EM Co
    *   	Month       	Month of batch
    *   	BatchId     	Batch ID to validate
    *   	PostingDate 	Posting date to write out if successful
    *
    * OUTPUT PARAMETERS
    *   	@errmsg     	If something went wrong
    *
    * RETURN VALUE
    *   	0   		Success
    *   	1   		fail
    *****************************************************/
   (@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @errmsg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @status tinyint, @Notes varchar(256)
   
   select @rcode = 0
   
   -- Check for date posted. 
   if @dateposted is null
   	begin
   	select @errmsg = 'Missing posting date!', @rcode = 1
   	goto bspexit
   	end
   
   -- Validate HQ Batch. 
   exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'EMMeter',	'EMBF', @errmsg output, @status output
   if @rcode <> 0 goto bspexit
   if @status <> 3 and @status <> 4 -- valid - OK to post, or posting in progress. 
   	begin
   	select @errmsg = 'Invalid Batch Status-must be Valid-OK to Post or Posting in Progress!', @rcode = 1
   	goto bspexit
   	end
   
   -- Set HQ Batch status to 4 (posting in progress). 
   update bHQBC
   set Status = 4, 
       DatePosted = @dateposted
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
   	goto bspexit
   	end
   
   -- Insert records in bEMMR.  
   exec @rcode = dbo.bspEMPost_Meters_EMMRInserts @co, @mth, @batchid, @dateposted, @errmsg output
   if @rcode <> 0
   	begin
      	select @errmsg = @errmsg, @rcode = 1
      	goto bspexit
      	end
   
   -- set interface levels note string
       select @Notes=Notes from bHQBC
       where Co = @co and Mth = @mth and BatchId = @batchid
       if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
       select @Notes=@Notes +
               'GL Adjustments Interface Level set at: ' + isnull(convert(char(1), a.AdjstGLLvl),'') + char(13) + char(10) +
               'GL Usage Interface Level set at: ' + isnull(convert(char(1), a.UseGLLvl),'') + char(13) + char(10) +
               'GL Parts Interface Level set at: ' + isnull(convert(char(1), a.MatlGLLvl),'') + char(13) + char(10)
       from bEMCO a where EMCo=@co
   
   -- Delete HQ Close Control entries. 
   delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
   -- Set HQ Batch status to 5 (posted). 
   update bHQBC
   set Status = 5, 
       DateClosed = getdate(), 
       Notes = convert(text,@Notes)
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMPost_Meters_Main]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMPost_Meters_Main] TO [public]
GO
