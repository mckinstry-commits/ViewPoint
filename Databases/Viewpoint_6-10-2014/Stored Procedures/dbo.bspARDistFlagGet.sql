SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARDistFlagGet    Script Date: 8/28/99 9:34:11 AM ******/
CREATE   proc [dbo].[bspARDistFlagGet]
/***********************************************************
* CREATED BY	: cjw 6/5/97
* MODIFIED BY	: cjw 6/5/97
		  TJL  08/15/01  Issue #11672, Add AR EM Misc Distributions flag for AR Misc Cash Rec
*
* USAGE:
* called from AR Batch Process form. Send it batch source
* and based on that source it checks to see if Misc distributions
* are made and if IN distributions are made.
*
* INPUT PARAMETERS
*   ARCo  AR Co to validate against
*   Source of batch
*   BatchId
*   BatchMth
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of AR
*   @flag - 0 if no in and no jc entries
*	     1st bit=misc entry
*	     2nd bit= jc distribution
*
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@arco bCompany = 0, @source bSource,
   @mth bMonth=null, @batchid bBatchID=null, @flag tinyint output, @msg varchar(60) output )
as
set nocount on
declare @rcode int, @tmp varchar(100)
select @rcode = 0, @flag=0
if @source in ('AR Invoice','ARRelease','SM Invoice')
   	begin
   	/* Misc distributions  */
   	if exists(select Co from bARBM where Co=@arco and Mth=@mth and BatchId=@batchid) select @flag=@flag | 1
   	/* Job distributions*/
   	if exists(select ARCo from bARBI where ARCo=@arco and Mth=@mth and BatchId=@batchid) select @flag=@flag | 2
   	/*GL distributions*/
   	if exists(select Co from bARBA where Co = @arco and Mth = @mth and BatchId = @batchid) select @flag=@flag | 4
   	end
if @source='AR Receipt'
   	begin
   	/* Misc distributions  */
   	if exists(select Co from bARBM where Co=@arco and Mth=@mth and BatchId=@batchid) select @flag=@flag | 1
   	/* Job distributions*/
   	if exists(select ARCo from bARBI where ARCo=@arco and Mth=@mth and BatchId=@batchid) select @flag=@flag | 2
   	/*GL distributions*/
   	if exists(select Co from bARBA where Co = @arco and Mth = @mth and BatchId = @batchid) select @flag=@flag | 4
   	/*CM distributions*/
   	if exists(select ARCo from bARBC where ARCo = @arco and Mth = @mth and BatchId = @batchid) select @flag=@flag | 8
   	/*Job Cost Detail*/
   	if exists(select ARCo from bARBJ where ARCo = @arco and Mth = @mth and BatchId = @batchid) select @flag=@flag | 16
   	/*Equipment Cost Detail*/
   	if exists(select ARCo from bARBE where ARCo = @arco and Mth = @mth and BatchId = @batchid) select @flag=@flag | 32
   	end
if @source = 'ARFinanceC'
   	begin
   	/* Job distributions*/
   	if exists(select ARCo from bARBI where ARCo=@arco and Mth=@mth and BatchId=@batchid) select @flag=@flag | 2
   	/*GL Distributions*/
   	if exists(select Co from bARBA where Co = @arco and Mth = @mth and BatchId = @batchid) select @flag=@flag | 4
   	end
bspexit:
   	if @rcode<>0 select @msg=@msg	--+ char(13) + char(10) + '[bspARDistFlagGet]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARDistFlagGet] TO [public]
GO
