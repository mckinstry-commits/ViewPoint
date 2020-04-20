SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMMilesByStateLineVal    Script Date:  ******/
CREATE procedure [dbo].[vspEMMilesByStateLineVal]
   
/***********************************************************
* CREATED BY:  TJL 04/10/07 - Issue #27992, 6x Rewrite EMMilesByState.
*
* MODIFIED By : 
*
* USAGE:
*	Validates EMSD & EMML Line value to see if it already exists on new line.
*
*
* INPUT PARAMETERS
*	@emco			EMCo
*	@batchmonth		BatchMonth
* 	@batchid		BatchId
*	@batchseq		BatchSeq
*	@line			BatchLine
*
* OUTPUT PARAMETERS
*
*
**********************************************************/
   
(@emco bCompany, @batchmonth bMonth, @batchid bBatchID, @batchseq int, @emtrans bTrans, @line int,
	@errmsg varchar(255) output)
   
as
set nocount on
declare @rcode int, @action varchar(1)
select @rcode = 0
   
if @emco is null
	begin
	select @errmsg = 'Missing EM Company.', @rcode = 1
	goto vspexit
	end
if @batchmonth is null
	begin
	select @errmsg = 'Missing BatchMonth.', @rcode = 1
	goto vspexit
	end
if @batchid is null
	begin
	select @errmsg = 'Missing BatchId.', @rcode = 1
	goto vspexit
	end
if @batchseq is null
	begin
	select @errmsg = 'Missing BatchSeq.', @rcode = 1
	goto vspexit
	end
if @line is null
	begin
	select @errmsg = 'Missing Batch Line.', @rcode = 1
	goto vspexit
	end


/* Get BatchTransType value. */
select @action = BatchTransType
from EMMH with (nolock)
where Co = @emco and Mth = @batchmonth and BatchId = @batchid and BatchSeq = @batchseq
if @@rowcount = 0
	begin
	select @errmsg = 'Batch TransType could not be determined.', @rcode = 1
	goto vspexit
	end

/* In this form, Lines are not allowed to be added back into a batch one at a time.
   They are all added back in at once.  After this point, if a user has deleted one of the
   Lines and attempts to re-add it back to the batch, they will be inform that this action is not
   allowed.  */
if @action = 'C' or @action = 'D'
	begin
	if exists(select 1 from EMML with (nolock) 
		where Co = @emco and Mth = @batchmonth and BatchId = @batchid and BatchSeq = @batchseq
			and Line = @line)
		begin
		/* Do nothing.  Form will find this line in batch. */
		goto vspexit
		end

	/* Not in batch so check posting table.  If there user must be stopped. */
	if exists(select 1 from EMSD with (nolock) 
	where Co = @emco and Mth = @batchmonth and EMTrans = @emtrans and Line = @line)
		begin
		select @errmsg = 'Line number is already in use in posting table for this EM Transaction '
		select @errmsg = @errmsg + 'and cannot be added back by itself.  To get this line back, the entire '
		select @errmsg = @errmsg + 'sequence must be deleted and then re-added.', @rcode = 1
		goto vspexit
		end
	end
   
vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMMilesByStateLineVal] TO [public]
GO
