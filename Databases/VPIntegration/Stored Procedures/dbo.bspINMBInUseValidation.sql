SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspINMOInUseValidation    Script Date: 09/27/01 9:36:29 AM ******/
    CREATE     PROCEDURE [dbo].[bspINMBInUseValidation]
      /***********************************************************
       * CREATED BY: 05/06/02 RM
       * MODIFIED By : 
       *               
       * USAGE:
       *
       * Checks batch info in bHQBC, and transaction info in bMOIT.
       *
       * INPUT PARAMETERS
       *   @co         INCo to pull from
       *   @mth        Month of batch
       *   @actualBatchID    Batch ID to insert transaction into
       *   @mo         MO pull
       * OUTPUT PARAMETERS
       *   @mostedmth  Month the Batch was mosted
       *   @errmsg     Returns message with in use information
       * RETURN VALUE
       *   0   success
       *   1   fail
       *****************************************************/
    
    @co bCompany, @mth bMonth, @mo bMO, @actualBatchID bBatchID output, @postedmth bMonth output, @errmsg varchar(200) output
    
    as
    set nocount on
    declare @rcode int, @source bSource,@inusebatchid bBatchID, @inusemth bDate
    
    select @rcode = 0
    --Look in MO Header information for the InUseBatchId of the existing MO
    select @inusebatchid = InUseBatchId, @inusemth = InUseMth
    from bINMO
    where INCo = @co and MO = @mo
    --Now check if the MO is in use by another batch and get info about which program is using it
    if @@rowcount<>0 and (@inusebatchid is not null)
        begin
            select @source = Source
            from bHQBC
            where Co = @co and  Mth = @inusemth and BatchId = @inusebatchid
            if @@rowcount<>0
                begin
    			select @actualBatchID = @inusebatchid, @postedmth = @inusemth
                                    select @errmsg = 'Material Order already in use by Mth: ' +
                                    convert(varchar(2),datepart(month, @inusemth)) + '/' +
                                    substring(convert(varchar(4),datepart(year, @inusemth)),3,4) +
                                    ' Batch: ' + convert(varchar(6),@inusebatchid) + ' - ' + ' Source: ' + @source, @rcode = 1
                                    goto bspexit
                                end
                            else
                              	begin
                                    select @errmsg='MO transaction already in use by another batch!', @rcode=1
                                    goto bspexit
    		end
    
        end
           
    bspexit:
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMBInUseValidation] TO [public]
GO
