SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARKeyValForDescDetail    Script Date:  ******/
CREATE PROC [dbo].[vspARKeyValForDescDetail]
/*********************************************************************************************
* CREATED BY:		TJL 04/11/07
* MODIFIED By :		CHS	08/10/10	#140559 
* 
* 
* USAGE:
*   Returns Detail Key Description for Batch Forms
*
* INPUT PARAMETERS
*   
*           
* OUTPUT PARAMETERS
*   @msg      error message if error occurs.
*
* RETURN VALUE
*   0         Success
*   1         Failure
**********************************************************************************************/
(@arco bCompany, @mth bMonth, @batchid bBatchID, @seq int, @arline smallint, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @action varchar(1), @artrans bTrans, @artranstype varchar(1), @applymth bMonth, @applytrans bTrans

select @rcode = 0


if @arco is null
	begin
   	select @rcode = 1, @errmsg = 'ARCo is missing.'
   	goto vspexit
   	end
if @mth is null
	begin
   	select @rcode = 1, @errmsg = 'BatchMth is missing.'
   	goto vspexit
   	end
if @batchid is null
	begin
   	select @rcode = 1, @errmsg = 'BatchId is missing.'
   	goto vspexit
   	end
if @seq is null
	begin
   	select @rcode = 1, @errmsg = 'BatchSeq is missing.'
   	goto vspexit
   	end
if @arline is null
	begin
   	select @rcode = 1, @errmsg = 'BatchLine is missing'
   	goto vspexit
   	end
-- if @source not in ('AR Receipt', 'ARRelease', 'ARFinanceC', 'AR Invoice')
-- 	begin
--    	select @rcode = 1, @errmsg = 'Not a valid Source.'
--    	goto vspexit
--    	end

/* Get TransType value. */
select @action = TransType, @artrans = ARTrans, @artranstype = ARTransType, @applymth = AppliedMth, @applytrans = AppliedTrans
from ARBH with (nolock)
where Co = @arco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
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
	if exists(select 1 from ARBL with (nolock) 
		where Co = @arco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
			and ARLine = @arline)
		begin
		/* Do nothing.  Form will find this line in batch. */
		goto vspexit
		end

	/* Not in batch so check posting table.  If there, user must be stopped. */
	if exists(select 1 from ARTL with (nolock) 
	where ARCo = @arco and Mth = @mth and ARTrans = @artrans and ARLine = @arline)
		begin
		select @errmsg = 'Line number is already in use in posting table for this AR Transaction '
		select @errmsg = @errmsg + 'and cannot be added back into the batch by itself.  To get this line back into the batch, '
		select @errmsg = @errmsg + 'the entire sequence must be deleted and then re-added.', @rcode = 1
		goto vspexit
		end
	end

/*	when making an adjustment to a posted invoice, you can adjust using the line numbers of the posted invoice, but 
	you cannot use the line number more once even when multiple sequences are used.
	#140599 */
if @action = 'A'
	begin
	if @artranstype = 'A' or @artranstype = 'C' or @artranstype = 'W'
		begin
		/*	look in the posted lines table and if the line number is there then don't look for the error condition */
		if not exists(select 1 from ARTL with (nolock) where ARCo = @arco and Mth = @applymth and ARTrans = @applytrans and ARLine = @arline)
			begin
			/*	look in the batch lines table for ANY line values which are not in the posted lines table 
				to ensure number is unique	*/
			if exists(select 1 from ARBL with (nolock) where Co = @arco and ApplyMth = @applymth and ApplyTrans = @applytrans and ARLine = @arline)
				begin
				select @errmsg = 'Line number is already in use in this or another batch '
				select @errmsg = @errmsg + 'for this Apply Month or Apply Trans.', @rcode = 1
				goto vspexit				
				end				
			end
		end		
	end
	
vspexit:
/* Currently all AR Line descriptions come from ARBL.Description.  At the moment, there is 
   no need for checking Source or any other values to descriminate. */
select @errmsg = Description
from bARBL with (nolock)
where Co = @arco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and ARLine = @arline

if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + char(13) + char(10) + '[dbo.vspARKeyValForDescDetail]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARKeyValForDescDetail] TO [public]
GO
