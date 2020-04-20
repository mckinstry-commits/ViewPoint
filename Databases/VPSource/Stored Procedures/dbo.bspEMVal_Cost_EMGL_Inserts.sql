SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMVal_Cost_EMGL_Inserts    Script Date: 4/4/2002 11:49:00 AM ******/
CREATE       procedure [dbo].[bspEMVal_Cost_EMGL_Inserts]
/***********************************************************
* CREATED BY: JM 2/11/99
* MODIFIED By :  JM 1/17/00 - Removed Equipt Expense GLAcct and
*                           Old Equip Expense GLAcct per Darin - same as GLTransAcct/OldGLTransAcct.
*                DANF 05/3/00 Added update of gl amounts to gloffset and gltransaction
*                             accounts this will take into account where the accounts are the same
*                JM 6/13/00 - Misc corrections
*                DANF 08/15/00 - Allowed the gl accounts to be the same for all gl accounts
*                DANF 08/24/00 - Corrected error message on incorrect gl accounts.
*                DANF 09/12/01 - Corrected Intercompany accounts
*                DANF/TONYV 10/31/01 - Correct Inventory GL Offset Accounts
*                bc 01/21/02 - Issue # 15967.  Intercompany stuff again.  Hopefully this'll be the end of it.  
*	              JM 6/18/02 - Added 'select @deadchar = null, @deadnum = null' before each exec statement that uses
*		               @deadchar or @deadnum to make sure value is not inadvertently passed into procedure
*               gh 08/02/02 - Issue #18184 Changed passing of @emglco to @inglco for intercompany ar gl acct validation 
*				  GF 01/21/2003 - issue #19882 - updating GL incorrectly for old entries when changing or deleting.
*				  GF 01/27/03 - issue #20184 - Sometimes not generating distributions for  
*								old/changed values when BatchTransType='C'
*				  GF 06/13/2003 - issue #19756 if adjustments and cross-company gl verify adjustment journal exists in both.
*       		  TV 02/11/04 - 23061 added isnulls
*				  TV 06/01/04 24715 Should post for 0 amounts. Vision did
*				  TV 06/03/04 24732 - Old Inter-Co ARGLAcct is invalid error when doing intercompany EM to IN deletes
*				  TV 05/05/05 27430 - GL Account Pulls wrong when info is changed
*				  DANF 03/27/07 124222 - Correct GL Distributions when Inventory Company changes.
*				GF 09/15/2009 - issue #134513 no tax gl distribution when source = 'EMFuel'
*				TRL 02/04/2010 Issue 137916  change @description to 60 characters
*
*
* USAGE:
*	Called by bspEMVal_Cost_Main to add following account
*  distributions to bEMGL:
*
* 	    Equipt Expense GLAcct
*      Old Equip Expense GLAcct
*
*  	if @inlocation is not null
*  	Equipt Sales GLAcct
*  	Cost of Goods Sold GLAcct
*	    Matl Inv GLAcct
*
*  	if @oldinlocation is not null
*  	Old Equip Sales GLAcct
*      Old Cost of Goods Sold GLAcct
*	    Old Matl Inv GLAcct
*
*	    if @taxcode is not null
*	    Tax Accrual GLAcct
*
*	    if @oldtaxcode is not null
*	    Old Tax Accrual GLAcct
*
*	    if @inglco <> @glco
*	    Inter-Company ARGLAcct
*	    Inter-Company APGLAcct
*
*	    if @oldinglco <> @oldglco
*      Old Inter-Company ARGLAcct
*	    Old Inter-Company APGLAcct
*
* 	Errors in batch added to bHQBE using bspHQBEInsert.
*
* INPUT PARAMETERS
*	EMCo        	EM Company
*	Month       	Month of batch
*	BatchId     	Batch ID
*	BatchSeq	    Batch Sequence in psuedo-cursor
*
* OUTPUT PARAMETERS
*	@errmsg     if something went wrong
*
* RETURN VALUE
*	0   Success
*	1   Failure
*****************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @errmsg varchar(255) output

as
set nocount on
    
    --declare new stuff 
    declare @actualdate bDate,	@apglacct bGLAcct, @arglacct bGLAcct, @batchtranstype char(1), @costcode bCostCode, @costglacct bGLAcct, @description bItemDesc /*137916*/,
    @dollars bDollar, @dollars2 bDollar, @emcosttype bEMCType, @emglco bCompany, @emgroup bGroup, @emtrans bTrans, @emtranstype varchar(10),
    @equipexpenseglacct bGLAcct, @equipment bEquip, @equipsalesglacct bGLAcct, @errorstart varchar(50), @errtext varchar(255),	@glco bCompany,
    @gloffsetacct bGLAcct, @gltransacct bGLAcct,	@inco bCompany, @inglco bCompany, @inlocation bLoc, @invglacct bGLAcct,	@material bMatl, @matlgroup bGroup
    
    --declare old stuff
    declare @oldactualdate bDate, @oldapglacct bGLAcct, @oldarglacct bGLAcct, @oldcostglacct bGLAcct, @olddescription bTransDesc, @olddollars bDollar,
    @oldcostcode bCostCode,	@oldemcosttype bEMCType, @oldemgroup bGroup, @oldemtrans bTrans, @oldemtranstype varchar(10), @oldequipexpenseglacct bGLAcct,
    @oldequipment bEquip, @oldequipsalesglacct bGLAcct, @oldglco bCompany, @oldgloffsetacct bGLAcct, @oldgltransacct bGLAcct, @oldinco bCompany,
    @oldinglco bCompany, @oldinlocation bLoc, @oldinvglacct bGLAcct, @oldmaterial bMatl, @oldmatlgroup bGroup, @oldsource bSource, 
    @oldtaxaccrualglacct bGLAcct,	@oldtaxamount bDollar, @oldtaxcode bTaxCode, @oldtaxgroup bGroup, @oldtotalcost bDollar, @oldwoitem bItem,
    @oldworkorder bWO
    
    --Declare Standard stuff
    declare @rcode int, @source bSource, @taxaccrualglacct bGLAcct, @taxamount bDollar, @taxcode bTaxCode, @taxgroup bGroup, @totalcost bDollar,
    @woitem bItem, @workorder bWO, @um bUM, @oldum bUM, @units bUnits, @oldunits bUnits, @stdum bUM, @stdunits bUnits,@stdunitcost bUnitCost,
    @stdecm bECM, @inpstunitcost bUnitCost, @adjstgljrnl bJrnl,	@adjstgllvl tinyint,	@toadjstgljrnl bJrnl, @deadchar varchar(255)
    
    select @rcode = 0
    
    --Setup @errorstart string. 
    select @errorstart = 'Seq ' + isnull(convert(varchar(9),@batchseq),'') + '-'
    
    -- Fetch data from bEMBF into variables. 
    select 	@actualdate = ActualDate, 
    			@batchtranstype = BatchTransType, 
    			@costcode = CostCode, 
    			@description = Description, 
    			@dollars = isnull(Dollars,0),
    			@emcosttype = EMCostType,
    			@emgroup = EMGroup,
    			@emtrans = EMTrans,
      			@emtranstype = EMTransType,
    			@equipment = Equipment,
    			@glco = GLCo,
    			@gloffsetacct = GLOffsetAcct,
    			@gltransacct = GLTransAcct,
    			@inco = INCo,
    			@inlocation = INLocation,
    			@material = Material,
    			@matlgroup = MatlGroup,
    			@um = UM,
    			@oldum = OldUM,
    			@units = Units,
    			@oldunits = OldUnits,
    			@oldactualdate = OldActualDate,
    			@oldcostcode = OldCostCode,
    			@olddescription = OldDescription,
    			@olddollars = isnull(OldDollars,0),
    			@oldemcosttype = OldEMCostType,
    			@oldemgroup = OldEMGroup,
    			@oldemtrans = OldEMTrans,
    			@oldemtranstype = OldEMTransType,
    			@oldequipment = OldEquipment,
    			@oldglco = OldGLCo,
    			@oldgloffsetacct = OldGLOffsetAcct,
    			@oldgltransacct = OldGLTransAcct,
    			@oldinco = OldINCo,
    			@oldinlocation = OldINLocation,
    			@oldmaterial = OldMaterial,
    			@oldmatlgroup = OldMatlGroup,
    			@oldsource = OldSource,
    			@oldtaxamount = isnull(OldTaxAmount,0),
    			@oldtaxcode = OldTaxCode,
    			@oldtaxgroup = OldTaxGroup,
    			@oldtotalcost = isnull(OldTotalCost,0),
    			@oldwoitem = OldWOItem,
    			@oldworkorder = OldWorkOrder,
    			@source = Source,
    			@taxamount = isnull(TaxAmount,0),
    			@taxcode = TaxCode,
    			@taxgroup = TaxGroup,
    			@totalcost = isnull(TotalCost,0),
    			@woitem = WOItem,
    			@workorder = WorkOrder
    from bEMBF
    where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
    
    
    
    -- Make sure we have the correct GLCo from bEMCO. Can't be null there. 
    -- get EMCo information
    select @emglco=GLCo, @adjstgljrnl=AdjstGLJrnl, @adjstgllvl=AdjstGLLvl
    from bEMCO with (nolock) 
    where EMCo = @co
    
    /* ******************** */
    /* Get various GLAccts. */
    /* ******************** */
    select @inglco = @glco
    select @oldinglco = @oldglco
    
    /* ============================================================================== */
    /* Get Equipt Sales, COGS and Matl Inv GLAccts. */
    /* ============================================================================== */
    if @inlocation is not null
      begin
      select @deadchar = null
      exec @rcode = dbo.bspEMVal_Cost_Inventory @mth, @inco, @inlocation, @matlgroup, @material, @um, @units,
                     @glco, @costcode, @emcosttype, @equipment, @co,
                     @stdum output, @stdunits output, @stdunitcost output, @stdecm output, @inpstunitcost output,
                     @deadchar output, @inglco output, @equipsalesglacct output, @costglacct output, @invglacct output, @errmsg output
    	if @rcode <> 0
    		begin
    		select @errtext = isnull(@errorstart,'') + isnull(@errmsg,'')
    		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    		if @rcode <> 0
    		   	begin
    			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    			goto bspexit
    			end
    		end
    
       if (@source = 'EMAdj' and (@emtranstype = 'Fuel' or @emtranstype = 'Parts')) or (@source = 'EMParts' and @emtranstype = 'Parts')
         begin
           select @gloffsetacct = @equipsalesglacct
           Update bEMBF
           Set GLOffsetAcct = @gloffsetacct
           where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
         end
    
      end
    
    /* ============================================================================== */
    /* Get Old Equipt Sales, Old COGS and Old Matl Inv GLAccts. */
    /* ============================================================================== */
    
    if @oldinlocation is not null
      begin
      -- Changed and Old Entries 
      select @deadchar = null
      exec @rcode = dbo.bspEMVal_Cost_Inventory @mth, @oldinco, @oldinlocation, @oldmatlgroup, @oldmaterial, @oldum, @oldunits,
                    @oldglco, @oldcostcode, @oldemcosttype, @oldequipment, @co,
                    @stdum output, @stdunits output, @stdunitcost output, @stdecm output, @inpstunitcost output,
                    @deadchar output, @oldinglco output, @oldequipsalesglacct output, @oldcostglacct output, @oldinvglacct output, @errmsg output
    	if @rcode = 1
    		begin
    		select @errtext = isnull(@errorstart,'') + isnull(@errmsg,'')
    		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    		if @rcode <> 0
    			begin
    			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    			goto bspexit
    			end
    		end
      end
    
