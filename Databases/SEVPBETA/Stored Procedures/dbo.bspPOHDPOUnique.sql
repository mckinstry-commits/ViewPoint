SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPOHDPOUnique    Script Date: 8/28/99 9:35:25 AM ******/
   CREATE   proc [dbo].[bspPOHDPOUnique]
   /***********************************************************
    * CREATED BY	: SE 4/9/97
    * MODIFIED BY	: SE 4/9/97
    *                  kb 3/20/2 - issue #16614
    *                  kb 6/18/2 - issue #16614  
	*					GF 7/27/2011 - TK-07144 changed to varchar(30)  
	*					GP 4/3/2012 - TK-13774 added check against pending purchase order table
    *
    * USAGE:
    * validates PO to insure that it is unique.  Checks POHD and POHB
    *
    * INPUT PARAMETERS
    *   POCo      PO Co to validate against
    *   PO        PO to Validate
    *   Mth       Batch Month
    *   BatchId   Batch that this is being validated from
    *   Seq       Seq that this po is on(keeps from thinking same is duplicate
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Location
    * RETURN VALUE
    *   0         success
    *   1         Failure  'if Fails Address, City, State and Zip are ''
    *****************************************************/
   
       (@poco bCompany = 0, @mth bMonth, @batchid bBatchID, @seq int,
        @po VARCHAR(30), @oldcompgroup varchar(10) output, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0, @msg = 'PO Unique'
   
	--Check pending purchase order table
	if exists (select 1 from dbo.vPOPendingPurchaseOrder where POCo = @poco and PO = @po)
	begin
		set @msg = 'Pending PO ' + @po + ' already exists.'
		return 1
	end
   
   select @rcode=1, @msg='PO ' + @po + ' already Exists'  from bPOHD
         where POCo=@poco and PO=@po
   
   select @rcode=1, @msg='PO '+ @po + ' is in use by batch  Month:' + substring(convert(varchar(12),Mth,3),4,5) + ' ID:' + convert(varchar(10),BatchId)
         from bPOHB
         where Co=@poco and PO=@po and not (Mth=@mth and BatchId=@batchid and BatchSeq=@seq)
   
   select @oldcompgroup = OldCompGroup from POHB where Co = @poco
     and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
   
   return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPOHDPOUnique] TO [public]
GO
