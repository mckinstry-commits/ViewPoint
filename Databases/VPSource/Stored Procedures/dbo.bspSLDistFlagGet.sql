SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLDistFlagGet    Script Date: 8/28/99 9:35:45 AM ******/
   CREATE proc [dbo].[bspSLDistFlagGet]
   /***********************************************************
    * CREATED BY	: SE 6/10/97
    * MODIFIED BY	: SE 6/10/97
    *
    * USAGE:
    * called from SL Batch Process form. Send it batch source
    * and based on that source it checks to see if JC distributions
    * are made. 
    *
    * INPUT PARAMETERS
    *   POCo  PO Co to validate against 
    *   Source of batch
    *   BatchId
    *   BatchMth
    * 
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise check DistFlag
    *   @flag - 0 if no jc entries
    *	     1 if jc entries
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
       (@slco bCompany = 0, @source bSource,
       @mth bMonth=null, @batchid bBatchID=null, @flag tinyint output, @msg varchar(60) output )
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0, @flag=0
   
   if @source='SL Entry'
   	begin
   	if exists(select SLCo from bSLIA where SLCo=@slco and Mth=@mth and BatchId=@batchid) select @flag=@flag | 1
   	end	
   
   if @source='SL Change'
   	begin
   	select @flag=0
   	if exists(select SLCo from SLCA where SLCo=@slco and Mth=@mth and BatchId=@batchid) select @flag=@flag | 1
   	end
   if @source='SL Close'
   	begin
   	select @flag=0
   	if exists(select SLCo from SLXA where SLCo=@slco and Mth=@mth and BatchId=@batchid) select @flag=@flag | 1
   	end
   	
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLDistFlagGet] TO [public]
GO
