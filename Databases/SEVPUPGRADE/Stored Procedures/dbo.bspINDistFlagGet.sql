SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspINDistFlagGet]
   /*****************************************************************************************
    * Created: GR 1/26/00
    * Modified: RM 09/07/01 - Added Source 'IN Count'
    *           RM 09/13/01 - Removed Source 'IN Count'
    *			GG 03/12/02 - Added 'MO Entry' and 'MO Confirm' sources
    *			GG 04/17/02 - Added 'MO Close' source
    *			
    *
    * USAGE:
    * 	Called from IN Batch Process form to determine which distribution tables
    *	have data related to the current batch. 
    *
    * INPUT PARAMETERS
    *  @inco		IN Company
    *  @source		Batch Source 
    *	@mth		Month
    *  @batchid	Batch #
    *
    * OUTPUT PARAMETERS
    *   @flag  	initalized to 0, set to 1 if distribution found.
    *          	1st = GL distribution
    *          	2nd = JC distribution
    *   @msg      	error message if error occurs
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ************************************************************************************/
   
       (@inco bCompany = 0, @source bSource, @mth bMonth = null, @batchid bBatchID = null,
   	 @flag varchar(10) output, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0, @flag='0000000000'
   
   if @source='IN Adj'-- or @source = 'IN Count'
   	if exists(select 1 from bINAG where INCo=@inco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,1,1,'1')
   if @source='IN Trnsfr'
   	if exists(select 1 from bINTG where INCo=@inco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,1,1,'1')
   if @source='IN Prod'
   	if exists(select 1 from bINPG where INCo=@inco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,1,1,'1')
   if @source='MO Entry'
   	if exists(select 1 from bINJC where INCo=@inco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,2,1,'1')	
   if @source='MO Confirm'
   	begin
   	if exists(select 1 from bINCG where INCo=@inco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,1,1,'1')
   	if exists(select 1 from bINCJ where INCo=@inco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,2,1,'1')	
   	end
   if @source='MO Close'
   	if exists(select 1 from bINXJ where INCo=@inco and Mth=@mth and BatchId=@batchid)
           select @flag = stuff(@flag,2,1,'1')
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINDistFlagGet] TO [public]
GO
