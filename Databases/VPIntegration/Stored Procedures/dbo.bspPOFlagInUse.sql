SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPOFlagInUse    Script Date: 8/28/99 9:35:25 AM ******/
   CREATE  proc [dbo].[bspPOFlagInUse]
   /***********************************************************************************
    * CREATED BY	: kf 4/15/97
    * MODIFIED BY	: kf 4/15/97
	*				GF 7/27/2011 - TK-07144 changed to varchar(30)
    *
    * USAGE:
    * sets batch fields in POHD and POIT when inuse 
    *
    * INPUT PARAMETERS
    *   POCo  PO Co of PO to update
    *   PO to update
    *   
    * 
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of PO, Vendor, Vendor group, and Vendor Name
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ************************************************************************************/ 
   
   	(@poco bCompany = 0, @po VARCHAR(30) = null, @poitem bItem = null, @month bMonth=null,
   	@batchid bBatchID=null, @msg varchar(60) output)
   as
   
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
   if @poco is null
   	begin
   	select @msg = 'Missing PO Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @po is null
   	begin
   	goto bspexit
   	end
   
   update bPOHD
   set InUseBatchId=@batchid, InUseMth=@month
   where POCo=@poco and PO=@po
   
   if @@rowcount=0
   	begin
   	select @msg='Unable to flag PO as in use!', @rcode=1
   	goto bspexit
   	end
   
   update bPOIT
   set InUseBatchId=@batchid, InUseMth=@month
   where POCo=@poco and PO=@po and POItem=@poitem
   
   if @@rowcount=0
   	begin
   	select @msg='Unable to flag PO Item as in use!', @rcode=1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOFlagInUse] TO [public]
GO
