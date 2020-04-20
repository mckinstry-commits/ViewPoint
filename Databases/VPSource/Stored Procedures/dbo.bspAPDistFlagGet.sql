SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPDistFlagGet    Script Date: 8/28/99 9:33:57 AM ******/
   CREATE proc [dbo].[bspAPDistFlagGet]
   /***********************************************************
    * CREATED BY	: SE 7/8/97
    * MODIFIED BY	: kb 3/9/99
    *              : danf 06/07/01
    *
    * USAGE:
    * called from AP Batch Process form. Send it batch source
    * and based on that source it checks to see what distributions
    * lists are available
    *
    * INPUT PARAMETERS
    *   APCo  PO Co to validate against
    *   Source of batch
    *   BatchId
    *   BatchMth
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of PO, Vendor,
    *   @flag - 0 if no in and no jc entries
    *	     1st bit=gl entry
    *	     2nd bit=jc entry
    *	     3rd bit=in entry
    *	     4th bit=em entry
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
       (@apco bCompany = 0, @source bSource,
       @mth bMonth=null, @batchid bBatchID=null, @flag varchar(8) output, @msg varchar(60) output )
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0,  @flag='00000000'
   
   if @source='AP Entry'
   	begin
   	if exists(select APCo from bAPGL where APCo=@apco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,1,1,'1')
   	if exists(select APCo from bAPJC where APCo=@apco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,2,1,'1')
   	if exists(select APCo from bAPIN where APCo=@apco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,3,1,'1')
   	if exists(select APCo from bAPEM where APCo=@apco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,4,1,'1')
       if exists(select POCo from bPORJ where POCo=@apco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,5,1,'1')
   	if exists(select POCo from bPORN where POCo=@apco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,6,1,'1')
   	if exists(select POCo from bPORE where POCo=@apco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,7,1,'1')
   	if exists(select POCo from bPORG where POCo=@apco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,8,1,'1')
   	end
   
   if @source='AP Payment'
   	begin
   	if exists(select APCo from bAPPG where APCo=@apco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,1,1,'1')
   	end
   
   if @source='AP Clear'
   	begin
   	if exists(select Co from bAPCD where Co=@apco and Mth=@mth and BatchId=@batchid) select @flag = stuff(@flag,1,1,'1')
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPDistFlagGet] TO [public]
GO
