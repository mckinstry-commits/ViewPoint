SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspSLChangeOrderAllowUnitCostChangeGet]
   /***********************************************************
    * CREATED:  DC  11/14/06
    * MODIFIED: GF  06/24/2010 - issue #135813 expanded SL to varchar(30)
    *
    * Used by SL Change Order form to determine if changes are allowed 
    * to Unit Cost
    *
    * INPUT PARAMETERS
    *    @slco        SL Co#
    *    @sl          SL to validate
    *    @slitem      Item to validate
    *    @mth         Batch Month
    *    @batchid     Batch #
    *    @batchseq    Batch Seq#
    *
    * OUTPUT PARAMETERS
    *    @allowunitcostchange  'Y'=allow unit cost change, 'N' = not allowed
    *
    * RETURN VALUE
    *   0         Yes - Changes Allowed
    *   1         No - Changes Not Allowed
    *****************************************************/
   
       (@slco bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @batchseq int,
        @sl VARCHAR(30) = null, @slitem bItem = null, @allowunitcostchange bYN output, @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @itemtype tinyint, @um bUM
   
   select @rcode = 0, @allowunitcostchange = 'N'
   
   if @slco is null
     	begin
     	select @msg = 'Missing SL Company!', @rcode = 1
     	goto bspexit
     	end
   if @sl is null
     	begin
     	select @msg = 'Missing SL!', @rcode = 1
     	goto bspexit
     	end
   if @slitem is null
     	begin
     	select @msg = 'Missing SL Item#!', @rcode = 1
     	goto bspexit
     	end
      
   -- validate SL Item and get info
   select @um = UM, @itemtype = ItemType
   from dbo.SLIT
   where SLCo = @slco and SL = @sl and SLItem = @slitem
   if @@rowcount = 0
     	begin
     	select @msg = 'SL Item does not exist!', @rcode = 1
     	goto bspexit
     	end

   -- determine whether Item Unit Cost can be changed
   if @um = 'LS' or @itemtype <> 2 goto bspexit   -- must be a unit based Change Order Item
   -- Item must not have any previously posted Change Orders, except the one in the batch
   if exists(select * from bSLCD where SLCo = @slco and SL = @sl and SLItem = @slitem
           and (Mth <> @mth or (Mth = @mth and isnull(InUseBatchId,0) <> @batchid))) goto bspexit
   -- Item must not have any Change Orders in the batch except the current entry
   if exists(select * from bSLCB where Co = @slco and SL = @sl and SLItem = @slitem
       and BatchSeq <> @batchseq) goto bspexit
   select @allowunitcostchange = 'Y'
   
   bspexit:
   
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSLChangeOrderAllowUnitCostChangeGet] TO [public]
GO