/* ****************************************************************************** */
/* Get valid Tax Accrual GLAcct from bHQTX. */
/* ****************************************************************************** */

if @source <> 'EMFuel'
	begin
	if @taxcode is not null
		begin
		select @taxaccrualglacct = GLAcct
		from bHQTX
		where TaxGroup = @taxgroup and TaxCode = @taxcode
		if @@rowcount = 0
			begin
			select @errtext = isnull(@errorstart,'') + 'No Tax Accrual GLAcct in bHQTX for TaxGroup ' +
				isnull(convert(varchar(3),@taxgroup),'') + ' and TaxCode ' + isnull(@taxcode,'') + '!'
				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
      		if @rcode <> 0
      	 		begin
				  select @rcode = 1
      	  		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
      	   		goto bspexit
      			end
			  else
				  begin
				  select @rcode = 1
					select @errmsg = @errtext
				  goto bspexit
				  end
			end
		else
			begin
			exec @rcode = bspGLACfPostable @emglco, @taxaccrualglacct, null, @errmsg output
			if @rcode = 1
				begin
				select @errtext = isnull(@errorstart,'') + 'Tax Accrual GLAcct - ' + isnull(@errmsg,'')
				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
      		if @rcode <> 0
      	 		begin
				  select @rcode = 1
      	  		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
      	   		goto bspexit
      			end
			  else
				  begin
				  select @rcode = 1
				  select @errmsg = @errtext
				  goto bspexit
				  end
				end
			end
		end
	end
	
	
