SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLHDSLUnique    Script Date: 8/28/99 9:35:46 AM ******/
   CREATE  proc [dbo].[bspSLHDSLUnique]
   /***********************************************************
    * CREATED BY	: SE 5/2/97
    * MODIFIED BY	: SE 5/2/97
    *                  kb 3/20/2 - issue #16614
    *                  kb 6/17/2 - issue #16614
    *					DC 6/25/10 - #135813 - expand subcontract number
    * USAGE:
    * validates Subcontract to insure that it is unique.  Checks SLHD and SLHB
    *
    * INPUT PARAMETERS
    *   SLCo      PO Co to validate against
    *   Subcontract        PO to Validate
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Location
    * RETURN VALUE
    *   0         success
    *   1         Failure  'if Fails Address, City, State and Zip are ''
    *****************************************************/
       (@slco bCompany = 0,@mth bMonth, @batchid bBatchID, @seq int, @sl VARCHAR(30), --bSL,  DC #135813
    @oldcompgroup varchar(10) output, @msg varchar(255) output )
    
    
   as
   set nocount on
   declare @rcode int
   select @rcode = 0, @msg = 'SL Unique'
   select @rcode=1, @msg='Subcontract ' + @sl + ' already Exists'  from bSLHD
         where SLCo=@slco and SL=@sl
   select @rcode=1, @msg='Subcontract '+ @sl + ' is in use by batch  Month:' + substring(convert(varchar(12),Mth,3),4,5) + ' ID:' + convert(varchar(10),BatchId)
         from bSLHB
         where Co=@slco and SL=@sl and not (Mth=@mth and BatchId=@batchid and BatchSeq=@seq)
   
   select @oldcompgroup = OldCompGroup from bSLHB where Co = @slco 
    and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLHDSLUnique] TO [public]
GO
