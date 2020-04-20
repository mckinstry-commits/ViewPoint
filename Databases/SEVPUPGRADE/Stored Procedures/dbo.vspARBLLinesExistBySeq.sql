SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARBLLinesExistBySeq    Script Date: ******/
CREATE procedure [dbo].[vspARBLLinesExistBySeq]
/*************************************************************************************************
* CREATED BY: 		TJL 07/29/05 - Issue #27715, 6x rewrite ARRelease.  Check for presence of ARBL records by Seq
* MODIFIED By :
*
* USAGE:
* 	Currently used only by 'ARRelease' and 'AR Receipt'.  It determines if Detail records have been placed into
*	the ARBL batch table relative to an entire Sequence.  If so, Header Filtering inputs are disabled.  
*	If no records exist for a particular BatchMth, BatchSeq then access to the Filtering inputs are
*	enabled.
*
* INPUT PARAMETERS
*   @co				AR Co
*   @mth			Month of batch
*   @batchid		Batch ID 
*	@batchseq		Batch Sequence
*	@source			Source 
*
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
**************************************************************************************************/
  
(@arco bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @source char(10),
	@errmsg varchar(255) output)
as

set nocount on

declare @rcode int

select @rcode = 0

if @source not in ('ARRelease', 'AR Receipt')
	begin
	select @errmsg = 'Not a valid Source.', @rcode = 1
	goto vspexit
	end
  
/* Check for the existence of Batch Lines for this BatchSeq. */
if exists (select 1 
	from bARBL with (nolock) 
	where Co = @arco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq)
	begin
	/* Detail records exist.  Form will not allow user to Header Filtering inputs. */
	select @rcode = 1
	end
  
vspexit:
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[vspARBLLinesExistBySeq]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARBLLinesExistBySeq] TO [public]
GO
