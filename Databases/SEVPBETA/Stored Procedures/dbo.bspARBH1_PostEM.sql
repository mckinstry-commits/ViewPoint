SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBH1_PostEM    Script Date: 08/13/01 12:00:59 AM ******/
   CREATE procedure [dbo].[bspARBH1_PostEM]
   /*****************************************************************************************
   * CREATED BY: 	TJL 08/13/01, Preliminary, certain to need more work when we see how customers use this
   * MODIFIED By : TJL 04/30/04 - Issue #24480, Added 'with (nolock)' 
   *               
   *
   * USAGE: Called from the bspARBHPost_Cash procedure to post EM distributions
   *	tracked in bARBE.  Interface level to EM is as assigned in bARCO.
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
   *	@co			ARCo#
   *	@mth			Batch month
   *	@batchid		Batch ID#
   *	@dateposted	    	Posting date
   *
   * OUTPUT PARAMETERS
   *	@errmsg		    Message used for errors
   *
   * RETURN VALUE
   *	0	success
   *	1	fail
   **********************************************************************************/
   
   (@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @Source bSource,
   	@errmsg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @arline smallint, @artrans bTrans, @component bEquip, @comptype varchar(10),
   	@costcode bCostCode, @ecm bECM, @emco bCompany, @emctype bEMCType, @emgroup bGroup, @eminterfacelvl tinyint,
   	@emtrans bTrans, @emum bUM,	@emunits bUnits, @equip bEquip, @glacct bGLAcct, @glco bCompany, @transdate bDate,
   	@linedesc bDesc, @material bMatl, @matlgroup bGroup, @msg varchar(200), @oldnew tinyint, @openLvl1cursor tinyint,
   	@openLvl2cursor tinyint, @rcode int, @seq int, @totalcost bDollar, @transdesc bDesc, 
   	@um bUM, @unitcost bUnitCost, @units bUnits, 
   	@taxtype tinyint, @taxgroup bGroup, @taxcode bTaxCode, @taxbasis bDollar, @taxrate bRate, @taxamt bDollar
   
   select @rcode = 0, @openLvl1cursor = 0, @openLvl2cursor = 0
   
   /* get EM interface level */
   select @eminterfacelvl = EMInterface 
   from bARCO with (nolock)
   where ARCo = @co
   
   /* EM Interface Level 0 = No Update */
   if @eminterfacelvl = 0		
   	begin
   	delete from bARBE where ARCo = @co and Mth = @mth and BatchId = @batchid
   	goto bspexit
   	end
   
   /* EM Interface Level = 1 Line - One entry in bEMCD per Equip/CostCode/EMCType/ARTrans/ARLine */
   if @eminterfacelvl = 1
   	begin
   	declare bcLvl1 cursor for
   	select EMCo, Equip, EMGroup, CostCode, EMCType, BatchSeq, ARLine, OldNew, ARTrans, TransDate,
       	CompType, Component, LineDesc, GLCo, GLAcct, EMUM, EMUnits, UnitCost, TotalCost, 
   		TaxGroup, TaxCode, TaxBasis, TaxAmt
   	from bARBE with (nolock)
   	where ARCo = @co and Mth = @mth and BatchId = @batchid
   
   	/* open cursor */
   	open bcLvl1
   	select @openLvl1cursor = 1
   
   	/* loop through all rows in cursor */
   lvl1_posting_loop:
   
   	fetch next from bcLvl1 into @emco, @equip, @emgroup, @costcode, @emctype, @seq, @arline, @oldnew, @artrans, @transdate, 
   		@comptype, @component, @linedesc, @glco, @glacct, @um, @units, @unitcost, @totalcost, 
   		@taxgroup, @taxcode, @taxbasis, @taxamt
   
   	if @@fetch_status = -1 goto lvl1_posting_end
   	if @@fetch_status <> 0 goto lvl1_posting_loop
   
   	-- get tax rate
   	select @taxrate = null
   	if @taxcode is not null
   		begin
   		exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @transdate, @taxrate = @taxrate output, @msg = @msg output
   		if @rcode <> 0
       		begin
       		select @errmsg = 'Unable to get Tax Rate. ' + isnull(@msg,''), @rcode = 1
       		goto bspexit
       		end
   		end
   
   	begin transaction
   
   	/* add EM Cost Detail */
   	if @units <> 0 or @totalcost <> 0
   		begin
   		/* get next available transaction # for EMCD */
   
       	exec @emtrans = bspHQTCNextTrans 'bEMCD', @emco, @mth, @msg output
        	if @emtrans = 0
          		begin
            	select @errmsg = 'Unable to update EM Cost Detail.  ' + isnull(@msg,''), @rcode=1
           	goto lvl1_posting_error
   	     	end
   
        	/* add EM Cost Detail entry */
        	insert bEMCD (EMCo, Mth, EMTrans, BatchId, EMGroup, Equipment, Component,
           	ComponentTypeCode, CostCode, EMCostType, PostedDate,
            	ActualDate, Source, EMTransType,  Description, GLCo, GLTransAcct, ReversalStatus, UM, Units,
             	Dollars, UnitPrice, PerECM, TaxType, TaxCode, TaxGroup, TaxBasis, TaxRate, TaxAmount,
              	CurrentHourMeter, CurrentTotalHourMeter, CurrentOdometer, CurrentTotalOdometer)
   		values (@emco, @mth, @emtrans, @batchid, @emgroup, @equip, @component,
            	@comptype, @costcode, @emctype, @dateposted,
            	@transdate, @Source, 'AR', @linedesc, @glco, @glacct, 0, @um, isnull(@units,0),
             	@totalcost, isnull(@unitcost,0), null, null, @taxcode, @taxgroup, @taxbasis, @taxrate, @taxamt,
             	0, 0, 0, 0)
   
         	if @@error <> 0 
   			begin
   			select @errmsg ='Cannot insert into bEMCD'
   			goto lvl1_posting_error
   			end
   		end
         
     	/* delete current row from cursor */
   	delete bARBE
   	where ARCo = @co and Mth = @mth and BatchId = @batchid and EMCo = @emco
       	and Equip = @equip and EMGroup = @emgroup and CostCode = @costcode
       	and EMCType = @emctype and BatchSeq = @seq and ARLine = @arline
       	and OldNew = @oldnew
    	if @@rowcount <> 1
       	begin
    	 	select @errmsg = 'Unable to remove posted distributions from ARBE.', @rcode = 1
     	  	goto lvl1_posting_error
    		end
   
   	commit transaction
   
   	goto lvl1_posting_loop
   
   lvl1_posting_error:
   	rollback transaction
   	goto bspexit
   
   lvl1_posting_end:       /* finished with EM interface level 1 - Line */
   	close bcLvl1
   	deallocate bcLvl1
   	select @openLvl1cursor = 0
   
   	end
   
   /* EM Interface Level = 2 Transaction - One entry in EMCD per Equip/CostCode/EMCType/ARTrans */
   if @eminterfacelvl = 2		-- Currently not used by AR
   	begin
   	declare bcLvl2 cursor for
   	select EMCo, Equip, EMGroup, CostCode, EMCType, BatchSeq, ARTrans, 
       	TransDesc, TransDate, EMUM, TaxGroup, TaxCode, 
    	   	convert(numeric(12,3), sum(EMUnits)), convert(numeric(12,2), sum(TotalCost)),
       	convert(numeric(12,2), sum(TaxBasis)), convert(numeric(12,2), sum(TaxAmt))
    	from bARBE with (nolock)
   	where ARCo = @co and Mth = @mth and BatchId = @batchid
   	group by EMCo, Equip, EMGroup, CostCode, EMCType, BatchSeq, ARTrans, 
       	TransDesc, TransDate, EMUM, TaxGroup, TaxCode
   
     	/* open cursor */
     	open bcLvl2
     	select @openLvl2cursor = 1
   
      	/* loop through all rows in cursor */
   lvl2_posting_loop:
   	fetch next from bcLvl2 into @emco, @equip, @emgroup, @costcode, @emctype, @seq, @artrans, 
    		@transdesc, @transdate, @emum, @taxgroup, @taxcode, @emunits, @totalcost, @taxbasis, @taxamt
   
   	if @@fetch_status = -1 goto lvl2_posting_end
   	if @@fetch_status <> 0 goto lvl2_posting_loop
   
   	/* calculate Unit Cost */
   	select @unitcost = 0, @ecm = 'E'
   	if @emunits <> 0 select @unitcost = @totalcost / @emunits
   
   	-- get tax rate
   	select @taxrate = null
   	if @taxcode is not null
       	begin
      		exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @transdate, @taxrate = @taxrate output, @msg = @msg output
   		if @rcode <> 0
       		begin
       		select @errmsg = 'Unable to get Tax Rate. ' + isnull(@msg,''), @rcode = 1
       		goto bspexit
       		end
             
     		end
   
    	begin transaction
   
   	/* add EM Cost Detail */
   	if @emunits <> 0 or @totalcost <> 0
       	begin
       	/* get next available transaction # for EMCD */
        	exec @emtrans = bspHQTCNextTrans 'bEMCD', @emco, @mth, @msg output
    		if @emtrans = 0
       		begin
           	select @errmsg = 'Unable to update EM Cost Detail.  ' + isnull(@msg,''), @rcode=1
       		goto lvl2_posting_error
           	end
   
  
   		/* add EM Cost Detail entry */
     
       	insert bEMCD (EMCo, Mth, EMTrans, BatchId, EMGroup, Equipment, CostCode, EMCostType, PostedDate,
           	ActualDate, Source, EMTransType, Description, ReversalStatus, UM, Units, Dollars, UnitPrice,
           	PerECM, TaxType, TaxCode, TaxGroup, TaxBasis, TaxRate, TaxAmount,
             	CurrentHourMeter, CurrentTotalHourMeter, CurrentOdometer, CurrentTotalOdometer)
          	values (@emco, @mth, @emtrans, @batchid, @emgroup, @equip, @costcode, @emctype, @dateposted,
              	@transdate, @Source, 'AR', @transdesc, 0, @emum, isnull(@emunits,0), @totalcost, isnull(@unitcost,0),
            	@ecm, null, @taxcode, @taxgroup, @taxbasis, @taxrate, @taxamt,
             	0, 0, 0 ,0)
       	end
   
      	/* delete current row from cursor */
     	delete from bARBE
     	where ARCo = @co and Mth = @mth and BatchId = @batchid and EMCo = @emco and Equip = @equip
        	and EMGroup = @emgroup and CostCode = @costcode and EMCType = @emctype and
          	BatchSeq = @seq and isnull(ARTrans,0) = isnull(@artrans,0) and isnull(TransDesc,'') = isnull(@transdesc,'')
          	and TransDate = @transdate and EMUM = @emum and isnull(TaxGroup,0) = isnull(@taxgroup,0)
         	and isnull(TaxCode,'') = isnull(@taxcode,'') and isnull(TaxType,0) = isnull(@taxtype,0)
               
     	if @@rowcount = 0
   		begin
    	  	select @errmsg = 'Unable to remove posted distributions from ARBE.', @rcode = 1
     	  	goto lvl2_posting_error
    	  	end
   
   	commit transaction
   
   	goto lvl2_posting_loop
   
   lvl2_posting_error:
     	rollback transaction
     	goto bspexit
   
   lvl2_posting_end:       /* finished with EM interface level 2 - Transaction */
   	close bcLvl2
   	deallocate bcLvl2
     	select @openLvl2cursor = 0
   	end
   
   bspexit:
       if @errmsg is not null 
   	select @errmsg=@errmsg		--+ ' [bspARBH1_PostEM]'
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
   
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARBH1_PostEM] TO [public]
GO
