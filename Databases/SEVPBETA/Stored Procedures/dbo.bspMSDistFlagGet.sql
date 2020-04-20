SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
   CREATE   proc [dbo].[bspMSDistFlagGet]
   /***********************************************************
    * Created By:  GF 10/12/2000
    * Modified By: GG 11/20/00 - Changed to handle MS Haul and Invoice batches
    *				GG 12/18/00 - added flag for AR Invoice distributions
    *				GG 02/12/01 - changed to handle MS Hauler Payment batches
    *				GF 05/08/2003 - issue #21197 - changed to handle MS Addons, same as MS Tickets
    *				GF 03/02/2005 - issue #19185 material vendor enhancement 'MS Matlpay'
    *
    *
    *
    * USAGE:
    * Called from MS Batch Process form to see what distributions
    * lists are available for a given batch.
    *
    * INPUT PARAMETERS
    *   @msco		MS Company
    *   @source		Batch source
    *   @mth			Batch month
    *   @batchid		Batch ID#
    *
    * OUTPUT PARAMETERS
    *   @msg   error message if error occurs.
    *   @flag  initalized to 0, set to 1 if distribution found.
    *          1st = jc distribution
    *          2nd = em distribution
    *          3rd = in distribution
    *          4th = in production distribution
    *          5th = gl distribution
    *	        6th = ar/ap invoice distribution
   
    *
    * RETURN VALUE
    *   0         success
    *   1         failure
    *****************************************************/
   (@msco bCompany = null, @source bSource = null, @mth bMonth = null,
    @batchid bBatchID = null, @flag varchar(10) output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   select @rcode = 0, @flag='0000000000'
   
   if @source in ('MS Tickets', 'MS Addons')
       begin
   	if exists(select MSCo from bMSJC with (nolock) where MSCo=@msco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,1,1,'1')
   	if exists(select MSCo from bMSEM with (nolock) where MSCo=@msco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,2,1,'1')
   	if exists(select MSCo from bMSIN with (nolock) where MSCo=@msco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,3,1,'1')
       if exists(select MSCo from bMSPA with (nolock) where MSCo=@msco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,4,1,'1')
   	if exists(select MSCo from bMSGL with (nolock) where MSCo=@msco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,5,1,'1')
   	end
   if @source='MS Haul'
       begin
   	if exists(select MSCo from bMSJC with (nolock) where MSCo=@msco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,1,1,'1')
   	if exists(select MSCo from bMSEM with (nolock) where MSCo=@msco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,2,1,'1')
   	if exists(select MSCo from bMSIN with (nolock) where MSCo=@msco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,3,1,'1')
       if exists(select MSCo from bMSGL with (nolock) where MSCo=@msco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,5,1,'1')
   	end
   if @source='MS Invoice'
       begin
   	if exists(select MSCo from bMSIG with (nolock) where MSCo=@msco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,5,1,'1')
   	if exists(select MSCo from bMSAR with (nolock) where MSCo=@msco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,6,1,'1')
   	end
   if @source='MS HaulPay'
       begin
   	if exists(select MSCo from bMSWG with (nolock) where MSCo=@msco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,5,1,'1')
   	if exists(select MSCo from bMSAP with (nolock) where MSCo=@msco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,6,1,'1')
   	end
   if @source='MS MatlPay'
       begin
   	if exists(select MSCo from bMSMG with (nolock) where MSCo=@msco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,5,1,'1')
   	if exists(select MSCo from bMSMA with (nolock) where MSCo=@msco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,6,1,'1')
   	end
   
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSDistFlagGet] TO [public]
GO
