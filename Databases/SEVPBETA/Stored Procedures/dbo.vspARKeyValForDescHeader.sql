SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARKeyValForDescHeader    Script Date:  ******/
CREATE PROC [dbo].[vspARKeyValForDescHeader]
/*********************************************************************************************
* CREATED BY: TJL   11/16/05
* MODIFIED By : 
* 
*
* USAGE:
*   Returns Header Key Description for Batch Forms
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
(@arco bCompany, @mth bMonth, @batchid bBatchID, @seq int, @source char(10), @artranstype char(1), @errmsg varchar(255) output)
as
set nocount on

declare @rcode int

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
if @source is null
	begin
   	--select @rcode = 1, @errmsg = 'New Sequence'
   	goto vspexit
   	end
if @artranstype is null
	begin
   	--select @rcode = 1, @errmsg = 'New Sequence'
   	goto vspexit
   	end
if @source not in ('AR Receipt', 'ARRelease', 'ARFinanceC', 'AR Invoice')
	begin
   	select @rcode = 1, @errmsg = 'Not a valid Source.'
   	goto vspexit
   	end

if @source = 'AR Receipt'
	begin
	if @artranstype = 'P'
		begin
		select @errmsg = Source
		from bARBH with (nolock)
		where Co = @arco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
		goto vspexit
		end
	if @artranstype = 'M'
		begin
		select @errmsg = Description
		from bARBH with (nolock)
		where Co = @arco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
		goto vspexit
		end
	end

if @source = 'ARRelease'
	begin
	select @errmsg = Source
	from bARBH with (nolock)
	where Co = @arco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
	goto vspexit
	end

if @source = 'ARFinanceC'
	begin
	select @errmsg = Description
	from bARBH with (nolock)
	where Co = @arco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
	goto vspexit
	end

if @source = 'AR Invoice'
	begin
	select @errmsg = Description
	from bARBH with (nolock)
	where Co = @arco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
	goto vspexit
	end

vspexit:
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + char(13) + char(10) + '[dbo.vspARKeyValForDescHeader]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARKeyValForDescHeader] TO [public]
GO
