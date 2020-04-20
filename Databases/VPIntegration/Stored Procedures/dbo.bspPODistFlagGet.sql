SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPODistFlagGet    Script Date: 8/28/99 9:33:09 AM ******/
   CREATE proc [dbo].[bspPODistFlagGet]
   /***********************************************************
    * CREATED BY	: kf 5/21/97
    * MODIFIED BY	: kf 5/21/97
    *              : danf 05/24/01 Added table for po receipt expenses
    *              : danf 05/28/01 Changed flag distributions.
    *
    * USAGE:
    * called from PO Batch Process form. Send it batch source
    * and based on that source it checks to see if JC distributions
    * are made and if IN distributions are made.
    *
    * INPUT PARAMETERS
    *   POCo  PO Co to validate against
    *   Source of batch
    *   BatchId
    *   BatchMth
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of PO, Vendor,
    *   @flag - 0 if no in and no jc entries
    *	     1st = jc entry
    *	     2nd = in entry
    *       3rd = jc expenses
    *       4th = in expenses
    *       5th = em expenses
    *       6th = gl expenses
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
       (@poco bCompany = 0, @source bSource,
       @mth bMonth=null, @batchid bBatchID=null, @flag varchar(7) output, @msg varchar(60) output )
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0, @flag='0000000'
   
   if @source='PO Entry'
   	begin
   	if exists(select POCo from bPOIA where POCo=@poco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,1,1,'1')
   	if exists(select POCo from bPOII where POCo=@poco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,2,1,'1')
   	end
   if @source='PO Receipt'
   	begin
   	if exists(select POCo from bPORA where POCo=@poco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,1,1,'1')
   	if exists(select POCo from bPORI where POCo=@poco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,2,1,'1')
   	if exists(select POCo from bPORJ where POCo=@poco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,3,1,'1')
   	if exists(select POCo from bPORN where POCo=@poco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,4,1,'1')
   	if exists(select POCo from bPORE where POCo=@poco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,5,1,'1')
   	if exists(select POCo from bPORG where POCo=@poco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,6,1,'1')
       end
   
   if @source='PO Change'
   	begin
   	if exists(select POCo from bPOCA where POCo=@poco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,1,1,'1')
   	if exists(select POCo from bPOCI where POCo=@poco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,2,1,'1')
       end
   if @source='PO Close'
   	begin
   	if exists(select POCo from bPOXA where POCo=@poco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,1,1,'1')
   	if exists(select POCo from bPOXI where POCo=@poco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,2,1,'1')
   	end
   if @source='PO InitRec'
   	begin
   	if exists(select POCo from bPORJ where POCo=@poco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,3,1,'1')
   	if exists(select POCo from bPORN where POCo=@poco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,4,1,'1')
   	if exists(select POCo from bPORE where POCo=@poco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,5,1,'1')
   	if exists(select POCo from bPORG where POCo=@poco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,6,1,'1')
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPODistFlagGet] TO [public]
GO