/* ****************************************************************************** */
/* Get valid Old Tax Accrual GLAcct from bHQTX. */
/* ****************************************************************************** */

if @source <> 'EMFuel'
	begin
	if @oldtaxcode is not null
		begin
		select @oldtaxaccrualglacct = GLAcct
		from bHQTX
		where TaxGroup = @oldtaxgroup and TaxCode = @oldtaxcode

		if @@rowcount = 0
			begin
			select @errtext = isnull(@errorstart,'') +' No Old Tax Accrual GLAcct in bHQTX for Old TaxGroup ' +
				isnull(convert(varchar(3),@oldtaxgroup),'') + ' and Old TaxCode ' + isnull(@oldtaxcode,'') + '!'
				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
      		if @rcode <> 0
     	 		begin
				  select @rcode = 1
      	  		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
      	   		goto bspexit
      			end
			  else
				  begin
				  select @rcode = 1
				  select @errmsg = @errtext
				  goto bspexit
				  end
			end
		else
			begin
			exec @rcode = dbo.bspGLACfPostable @emglco, @oldtaxaccrualglacct, null, @errmsg output
			if @rcode = 1
				begin
				select @errtext = isnull(@errorstart,'') + 'Old Tax Accrual GLAcct invalid - ' + isnull(@errmsg,'')
				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
      		if @rcode <> 0
      	 		begin
				  select @rcode = 1
      	  		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
      	   		goto bspexit
      			end
			  else
				  begin
				  select @rcode = 1
				  select @errmsg = @errtext
				  goto bspexit
				  end
				end
			end
		end
	end
    
    
    /* ****************************************************************************** */
    /* Get interco GLAccts if necessary. */
    /* ****************************************************************************** */
    select @inglco = GLCo 
    from bINCO 
    where INCo = @inco and @inlocation is not null
    
    if @inlocation is not null and @inglco <> @glco
    	begin
    	select @arglacct = ARGLAcct, @apglacct = APGLAcct
    	from bGLIA
    	where ARGLCo = @inglco and APGLCo = @glco
    	if @arglacct is null
    		begin
    		select @errtext = isnull(@errorstart,'') +  'No Inter-Company ARGLAcct in bGLIA for ARGLCo ' +
    			isnull(convert(varchar(3),@inglco),'') + ' and APGLCo ' + isnull(convert(varchar(3),@glco),'') + '!'
    			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
          	if @rcode <> 0
          	 	begin
                  select @rcode = 1
          	  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
          	   	goto bspexit
          	    end
              else
                  begin
                  select @rcode = 1
                  select @errmsg = @errtext
                  goto bspexit
                  end
    		end
    	else
    		begin
    		exec @rcode = dbo.bspGLACfPostable @inglco, @arglacct, null, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext = isnull(@errorstart,'') +  'Inter-Co ARGLAcct invalid - ' + isnull(@errmsg,'')
    			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
          	if @rcode <> 0
          	 	begin
                  select @rcode = 1
          	  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
          	   	goto bspexit
          	    end
              else
                  begin
                  select @rcode = 1
                  select @errmsg = @errtext
                  goto bspexit
                  end
    			end
          end
    	if @apglacct is null
    		begin
    		select @errtext = 'No Inter-Company APGLAcct in bGLIA for ARGLCo ' +
    			isnull(convert(varchar(3),@inglco),'') + ' and APGLCo ' + isnull(convert(varchar(3),@glco),'') + '!'
    			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
          	if @rcode <> 0
          	 	begin
                  select @rcode = 1
          	  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
          	   	goto bspexit
          	    end
              else
                  begin
                  select @rcode = 1
                  select @errmsg = @errtext
                  goto bspexit
                  end
    		end
    	else
    		begin
    		exec @rcode = dbo.bspGLACfPostable @emglco, @apglacct, null, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext = isnull(@errorstart,'') +   'Inter-Co APGLAcct invalid - ' + isnull(@errmsg,'')
    			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
          	if @rcode <> 0
          	 	begin
                  select @rcode = 1
          	  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    
          	   	goto bspexit
          	    end
              else
                  begin
                  select @rcode = 1
                select @errmsg = @errtext
                  goto bspexit
                  end
              end
          end
      end
    
    
    /* ****************************************************************************** */
    /* Get Old interco GLAccts if necessary. */
    /* ****************************************************************************** */
    select @oldinglco = GLCo 
    from bINCO 
    where INCo = @oldinco and @oldinlocation is not null
    
    if @oldinlocation is not null and @oldinglco <> @oldglco
    	begin
    
    	select @oldarglacct = ARGLAcct,	@oldapglacct = APGLAcct
    	from bGLIA
    	where ARGLCo = @oldinglco and APGLCo = @oldglco
    	if @oldarglacct is null
    		begin
    		select @errtext = isnull(@errorstart,'')  + 'No old Inter-Company ARGLAcct in bGLIA for ARGLCo ' +
    			isnull(convert(varchar(3),@oldinglco),'') + ' and APGLCo ' + isnull(convert(varchar(3),@oldglco),'') + '!'
    			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
         	if @rcode <> 0
          	 	begin
                  select @rcode = 1
          	  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
          	   	goto bspexit
          	    end
              else
                  begin
                  select @rcode = 1
                  select @errmsg = @errtext
                  goto bspexit
                 end
    		end
    	else
    		begin
    	-- TV 06/03/04 24732 - Old Inter-Co ARGLAcct is invalid error when doing intercompany EM to IN deletes
    		exec @rcode = dbo.bspGLACfPostable @oldinglco/*@emglco*/, @oldarglacct, null, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext = isnull(@errorstart,'') +   'Old Inter-Co ARGLAcct invalid - ' + isnull(@errmsg,'')
    			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
          	if @rcode <> 0
          	 	begin
                  select @rcode = 1
          	  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
          	   	goto bspexit
          	    end
              else
                  begin
                  select @rcode = 1
                  select @errmsg = @errtext
                  goto bspexit
                  end
    			end
    		end
    	if @oldapglacct is null
    		begin
    		select @errtext = isnull(@errorstart ,'') + 'No old Inter-Company APGLAcct in bGLIA for ARGLCo ' +
    			isnull(convert(varchar(3),@oldinglco),'') + ' and APGLCo ' + isnull(convert(varchar(3),@oldglco),'') + '!'
    			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
          	if @rcode <> 0
          	 	begin
                  select @rcode = 1
          	  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
          	   	goto bspexit
          	    end
              else
                  begin
                  select @rcode = 1
                  select @errmsg = @errtext
                  goto bspexit
                  end
    		end
    	else
    		begin
    		exec @rcode = dbo.bspGLACfPostable @emglco, @oldapglacct, null, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext = isnull(@errorstart,'') + 'Old Inter-Co APGLAcct invalid - ' + isnull(@errmsg,'')
    			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
          	if @rcode <> 0
          	 	begin
                  select @rcode = 1
          	  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
          	   	goto bspexit
          	    end
              else
                  begin
                  select @rcode = 1
                  select @errmsg = @errtext
                  goto bspexit
                  end
    			end
    		end
      end
     
    --goto Change_trans
    /* ============================================================================== */
    /* Make distributions to bEMGL. */
    /* ============================================================================== */
    if (@batchtranstype <> 'C')
        or (isnull(@oldinco,'') <> isnull(@inco,'')  --added this line, issue 124215
    	or isnull(@oldgltransacct,'') <> isnull(@gltransacct,'')
    	or isnull(@oldgloffsetacct,'') <> isnull(@gloffsetacct,'')
    	or isnull(@oldtaxaccrualglacct,'') <> isnull(@taxaccrualglacct,'')
    	or @olddollars <> @dollars or @units <> @oldunits
      or @oldtaxamount <> @taxamount)
    	begin
    	/* Dont add GL distributions for 0 amounts. */
    	if @batchtranstype <> 'A' and @olddollars is not null--@olddollars <> 0
    		begin
    
    		/* Insert 'old' entry for OldGLTransAccount. */
              if @oldgltransacct is not null
              begin
              Update bEMGL
              Set Amount = Amount - (@olddollars + @oldtaxamount)
              Where EMCo=@co and Mth=@mth and BatchId=@batchid and GLCo= @glco and GLAcct=@oldgltransacct and BatchSeq=@batchseq and OldNew=0
              If @@rowcount = 0
                begin
      		  insert into bEMGL (EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq,
      			OldNew, EMTrans, Equipment, ActualDate, TransDesc,
      			Source, EMTransType, EMGroup, CostCode, EMCostType,
      			INCo, INLocation, MatlGroup, Material,
      			WorkOrder, WOItem, Amount)
      		  values (@co, @mth, @batchid, @oldglco, @oldgltransacct, @batchseq,
      			0, @oldemtrans, @oldequipment, @oldactualdate, @olddescription,
      			@oldsource, @oldemtranstype, @oldemgroup, @oldcostcode, @oldemcosttype,
      			@oldinco, @oldinlocation, @oldmatlgroup, @oldmaterial,
      			@oldworkorder, @oldwoitem, (-1 * (@olddollars + @oldtaxamount)))
      		  if @@rowcount = 0
      			begin
      			select @errtext = isnull(@errorstart,'')  + 'Unable to add EMGL audit for OldGLTransAcct = ' + isnull(@oldgltransacct,'') + '!'
      				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
              	if @rcode <> 0
              	 	begin
                      select @rcode = 1
              	  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
              	   	goto bspexit
              	    end
                  else
                      begin
                      select @rcode = 1
    					 select @errmsg = @errtext
                      goto bspexit
     end
      			end -- end insert
         end -- end update
          end
    
          /* If applicable, insert 'old' entry for OldGLOffsetAcct. */
    		if @oldgloffsetacct is not null
    			begin
              Update bEMGL
              Set Amount = Amount + (@olddollars)-- + @oldtaxamount) TV 05/05/05 27430
              Where EMCo=@co and Mth=@mth and BatchId=@batchid and GLCo=@oldinglco and GLAcct=@oldgloffsetacct and BatchSeq=@batchseq and OldNew=0
              If @@rowcount = 0
                begin
    			  insert into bEMGL (EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq,
    				OldNew, EMTrans, Equipment, ActualDate, TransDesc,
    				Source, EMTransType, EMGroup, CostCode, EMCostType,
    				INCo, INLocation, MatlGroup, Material,
    				WorkOrder, WOItem, Amount)
    			  values (@co, @mth, @batchid, @oldinglco, @oldgloffsetacct, @batchseq,
    				0, @oldemtrans, @oldequipment, @oldactualdate, @olddescription,
    				@oldsource, @oldemtranstype, @oldemgroup, @oldcostcode, @oldemcosttype,
    				@oldinco, @oldinlocation, @oldmatlgroup, @oldmaterial,
    				@oldworkorder, @oldwoitem, (@olddollars))-- + @oldtaxamount) ) TV 05/05/05 27430
    			if @@rowcount = 0
    				begin
    				select @errtext = isnull(@errorstart,'') + 'Unable to add EMGL audit for OldGLOffsetAcct = ' + isnull(@oldgloffsetacct,'') + '!'
      			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
              	if @rcode <> 0
              	 	begin
                      select @rcode = 1
    
              	  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
              	   	goto bspexit
              	    end
                  else
   
                      begin
                      select @rcode = 1
                      select @errmsg = @errtext
                      goto bspexit
                      end
    				end -- end insert
                end -- end update
    			end
    
    
    		/* Insert 'old' entry for OldCostGLAcct. */
          if @oldcostglacct is not null
              begin
              Update bEMGL
              --Set Amount = Amount - (@oldtotalcost)
    			set Amount = Amount + (@oldtotalcost)
              Where EMCo=@co and Mth=@mth and BatchId=@batchid and GLCo=@oldinglco and GLAcct=@oldcostglacct and BatchSeq=@batchseq and OldNew=0
              If @@rowcount = 0
                begin
      		  insert into bEMGL (EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq,
      			OldNew, EMTrans, Equipment, ActualDate, TransDesc,
    
      			Source, EMTransType, EMGroup, CostCode, EMCostType,
      			INCo, INLocation, MatlGroup, Material,
      			WorkOrder, WOItem, Amount)
      		  values (@co, @mth, @batchid, @oldinglco, @oldcostglacct, @batchseq,
      			0, @oldemtrans, @oldequipment, @oldactualdate, @olddescription,
    
      			@oldsource, @oldemtranstype, @oldemgroup, @oldcostcode, @oldemcosttype,
      			@oldinco, @oldinlocation, @oldmatlgroup, @oldmaterial,
      			--@oldworkorder, @oldwoitem,  (-1 * @oldtotalcost))
    				@oldworkorder, @oldwoitem, (@oldtotalcost))
      		  if @@rowcount = 0
      			begin
      			select @errtext = isnull(@errorstart,'')  + 'Unable to add EMGL audit for OldCostGLAcct = ' + isnull(@oldcostglacct,'') + '!'
      			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
                 	if @rcode <> 0
              	 	begin
                      select @rcode = 1
              	  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
              	   	goto bspexit
              	    end
                  else
                      begin
                      select @rcode = 1
                      select @errmsg = @errtext
                      goto bspexit
                      end
      			end
                end
              end
    
    		/* Insert 'old' entry for OldInvGLAcct. */
          if @oldinvglacct is not null
              begin
              Update bEMGL
              --Set Amount = Amount + (@oldtotalcost)
    			set Amount = Amount - (@oldtotalcost)
              Where EMCo=@co and Mth=@mth and BatchId=@batchid and GLCo=@oldinglco and GLAcct=@oldinvglacct and BatchSeq=@batchseq and OldNew=0
              If @@rowcount = 0
                begin
      		  insert into bEMGL (EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq,
      	   		OldNew, EMTrans, Equipment, ActualDate, TransDesc,
      			Source, EMTransType, EMGroup, CostCode, EMCostType,
      			INCo, INLocation, MatlGroup, Material,
      			WorkOrder, WOItem, Amount)
      		  values (@co, @mth, @batchid, @oldinglco, @oldinvglacct, @batchseq,
      			0, @oldemtrans, @oldequipment, @oldactualdate, @olddescription,
      			@oldsource, @oldemtranstype, @oldemgroup, @oldcostcode, @oldemcosttype,
      			@oldinco, @oldinlocation, @oldmatlgroup, @oldmaterial,
      			--@oldworkorder, @oldwoitem, @oldtotalcost)
    				@oldworkorder, @oldwoitem, (-1 * @oldtotalcost))
      		  if @@rowcount = 0
      			begin
      			select @errtext = isnull(@errorstart,'')  + 'Unable to add EMGL audit for OldInvGLAcct = ' + isnull(@oldinvglacct,'') + '!'
    				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
              	if @rcode <> 0
              	 	begin
                      select @rcode = 1
              	  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
           	   	    goto bspexit
              	    end
                  else
                      begin
                      select @rcode = 1
                      select @errmsg = @errtext
                      goto bspexit
                      end
      			end
                end
              end
    
       /* Insert 'old' entry for OldTaxAccrualGLAcct. */
    		if @oldtaxaccrualglacct is not null
    			begin
              Update bEMGL
              Set Amount = Amount + (@oldtaxamount)
              Where EMCo=@co and Mth=@mth and BatchId=@batchid and GLCo=@glco and GLAcct=@oldtaxaccrualglacct and BatchSeq=@batchseq and OldNew=0
              If @@rowcount = 0
                begin
    			  insert into bEMGL (EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq,
    				OldNew, EMTrans, Equipment, ActualDate, TransDesc,
    				Source, EMTransType, EMGroup, CostCode, EMCostType,
    				INCo, INLocation, MatlGroup, Material,
    				WorkOrder, WOItem, Amount)
    			  values (@co, @mth, @batchid, @oldglco, @oldtaxaccrualglacct, @batchseq,
    				0, @oldemtrans, @oldequipment, @oldactualdate, @olddescription,
    				@oldsource, @oldemtranstype, @oldemgroup, @oldcostcode, @oldemcosttype,
    				@oldinco, @oldinlocation, @oldmatlgroup, @oldmaterial,
    				@oldworkorder, @oldwoitem, @oldtaxamount)
    			  if @@rowcount = 0
    				begin
    
    				select @errtext = isnull(@errorstart,'')  + 'Unable to add EMGL audit for OldTaxAccrualGLAcct = ' + isnull(@oldtaxaccrualglacct,'') + '!'
    				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
              	if @rcode <> 0
              	 	begin
                      select @rcode = 1
              	  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
              	   	goto bspexit
              	    end
                  else
                      begin
                      select @rcode = 1
                      select @errmsg = @errtext
                      goto bspexit
                      end
    				end
                end
    			end
    
      /* Insert 'old' entry for OldARGLAcct. */
    		if @oldarglacct is not null
    			begin
              Update bEMGL
              Set Amount = Amount + (@olddollars + @oldtaxamount)
              Where EMCo=@co and Mth=@mth and BatchId=@batchid and GLCo=@oldinglco and GLAcct=@oldarglacct and BatchSeq=@batchseq and OldNew=0
              If @@rowcount = 0
                begin
    			  insert into bEMGL (EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq,
    				OldNew, EMTrans, Equipment, ActualDate, TransDesc,
    				Source, EMTransType, EMGroup, CostCode, EMCostType,
    				INCo, INLocation, MatlGroup, Material,
    				WorkOrder, WOItem, Amount)
    			  values (@co, @mth, @batchid, @oldinglco, @oldarglacct, @batchseq,
    				0, @oldemtrans, @oldequipment, @oldactualdate, @olddescription,
    				@oldsource, @oldemtranstype, @oldemgroup, @oldcostcode, @oldemcosttype,
    				@oldinco, @oldinlocation, @oldmatlgroup, @oldmaterial,
    				@oldworkorder, @oldwoitem, (-1*(@olddollars)))-- + @oldtaxamount)))
    			  if @@rowcount = 0
    				begin
    				select @errtext = isnull(@errorstart,'')  + 'Unable to add EMGL audit for OldARGLAcct = ' + isnull(@oldarglacct,'') + '!'
    				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
              	if @rcode <> 0
              	 	begin
                      select @rcode = 1
              	  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
              	   	goto bspexit
              	    end
                  else
                      begin
    select @rcode = 1
         select @errmsg = @errtext
                      goto bspexit
                      end
    				end
                end
    			end
    
          /* Insert 'old' entry for OldAPGLAcct. */
    		if @oldapglacct is not null
    			begin
              Update bEMGL
              Set Amount = Amount - (@olddollars + @oldtaxamount)
              Where EMCo=@co and Mth=@mth and BatchId=@batchid and GLCo=@glco and GLAcct=@oldapglacct and BatchSeq=@batchseq and OldNew=0
              If @@rowcount = 0
                begin
    			  insert into bEMGL (EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq,
    				OldNew, EMTrans, Equipment, ActualDate, TransDesc,
    				Source, EMTransType, EMGroup, CostCode, EMCostType,
    				INCo, INLocation, MatlGroup, Material,
    				WorkOrder, WOItem, Amount)
    			  values (@co, @mth, @batchid, @oldglco, @oldapglacct, @batchseq,
    				0, @oldemtrans, @oldequipment, @oldactualdate, @olddescription,
    				@oldsource, @oldemtranstype, @oldemgroup, @oldcostcode, @oldemcosttype,
    				@oldinco, @oldinlocation, @oldmatlgroup, @oldmaterial,
    				@oldworkorder, @oldwoitem, (@olddollars))-- + @oldtaxamount))
    			  if @@rowcount = 0
    				begin
    				select @errtext = isnull(@errorstart,'') + 'Unable to add EMGL audit for OldAPGLAcct = ' + isnull(@oldapglacct,'') + '!'
    				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
              	if @rcode <> 0
              	 	begin
                      select @rcode = 1
              	  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
              	   	goto bspexit
              	    end
                  else
                      begin
                      select @rcode = 1
                      select @errmsg = @errtext
                      goto bspexit
                      end
    				end
                end
    			end
    
    		end
    
    Change_trans:
    /* Insert entry for Adjustment. */
    -- TV 06/01/04 24715 Should post for 0 amounts. Vision did
    if @batchtranstype <> 'D' and  (@dollars is not null or @taxamount is not null)--(@dollars <> 0 or @taxamount <>0)
    	begin
    
    -- validate that adjustment journal exists in to INGL company
    if isnull(@adjstgllvl,0) > 0 and @source='EMAdj' and @co <> isnull(@inglco,@co)
    	begin
    	if not exists(select GLCo from bGLJR with (nolock) where GLCo=@inglco and Jrnl=@adjstgljrnl)
    		begin
    		select @errtext = isnull(@errorstart,'')  + 'Missing GL Journal: ' + isnull(@adjstgljrnl,'') + ' in GL Company: ' + isnull(convert(varchar(3),@inglco),'') + '!'
    		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
             if @rcode <> 0
    			begin
    			select @rcode = 1
                 select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
                 goto bspexit
                 end
    		else
    			begin
    			select @rcode = 1
                 select @errmsg = @errtext
                 goto bspexit
                 end
    		end
    	end
    
      /* Insert entry for GLTransAcct. */
      if @gltransacct is not null
          begin
          Update bEMGL
          Set Amount = Amount + (@dollars + @taxamount)
          Where EMCo=@co and Mth=@mth and BatchId=@batchid and GLCo=@glco and GLAcct=@gltransacct and BatchSeq=@batchseq and OldNew=1
          If @@rowcount = 0
            begin
            insert into bEMGL (EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq,
      			OldNew, EMTrans, Equipment, ActualDate, TransDesc,
      			Source, EMTransType, EMGroup, CostCode, EMCostType,
      			INCo, INLocation, MatlGroup, Material,
      			WorkOrder, WOItem, Amount)
       	  values (@co, @mth, @batchid, @glco, @gltransacct, @batchseq,
      			1, @emtrans, @equipment, @actualdate, @description,
                  @source, @emtranstype, @emgroup, @costcode, @emcosttype,
                  @inco, @inlocation, @matlgroup, @material,
                  @workorder, @woitem, @dollars + @taxamount)
            if @@rowcount = 0
      		begin
      		select @errtext = isnull(@errorstart,'')  + 'Unable to add EMGL audit for GLTransAcct = ' + isnull(@gltransacct,'') + '!'
      			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
                  if @rcode <> 0
                 	begin
                      select @rcode = 1
                  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
                  	goto bspexit
                  	end
                  else
                      begin
                      select @rcode = 1
                      select @errmsg = @errtext
                      goto bspexit
                      end
              end -- end insert
            end -- end update
          end
    
    
    	/* If theres a credit account, make that entry also. */
    	if @gloffsetacct is not null
    		begin
          Update bEMGL
          Set Amount = Amount - (@dollars)
          Where EMCo=@co and Mth=@mth and BatchId=@batchid and GLCo=@inglco and GLAcct=@gloffsetacct and BatchSeq=@batchseq and OldNew=1
          If @@rowcount = 0
            begin
    		  insert into bEMGL (EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq,
    			OldNew, EMTrans, Equipment, ActualDate, TransDesc,
    			Source, EMTransType, EMGroup, CostCode, EMCostType,
    			INCo, INLocation, MatlGroup, Material,
    			WorkOrder, WOItem, Amount)
    		  values (@co, @mth, @batchid, @inglco, @gloffsetacct, @batchseq,
    			1, @emtrans, @equipment, @actualdate, @description,
    			@source, @emtranstype, @emgroup, @costcode, @emcosttype,
    			@inco, @inlocation, @matlgroup, @material,
    			@workorder, @woitem, (-1 * (@dollars)))
    		  if @@rowcount = 0
    			begin
    			select @errtext = isnull(@errorstart,'')  + 'Unable to add EMGL audit for GLOffsetAcct = ' + isnull(@gloffsetacct,'') + '!'
    			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
              if @rcode <> 0
           	begin
                      select @rcode = 1
                  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    	                goto bspexit
    
                  	end
              else
                      begin
                      select @rcode = 1
                      select @errmsg = @errtext
                      goto bspexit
                      end
    			end -- insert rwocount
           end -- update rowcount
    		end
    
    
      /* Insert entry for CostGLAcct. */
      if @costglacct is not null
          begin
          update bEMGL
          Set Amount = Amount - @totalcost
          where EMCo=@co and Mth=@mth and BatchId=@batchid and GLCo=@inglco and GLAcct=@costglacct and BatchSeq=@batchseq and OldNew=1
          if @@rowcount = 0
              begin
              insert into bEMGL (EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq,
      		OldNew, EMTrans, Equipment, ActualDate, TransDesc,
      		Source, EMTransType, EMGroup, CostCode, EMCostType,
      		INCo, INLocation, MatlGroup, Material,
      		WorkOrder, WOItem, Amount)
    	        values (@co, @mth, @batchid, @inglco, @costglacct, @batchseq,
      		1, @emtrans, @equipment, @actualdate, @description,
              @source, @emtranstype, @emgroup, @costcode, @emcosttype,
              @inco, @inlocation, @matlgroup, @material,
              @workorder, @woitem, (-1 * @totalcost))
              if @@rowcount = 0
      		  begin
      		  select @errtext = isnull(@errorstart,'')  + 'Unable to add EMGL audit for CostGLAcct = ' + isnull(@costglacct,'') + '!'
      		  exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
                if @rcode <> 0
               	begin
                  select @rcode = 1
                  select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
                  goto bspexit
                  end
                else
                  begin
                  select @rcode = 1
                  select @errmsg = @errtext
                  goto bspexit
                  end
                end
             end
          end
    
    
      /* Insert entry for InvGLAcct. */
      if @invglacct is not null
          begin
          update bEMGL
          Set Amount = Amount + @totalcost
          where EMCo=@co and Mth=@mth and BatchId=@batchid and GLCo=@inglco and GLAcct=@invglacct and BatchSeq=@batchseq and OldNew=1
          if @@rowcount = 0
              begin
              insert into bEMGL (EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq,
      		OldNew, EMTrans, Equipment, ActualDate, TransDesc,
      		Source, EMTransType, EMGroup, CostCode, EMCostType,
      		INCo, INLocation, MatlGroup, Material,
      		WorkOrder, WOItem, Amount)
              values (@co, @mth, @batchid, @inglco, @invglacct, @batchseq,
      		1, @emtrans, @equipment, @actualdate, @description,
              @source, @emtranstype, @emgroup, @costcode, @emcosttype,
              @inco, @inlocation, @matlgroup, @material,
              @workorder, @woitem, @totalcost)
              if @@rowcount = 0
      		  begin
      		  select @errtext = isnull(@errorstart,'')  + 'Unable to add EMGL audit for InvGLAcct = ' + isnull(@invglacct,'') + '!'
      		  exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
                  if @rcode <> 0
                  	begin
                      select @rcode = 1
                  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
                  	goto bspexit
                  	end
                  else
                      begin
                      select @rcode = 1
                      select @errmsg = @errtext
                      goto bspexit
     end
                 end
              end
    end
    
      /* If applicable, insert entry for TaxAccrualGLAcct. */
    	if @taxaccrualglacct is not null
    		begin
          update bEMGL
          Set Amount = Amount - @taxamount
          where EMCo=@co and Mth=@mth and BatchId=@batchid and GLCo=@glco and GLAcct=@taxaccrualglacct and BatchSeq=@batchseq and OldNew=1
          if @@rowcount = 0
              begin
    		    insert into bEMGL (EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq,
    			OldNew, EMTrans, Equipment, ActualDate, TransDesc,
    			Source, EMTransType, EMGroup, CostCode, EMCostType,
    			INCo, INLocation, MatlGroup, Material,
    			WorkOrder, WOItem, Amount)
    	    	values (@co, @mth, @batchid, @glco, @taxaccrualglacct, @batchseq,
    			1, @emtrans, @equipment, @actualdate, @description,
    			@source, @emtranstype, @emgroup, @costcode, @emcosttype,
    			@inco, @inlocation, @matlgroup, @material,
    			@workorder, @woitem, (-1 * @taxamount))
    		    if @@rowcount = 0
    		    	begin
    			    select @errtext = isnull(@errorstart,'')  + 'Unable to add EMGL audit for TaxAccrualGLAcct = ' + isnull(@taxaccrualglacct,'') + '!'
    				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
                  if @rcode <> 0
                  	begin
                      select @rcode = 1
                  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
          	        goto bspexit
                  	end
                  else
                      begin
                      select @rcode = 1
                      select @errmsg = @errtext
                      goto bspexit
                      end
    			    end
              end
    		end
    
      /* If applicable, insert entry for ARGLAcct. */
    	if @arglacct is not null
    		begin
          update bEMGL
          Set Amount = Amount - @dollars + @taxamount
          where EMCo=@co and Mth=@mth and BatchId=@batchid and GLCo=@inglco and GLAcct=@arglacct and BatchSeq=@batchseq and OldNew=1
          if @@rowcount = 0
            begin
    		    insert into bEMGL (EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq,
    			OldNew, EMTrans, Equipment, ActualDate, TransDesc,
    			Source, EMTransType, EMGroup, CostCode, EMCostType,
    			INCo, INLocation, MatlGroup, Material,
    			WorkOrder, WOItem, Amount)
    	    	values (@co, @mth, @batchid, @inglco, @arglacct, @batchseq,
    			1, @emtrans, @equipment, @actualdate, @description,
    			@source, @emtranstype, @emgroup, @costcode, @emcosttype,
    			@inco, @inlocation, @matlgroup, @material,
    			@workorder, @woitem, ((@dollars)))
    	    	if @@rowcount = 0
    		    	begin
    		    	select @errtext = isnull(@errorstart,'')  + 'Unable to add EMGL audit for ARGLAcct = ' + isnull(@arglacct,'') + '!'
    				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
                  if @rcode <> 0
                  	begin
                      select @rcode = 1
                  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
                  	goto bspexit
                  	end
                  else
                      begin
                      select @rcode = 1
                      select @errmsg = @errtext
                      goto bspexit
                      end
    			    end
              end
    		end
      /* If applicable, insert entry for APGLAcct. */
    	if @apglacct is not null
    		begin
          update bEMGL
          Set Amount = Amount + @dollars + @taxamount
          where EMCo=@co and Mth=@mth and BatchId=@batchid and GLCo=@glco and GLAcct=@apglacct and BatchSeq=@batchseq and OldNew=1
          if @@rowcount = 0
            begin
    	    	insert into bEMGL (EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq,
    			OldNew, EMTrans, Equipment, ActualDate, TransDesc,
    			Source, EMTransType, EMGroup, CostCode, EMCostType,
    			INCo, INLocation, MatlGroup, Material,
    			WorkOrder, WOItem, Amount)
    	    	values (@co, @mth, @batchid, @glco, @apglacct, @batchseq,
    			1, @emtrans, @equipment, @actualdate, @description,
    			@source, @emtranstype, @emgroup, @costcode, @emcosttype,
    			@inco, @inlocation, @matlgroup, @material,
    			@workorder, @woitem, (-1*(@dollars)))
    		    if @@rowcount = 0
    		    	begin
    		    	select @errtext = isnull(@errorstart,'')  + 'Unable to add EMGL audit for APGLAcct = ' + isnull(@apglacct,'') + '!'
    			    	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
                      if @rcode <> 0
                  	begin
                      select @rcode = 1
                  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
                  	goto bspexit
                  	end
                    else
                      begin
                      select @rcode = 1
                      select @errmsg = @errtext
                      goto bspexit
                      end
    			    end
             end
    
    		end
    
    	end
    end
    
    
    
    bspexit:
    	if @rcode<>0 select @errmsg=isnull(@errmsg,'')		--+ char(13) + char(10) + '[bspEMVal_Cost_EMGL_Inserts]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMVal_Cost_EMGL_Inserts] TO [public]
GO
