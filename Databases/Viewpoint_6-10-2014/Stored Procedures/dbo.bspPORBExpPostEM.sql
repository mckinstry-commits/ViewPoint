SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPORBExpPostEM    Script Date: 8/28/99 9:35:59 AM ******/
   CREATE     procedure [dbo].[bspPORBExpPostEM]
   /***********************************************************
    * CREATED BY: DANF 04/21/01
    * MODIFIED By : DANF 08/31/01 - Issue 14506 - Check for no PO Company
    *               DANF 05/01/02 - Added Interface levels from PORH for Initializing Receipts.
    *				 GF 08/11/2003 - issue #22116 - performance improvements
    *				 DANF 09/25/03 - issue 21985 - Corrected Backingout or turning Reciept expenses.
    *				 RT 12/04/03 - #23061, use isnulls when concatenating message strings, added with (nolock)s.
    *				DC 12/17/09 - #122288 - Store Tax Rate in POIT
    *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
    *				GF 08/22/2011 TK-07879 PO ITEM LINE
    *
    *	
    * USAGE: Called from the bspPORBPost procedure to post EM distributions
    *	tracked in bPORE.  Interface level to EM is as signed in bPOCO.
    *
    * Interface levels:
    *	0      No update of actual units or costs to EM.
    *	1      Interface at the transaction level.  All lines  on a transaction
    *		posted to the same equipment, cost code, and cost type will be summarized
    *		into a single bEMCD entry.
    *
    * INPUT PARAMETERS
    *	@co			    PO Co#
    *	@mth			Batch month
    *	@batchid		Batch ID#
    *	@dateposted	    Posting date
    *
    * OUTPUT PARAMETERS
    *	@errmsg		    Message used for errors
    *
    * RETURN VALUE
    *	0	success
    *	1	fail
    *****************************************************/
   (@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @errmsg varchar(255) output)
   
   as
   set nocount on
   
   declare @apline smallint, @apref bAPReference, @aptrans bTrans, @component bEquip, @comptype varchar(10),
   		@costcode bCostCode, @ecm bECM, @emco bCompany, @emctype bEMCType, @emgroup bGroup, 
   		@eminterfacelvl tinyint, @emtrans bTrans, @emum bUM, @emunits bUnits, @equip bEquip,
   		@glacct bGLAcct, @glco bCompany, @invdate bDate, @linedesc bDesc, @material bMatl, @matlgroup bGroup, 
   		@msg varchar(200), @oldnew tinyint, @openLvl1cursor tinyint, @openLvl2cursor tinyint, @po varchar(30), 
   		@poitem bItem, @rcode int, @seq int, @totalcost bDollar, @transdesc bDesc, @um bUM, @unitcost bUnitCost, 
   		@units bUnits, @vendor bVendor, @vendorgroup bGroup, @wo bWO, @woitem bItem, @taxtype tinyint, 
   		@taxgroup bGroup, @taxcode bTaxCode, @taxbasis bDollar, @taxrate bRate, @taxamt bDollar,
       	@recdate bDate, @receiver# varchar(20), @potrans bTrans, @desc bDesc, @source bSource,
       	@oldeminterfacelvl TINYINT,
       	----TK-07879
       	@POItemLine INT
   
   select @rcode = 0, @openLvl1cursor = 0, @openLvl2cursor = 0
   
   -- get EM interface level
   select @eminterfacelvl = RecEMInterfacelvl from bPOCO with (nolock) where POCo = @co
   if @@rowcount = 0
       begin
       --- Not every one will have PO /// select @errmsg = 'Missing PO Company!', @rcode = 1
       goto bspexit
       end
   
   --   Over Ride Interface levels if Initializing Expenses from Receipts.
   select @source=Source from bHQBC with (nolock) 
   where Co = @co and Mth = @mth and BatchId = @batchid
   if isnull(@source,'') = 'PO InitRec'
   	begin
   	-- get PORH info
   	select @eminterfacelvl = RecEMInterfacelvl, @oldeminterfacelvl = OldRecEMInterfacelvl 
   	from bPORH with (nolock) 
   	where Co = @co and Mth = @mth and BatchId = @batchid
   	if @@rowcount = 0
   		begin
   		select @errmsg = ' Missing Receipt Header for Interface levels!', @rcode = 1
   		goto bspexit
   		end
       -- if turning off receipt expenses switch interface level to on for backing out receipt expenses
   	if @oldeminterfacelvl = 1 and @eminterfacelvl = 0 select @eminterfacelvl =1
   	end
   
   -- EM Interface Level 0 = No Update
   if @eminterfacelvl = 0
   	begin
   	delete from bPORE where POCo = @co and Mth = @mth and BatchId = @batchid
   	goto bspexit
   	end
   
   -- EM Interface Level = 1 - Line - One entry in bEMCD per Receiving Entry
   if @eminterfacelvl = 1
       begin
       declare bcLvl1 cursor LOCAL FAST_FORWARD
   	for select EMCo, Equip, EMGroup, CostCode, EMCType, BatchSeq, APLine, OldNew, VendorGroup,
				Vendor, POTrans, PO, POItem, WO, WOItem, CompType, Component, MatlGroup, Material,
				Description, RecDate, Receiver#, GLCo, GLAcct, UM, Units, UnitCost, ECM,
				TotalCost, TaxGroup, TaxCode, TaxType, TaxBasis, TaxAmt,
				----TK-07879
				POItemLine
       from bPORE with (nolock)
       where POCo = @co and Mth = @mth and BatchId = @batchid
   
       -- open cursor
       open bcLvl1
       select @openLvl1cursor = 1
   
       -- loop through all rows in cursor
       lvl1_posting_loop:
		fetch next from bcLvl1 into @emco, @equip, @emgroup, @costcode, @emctype, @seq, @apline,
				@oldnew, @vendorgroup, @vendor, @potrans, @po, @poitem, @wo, @woitem, @comptype, 
				@component, @matlgroup, @material, @desc, @recdate, @receiver#, @glco, @glacct, 
				@um, @units, @unitcost, @ecm, @totalcost, @taxgroup, @taxcode, @taxtype,
				@taxbasis, @taxamt,
				----TK-07879
				@POItemLine
   
   	if @@fetch_status = -1 goto lvl1_posting_end
   	if @@fetch_status <> 0 goto lvl1_posting_loop
   
   --DC #122288
   --Get tax rate from POIT
   select @taxrate = null
   select @taxrate = TaxRate from bPOIT where POCo = @co and PO = @po and POItem = @poitem
   /*
   	-- get tax rate
   	select @taxrate = null
   	if @taxcode is not null
   		begin
   		exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @invdate, @taxrate = @taxrate output, @msg = @msg output
   		if @rcode <> 0
   			begin
   			select @errmsg = 'Unable to get Tax Rate. ' + isnull(@msg,''), @rcode = 1
   			goto bspexit
   			end
   		end
   */
   	begin transaction
   
   	-- add EM Cost Detail
   	if @units <> 0 or @totalcost <> 0
   		begin
   		-- get next available transaction # for EMCD
   		exec @emtrans = bspHQTCNextTrans 'bEMCD', @emco, @mth, @msg output
   		if @emtrans = 0
   			begin
   			select @errmsg = 'Unable to update EM Cost Detail.  ' + isnull(@msg,''), @rcode=1
   			goto lvl1_posting_error
   			end
   
   		-- add EM Cost Detail entry
   		insert bEMCD (EMCo, Mth, EMTrans, BatchId, EMGroup, Equipment, Component,
				ComponentTypeCode, WorkOrder, WOItem, CostCode, EMCostType, PostedDate,
				ActualDate, Source, EMTransType,  Description, GLCo, GLTransAcct, ReversalStatus,
				APCo, VendorGrp, APVendor,  MatlGroup, Material, UM, Units,
				Dollars, UnitPrice, PerECM, TaxType, TaxCode, TaxGroup, TaxBasis, TaxRate, TaxAmount,
				CurrentHourMeter, CurrentTotalHourMeter, CurrentOdometer, CurrentTotalOdometer,
				PO, POItem,
				----TK-07879
				POItemLine)
   	    values (@emco, @mth, @emtrans, @batchid, @emgroup, @equip, @component,
				@comptype, @wo, @woitem, @costcode, @emctype, @dateposted,
				@recdate, 'PO', 'PO Receipt', @desc, @glco, @glacct, 0,
				@co, @vendorgroup, @vendor, @matlgroup, @material, @um, @units,
				@totalcost, @unitcost, @ecm, @taxtype, @taxcode, @taxgroup, @taxbasis,
				@taxrate, @taxamt, 0, 0, 0, 0, @po, @poitem,
				----TK-07879
				@POItemLine)
   
   		if @@error <> 0
   			begin
   			select @errmsg ='Cannot insert into bEMCD'
   			goto lvl1_posting_error
   			end
   		end
   
   
   	-- delete current row from cursor
   	delete bPORE where POCo = @co and Mth = @mth and BatchId = @batchid and EMCo = @emco
   	and Equip = @equip and EMGroup = @emgroup and CostCode = @costcode
   	and	EMCType = @emctype and BatchSeq = @seq and APLine = @apline and OldNew = @oldnew
   	if @@rowcount <> 1
   		begin
   		select @errmsg = 'Unable to remove posted distributions from APEM.', @rcode = 1
   		goto lvl1_posting_error
   		end
   
   	commit transaction
   
   	goto lvl1_posting_loop
   
   	lvl1_posting_error:
           rollback transaction
           goto bspexit
   
   	lvl1_posting_end:       -- finished with EM interface level 1 - Line
           close bcLvl1
           deallocate bcLvl1
           select @openLvl1cursor = 0
   
   end
   
   
   
   
   bspexit:
       if @openLvl1cursor = 1
           begin
    		close bcLvl1
    		deallocate bcLvl1
    		end
       if @openLvl2cursor = 1
           begin
    		close bcLvl2
    		deallocate bcLvl2
    		end
   
       if @rcode <> 0 select @errmsg = isnull(@errmsg,'') + ' [bspPORBExpPostEM]'
       return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPORBExpPostEM] TO [public]
GO
