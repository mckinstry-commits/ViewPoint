SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPOHDInUseValidation    Script Date: 09/27/01 9:36:29 AM ******/
   CREATE   PROCEDURE [dbo].[bspPOHDInUseValidation]
     /***********************************************************
      * CREATED BY: allenn 09/27/01 - Issue 13708 
      * MODIFIED By : RT 12/04/03 - #23061, use isnulls when concatenating message strings, added with (nolock)s.
	  *					GF 7/27/2011 - TK-07144 changed to varchar(30)
	  *               
      * USAGE:
      *
      * Checks batch info in bHQBC, and transaction info in bPOIT.
      *
      * INPUT PARAMETERS
      *   @co         JCCo to pull from
      *   @mth        Month of batch
      *   @actualBatchID    Batch ID to insert transaction into
      *   @po         PO pull
      * OUTPUT PARAMETERS
      *   @postedmth  Month the Batch was posted
      *   @errmsg     Returns message with in use information
      * RETURN VALUE
      *   0   success
      *   1   fail
      *****************************************************/
   
   @co bCompany, @mth bMonth, @po VARCHAR(30), @actualBatchID bBatchID output, @postedmth bMonth output, @errmsg varchar(200) output
   
   as
   set nocount on
   declare @rcode int, @source bSource,@inusebatchid bBatchID, @inusemth bDate
   
   select @rcode = 0
   --Look in PO Header information for the InUseBatchId of the existing PO
   select @inusebatchid = InUseBatchId, @inusemth = InUseMth
   from bPOHD with (nolock)
   where POCo = @co and PO = @po
   --Now check if the PO is in use by another batch and get info about which program is using it
   if @@rowcount<>0 and (@inusebatchid is not null)
       begin
           select @inusebatchid = BatchId,@source = Source
           from bHQBC with (nolock)
           where Co = @co and  Mth = @inusemth and BatchId = @inusebatchid
           if @@rowcount<>0
               begin
   			select @actualBatchID = @inusebatchid, @postedmth = @inusemth
                   select @errmsg = 'Purchase Order already in use by Mth: ' +
                   convert(varchar(2),datepart(month, @inusemth)) + '/' +
                   substring(convert(varchar(4),datepart(year, @inusemth)),3,4) +
                   ' Batch: ' + convert(varchar(6),@inusebatchid) + ' - ' + ' Source: ' + @source, @rcode = 1
   				
   				select @errmsg = isnull(@errmsg, 'PO transaction already in use by another batch!')
                   goto bspexit
               end
           else
             	begin
                   select @errmsg='PO transaction already in use by another batch!', @rcode=1
                   goto bspexit
   		end
   
       end
          
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOHDInUseValidation] TO [public]
GO
