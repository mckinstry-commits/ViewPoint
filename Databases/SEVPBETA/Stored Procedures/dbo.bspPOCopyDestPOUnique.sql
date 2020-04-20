SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPOCopyDestPOUnique  Script Date: 03/14/2003 ******/
   CREATE proc [dbo].[bspPOCopyDestPOUnique]
   /***********************************************************
    * Created By:	GF 03/14/2003
    * Modified By:  TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
    *				GP 4/9/12 - TK-13774 added validation against POUnique view
    *
    *
    *
    * USAGE:
    * validates PO to insure that it is unique.  Checks POHD and POHB
    *
    * INPUT PARAMETERS
    *   POCo      PO Co to validate against
    *   PO        PO to Validate
    *   Mth       Batch Month
    *   BatchId   Batch that this is being validated from
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs
    * RETURN VALUE
    *   0         success
    *   1         Failure  error message
    *****************************************************/
   (@poco bCompany = 0, @mth bMonth, @batchid bBatchID, @po varchar(30), @poexists bYN output, @vendor bVendor output,
    @description bDesc output, @orderdate bDate output, @orderedby varchar(10) output, @expdate bDate output,
    @jcco bCompany output, @job bJob output, @shiploc varchar(10) output, @inco bCompany output,  
    @location bLoc output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @validcnt int
   
   select @rcode = 0, @msg = 'PO Unique', @poexists = 'N'
   
   --checks the POUnique view for records in vPOPendingPurchaseOrder
   exec @rcode = dbo.vspPOInitVal @poco, @po, @msg output
   if @rcode = 1	goto bspexit
   
   -- if PO already exists in POHB return information - valid
   select @vendor=a.Vendor, @description=a.Description, @orderdate=OrderDate, @orderedby=OrderedBy,
   	   @expdate=ExpDate, @jcco=JCCo, @job=Job, @shiploc=ShipLoc, @inco=INCo, @location=Loc
   from bPOHB a with (nolock) 
   where a.Co=@poco and a.Mth=@mth and a.BatchId=@batchid and a.PO=@po
   if @@rowcount <> 0
   	begin
   	select @poexists = 'Y'
   	goto bspexit
   	end
   
   -- check POHB for PO in use different batch month and id
   select @rcode=1, @msg='PO '+ @po + ' is in use by batch  Month:' + substring(convert(varchar(12),Mth,3),4,5) + ' ID:' + convert(varchar(10),BatchId)
   from bPOHB with (nolock) where Co=@poco and PO=@po --and Mth<>@mth and BatchId<>@batchid
   if @@rowcount <> 0 goto bspexit
   
   
   -- check POHD
   select @validcnt = count(*)
   from bPOHD with (nolock) where POCo=@poco and PO=@po
   if @validcnt <> 0
   	begin
   	select @rcode=1, @msg='PO ' + @po + ' already Exists'
   	goto bspexit
   	end
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOCopyDestPOUnique] TO [public]
GO
