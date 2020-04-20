SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLItemValRet    Script Date: 8/28/99 9:35:46 AM ******/
   CREATE   proc [dbo].[bspSLItemValRet]
   /***********************************************************
    * CREATED:  kf 5/5/97
    * MODIFIED: kb 10/26/98
    *           kb 10/12/99 - display section of change orders screen not showing updates correctly.
    *           GG 07/13/01 - cleanup for #13968
    *			 RT 12/03/03 - issue 23061, use isnulls when concatenating strings.
    *			DC 10/17/06 - 6.x Recode.  Added the @slitemexist output parameter.  In 5.x the existance
    *										of the SLItem was done with a seperate call to the db.  I 
    *										added to this validate procedure.
	*			DC 06/26/08	-	issue #128435 - Add taxes to SL
	*			DC 06/25/10 - #135813 - expand subcontract number
    *
    * Used by SL Change Order form to validate SL Item and retrieve amounts for display.
    * Amounts include entries from current batch.
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
    *    @itemtype             Item type (1=reg,2=change order,3=backcharge,4=add-on)
    *    @addon                Addon percentage (addon item only)
    *    @origunits            Original units
    *    @curunits             Current units
    *    @invunits             Invoiced units
    *    @remunits             Remaining units
    *    @origunitcost         Original unit cost
    *    @curunitcost          Current unit cost
    *    @origitemtot          Original total cost
    *    @curitemtot           Current total cost
    *    @invitemtot           Invoice total
    *    @remitemtot           Remaining total cost
    *    @um                   Unit of measure
    *    @jcco                 JC Co#
    *    @job                  Job
    *    @phase                JC Phase
    *    @jcctype              JC Cost Type
    *    @slchangeorder        Change Order # on existing batch entry or next available #
    *    @allowunitcostchange  'Y'=allow unit cost change, 'N' = not allowed
    *    @curlessaddons        SL current total cost excluding addon Items
    *    @calcaddon            Calculated amount for addon
    *	 @SLItemExist		   SL Item Exists (Y/N)
	*	@origtax				SLIT ! OrigTax
	*	@curtax					SLIT ! CurTax
	*	@invtax					SLIT ! InvTax
	*	@taxcode				SLIT ! taxcode
    *    @msg                  Item description or error message
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/   
       (@slco bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @batchseq int,
        @sl VARCHAR(30) = NULL, --bSL = null, DC #135813
        @slitem bItem = null,@itemtype tinyint output, @addon bPct output,
        @origunits bUnits output, @curunits bUnits output, @invunits bUnits output, @remunits bUnits output,
        @origunitcost bUnitCost output, @curunitcost bUnitCost output, @origitemtot bDollar output,
        @curitemtot bDollar output, @invitemtot bDollar output, @remitemtot bDollar output,
        @um bUM output, @jcco bCompany output, @job bJob output, @phase bPhase output, @jcctype bJCCType output,
        @slchangeorder smallint output, @allowunitcostchange bYN output, @curlessaddons bDollar output,
        @calcaddon bDollar output, @slitemexist bYN output, 
		@origtax bDollar output, @curtax bDollar output, @invtax bDollar output, --DC #128435
		@taxcode varchar(10) output, --DC #128435
		@msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @inusebatchid bBatchID, @inusemth bMonth, @inuseby bVPUserName, @slchgorder smallint,
     	@source bSource
   
   select @rcode = 0, @slitemexist = 'Y'
   
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
   
   -- only allow SL or Item to be changed on new entries
   if exists(select * from bSLCB where Co = @slco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
       and BatchTransType in ('C','D') and (SL <> @sl or SLItem <> @slitem))
   		begin
		select @msg = 'Cannot change Subcontract or Item on a previously posted Change Order', @rcode = 1
     	goto bspexit
     	end
   
   -- validate SL Item and get info
   select @msg = Description, @origunits = isnull(OrigUnits,0), @curunits = isnull(CurUnits,0),
     	@invunits = isnull(InvUnits,0), @origunitcost = isnull(OrigUnitCost,0),	@curunitcost = isnull(CurUnitCost,0),
     	@origitemtot = OrigCost, @curitemtot = isnull(CurCost,0), @invitemtot = isnull(InvCost,0),
		@origtax = isnull(OrigTax,0), @curtax = isnull(CurTax,0), @invtax = isnull(InvTax,0), --DC #128435
     	@um = UM, @job = Job, @jcco = JCCo, @itemtype = ItemType, @addon = AddonPct, @phase = Phase,
       @jcctype = JCCType, @inusemth = InUseMth, @inusebatchid = InUseBatchId,
		@taxcode = TaxCode --DC #128435
   from SLIT
   where SLCo = @slco and SL = @sl and SLItem = @slitem
   if @@rowcount = 0
     	begin
     	select @msg = 'SL Item does not exist!', @rcode = 1, @slitemexist = 'N'
     	goto bspexit
     	end
   -- make sure Item is not locked by another batch
   if @inusebatchid is not null and (@inusebatchid <> @batchid or @inusemth <> @mth)
   		begin
		select @inuseby = InUseBy, @source = Source
      	from bHQBC
   		where Co = @slco and BatchId = @batchid and Mth = @mth
   		select @msg = 'SL Item already in use by ' + convert(varchar(2),DATEPART(month, @inusemth)) + '/'
           + substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4) + ' Batch # ' + convert(varchar(6),@inusebatchid)
           + ' - ' + 'Batch Source: ' + @source, @rcode = 1
		select @msg = isnull(@msg,'SL Item already in use')
   		goto bspexit
     	end
   
   -- add new Change Order entries to current amounts
   select @curunits = @curunits + isnull(sum(ChangeCurUnits),0),
          @curunitcost = @curunitcost + isnull(sum(CurUnitCost),0),
          -- restrictions on unit cost change allow us to track total cost change w/in Change Order
          @curitemtot = @curitemtot + isnull(sum(ChangeCurCost),0)
   from bSLCB
   where Co = @slco and Mth = @mth and BatchId = @batchid and SL = @sl and SLItem = @slitem
       and BatchTransType = 'A'
   
   -- correct for Change Orders being modified in batch
   select @curunits = @curunits + isnull(sum(-OldCurUnits + ChangeCurUnits),0),
          @curunitcost = @curunitcost + isnull(sum(-OldUnitCost + CurUnitCost),0),
          -- restrictions on unit cost change allow us to track total cost change w/in Change Order
          @curitemtot = @curitemtot + isnull(sum(-OldCurCost + ChangeCurCost),0)
   from bSLCB
   where Co = @slco and Mth = @mth and BatchId = @batchid and SL = @sl and SLItem = @slitem
       and BatchTransType = 'C'
   
   -- back out Change Orders flagged for deletion in batch
   select @curunits = @curunits  - isnull(sum(OldCurUnits),0),
          @curunitcost = @curunitcost - isnull(sum(OldUnitCost),0),
          -- restrictions on unit cost change allow us to track total cost change w/in Change Order
          @curitemtot = @curitemtot - isnull(sum(OldCurCost),0)
   from bSLCB
   where Co = @slco and Mth = @mth and BatchId = @batchid and SL = @sl and SLItem = @slitem
       and BatchTransType = 'D'
   
   -- calculate remaining units and cost including Change Orders in batch
   select @remunits = @curunits - @invunits, @remitemtot = @curitemtot - @invitemtot
   
   -- make sure units and unit costs are null on all lump sum items
   if @um = 'LS'
     	select @origunits = null, @curunits = null, @invunits = null, @remunits = null,
           @origunitcost = null, @curunitcost = null
   
   -- get current or next available Change Order #
   select @slchangeorder = SLChangeOrder
   from bSLCB
   where Co = @slco and Mth = @mth and BatchId = @batchid and SL = @sl
   if @@rowcount=0
		begin
     	select @slchangeorder = isnull(max(SLChangeOrder),0) + 1
		from bSLCD
		where SLCo = @slco and SL = @sl
     	end
   
   -- get Subcontract current total cost excluding Add-ons
   select @curlessaddons = isnull(sum(CurCost),0)
   from bSLIT
   where SLCo = @slco and SL = @sl and ItemType <> 4
   
   -- add new Change Order entries to current amounts
   select @curlessaddons = @curlessaddons + isnull(sum(c.ChangeCurCost),0)
   from bSLCB c
   join bSLIT i on c.Co = i.SLCo and c.SL = i.SL and c.SLItem = i.SLItem
   where c.Co = @slco and c.Mth = @mth and c.BatchId = @batchid and c.SL = @sl
       and c.BatchTransType = 'A' and i.ItemType <> 4
   
   -- correct for Change Orders being modified in batch
   select @curlessaddons = @curlessaddons + isnull(sum(-c.OldCurCost + c.ChangeCurCost),0)
   from bSLCB c
   join bSLIT i on c.Co = i.SLCo and c.SL = i.SL and c.SLItem = i.SLItem
   where c.Co = @slco and c.Mth = @mth and c.BatchId = @batchid and c.SL = @sl
       and c.BatchTransType = 'C' and i.ItemType <> 4
   
   -- back out Change Orders flagged for deletion in batch
   select @curlessaddons = @curlessaddons - isnull(sum(c.OldCurCost),0)
   from bSLCB c
   join bSLIT i on c.Co = i.SLCo and c.SL = i.SL and c.SLItem = i.SLItem
   where c.Co = @slco and c.Mth = @mth and c.BatchId = @batchid and c.SL = @sl
       and c.BatchTransType = 'D' and i.ItemType <> 4
   
   -- calculate Addon amount
   select @calcaddon = 0
   if @itemtype = 4
       begin
       -- if percent based use calculation, else use current item total
       select @calcaddon = case @addon when 0 then @curitemtot else @curlessaddons * @addon end
       end
   
   -- determine whether Item Unit Cost can be changed
   select @allowunitcostchange = 'N'
   if @um = 'LS' or @itemtype <> 2 goto bspexit   -- must be a unit based Change Order Item
   -- Item must not have any previously posted Change Orders, except the one in the batch
   if exists(select * from bSLCD where SLCo = @slco and SL = @sl and SLItem = @slitem
           and (Mth <> @mth or (Mth = @mth and isnull(InUseBatchId,0) <> @batchid))) goto bspexit
   -- Item must not have any Change Orders in the batch except the current entry
   if exists(select * from bSLCB where Co = @slco and SL = @sl and SLItem = @slitem
       and BatchSeq <> @batchseq) goto bspexit
   select @allowunitcostchange = 'Y'
   

   bspexit:
   if @rcode = 1
     	select @itemtype = null, @addon = null, @origunits = null, @curunits = null, @invunits = null,
           @remunits = null, @origunitcost = null, @curunitcost = null, @origitemtot = null,
           @curitemtot = null, @invitemtot = null, @remitemtot = null,@um = null, @jcco = null,
           @job = null, @phase = null, @jcctype = null, @slchangeorder = null, @taxcode = null
   
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLItemValRet] TO [public]
GO
