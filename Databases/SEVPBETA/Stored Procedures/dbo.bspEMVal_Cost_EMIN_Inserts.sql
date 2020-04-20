SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspEMVal_Cost_EMIN_Inserts    Script Date: 12/11/2001 2:42:13 PM ******/
       CREATE              procedure [dbo].[bspEMVal_Cost_EMIN_Inserts]
       /***********************************************************
         * CREATED BY: JM 2/11/99
         * MODIFIED By : DANF 06/19/00 Inventory update
         *             : DANF 08/24/00 Corrected update of gl account for update to INDT.
         *             : DANF 12/19/00 Added check for inventory on add and delete
         *	JM 6/18/02 - Added 'select @deadchar = null, @deadnum = null' before each exec statement that uses
         *		@deadchar or @deadnum to make sure value is not inadvertently passed into procedure
         *	GF 10/02/02 - Issue #18707 Insert for new EMIN was using the IN GLCO S/B using EM GLCO.
         * 	JM 11-19-02 - Ref Issue 19408 - Removed update of EMBF.OldTotalCost 
         *	GF 01/24/03 - Issue #19882 - old inventory stkTotalCost is negative.
         *	GF 01/27/03 - issue #20184 - Sometimes not generating distributions for  old/changed values when BatchTransType='C'
         *	TV 03/06/03 - Clean up (no change)
         *	GF 04/24/2003 - issue #21067 - EM Offset acct validation for cross-co IN. Not passing in IN location.
         *	GF 06/06/2003 - issue #21488 - when no change made to existing transaction, new IN distr. created but no old.
         *	TV 02/11/04 - 23061 added isnulls
     	*	TV 06/04/04 24735 - IN distribution list not available on 'change' and 'delete'
         *	TV 07/09/04 25069 EM is updating IN Incorrectly. -all code backed as per Carol..
         *	GF 08/24/2012 TK-17347 part of EM Cost Adjustment import fix. error will occur if unit cost is null
         *
         *
         * USAGE:
         *	Called by bspEMVal_Cost_Main to add IN account distributions
         *	to bEMIN.
         *
         *	Note that INCo, INLocation and MatlGroup cannot arrive here
         *	as either null or invalid since they are used to validate
         *	Material in the calling procedure bspEMVal_Cost.
         *
         *	Several values can, however, arrive here as null or invalid
         *	if submitted to the calling procedure from a non-Bidtek
         *	front end since they are not directly checked in that
         *	procedure. GLCo, GLAcct, UM and StdUM are therefore
         *	checked here and rejected if null or invalid before the
         *	insert into bEMIN is allowed.
         *
         * 	Errors in batch added to bHQBE using bspHQBEInsert.
         *
         * INPUT PARAMETERS
         *	EMCo        	EM Company
         *	Month       	Month of batch
         *	BatchId     	Batch ID
         *	BatchSeq	Batch Sequence in psuedo-cursor
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
       
        declare @actualdate bDate,	@batchtranstype char(1), @costcode bCostCode, @emtrans bTrans, @deadnum float, @description bItemDesc /*137916*/,
        	@dollars bDollar, @emcosttype bEMCType, @emgroup bGroup, @equipment bEquip, @wo bWO, @woitem bItem, @comptype varchar(10),
           @component bEquip, @errorstart varchar(50), @errtext varchar(255), @glco bCompany, @gloffsetacct bGLAcct, @gltransacct bGLAcct,
        	@inco bCompany, @inglco bCompany, @inlocation bLoc, @material bMatl, @matlgroup bGroup, @numrows tinyint, @oldactualdate bDate,
        	@oldcostcode bCostCode, @olddescription bTransDesc, @olddollars bDollar, @oldemcosttype bEMCType, @oldemgroup bGroup,
        	@oldequipment bEquip, @oldwo bWO, @oldwoitem bItem, @oldcomptype varchar(10), @oldcomponent bEquip, @oldemtrans bTrans,
        	@oldglco bCompany, @oldgloffsetacct bGLAcct, @oldgltransacct bGLAcct, @oldinco bCompany, @oldinglco bCompany,
        	@oldinlocation bLoc, @oldmaterial bMatl, @oldmatlgroup bGroup, @oldstdum bUM, @oldstdunits bUnits, @oldum bUM,
        	@oldunitprice bUnitCost, @oldecm bECM, @oldunits bUnits, @rcode int, @stdum bUM, @stdunits bUnits, @um bUM,
       	@unitprice bUnitCost, @ecm  bECM, @units bUnits, @oldstkum bUM, @oldstkunitcost bUnitCost, @oldstkecm bECM,
           @oldstkunits bUnits, @oldunitcost bUnitCost, @oldtotalcost bDollar, @oldstktotalcost bDollar, @oldtotalprice bDollar,
           @stkum  bUM, @stkunitcost bUnitCost, @stkecm bECM, @i int, @deadchar varchar(255), @stdunitcost bUnitCost,
           @stdecm bECM, @inpstunitcost bUnitCost, @oldcost bDollar, @cost bDollar, @totalprice bDollar, @stktotalcost bDollar,
           @ingloffsetacct bGLAcct, @source bSource, @emtranstype varchar(10), @glsubtype char(1)
       
       
        select @rcode = 0
        /* Setup @errorstart string. */
        select @errorstart = 'Seq ' + convert(varchar(9),@batchseq) + '-'
        
        
        update bEMBF set PerECM = 'E'
        where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
        
        /* Fetch data from bEMBF into variables. */
        select @equipment = Equipment,
            @wo  = WorkOrder,
            @woitem = WOItem,
            @comptype = ComponentTypeCode,
            @component = Component,
        	@emtrans = EMTrans,
        	@batchtranstype = BatchTransType,
            @source = Source,
            @emtranstype = EMTransType,
        	@emgroup = EMGroup,
        	@costcode = CostCode,
        	@emcosttype = EMCostType,
        	@actualdate = ActualDate,
        	@description = Description,
        	@glco = GLCo,
        	@gloffsetacct = GLOffsetAcct,
            @gltransacct = GLTransAcct,
        	@matlgroup = MatlGroup,
        	@inco = INCo,
        	@inlocation = INLocation,
        	@material = Material,
            @stkum = INStkUM,
            @stkunitcost = INStkUnitCost,
            @stkecm = INStkECM,
        	@um = UM,
        	@units = Units,
        	@dollars = Dollars,
        	@unitprice = UnitPrice,
            @ecm = PerECM,
        	@oldequipment = OldEquipment,
            @oldwo  = OldWorkOrder,
            @oldwoitem = OldWOItem,
            @oldcomptype = OldComponentTypeCode,
            @oldcomponent = OldComponent,
        	@oldemtrans = OldEMTrans,
        	@oldemgroup = OldEMGroup,
        	@oldcostcode = OldCostCode,
        	@oldemcosttype = OldEMCostType,
        	@oldactualdate = OldActualDate,
        	@olddescription = OldDescription,
        	@oldglco = OldGLCo,
        	@oldgloffsetacct = OldGLOffsetAcct,
            @oldgltransacct = OldGLTransAcct,
           	@oldmatlgroup = OldMatlGroup,
        	@oldinco = OldINCo,
        	@oldinlocation = OldINLocation,
        	@oldmaterial = OldMaterial,
        	@oldum = OldUM,
        	@oldunits = OldUnits,
        	@olddollars = OldDollars,
        	@oldunitprice = OldUnitPrice,
            @oldecm = OldPerECM,
            @oldstkum = OldINStkUM,
            @oldstkunitcost = OldINStkUnitCost,
            @oldstkecm = OldINStkECM,
            @oldtotalcost = OldTotalCost
        from bEMBF
        where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
        
        if (@batchtranstype = 'C' or @batchtranstype = 'D')
        	begin
        	/*-- Dont add INLocation for 0 amounts.
        	if (@batchtranstype = 'C' and isnull(@oldunits,0) <> 0 and isnull(@olddollars,0) <> 0 and @oldinlocation is not null)
        		and (isnull(@equipment,'') <> isnull(@oldequipment,'')
        		or isnull(@wo,'') <> isnull(@oldwo,'')
        		or isnull(@woitem,'') <> isnull(@oldwoitem,'')
        		or isnull(@comptype,'') <> isnull(@oldcomptype,'')
        		or isnull(@component,'') <> isnull(@oldcomponent,'')
        		or isnull(@costcode,'') <> isnull(@oldcostcode,'')
        		or isnull(@emcosttype,'') <> isnull(@oldemcosttype,'')
        		or isnull(@actualdate,'') <> isnull(@oldactualdate,'')
        		or isnull(@inlocation,'') <> isnull(@oldinlocation,'')
        		or isnull(@material,'') <> isnull(@oldmaterial,'')
        		or isnull(@um,'') <> isnull(@oldum,'')
        		or isnull(@units,'') <> isnull(@oldunits,'')
        		or isnull(@dollars,'') <> isnull(@olddollars,'')
        		or isnull(@unitprice,'') <> isnull(@oldunitprice,'')) or
                (@batchtranstype = 'D' and isnull(@oldunits,0) <> 0 and isnull(@olddollars,0) <> 0 and @oldinlocation is not null)*/
     	--TV 06/04/04 24735 - IN distribution list not available on 'change' and 'delete'
     	if ((@batchtranstype = 'C' and @oldunits is not null and @olddollars is not null
     		and @oldinlocation is not null)
     	   	and ((isnull(@equipment,'') <> isnull(@oldequipment,'')
     		or isnull(@wo,'') <> isnull(@oldwo,'')
     		or isnull(@woitem,'') <> isnull(@oldwoitem,'')
     		or isnull(@comptype,'') <> isnull(@oldcomptype,'')
     		or isnull(@component,'') <> isnull(@oldcomponent,'')
     		or isnull(@costcode,'') <> isnull(@oldcostcode,'')
     		or isnull(@emcosttype,'') <> isnull(@oldemcosttype,'')
     		or isnull(@actualdate,'') <> isnull(@oldactualdate,'')
     		or isnull(@inlocation,'') <> isnull(@oldinlocation,'')
     		or isnull(@material,'') <> isnull(@oldmaterial,'')
     		or isnull(@um,'') <> isnull(@oldum,'')
     		or isnull(@units,'') <> isnull(@oldunits,'')
     		or isnull(@dollars,'') <> isnull(@olddollars,'')
     	   	or isnull(@unitprice,'') <> isnull(@oldunitprice,''))) 
     		or (@batchtranstype = 'D' 
     		and @oldunits is not null and @olddollars is not null
     		and @oldinlocation is not null))
        		begin
        		/* *********************************************** */
        		/* Validate fields that can arrive here as null or */
        		/* invalid but cannot be null in bEMIN.		   */
        		/* *********************************************** */
                select @oldmatlgroup = MatlGroup
                from bHQCO with (nolock) where HQCo = @oldinco
        		if @oldmatlgroup is null
        			begin
        			select @errmsg = isnull(@errtext,'') + 'Missing old Material Group for old IN company.'
        			goto bspexit
        			end
        
        		if @oldglco is null
        			begin
        			select @errtext = isnull(@errorstart,'') + 'Invalid OldGLCo in bEMBF, must be not null.'
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
            		if @rcode <> 0
        				begin
         	 		    select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			    goto bspexit
        			    end
        			end
        		else
         			begin
        			exec @rcode = dbo.bspGLCompanyVal @oldglco, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errtext = isnull(@errorstart,'') + 'OldGLCo ' + isnull(convert(varchar(5),isnull(@oldglco,0)),'') + '-' + isnull(@errmsg,'')
        				exec @rcode =dbo. bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        				if @rcode <> 0
        			 	      	begin
        			  	     	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			   	    	goto bspexit
        			    	   	end
        				end
        			end
        
        		if @oldgloffsetacct is null
        			begin
        			select @errtext = isnull(@errorstart,'') + 'Invalid OldGLOffsetAcct in bEMBF, must be not null.'
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        		 	    begin
        		  	    select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        		   	    goto bspexit
        		    	end
        			end
        		else
        			begin
      			set @glsubtype = 'N'
      			set @oldinglco = @glco
      			-- Select OldINGLCo based on whether INCo passed in or not
      			if @oldinco is not null and @oldinlocation is not null
      				begin
      			  	select @oldinglco = GLCo from bINCO where INCo = @oldinco
      				end
                  if @oldmaterial is not null  and @oldinlocation is not null select @glsubtype = 'I'
        			exec @rcode = dbo.bspGLACfPostable  @oldinglco, @oldgloffsetacct, @glsubtype, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errtext = isnull(@errorstart,'') + 'OldGLOffsetAcct ' + isnull(@oldgloffsetacct,'') + '-' + isnull(@errmsg,'')
        				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        				if @rcode <> 0
        			 	    begin
        			  	    select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			   	    goto bspexit
        			    	end
        				end
        			end
        		if @oldum is null
        			begin
        			select @errtext = isnull(@errorstart,'') + 'Invalid OldUM in bEMBF, must be not null.'
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        		 	      	begin
        		  	     	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        		   	    	goto bspexit
        		    	   	end
        			end
        		else
        			begin
        			exec @rcode = dbo.bspHQUMVal @oldum, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errtext = isnull(@errorstart,'')+ 'OldUM ' + isnull(@oldum,'') + '-' + isnull(@errmsg,'')
        				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        				if @rcode <> 0
        			 	      	begin
        			  	     	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			   	    	goto bspexit
        			    	   	end
        				end
        			end
        		if @oldstkum is null
        			begin
        			select @errtext = isnull(@errorstart,'') + 'Invalid OldStkUM in bEMBF, must be not null.'
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        		 	      	begin
        		  	     	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        		   	    	goto bspexit
        		  	   	end
        			end
        
        		/* *************************************************** */
        		/* Validate fields that can be null in bEMIN but must  */
        		/* be validated if they arrive here as non-null. Note  */
        		/* that we will validate OldCostCode and OldEMCostType */
        		/* separately and then together.                       */
        		/* *************************************************** */
        		if @oldemgroup is not null
        			begin
        			exec @rcode = dbo.bspHQGroupVal @oldemgroup, @errmsg output
        			if @rcode = 1
        				begin
        				select @errtext = isnull(@errorstart,'') + 'OldEMGroup ' + isnull(convert(varchar(5),@oldemgroup),'') + '-' + isnull(@errmsg,'')
        				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        				if @rcode <> 0
        			 	      	begin
        			  	     	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			   	    	goto bspexit
        			    	   	end
        				end
        			end
        
        		if @oldcostcode is not null
        			begin
        			exec @rcode = dbo.bspEMCostCodeVal @oldemgroup, @oldcostcode, @errmsg output
        			if @rcode = 1
        				begin
        				select @errtext = isnull(@errorstart,'') + 'OldCostCode ' + isnull(convert(varchar(5),@oldcostcode),'') + '-' + isnull(@errmsg,'')
        				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        				if @rcode <> 0
        			 	      	begin
        			  	     	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			   	    	goto bspexit
        			    	   	end
        				end
        			end
        
        		if @oldemcosttype is not null
        			begin
        			-- First validate CT vs EMCT.
        			select @deadchar = null, @deadnum = null
        			exec @rcode = dbo.bspEMCostTypeVal @oldemgroup, @oldemcosttype, @deadnum output, @errmsg output
        			if @rcode = 1
        				begin
        				select @errtext = isnull(@errorstart,'') + 'OldEMCostType ' + isnull(convert(varchar(5),@oldemcosttype),'') + '-' + isnull(@errmsg,'')
        				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        				if @rcode <> 0
        			 	      	begin
        			  	     	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			   	    	goto bspexit
        			    	   	end
        				end
        
        			-- Now validate CT/CostCode combination vs EMCX.
        			select @deadchar = null, @deadnum = null
        			exec @rcode = dbo.bspEMCostTypeCostCodeVal @oldemgroup, @oldcostcode, @oldemcosttype, @deadnum output, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errtext = isnull(@errorstart,'') + 'OldEMCostType ' + isnull(convert(varchar(5),@oldemcosttype),'') + '-' + isnull(@errmsg,'')
        				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        				if @rcode <> 0
        			 	      	begin
        			  	     	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			   	    	goto bspexit
        			    	   	end
        				end
        			end
        
        		    -- Changed and Old Entries
        		    select @deadchar = null, @deadnum = null
        		    exec @rcode = dbo.bspEMVal_Cost_Inventory @mth, @oldinco, @oldinlocation, @oldmatlgroup, @oldmaterial, @oldum, @oldunits,
                                                      @oldglco, @oldcostcode, @oldemcosttype, @oldequipment, @co,
                                                      @stdum output, @stdunits output, @stdunitcost output, @stdecm output, @inpstunitcost output,
                                                      @deadchar output, @inglco output, @deadchar output, @deadchar output, @deadchar output, @errmsg output
        		    if @rcode <> 0
        				begin
        				select @errtext = isnull(@errorstart,'') + isnull(@errmsg,'')
        				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        				if @rcode <> 0
        			 		begin
        			  		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			    	end
        				    goto bspexit
        				end
        
        		/* ******************* */
        		/* Insert 'old' entry. */
        		/* ******************* */
                select @i = 1
                if @oldecm = 'C' select @i = 100
                if @oldecm = 'M' select @i = 1000
   			 select @oldcost = (@oldunits * @inpstunitcost)/@i
                select @oldtotalprice = ((@oldunits * @oldunitprice)/@i)
                select @i = 1
                if @oldstkecm = 'C' select @i = 100
                if @oldstkecm = 'M' select @i = 1000
                select @oldstktotalcost = ( @stdunits * @oldstkunitcost)/@i
                insert into bEMIN (EMCo, Mth, BatchId, INCo, INLocation, MatlGroup,
        			Material, BatchSeq, OldNew, EMTrans, ActualDate, WO, WOItem, Equip, EMGroup,
        			CostCode, EMCType, CompType, Component, GLCo, GLAcct, Description,
        			PostedUM, PostedUnits, PostedUnitCost, PostECM, PostedTotalCost,
                    StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost,
                    UnitPrice, PECM, TotalPrice)
        		values (@co, @mth, @batchid, @oldinco, @oldinlocation, @oldmatlgroup,
        			@oldmaterial, @batchseq, 0, @oldemtrans, @oldactualdate, @oldwo, @oldwoitem, @oldequipment, @oldemgroup,
        			@oldcostcode, @oldemcosttype, @oldcomptype, @oldcomponent,  @oldglco, @oldgltransacct, @olddescription,
        			@oldum, @oldunits, @inpstunitcost, @oldecm, @oldcost,
                    @oldstkum, @stdunits, @oldstkunitcost, @oldstkecm, (-1*@oldtotalcost),
                    isnull(@oldunitprice,0), @oldecm, isnull(@oldtotalprice,0))
        		if @@rowcount = 0
        			begin
        			select @errmsg = 'Unable to add Old entry for posted GL Acct to bEMIN!', @rcode = 1
        			goto bspexit
        			end
        	/* JM 11-19-02 - Ref Issue 19408 - Removed update of EMBF.OldTotalCost */
                /*update bEMBF
                set OldTotalCost = @oldstktotalcost
        	    where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq*/
        
        		end
              end
      
      
        	/* Insert entry for Adjustment. */
        	if @batchtranstype <> 'D' and (@dollars is not null or @units is not null)
        		begin
        		-- Dont add INLocation for 0 amounts.
     	   -- TV 06/04/04 24735 - IN distribution list not available on 'change' and 'delete'
        	   if 	@batchtranstype = 'A' or
     			(@batchtranstype = 'C'
     			and @oldunits is not null and @olddollars is not null and @inlocation is not null
      	  		and (isnull(@equipment,'') <> isnull(@oldequipment,'')
      	  		or isnull(@wo,'') <> isnull(@oldwo,'')
      	  		or isnull(@woitem,'') <> isnull(@oldwoitem,'')
      	  		or isnull(@comptype,'') <> isnull(@oldcomptype,'')
      	  		or isnull(@component,'') <> isnull(@oldcomponent,'')
      	  		or isnull(@costcode,'') <> isnull(@oldcostcode,'')
      	  		or isnull(@emcosttype,'') <> isnull(@oldemcosttype,'')
      	  		or isnull(@actualdate,'') <> isnull(@oldactualdate,'')
      	  		or isnull(@inlocation,'') <> isnull(@oldinlocation,'')
      	  		or isnull(@material,'') <> isnull(@oldmaterial,'')
      	  		or isnull(@um,'') <> isnull(@oldum,'')
      	  		or isnull(@units,'') <> isnull(@oldunits,'')
      	  		or isnull(@dollars,'') <> isnull(@olddollars,'')
      	  		or isnull(@unitprice,'') <> isnull(@oldunitprice,'')))
        		begin
        		/* *********************************************** */
        		/* Validate fields that can arrive here as null or */
        		/* invalid but cannot be null in bEMIN.		   */
        		/* *********************************************** */
                select @matlgroup = MatlGroup
                from bHQCO
                where HQCo = @inco
        
        		if @glco is null
        			begin
        			select @errtext = isnull(@errorstart,'') + 'Invalid GLCo in bEMBF, must be not null.'
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        		 	      	begin
        		  	     	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        		   	    	goto bspexit
        		    	   	end
        			end
        		else
        			begin
        			exec @rcode = dbo.bspGLCompanyVal @glco, @errmsg output
        			if @rcode = 1
        				begin
        				select @errtext = isnull(@errorstart,'') + 'GLCo ' + isnull(convert(varchar(5),@glco),'') + '-' + isnull(@errmsg,'')
        				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        				if @rcode <> 0
        			 	      	begin
        			  	     	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        		   	    	goto bspexit
        			    	   	end
        				end
        			end
        
        
        		/* ************************************************** */
        		/* Validate fields that can be null in bEMIN but must */
        		/* be validated if they arrive here as non-null. Note */
        		/* that we will validate CostCode and EMCostType      */
        		/* separately and then together.                      */
        		/* ************************************************** */
        		if @emgroup is not null
        			begin
        			exec @rcode = dbo.bspHQGroupVal @emgroup, @errmsg output
        			if @rcode = 1
        				begin
        				select @errtext = isnull(@errorstart,'') + 'EMGroup ' + isnull(convert(varchar(5),@emgroup),'') + '-' + isnull(@errmsg,'')
        				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        				if @rcode <> 0
        			 	   	begin
        			  	     	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			   	    	goto bspexit
        			    	   	end
        				end
        			end
        
        		if @costcode is not null
        			begin
        			exec @rcode = dbo.bspEMCostCodeVal @emgroup, @costcode, @errmsg output
        			if @rcode = 1
        				begin
        				select @errtext = isnull(@errorstart,'') + 'CostCode ' + isnull(convert(varchar(5),@costcode),'') + '-' + isnull(@errmsg,'')
        				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        				if @rcode <> 0
        			 	      	begin
        			  	     	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			   	    	goto bspexit
        			    	   	end
        				end
        			end
        
        		if @emcosttype is not null
        			begin
        			/* First validate CT vs EMCT. */
        			select @deadchar = null, @deadnum = null
        			exec @rcode = dbo.bspEMCostTypeVal @emgroup, @emcosttype, @deadnum output, @errmsg output
        			if @rcode = 1
        				begin
        				select @errtext = isnull(@errorstart,'') + 'EMCostType ' + isnull(convert(varchar(5),@emcosttype),'') + '-' + isnull(@errmsg,'')
        				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        				if @rcode <> 0
        			 	      	begin
        			  	     	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			   	    	goto bspexit
        			    	   	end
        				end
        
        			/* Now validate CT/CostCode combination vs EMCX. */
        			select @deadchar = null, @deadnum = null
        			exec @rcode = dbo.bspEMCostTypeCostCodeVal @emgroup, @costcode, @emcosttype, @deadnum output, @errmsg output
        			if @rcode = 1
        				begin
        				select @errtext = isnull(@errorstart,'') + 'EMCostType ' + isnull(convert(varchar(5),@emcosttype),'') + '-' + isnull(@errmsg,'')
        				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        				if @rcode <> 0
        			 	      	begin
        			  	     	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			   	    	goto bspexit
        			    	   	end
        				end
        
        		    /* ******************* */
        			/* Insert 'new' entry. */
        			/* ******************* */
        			select @deadchar = null, @deadnum = null
        			exec @rcode = dbo.bspEMVal_Cost_Inventory @mth, @inco, @inlocation, @matlgroup, @material, @um, @units,
                   			      	@glco, @costcode, @emcosttype, @equipment, @co, @stdum output, @stdunits output,
       								@stdunitcost output, @stdecm output, @inpstunitcost output, @deadchar output,
       								@inglco output, @ingloffsetacct output, @deadchar output, @deadchar output,
       								@errmsg output
       			if @rcode = 1
        				begin
        				select @errtext = isnull(@errorstart,'') + isnull(@errmsg,'')
        				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        				if @rcode <> 0
        			 	      	begin
        			  	     	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			    	   	end
        			   	goto bspexit
        				end
       
       			if (@source = 'EMAdj' and (@emtranstype = 'Fuel' or @emtranstype = 'Parts')) or (@source = 'EMParts' and @emtranstype = 'Parts')
                   	begin
                   	select @gloffsetacct = @ingloffsetacct
                   	end
        
        
        		/* ******************* */
        		/* Insert 'new' entry. */
        		/* ******************* */
        
                select @i = 1
                if @ecm = 'C' select @i = 100
                if @ecm = 'M' select @i = 1000
                select @units = @units * -1
                select @cost = (@units * @inpstunitcost)/@i
                select @totalprice = ((@units * @unitprice)/@i)
        
                select @i = 1
                if @stdecm = 'C' select @i = 100
                if @stdecm = 'M' select @i = 1000
                select @stdunits = (-1 * @stdunits)
                select @stktotalcost = ( @stdunits * @stdunitcost)/@i
        
                insert into bEMIN (EMCo, Mth, BatchId, INCo, INLocation, MatlGroup,
        			Material, BatchSeq, OldNew, EMTrans, ActualDate, WO, WOItem, Equip, EMGroup,
        			CostCode, EMCType, CompType, Component, GLCo, GLAcct, Description,
        			PostedUM, PostedUnits, PostedUnitCost, PostECM, PostedTotalCost,
        		            	StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost,
        			UnitPrice, PECM, TotalPrice)
        		-- 10/2/02 GF changed from @inglco to @glco
        		values (@co, @mth, @batchid, @inco, @inlocation, @matlgroup,
        			@material, @batchseq, 1, @emtrans, @actualdate, @wo, @woitem, @equipment, @emgroup,
        			@costcode, @emcosttype, @comptype, @component,  @glco, @gltransacct, @description,
        			@um, @units, @inpstunitcost, @ecm, @cost, @stdum, @stdunits, @stdunitcost, @stdecm, 
        			@stktotalcost, @unitprice, @ecm, @totalprice)
        		if @@rowcount = 0
        			begin
        			select @errmsg = 'Unable to add New entry for posted GL Acct to bEMIN!', @rcode = 1
        			goto bspexit
        			end
        		end
        
				----TK-17347 error will occur if unit cost is null
				IF @stdunitcost IS NOT NULL
					BEGIN
               		UPDATE bEMBF
        				SET TotalCost = @stktotalcost,
        					INStkUM = @stdum, 
        					INStkUnitCost = @stdunitcost, 
        					INStkECM = @stdecm
        	    	WHERE Co = @co 
        	    		AND Mth = @mth
        	    		AND BatchId = @batchid
        	    		AND BatchSeq = @batchseq
        	    	END
        	end
        end
        
        
        
        
        
        
        
        
        bspexit:
        	if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMVal_Cost_EMIN_Inserts]'
        	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMVal_Cost_EMIN_Inserts] TO [public]
GO
