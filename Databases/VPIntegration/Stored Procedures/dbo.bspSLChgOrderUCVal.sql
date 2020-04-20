SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLChgOrderUCVal    Script Date: 8/28/99 9:33:40 AM ******/
   CREATE  proc [dbo].[bspSLChgOrderUCVal]
   /***********************************************************
    * CREATED BY	: kb 3/10/99
    * MODIFIED BY	: kb 3/11/99
    *              : GR 5/16/00 commented the code to check if transaction type is not A - as per issue 6886
    *				:  DC 6/24/10 - #135813 - expand subcontract number
    *
    * USAGE: Used in the SL Change Order Batch program. Is called before a
    * 	record is saved. Will restrict users from entering unit cost
    *	change orders to an item that already exists in the batch with unit
    *	cost changes or unit changes.
    *
    * USED IN: SLChangeOrders
    *
    * INPUT PARAMETERS
    *	@slco - company posting in
    *	@sl - SL that is used on change order
    *	@slitem - Item that is used on the change order
    *	@batchid - batch id #
    *	@mth - batch month
    *	@batchseq - batch sequence
    *	@curunitcost - change to unit cost for this batch sequence
    *
    * OUTPUT PARAMETERS
    *  	@msg = Error Message
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
       (@slco bCompany, @sl VARCHAR(30), --bSL,   DC #135813
       @slitem bItem, @batchid bBatchID, @mth bMonth, @batchseq int, @curunitcost bUnitCost, @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @um bUM
   
   select @rcode = 0
   
   select @um = UM from SLIT where SLCo = @slco and SL = @sl and SLItem = @slitem
   
   if @um = 'LS'
   	begin
   	select @rcode = 0
   	goto bspexit
   	end
   
   if @curunitcost <> 0
   	begin
   	if exists(select 1 from SLCB where Co = @slco and Mth = @mth and BatchId = @batchid and
   	  SL = @sl and SLItem = @slitem and BatchSeq <> @batchseq)
   	  	begin
   	  	select @msg = 'Cannot post unit cost change orders to this SL/SLItem since change orders '
   	  		+ 'already exist in this batch', @rcode = 1
   	  	goto bspexit
   	  	end
   	/*if exists(select * from SLCB where Co = @slco and Mth = @mth and BatchId = @batchid and
   	  SL = @sl and SLItem = @slitem and BatchSeq = @batchseq and BatchTransType<>'A' and CurUnitCost<>@curunitcost)
   	  	begin
   	  	select @msg = 'Cannot change the unit cost on previously posted change orders', @rcode = 1
   	  	goto bspexit
   	  	end*/
   
   	end
   
   if exists(select 1 from SLCB where Co = @slco and Mth = @mth and BatchId = @batchid and SL = @sl
     and SLItem = @slitem and CurUnitCost<>0 and BatchSeq <> @batchseq)
   	begin
   	select @msg = 'Cannot post change orders to this SL/SLItem since changes to the current unit cost already '
   		+ 'exist in this batch.', @rcode = 1
   	goto bspexit
   	end
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLChgOrderUCVal] TO [public]
GO
