SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************/
CREATE procedure [dbo].[bspMSTBInsertExistingTransVal]
/*************************************
* Created By:   GF 02/18/2008
* Modified By:
*
*
*
* USAGE: Validates a MSTD transaction can be added to batch or that a ticket range can be added to batch.
*
*
* INPUT PARAMETERS
*  MS Company
*  Batch Month
*  Batch ID
*  MS Transaction
*  Beginning Ticket
*  Ending Ticket
*
* OUTPUT PARAMETERS
*  @msg      validation error message
* RETURN VALUE
*   0         Success
*   1         Failure
*
**************************************/
(@msco bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
 @mstrans bTrans = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @inusebatchid bBatchID, @haultrans bTrans

select @rcode = 0

---- validate that the MSTD transaction can be added to batch
if @mstrans is not null
	begin
	select @inusebatchid=InUseBatchId, @haultrans=HaulTrans
	from MSTD with (nolock) where MSCo=@msco and Mth=@mth and MSTrans=@mstrans
	if @@rowcount = 0
		begin
		select @msg = 'Invalid MS Transaction.', @rcode = 1
		goto bspexit
		end
	if @inusebatchid is not null
		begin
		select @msg = 'MS Transaction is already in use in batch: ' + convert(varchar(8),@inusebatchid) + '.', @rcode = 1
		goto bspexit
		end
	if @haultrans is not null
		begin
		select @msg = 'MS Transaction is a haul transaction, cannot add to ticket batch.', @rcode = 1
		goto bspexit
		end
	end

---- if the beg ticket and end ticket are the same then validate can be added to batch
----if isnull(@beg_ticket,'') = '' goto bspexit
----if isnull(@end_ticket,'') = '' goto bspexit
----
----if @beg_ticket = @end_ticket
----	begin
----	select @inusebatchid=InUseBatchId, @haultrans=HaulTrans
----	from MSTD with (nolock) where MSCo=@msco and Mth=@mth and Ticket=@beg_ticket
----	if @@rowcount = 0
----		begin
----		select @msg = 'Invalid MS Transaction.', @rcode = 1
----		goto bspexit
----		end
----	if @inusebatchid is not null
----		begin
----		select @msg = 'MS Ticket: ' + isnull(@beg_ticket,'') + ' is already in use in batch: ' + convert(varchar(8),@inusebatchid) + '.', @rcode = 1
----		goto bspexit
----		end
----	if @haultrans is not null
----		begin
----		select @msg = 'MS Transaction is a haul transaction, cannot add to ticket batch.', @rcode = 1
----		goto bspexit
----		end
----	end




bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTBInsertExistingTransVal] TO [public]
GO
