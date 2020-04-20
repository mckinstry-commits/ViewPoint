SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   /****** Object:  Stored Procedure dbo.bspPORecItemGet    Script Date: 8/28/99 9:36:30 AM ******/
   CREATE    proc [dbo].[bspPORecItemGet]
   /********************************************************
   * CREATED BY: 	KF 03/11/97
   * MODIFIED BY:	KB 03/12/99
   *                     GR 01/21/00 Corrected the calculation of InvCost if source is POChange. If the Invoiced Units
   *                                 Unit Cost is different from the Current Unit Cost then the InvCost is calculated
   *                                 based on Invoiced Units Unit Cost but not on Current Unit Cost
   *                     GR 03/13/00 Corrected the calculation of RemCost if source is POChange, and also corrected
   *                                 Invoiced cost when ECM is E, C or M
   *		
   *			GH 02/07/02 Invalid use of null error when entering POItem with null taxcode, issue #16212
   *			SR 06/14/02 - issue 16676 - Remaining Cost calc is off by a penny when using 5 decimal Unit Cost
   *			GG 06/25/02 - #16676 - Corrected Remaining Tax calculation, cleanup
   *			DC 08/23/06 - #27701 - Added PostToCo as part of the recordset returned.
   *			DC 11/3/09 - #122288 - Store Tax Rate in PO Item
   *			GF 06/08/2011 - TK-05743 bad data fix. ECM null set factor to 1
   *			TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
   *
   * USAGE:
   * 	Called by PO Change Order or Receiving Entry to return current Item values
   *	
   * INPUT PARAMETERS:
   *	@poco			PO Company number
   *	@po				PO#
   *	@poitem			PO Item#
   *	@recvddate		Receiving/Change Order Date - used for Tax Rate
   *	@source			Source - PO Change or PO Receipt
   *
   * OUTPUT PARAMETERS:
   *	none
   *
   * RETURNS:
   * 	Record set of current PO Item information
   *
   **********************************************************/   
	(@poco bCompany = 0, @po varchar(30) = null, @poitem bItem = null, @recvddate bDate = null, @source bSource = null)
     as
   
	declare @totunits bUnits, @totcost bDollar, @bounits bUnits, @bocost bDollar, @taxrate bRate,
		@errmsg varchar(30), @taxcode bTaxCode, @totunitcost bUnitCost, @tbounits bUnits,
		@ttotunits bUnits, @tcurunitcost bUnitCost, @tax varchar(20), @taxgroup bGroup,
		@invunits bUnits, @curunitcost bUnitCost, @invcost bDollar, @invunitscost bUnitCost, @factor smallint
   
	set nocount on
     
	-- Receipts
	if @source = 'PO Receipt'
		begin
   		-- get net change to Item's Received and BackOrdered Units and Cost from Receipts batch
     	select @totunits = isnull(sum(RecvdUnits),0) - isnull(sum(OldRecvdUnits),0),
     		@totcost = isnull(sum(RecvdCost),0) - isnull(sum(OldRecvdCost),0),
     		@bounits = isnull(sum(BOUnits),0) - isnull(sum(OldBOUnits),0),
     		@bocost = isnull(sum(BOCost),0) - isnull(sum(OldBOCost),0)
   		from bPORB
   		where Co = @poco and PO = @po and POItem = @poitem and BatchTransType <> 'D'	-- exclude deletes
   
   		-- back out amounts from batch entries flagged for delete
   		select @totunits = @totunits - isnull(sum(OldRecvdUnits),0),
     		@totcost = @totcost - isnull(sum(OldRecvdCost),0),
     		@bounits = @bounits - isnull(sum(OldBOUnits),0),
     		@bocost = @bocost - isnull(sum(OldBOCost),0)
   		from bPORB
   		where Co = @poco and OldPO = @po and OldPOItem = @poitem and BatchTransType = 'D'
      
     	-- get info from PO Item
     	select @taxcode = null, @taxrate = 0, @factor = 1
     	select @taxcode = TaxCode, @taxgroup = TaxGroup,
     		---- TK-05743
   			@factor = case CurECM when 'M' then 1000 when 'C' then 100 when 'E' then 1 ELSE 1 end,
   			@taxrate = TaxRate  --DC #122288
   		from bPOIT
   		where POCo = @poco and PO = @po and POItem = @poitem and RecvYN = 'Y'	-- Item must be flagged for Receiving
   
   		/*DC #122288
   		-- get current Tax Rate based on Receiving Date
     	if not @taxcode is null
     		begin
     		exec bspHQTaxRateGet @taxgroup, @taxcode, @recvddate, @taxrate output, @taxphase output,
     		@taxjcct output, @errmsg output
     		end
     	*/
   
   		-- create recordset of Item values 
     	select 	PostToCo, 'ItemType' = ItemType, 'Material' = Material, 'UM' = UM, 'Loc' = Loc,
     		'Job' = Job, 'Phase' = Phase, 'JCCType' = JCCType, 'Equip' = Equip,
     		'CostCode' = CostCode, 'EMCType' = EMCType, 'WO' = WO, 'WOItem' = WOItem,
     		'GLCo' = GLCo, 'GLAcct' = GLAcct, 'TaxCode' = isnull(TaxCode,''), 'TaxGroup' = isnull(TaxGroup,''),
     		'OrigUnits' = OrigUnits, 'OrigUnitCost' = OrigUnitCost, 'OrigECM' = OrigECM, 'OrigCost' = OrigCost,
   			'OrigTax' = OrigTax, 'CurUnits' = CurUnits, 'CurUnitCost' = CurUnitCost, 'CurECM' = CurECM,
   			'CurCost' = CurCost, 'CurTax' = CurTax, 'RecvdUnits' = (RecvdUnits+@totunits),
   			'RecvdCost'= case UM when 'LS' then (RecvdCost+@totcost) else ((RecvdUnits+@totunits)*CurUnitCost)/@factor end,
     		'BOUnits' = (BOUnits+@bounits),
   			'BOCost'= case UM when 'LS' then (BOCost+@bocost) else ((BOUnits+@bounits)*CurUnitCost)/@factor end,
     		'TotalUnits' = (BOUnits+@bounits+RecvdUnits+@totunits),
   			'TotalCost'= case UM when 'LS' then (BOCost+@bocost+RecvdCost+@totcost)
   			else ((BOUnits+@bounits+RecvdUnits+@totunits)*CurUnitCost)/@factor end, 
     		'TotalTax'= case when UM = 'LS' then (@taxrate*(@bocost+BOCost+@totcost+RecvdCost))
   			else (@taxrate*(((BOUnits+@bounits+RecvdUnits+@totunits)*CurUnitCost)/@factor)) end,
   			'InvUnits' = InvUnits, 'InvCost' = InvCost, 'InvTax' = InvTax,
   			'RemUnits'=(BOUnits+@bounits+RecvdUnits+@totunits-InvUnits),
     		'RemCost'= case when UM = 'LS' then (BOCost+@bocost+RecvdCost+@totcost-InvCost)
   			else(((BOUnits+@bounits+RecvdUnits+@totunits-InvUnits)*CurUnitCost)/@factor) end,
   		--(Issue 16676)((T.BOUnits+@bounits+T.RecvdUnits+@totunits)*T.CurUnitCost)-T.InvCost -- don't use InvCost
     		'RemTax'= case when UM = 'LS' then @taxrate*(BOCost+@bocost+RecvdCost+@totcost-InvCost)
   			else (@taxrate*(((BOUnits+@bounits+RecvdUnits+@totunits-InvUnits)*CurUnitCost)/@factor)) end
   		-- #16676 (@taxrate*(@bocost+BOCost))+((@taxrate*(@totcost+T.RecvdCost))-T.InvTax) -- don't use InvTax
     	from bPOIT
   		where POCo = @poco and PO = @po and POItem = @poitem
   	end
   
	-- Change Orders
	if @source = 'PO Change'
		begin
    	select @totunits = 0, @totcost = 0, @totunitcost = 0, @bounits = 0, @bocost = 0,
   			@invunits = 0, @curunitcost = 0, @invunitscost = 0, @invcost = 0
   
   		-- get net change to Item's Units and Cost from Change Order batch
     	select @totunits = isnull(sum(ChangeCurUnits),0) - isnull(sum(OldCurUnits),0),
   			@totcost = isnull(sum(ChangeCurCost),0) - isnull(sum(OldCurCost),0),
     		@totunitcost = isnull(sum(CurUnitCost),0) - isnull(sum(OldUnitCost),0),
   			@bounits = isnull(sum(ChangeBOUnits),0) - isnull(sum(OldBOUnits),0),
     		@bocost = isnull(sum(ChangeBOCost),0) - isnull(sum(OldBOCost),0)
     	from bPOCB
   		where Co = @poco and PO = @po and POItem = @poitem and BatchTransType <> 'D'
   
   		-- back out amounts from batch entries flagged for delete
    	select @totunits = @totunits - isnull(sum(OldCurUnits),0),
    		@totcost = @totcost - isnull(sum(OldCurCost),0),
     		@totunitcost = @totunitcost - isnull(sum(OldUnitCost),0),
    		@bounits = @bounits - isnull(sum(OldBOUnits),0),
     		@bocost = @bocost - isnull(sum(OldBOCost),0)
   		from bPOCB
   		where Co = @poco and OldPO = @po and OldPOItem = @poitem and BatchTransType = 'D'
    
     	-- get Item info from PO Item 
     	select @taxcode = null, @taxrate = 0, @factor = 1
     	select @taxcode = TaxCode, @taxgroup = TaxGroup,
     		---- TK-05743
   			@factor = case CurECM when 'M' then 1000 when 'C' then 100 when 'E' then 1 ELSE 1 end,
   			@taxrate = TaxRate   --DC #122288
     	from bPOIT
   		where POCo = @poco and PO = @po and POItem = @poitem
   
		/* DC 122288
   		-- get tax rate based on change order date
     	if not @taxcode is null
     		begin
     		exec bspHQTaxRateGet @taxgroup, @taxcode, @recvddate, @taxrate output, @taxphase output,
     		@taxjcct output, @errmsg output
     		end
     	*/
   
   		-- create recordset of Item values
     	select PostToCo, 'ItemType' = ItemType, 'Material' = Material, 'UM' = UM, 'Loc' = Loc, 'Job' = Job,
   			'Phase' = Phase, 'JCCType' = JCCType, 'Equip' = Equip, 'CostCode' = CostCode, 'EMCType' = EMCType,
   			'WO' = WO, 'WOItem' = WOItem, 'GLCo' = GLCo, 'GLAcct' = GLAcct, 'TaxCode' = isnull(TaxCode,''),
   			'TaxGroup' = isnull(TaxGroup,''), 'OrigUnits' = OrigUnits, 'OrigUnitCost' = OrigUnitCost,
   			'OrigECM' = OrigECM, 'OrigCost' = OrigCost, 'OrigTax' = OrigTax, 'CurUnits' = CurUnits+@totunits,
   			'CurUnitCost' = CurUnitCost+@totunitcost, 'CurECM' = CurECM,
   			'CurCost'= case when UM = 'LS' then (CurCost+@totcost)
   			else ((CurUnits+@totunits)*(CurUnitCost+@totunitcost))/@factor end,
   			'CurTax'= case when UM = 'LS' then (CurCost+@totcost)*@taxrate
   			else ((CurUnits+@totunits)*(CurUnitCost+@totunitcost)/@factor)*@taxrate end,
     		'RecvdUnits' = RecvdUnits,
     		'RecvdCost'= case when UM = 'LS' then RecvdCost
   			else RecvdUnits*(CurUnitCost+@totunitcost)/@factor end,
     		'BOUnits' = BOUnits+@bounits,
   			'BOCost'= case when UM = 'LS' then BOCost+@bocost
   			else(BOUnits+@bounits)*(CurUnitCost+@totunitcost)/@factor end,
     		'TotalUnits' = BOUnits+@bounits+RecvdUnits, 
   			'TotalCost'= case when UM = 'LS' then BOCost+@bocost+RecvdCost
   			else (BOUnits+@bounits+RecvdUnits)*(CurUnitCost+@totunitcost)/@factor end,
     		'TotalTax'= case when UM = 'LS' then (@bocost+BOCost+RecvdCost) * @taxrate
   			else (@bounits+BOUnits+RecvdUnits) * (CurUnitCost+@totunitcost)/@factor * @taxrate end,
     		'InvUnits' = InvUnits, 'InvCost' = InvCost, 'InvTax' = InvTax,
     		'RemUnits' = (BOUnits+@bounits+RecvdUnits-InvUnits),
     		'RemCost'= case when UM = 'LS' then (BOCost+@bocost+RecvdCost-InvCost)
   			else ((BOUnits+@bounits+RecvdUnits-InvUnits)*(CurUnitCost+@totunitcost))/@factor end,
   			'RemTax'= case when UM = 'LS' then (@taxrate * (BOCost+@bocost+RecvdCost-InvCost))
   			else @taxrate * (((BOUnits+@bounits+RecvdUnits-InvUnits)*(CurUnitCost+@totunitcost))/@factor) end
     		-- #16676 'RemTax'= case when UM = 'LS' then (@taxrate * (@bocost+BOCost))+(@taxrate * T.RecvdCost)-T.InvTax
     	from bPOIT
   		where POCo = @poco and PO = @po and POItem = @poitem
     	end
   
   bspexit:
   	return

GO
GRANT EXECUTE ON  [dbo].[bspPORecItemGet] TO [public]
GO
