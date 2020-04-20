SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE      proc [dbo].[bspPOReceived#Val]
/***********************************************************
* CREATED BY	: MV 7/02/02
* MODIFIED BY	:	MV 10/24/03 - #22756 warn for duplicate receiver # 
*						on same PO and Item in this batch or bPORD.		
*					GF 7/27/2011 - TK-07144 changed to varchar(30) 
*					GF 08/21/2011 TK-07879 pass POItemLine for validation
* 
*
* USED BY
*   PO Receiving
*
*
* USAGE:
* validates PO Received # and warns user if it is a duplicate
* for the PO
*
* INPUT PARAMETERS
*   POCo  PO Co to validate against 
*   PO to validate
* POItem to validate
* POItemLine to validate
*   PO Received #
* 
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise warning if 
*   Recieved # is a duplicate.
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@poco bCompany = 0,@po VARCHAR(30) = null, @poitem bItem,
 ----TK-07879 
 @POItemLine INT = NULL, @receiver# varchar(20),
 @msg varchar(100) output )
as
set nocount on
   
   declare @rcode int,@mth bMonth, @batchid int, @batchseq int, @potrans bTrans
   select @rcode = 0
   
   if @poco is null
   	begin
   	select @msg = 'Missing PO Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @po is null
   	begin
   	select @msg = 'Missing PO!', @rcode = 1
   	goto bspexit
   	end
   
   if @receiver# is not null
   	begin
   	--check bPORB 
   	select @mth=Mth, @batchid=BatchId, @batchseq=BatchSeq
   	from dbo.bPORB
   	where Co = @poco and PO = @po and POItem = @poitem
   		----TK-07879 
   		AND POItemLine = @POItemLine
   		AND Receiver# = @receiver#
   	if @@rowcount > 0 
   		begin
   		select @msg = 'Duplicate Receiver # for this PO, Item, and Line in Mth: ' 
            	+ convert(varchar(8),@mth,1)
				+ ' BatchId#: ' + convert(varchar(6), @batchid)
   				+ ' Seq#: ' + convert(varchar(4),@batchseq),@rcode=1
   		goto bspexit
   		end
   		
   	--check bPORD
   	select @mth=Mth, @potrans=POTrans 
   	from dbo.bPORD
   	where POCo = @poco and PO = @po and POItem = @poitem 
   		----TK-07879 
   		AND POItemLine = @POItemLine
   		AND Receiver# = @receiver#
   	if @@rowcount > 0 
   		begin
   		select @msg = 'Duplicate Receiver # for this PO, Item, and Line in Mth: ' 
            	+ convert(varchar(8),@mth,1)
				+ ' POTrans: ' + convert(varchar(6),@potrans),@rcode=1
   		goto bspexit
   		end
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOReceived#Val] TO [public]
GO
