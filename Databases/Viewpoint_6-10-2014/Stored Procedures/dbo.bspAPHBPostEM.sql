SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspAPHBPostEM    Script Date: 8/28/99 9:35:59 AM ******/
   CREATE  procedure [dbo].[bspAPHBPostEM]
/***********************************************************
* CREATED BY:	JM	06/17/1999
* MODIFIED By:	GG	07/02/1999
*				GG	06/20/2000	- Modified to update tax info to bEMCD
*				GG	11/27/2000	- changed datatype from bAPRef to bAPReference
*				kb	10/28/2002	- issue #18878 - fix double quotes
*				GF	08/11/2003	- issue #22112 - performance improvements
*				MV	11/26/2003	- #23061 isnull wrap
*				GF	08/04/2011	- TK-07144 expand PO
*				CHS	08/11/2011	- TK-07620
*
* USAGE: Called from the bspAPHBPost procedure to post EM distributions
*	tracked in bAPEM.  Interface level to EM is as signed in bAPCO.
*
* Interface levels:
*	0      No update of actual units or costs to EM.
*	1      Interface at the transaction line level.  Each line on an invoice
*		creates a bEMCD entry.
*	2      Interface at the transaction level.  All lines  on a transaction
*		posted to the same equipment, cost code, and cost type will be summarized
*		into a single bEMCD entry.
*
* INPUT PARAMETERS
*	@co			    AP Co#
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
    (@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null,
    	@errmsg varchar(255) output)
    
    as
    set nocount on
    
    declare @apline smallint, @apref bAPReference, @aptrans bTrans, @component bEquip, @comptype varchar(10),
    	@costcode bCostCode, @ecm bECM, @emco bCompany, @emctype bEMCType, @emgroup bGroup, @eminterfacelvl tinyint,
    	@emtrans bTrans, @emum bUM,	@emunits bUnits, @equip bEquip,	@glacct bGLAcct, @glco bCompany, @invdate bDate,
    	@linedesc bDesc, @material bMatl, @matlgroup bGroup, @msg varchar(200), @oldnew tinyint, @openLvl1cursor tinyint,
    	@openLvl2cursor tinyint, @po VARCHAR(30), @poitem bItem, @POItemLine int, 
    	@rcode int, @seq int, @totalcost bDollar, @transdesc bDesc,
    	@um bUM, @unitcost bUnitCost, @units bUnits, @vendor bVendor, @vendorgroup bGroup, @wo bWO, @woitem bItem,
        @taxtype tinyint, @taxgroup bGroup, @taxcode bTaxCode, @taxbasis bDollar, @taxrate bRate, @taxamt bDollar
    
    select @rcode = 0, @openLvl1cursor = 0, @openLvl2cursor = 0
    
   -- get EM interface level
   select @eminterfacelvl = EMInterfaceLvl from bAPCO with (nolock) where APCo = @co
    
   -- EM Interface Level 0 = No Update
   if @eminterfacelvl = 0
   	begin
    	delete from bAPEM where APCo = @co and Mth = @mth and BatchId = @batchid
   	goto bspexit
    	end
    
   -- EM Interface Level = 1 - Line - One entry in bEMCD per Equip/CostCode/EMCType/APTrans/APLine
   if @eminterfacelvl = 1
   	begin
   	declare bcLvl1 cursor LOCAL FAST_FORWARD 
   	for select EMCo, Equip, EMGroup, CostCode, EMCType, BatchSeq, APLine, OldNew, APTrans, VendorGroup,
   			Vendor, APRef, InvDate, PO, POItem, POItemLine, WO, WOItem, CompType, Component, MatlGroup, Material,
   			LineDesc, GLCo, GLAcct, UM, Units, UnitCost, ECM, TotalCost, TaxGroup, TaxCode, TaxType,
   			TaxBasis, TaxAmt
   	from bAPEM
   	where APCo = @co and Mth = @mth and BatchId = @batchid
    
   	-- open cursor
   	open bcLvl1
   	select @openLvl1cursor = 1
   	 
   	-- loop through all rows in cursor
   	lvl1_posting_loop:
   	 
   	fetch next from bcLvl1 into @emco, @equip, @emgroup, @costcode, @emctype, @seq, @apline,
   			@oldnew, @aptrans, @vendorgroup, @vendor, @apref, @invdate, @po, @poitem, @POItemLine, @wo, @woitem,
   			@comptype, @component, @matlgroup, @material, @linedesc, @glco, @glacct, @um, @units, @unitcost,
   			@ecm, @totalcost, @taxgroup, @taxcode, @taxtype, @taxbasis, @taxamt
   	 
   	if @@fetch_status = -1 goto lvl1_posting_end
   	if @@fetch_status <> 0 goto lvl1_posting_loop
    
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
   		insert bEMCD (EMCo, Mth, EMTrans, BatchId, EMGroup, Equipment, Component, ComponentTypeCode,
   				WorkOrder, WOItem, CostCode, EMCostType, PostedDate, ActualDate, Source, EMTransType,  
   				Description, GLCo, GLTransAcct, ReversalStatus, APCo, APTrans, APLine, VendorGrp, APVendor, 
   				APRef, MatlGroup, Material, UM, Units, Dollars, UnitPrice, PerECM, TaxType, TaxCode, 
   				TaxGroup, TaxBasis, TaxRate, TaxAmount, CurrentHourMeter, CurrentTotalHourMeter, 
   				CurrentOdometer, CurrentTotalOdometer, PO, POItem)
   		values (@emco, @mth, @emtrans, @batchid, @emgroup, @equip, @component, @comptype, 
   				@wo, @woitem, @costcode, @emctype, @dateposted, @invdate, 'AP', 'AP', @linedesc, 
   				@glco, @glacct, 0, @co, @aptrans, @apline, @vendorgroup, @vendor, @apref, @matlgroup, 
   				@material, @um, @units, @totalcost, @unitcost, @ecm, @taxtype, @taxcode, @taxgroup, 
   				@taxbasis, @taxrate, @taxamt, 0, 0, 0, 0, @po, @poitem)
   		if @@error <> 0 
   			begin
   			select @errmsg ='Cannot insert into bEMCD'
   			goto lvl1_posting_error
   	 		end
   		end
    
          
   	-- delete current row from cursor
   	delete bAPEM where APCo = @co and Mth = @mth and BatchId = @batchid and EMCo = @emco
   	and Equip = @equip and EMGroup = @emgroup and CostCode = @costcode and EMCType = @emctype 
   	and BatchSeq = @seq and APLine = @apline and OldNew = @oldnew
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
    
   
   -- EM Interface Level = 2 - Transaction - One entry in EMCD per Equip/CostCode/EMCType/APTrans
   if @eminterfacelvl = 2
   	begin
   	declare bcLvl2 cursor LOCAL FAST_FORWARD
   	for select EMCo, Equip, EMGroup, CostCode, EMCType, BatchSeq, APTrans, VendorGroup,
   		Vendor, APRef, TransDesc, InvDate, EMUM, TaxGroup, TaxCode, TaxType,
     	   	convert(numeric(12,3), sum(EMUnits)), convert(numeric(12,2), sum(TotalCost)),
   		convert(numeric(12,2), sum(TaxBasis)), convert(numeric(12,2), sum(TaxAmt))
     	from bAPEM
    	where APCo = @co and Mth = @mth and BatchId = @batchid
    	group by EMCo, Equip, EMGroup, CostCode, EMCType, BatchSeq, APTrans, VendorGroup,
   			Vendor, APRef, TransDesc, InvDate, EMUM, TaxGroup, TaxCode, TaxType
    
   	-- open cursor
        open bcLvl2
        select @openLvl2cursor = 1
    
   	-- loop through all rows in cursor 
   	lvl2_posting_loop:
    
   	fetch next from bcLvl2 into @emco, @equip, @emgroup, @costcode, @emctype, @seq,
   		@aptrans, @vendorgroup, @vendor, @apref, @transdesc, @invdate, @emum, 
    	    @taxgroup, @taxcode, @taxtype,@emunits, @totalcost, @taxbasis, @taxamt
    
   	if @@fetch_status = -1 goto lvl2_posting_end
   	if @@fetch_status <> 0 goto lvl2_posting_loop
    
   	-- calculate Unit Cost
   	select @unitcost = 0, @ecm = 'E'
   	if @emunits <> 0 select @unitcost = @totalcost / @emunits
    
   	-- get tax rate
   	select @taxrate = null
   	if @taxcode is not null
   		begin
   		exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @invdate, @taxrate = @taxrate output, @msg = @msg output
   		if @rcode <> 0
   			begin
   			select @errmsg = 'Unable to get Tax Rate. ' +isnull(@msg,''), @rcode = 1
   			goto bspexit
   			end
   		end
    
   	begin transaction
    
   	--add EM Cost Detail
   	if @emunits <> 0 or @totalcost <> 0
   		begin
   		-- get next available transaction # for EMCD
   		exec @emtrans = bspHQTCNextTrans 'bEMCD', @emco, @mth, @msg output
   		if @emtrans = 0
   			begin
   			select @errmsg = 'Unable to update EM Cost Detail.  ' + isnull(@msg,''), @rcode=1
   			goto lvl2_posting_error
   			end
    
   		-- add EM Cost Detail entry
   		insert bEMCD (EMCo, Mth, EMTrans, BatchId, EMGroup, Equipment, CostCode, EMCostType, PostedDate,
   				ActualDate, Source, EMTransType, Description, ReversalStatus, APCo, APTrans, VendorGrp, 
   				APVendor, APRef, UM, Units, Dollars, UnitPrice, PerECM, TaxType, TaxCode, TaxGroup, 
   				TaxBasis, TaxRate, TaxAmount, CurrentHourMeter, CurrentTotalHourMeter, CurrentOdometer, 
   				CurrentTotalOdometer)
   		values (@emco, @mth, @emtrans, @batchid, @emgroup, @equip, @costcode, @emctype, @dateposted,
   				@invdate, 'AP', 'AP', @transdesc, 0, @co, @aptrans, @vendorgroup, @vendor, @apref, @emum,
   				@emunits, @totalcost, @unitcost, @ecm, @taxtype, @taxcode, @taxgroup, @taxbasis, @taxrate, 
   				@taxamt, 0, 0, 0 ,0)
   		end
    
   	-- delete current row from cursor
      	delete from bAPEM where APCo = @co and Mth = @mth and BatchId = @batchid and EMCo = @emco and Equip = @equip
                and EMGroup = @emgroup and CostCode = @costcode and EMCType = @emctype and
                BatchSeq = @seq and isnull(APTrans,0) = isnull(@aptrans,0) and VendorGroup = @vendorgroup
                and Vendor = @vendor and isnull(APRef,'') = isnull(@apref,'')
                and isnull(TransDesc,'') = isnull(@transdesc,'') and InvDate = @invdate and EMUM = @emum
                and isnull(TaxGroup,0) = isnull(@taxgroup,0) and isnull(TaxCode,'') = isnull(@taxcode,'')
                and isnull(TaxType,0) = isnull(@taxtype,0)
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'Unable to remove posted distributions from APEM.', @rcode = 1
   		goto lvl2_posting_error
   		end
    
   	commit transaction
    
   	goto lvl2_posting_loop
    
   	lvl2_posting_error:
   		rollback transaction
   		goto bspexit
    
   	lvl2_posting_end:       -- finished with EM interface level 2 - Transaction
   		close bcLvl2
   		deallocate bcLvl2
   		select @openLvl2cursor = 0
   
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
   
   	if @rcode <> 0 select @errmsg = isnull(@errmsg,'') + ' [bspAPHBPostEM]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPHBPostEM] TO [public]
GO
