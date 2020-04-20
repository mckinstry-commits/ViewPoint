SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                procedure [dbo].[bspEMVal_Miles_Main]
/***********************************************************
* CREATED BY:	JM 10/8/99
* MODIFIED By :	JM 09/17/01 - Changed creation method for temp tables from 'select * into' to discrete declaration
*					of specific fields. Also changed inserts into temp tables to discrete declaration of fields. 
*					Ref Issue 14227.
*				JM 08/09/02 - Rewritten for new header-detail form design and new tables - ref Issue 17838
*				RM 10/07/02 - Rewritten for new Table structure
*				TV 02/11/04 - 23061 added isnulls 
*				Dan So 03/14/08 - 127082 - changed all bState TO varchar(4)
*				CHS	11/04/08 - 130774 changed bspHQStateVal to vspHQCountryStateVal
*
* USAGE:
* 	Validates each entry in bEMMH/bEMML for a selected EMMiles batch -
*	must be called prior to posting the batch.
*
* 	After initial Batch and EM checks, bHQBC Status set to 1
*	(validation in progress), bHQBE (Batch Errors) entries are deleted.
*
* 	Creates a loop on bEMMH\bEMML to validate each entry individually.
*
* 	Errors in batch added to bHQBE using bspHQBEInsert.
*
* 	bHQBC Status updated to 2 if errors found, or 3 if OK to post
*
* INPUT PARAMETERS
*	EMCo        EM Company
*	Month       Month of batch
*	BatchId     Batch ID to validate
*
* OUTPUT PARAMETERS
*	@errmsg     if something went wrong
*
* RETURN VALUE
*	0   Success
*	1   Failure
*****************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output
   
   as
   
   set nocount on
   
   declare @batchseq int, @batchtranstype char(1), @itemtranstype char(1), @beginodo bHrs,	@dch varchar(255), @ddate bDate,
   	@dhrs bHrs,	@emsmemtrans bTrans, @emsmequipment bEquip,	@emsmiftastate varchar(4), @emsmreadingdate bDate, @emsmbeginodo bHrs,
   	@emsmendodo bHrs, @emsmusagedate bDate,	@emsmstate varchar(4), @emsmloaded bHrs, @emsmunloaded bHrs, @emsmoffroad bHrs,
   	@emsminusemth bMonth, @emsminusebatchid bBatchID, @emsdemtrans bTrans, @emsdequipment bEquip, @emsdiftastate varchar(4),
    	@emsdreadingdate bDate, @emsdbeginodo bHrs, @emsdendodo bHrs, @emsdusagedate bDate,	@emsdstate varchar(4), @emsdloaded bHrs,
    	@emsdunloaded bHrs,	@emsdoffroad bHrs, @emsdinusemth bMonth, @emsdinusebatchid bBatchID, @emtrans bTrans, @endodo bHrs,
   	@equipment bEquip, @errorstart varchar(50), @errtext varchar(255), @iftastate varchar(4), @line int, @loaded bHrs,
   	@offroad bHrs, @oldbatchid bBatchID, @oldbatchtranstype char(1), @olditemtranstype char(1), @oldbeginodo bHrs,
   	@oldemtrans bTrans, @oldendodo bHrs, @oldequipment bEquip, @oldiftastate varchar(4), @oldline int, @oldloaded bHrs,
   	@oldoffroad bHrs, @oldreadingdate bDate, @oldstate varchar(4), @oldunloaded bHrs, @oldusagedate bDate, @rcode int,
   	@readingdate bDate, @state varchar(4), @status tinyint, @unloaded bHrs, @usagedate bDate, @opencursorEMMH int, 
   	@opencursorEMML int
   
   select @rcode = 0
   
   -- Verify parameters passed in. 
   if @co is null
   	begin
   	select @errmsg = 'Missing Batch Company!', @rcode = 1
   	goto bspexit
   	end
   if @mth is null
   	begin
   	select @errmsg = 'Missing Batch Month!', @rcode = 1
   	goto bspexit
   	end
   if @batchid is null
   	begin
   	select @errmsg = 'Missing BatchID!', @rcode = 1
   	goto bspexit
   	end
   
   
   
   
   /* **************************************************************** */
   /* Validate batch data, set HQ Batch status. clear HQ Batch Errors */
   /* and clear and refresh HQCC entries. Exit immediately if batch doesnt validate. */
   /* **************************************************************** */
   exec @rcode = dbo.bspEMVal_Miles_BatchVal @co, @mth, @batchid, @errmsg output
   if @rcode <> 0 goto bspexit
   
   declare bcEMMH cursor for
   select BatchSeq, BatchTransType,EMTrans, Equipment, ReadingDate,BeginOdo,EndOdo,
   	   OldEquipment,OldReadingDate,OldBeginOdo,OldEndOdo
   from bEMMH
   where Co = @co and Mth = @mth and BatchId = @batchid
   
   
   open bcEMMH
   select @opencursorEMMH = 1
   
   
   EMMH_Loop:
   
   fetch next from bcEMMH into  @batchseq,@batchtranstype,@emtrans,@equipment,@readingdate,@beginodo,@endodo,
   							 @oldequipment,@oldreadingdate,@oldbeginodo,@oldendodo
   
   
   if @@fetch_status <> 0 goto EMMH_end
   
   	/* Setup @errorstart string. */
   	select @errorstart = 'Seq ' + convert(varchar(9),@batchseq) + '-'
   
   	/* ***************************************** */
   	/* Run validation applicable to all records. */
   	/* ***************************************** */
   	/* Validate BatchTransType. */
   	 --validate Transaction Type
       if @batchtranstype not in ('A','C','D')
   		begin
           select @errtext = isnull(@errorstart,'') + ' -  Invalid transaction type, must be ''A'',''C'', or ''D''.'
           exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
           if @rcode <> 0 goto bspexit
           goto EMMH_Loop
           end
   	
   		/* Verify Equipment not null. */
   		if @equipment is null
   			begin
   			select @errtext = isnull(@errorstart,'') + 'Invalid Equipment, must be not null.'
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   			    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   	
   		/* Verify ReadingDate not null. */
   		if @readingdate is null
   			begin
   			select @errtext = isnull(@errorstart,'') + 'Invalid ReadingDate, must be not null.'
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   			    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   	
   		/* Verify BeginOdo not null. */
   		if @beginodo is null
   			begin
   			select @errtext = isnull(@errorstart,'') + 'Invalid BeginOdo, must be not null.'
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   	
   				begin
   	
   			    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   	
   		/* Verify EndOdo not null. */
   		if @endodo is null
   			begin
   			select @errtext = isnull(@errorstart,'') + 'Invalid EndOdo, must be not null.'
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   			    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		
   /* ************************************************ */
   	/* Run validation applicable only to Added records. */
   	/* ************************************************ */
   	if @batchtranstype = 'A'
   		begin
   
   		/* Verify that EMTrans is null for Add type record. */
   		if @emtrans is not null
   			begin
   			select @errtext = isnull(@errorstart,'') + 'New entries may not ref a EMTrans.'
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   			    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   
   		/* Verify all 'old' values are null. */
   		if @oldbatchtranstype is not null or 
   			@oldemtrans  is not null or
   			@oldequipment  is not null or
   			@oldreadingdate  is not null or
   			@oldbeginodo  is not null or
   			@oldendodo  is not null
   			begin
   			select @errtext = isnull(@errorstart,'') + 'Old info must be null for Add entries.'
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   			    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   
   				goto bspexit
   				end
   			end
   	end /* Validations on Added records. */
   
   	/* *********************************************************** */
   	/* Run validation applicable only to Added and Changed records */
   	/* *********************************************************** */
   	if @batchtranstype = 'A' or @batchtranstype = 'C'
   
   		/* Validate Equipment - cannot be null. */
   		exec @rcode = dbo.bspEMEquipValForMilesByState @co, @equipment, @dch output, @ddate output, @dhrs output, @dhrs output, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'Equipment ' + isnull(@equipment,'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		
   		
   
   		/* ************************************************************* */
   		/* Run validation applicable only to Changed and Deleted records */
   		/* ************************************************************* */
   		if @batchtranstype = 'C' or @batchtranstype = 'D'
   			begin
   			/* Get existing values from bEMMS. */
   			select @emsmequipment = Equipment,
   				@emsmreadingdate = ReadingDate,
   				@emsmbeginodo = BeginOdo,
   				@emsmendodo = EndOdo,
   				@emsminusemth = InUseMth,
   				@emsminusebatchid = InUseBatchId
   			from bEMSM where Co = @co and Mth = @mth and EMTrans = @emtrans
   		
   			if @@rowcount = 0
   				begin
   				select @errtext = isnull(@errorstart,'') + '-Missing EM Miles Trans #:' + isnull(convert(char(3),@emtrans),'')
   				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   				if @rcode <> 0
   					begin
   					select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   					goto bspexit
   					end
   				end
   		
   			/* Verify EMMS record assigned to same BatchId. */
   			if @emsminusebatchid <> @batchid
   				begin
   				select @errtext = isnull(@errorstart,'') + '- Miles Trans has not been assigned to this BatchId.'
   				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   				if @rcode <> 0
   					begin
   					select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   					goto bspexit
   					end
   				end
   		
   			/* Make sure old values in batch match existing values in Miles detail table bEMMS. */
   			if  @emsmequipment <> @oldequipment
   				or @emsmreadingdate <> @oldreadingdate
   				or @emsmbeginodo <> @oldbeginodo
   				or @emsmendodo <> @oldendodo
   				begin
   				select @errtext = isnull(@errorstart,'') + '-Batch Old info does not match EM Miles Detail.'
   				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   				if @rcode <> 0
   					begin
   					select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   					goto bspexit
   					end
   				end
   		
   			/* **************************** */
   			/* Validate old values in EMBM. */
   			/* **************************** */
   			/* Validate Equipment - cannot be null. */
   			exec @rcode = dbo.bspEMEquipValForMilesByState @co, @equipment, @dch output, @ddate output, @dhrs output, @dhrs output, @errmsg output
   			if @rcode = 1
   				begin
   				select @errtext = isnull(@errorstart,'') + 'Equipment ' + @equipment + '-' + @errmsg
   				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   				if @rcode <> 0
   					begin
   					select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   					goto bspexit
   					end
   				end
   			end
   /**************************************************************************************************************************/		
   /**************************************************BEGIN LINE CURSOR*******************************************************/
   /**************************************************************************************************************************/
   
   		-- create a cursor to validate all the Items for this header
   	    declare bcEMML cursor for
   		select Line,BatchTransType,UsageDate,State,OnRoadLoaded,OnRoadUnLoaded,OffRoad,
   			   OldUsageDate,OldState,OldOnRoadLoaded,OldOnRoadUnLoaded,OldOffRoad
   	    from bEMML
   	    where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
   	
   	    open bcEMML
   	    select @opencursorEMML = 1
   	
   	 	EMML_loop:     -- get next Item
   			fetch next from bcEMML into @line,@itemtranstype,@usagedate,@state,@loaded,@unloaded,@offroad,
   										@oldusagedate,@oldstate,@oldloaded,@oldunloaded,@oldoffroad
   	
   	        if @@fetch_status <> 0 goto EMML_end
   	
   	        select @errorstart = 'Seq#: ' +isnull( convert(varchar(6),@batchseq),'') + ' Item: ' + isnull(convert(varchar(6),@line),'') + ' '
   			
   			-- validate transaction type
   			if @itemtranstype not in ('A','C','D')
   				begin
   	            select @errtext = isnull(@errorstart,'') + ' -  Invalid transaction type, must be ''A'',''C'', or ''D''.'
   	            exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	            if @rcode <> 0 goto bspexit
   	            goto EMML_loop
   	            end
   	
   			/* Verify Line not null. */
   			if @line is null
   				begin
   				select @errtext = isnull(@errorstart,'') + 'Invalid Line, must be not null.'
   				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   				if @rcode <> 0
   					begin
   				    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   					goto bspexit
   					end
   				end
   		
   			/* Verify UsageDate not null. */
   			if @usagedate is null
   				begin
   				select @errtext = isnull(@errorstart,'') + 'Invalid UsageDate, must be not null.'
   				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   				if @rcode <> 0
   					begin
   				    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   					goto bspexit
   					end
   				end
   		
   			/* Verify State not null. */
   			if @state is null
   				begin
   				select @errtext = isnull(@errorstart,'') + 'Invalid State, must be not null.'
   				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   				if @rcode <> 0
   					begin
   				    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   					goto bspexit
   					end
   				end
   		
   			/* Verify Loaded not null. */
   			if @loaded is null
   				begin
   				select @errtext = isnull(@errorstart,'') + 'Invalid Loaded, must be not null.'
   				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   				if @rcode <> 0
   					begin
   				    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   					goto bspexit
   					end
   				end
   		
   			/* Verify Unloaded not null. */
   			if @unloaded is null
   				begin
   				select @errtext = isnull(@errorstart,'') + 'Invalid Unloaded, must be not null.'
   				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   				if @rcode <> 0
   					begin
   				    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   					goto bspexit
   					end
   				end
   		
   			/* Verify OffRoad not null. */
   			if @offroad is null
   				begin
   				select @errtext = isnull(@errorstart,'') + 'Invalid OffRoad, must be not null.'
   				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   				if @rcode <> 0
   					begin
   				    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   					goto bspexit
   					end
   				end
   
   		/* ************************************************ */
   		/* Run validation applicable only to Added records. */
   		/* ************************************************ */
   		if @itemtranstype = 'A'
   			begin
   	
   			/* Verify that EMTrans is null for Add type record. 
   			if @emtrans is not null
   				begin
   				select @errtext = isnull(@errorstart,'') + 'New entries may not ref a EMTrans.'
   				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   				if @rcode <> 0
   					begin
   				    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   					goto bspexit
   					end
   				end*/
   	
   			/* Verify all 'old' values are null. */
   			if  @oldusagedate  is not null or
   				@oldstate  is not null or
   				@oldloaded  is not null or
   				@oldunloaded  is not null or
   				@oldoffroad  is not null
   				begin
   				select @errtext = isnull(@errorstart,'') + 'Old info must be null for Add entries.'
   				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   				if @rcode <> 0
   					begin
   				    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   	
   					goto bspexit
   					end
   				end
   		end /* Validations on Added records. */
   	
   		/* *********************************************************** */
   		/* Run validation applicable only to Added and Changed records */
   		/* *********************************************************** */
   		if @itemtranstype = 'A' or @itemtranstype = 'C'
   	    begin
   			/* Validate Equipment - cannot be null. */
   			exec @rcode = dbo.bspEMEquipValForMilesByState @co, @equipment, @dch output, @ddate output, @dhrs output, @dhrs output, @errmsg output
   			if @rcode = 1
   				begin
   				select @errtext = isnull(@errorstart,'') + 'Equipment ' + isnull(@equipment,'') + '-' + isnull(@errmsg,'')
   				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   				if @rcode <> 0
   					begin
   					select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   					goto bspexit
   					end
   				end
   			
   			
   			/* Validate State - cannot be null. */
			-- #130774
			-- exec @rcode = dbo.bspHQStateVal @state, @errmsg output
   			exec @rcode = dbo.vspHQCountryStateVal @co, null, @state, @errmsg output
   			if @rcode = 1
   				begin
   				select @errtext = isnull(@errorstart,'') + 'State ' + isnull(@state,'') + '-' + isnull(@errmsg,'')
   				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   				if @rcode <> 0
   					begin
   					select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   					goto bspexit
   					end
   				end
   		end -- 'A' and 'C' Validation
   
   			/* ************************************************************* */
   			/* Run validation applicable only to Changed and Deleted records */
   			/* ************************************************************* */
   			if @itemtranstype = 'C' or @itemtranstype = 'D'
   				begin
   				/* Get existing values from bEMMS. */
   				select @emsdusagedate = UsageDate,
   					@emsdstate = State,
   					@emsdloaded = OnRoadLoaded,
   					@emsdunloaded = OnRoadUnLoaded,
   					@emsdoffroad = OffRoad,
   					@emsdinusebatchid = InUseBatchId
   				from bEMSD where Co = @co and Mth = @mth and EMTrans = @emtrans and Line=@line
   			
   				if @@rowcount = 0
   					begin
   					select @errtext = isnull(@errorstart,'') + '-Missing EM Miles Trans #:' + isnull(convert(char(3),@emtrans),'')
   					exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   					if @rcode <> 0
   						begin
   						select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   						goto bspexit
   						end
   					end
   			
   				/* Verify EMMS record assigned to same BatchId. */
   				if @emsdinusebatchid <> @batchid
   					begin
   					select @errtext = isnull(@errorstart,'') + '- Miles Trans has not been assigned to this BatchId.'
   					exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   					if @rcode <> 0
   						begin
   						select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   						goto bspexit
   						end
   					end
   			
   				/* Make sure old values in batch match existing values in Miles detail table bEMSD. */
   				if	@emsdstate <> @oldstate
   					or @emsdloaded <> @oldloaded
   					or @emsdunloaded <> @oldunloaded
   					or @emsdoffroad <> @oldoffroad
   					begin
   					select @errtext = isnull(@errorstart,'') + '-Batch Old info does not match EM Miles Detail.'
   					exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   					if @rcode <> 0
   						begin
   						select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   						goto bspexit
   						end
   					end
   			
   				/* **************************** */
   				/* Validate old values in EMBM. */
   				/* **************************** */
   				
   				
   				/* Validate OldState - cannot be null. */
   				exec @rcode = bspHQStateVal @state, @errmsg output
   				if @rcode = 1
   					begin
   					select @errtext = isnull(@errorstart,'') + 'State ' + isnull(@state,'') + '-' + isnull(@errmsg,'')
   					exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   					if @rcode <> 0
   						begin
   						select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   						goto bspexit
   						end
   					end
   		
   				end
   
   	       
   	        goto EMML_loop  -- next Item
   	
   			EMML_end:
   		     	close bcEMML
   		     	deallocate bcEMML
   		     	select @opencursorEMML = 0
   		
   		     	goto EMMH_Loop      -- next  Header
   
   	EMMH_end:
   		close bcEMMH
   	    deallocate bcEMMH
   	    select @opencursorEMMH = 0
   
   
   /* ************************* */
   /* Check balances and close. */
   /* ************************* */
   /* Check HQ Batch Errors and update HQ Batch Control status. */
   if exists(select * from bHQBE where Co = @co and Mth = @mth and BatchId = @batchid)
   	select @status = 2 /* validation errors */
   else
   	select @status = 3 /* valid - ok to post */
   
   update bHQBC set Status = @status where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount <> 1
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
   	goto bspexit
   	end
   
   if @rcode <> 0 goto bspexit
   
   bspexit:
   	if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMVal_Miles_Main]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMVal_Miles_Main] TO [public]
GO
