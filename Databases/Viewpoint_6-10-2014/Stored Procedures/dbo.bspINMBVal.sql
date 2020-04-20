SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      procedure [dbo].[bspINMBVal]
   /***********************************************************
    * CREATED: GG 03/14/02
    * MODIFIED: RM 05/31/02 - Cannot pass date as parameter to SP, must assign to variable (bspHQTaxRateGet)
    *			GG 06/03/02 - #17529 - don't allow Item delete if confirmed units <> 0.00
    *           DANF 09/05/02 - 17738 - Added phase group to bspJobTypeVal
    *			RM 12/23/02 Cleanup Double Quotes
    *			RM 05/15/03 - Add Check for Job in header (19248)
    *			TRL 09/07/07 -- Issue 125273 fixed recommitted units calc for Item Change or Delete and 
	*							added validation error when Item type is change and units have been confirmed 
	*							and Job, Phase or Cost Type has been changed.
	*			DC 01/24/08 #121529  - Increase the description to 60.
	*			GF 09/09/2010 - issue #141031 changed to use function vfDateOnly
	*
	*
    * USAGE:
    * Validates IN Material Order Entry batch - must be called
    * prior to posting the batch.
    *
    * Batch Control status (bHQBC.Status) set to 1 (validation in progress)
    * bHQBE (Batch Errors) and bINJC (IN JC Detail Audit) entries are deleted.
    *
    * Creates a cursor on bINMB to validate each entry individually, then a cursor on bINIB for
    * each item for the header record.
    *
    * Errors in batch added to bHQBE using bspHQBEInsert
    * Job distributions added to bINJC
    *
    * bHQBC Status updated to 2 if errors found, or 3 if OK to post
    *
    * INPUT PARAMETERS
    *   @co        IN Company
    *   @mth       Month of batch
    *   @batchid   Batch ID to validate
    *	 @source	Batch Source - either 'MO Entry' or 'PM Intface'
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
   
   	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @source bSource = null,
   	 @errmsg varchar(255) output)
    
   as
    
   set nocount on
   
   declare @rcode int, @errortext varchar(255), @inuseby bVPUserName, @status tinyint,	@opencursorINMB tinyint,
   	@opencursorINIB tinyint, @itemcount int, @deletecount int, @errorstart varchar(50), @lastglco bCompany,
   	@rc int, @umconv bUnitCost,	@oldumconv bUnitCost, @jcremainunits bUnits, @oldjcremainunits bUnits, 
   	@inmiloc bLoc, @inmimatlgroup bGroup, @inmimaterial bMatl, @inmijcco bCompany, @inmijob bJob,
   	@inmiphasegroup bGroup, @inmiphase bPhase, @inmijcctype bJCCType, @inmium bUM, @inmiorderunits bUnits,
   	@inmiunitprice bUnitCost, @inmiecm bECM, @inmitotalprice bDollar, @inmitaxgroup bGroup, @inmitaxcode bTaxCode,
   	@inmiconfirmedunits bUnits, @inmiremainunits bUnits, @factor int, @totalamt bDollar, @remainamt bDollar,
   	@taxgetdate bDate
   
   -- IN MO Header
   declare @transtype char(1), @seq int, @mo bMO, @jcco bCompany, @oldjcco bCompany, @oldstatus tinyint,@headerjob bJob
   
   -- IN MO Item
   declare @moitem bItem, @itemtranstype char(1), @itemdesc bItemDesc, @loc bLoc, @matlgroup bGroup, @material bMatl,
   	@itemjcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @glco bCompany,
   	@glacct bGLAcct, @um bUM, @orderunits bUnits, @unitprice bUnitCost, @ecm bECM, @totalprice bDollar,
   	@taxgroup bGroup, @taxcode bTaxCode, @taxamt bDollar, @remainunits bUnits, @taxphase bPhase,
   	@taxjcctype bJCCType, @taxrate bRate, @jcumconv bUnitCost, @jcum bUM, @jcunits bUnits,
   	@olditemdesc bItemDesc, @oldloc bLoc, @oldmatlgroup bGroup, @oldmaterial bMatl, @olditemjcco bCompany,
   	@oldjob bJob, @oldphasegroup bGroup, @oldphase bPhase, @oldjcctype bJCCType, @oldum bUM, @oldorderunits bUnits,
   	@oldunitprice bUnitCost, @oldecm bECM, @oldtotalprice bDollar, @oldtaxgroup bGroup, @oldtaxcode bTaxCode,
   	@oldtaxamt bDollar, @oldremainunits bUnits, @oldtaxphase bPhase, @oldtaxjcctype bJCCType, @oldtaxrate bRate,
   	@oldjcumconv bUnitCost, @oldjcum bUM, @oldjcunits bUnits
   
   select @rcode = 0
   
   -- validate HQ Batch 
   exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, @source, 'INMB', @errmsg output, @status output
   if @rcode <> 0 goto bspexit
   if @status < 0 or @status > 3
   	begin
       select @errmsg = 'Invalid Batch status!', @rcode = 1
       goto bspexit
       end
   -- set HQ Batch status to 1 (validation in progress) 
   update dbo.HQBC set Status = 1
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
       begin
       select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
       goto bspexit
       end
   
   -- clear HQ Batch Errors 
   delete dbo.HQBE where Co = @co and Mth = @mth and BatchId = @batchid
   -- clear JC Distributions 
   delete dbo.INJC where INCo = @co and Mth = @mth and BatchId = @batchid
   
   /* declare cursor on IN Material Order Header Batch for validation */
   declare bcINMB cursor for
   select BatchSeq, BatchTransType, MO, JCCo, Status, OldJCCo, OldStatus,Job
   from dbo.INMB with(nolock)
   where Co = @co and Mth = @mth and BatchId = @batchid
   
   open bcINMB
   select @opencursorINMB = 1
   
   INMB_loop:  -- loop through each entry in the batch
   	fetch next from bcINMB into @seq, @transtype, @mo, @jcco, @status, @oldjcco, @oldstatus,@headerjob
   
       if @@fetch_status <> 0 goto INMB_end
   
       select @errorstart = 'Seq#:' + convert(varchar(6),@seq)
   
       --validate Transaction Type
       if @transtype not in ('A','C','D')
   		begin
           select @errortext = @errorstart + ' -  Invalid transaction type, must be ''A'',''C'', or ''D''.'
           exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
           if @rcode <> 0 goto bspexit
           goto INMB_loop
           end
   	
       if @transtype = 'A'     -- validation specific to new MOs
           begin
           -- check for uniqueness among existing MOs
           if exists (select 1 from dbo.INMO with(nolock) where INCo = @co and MO = @mo)
           	begin
               select @errortext = @errorstart + ' - Material Order # already exists.'
               exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               if @rcode <> 0 goto bspexit
               goto INMB_loop
               end
           -- check for uniqueness in current batch
           if exists (select 1 from dbo.INMB with(nolock) where Co = @co and Mth = @mth and BatchId = @batchid
               and  MO = @mo and BatchSeq <> @seq)
               begin
               select @errortext = @errorstart + ' - Material Order # already exists in this batch.'
               exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               if @rcode <> 0 goto bspexit
               goto INMB_loop
               end
           -- all Items must be 'adds' with a new MO
           if exists(select 1 from dbo.INIB with(nolock) where Co = @co and Mth = @mth and BatchId = @batchid
               and BatchSeq = @seq and BatchTransType <> 'A')
       		begin
            	select @errortext = @errorstart + ' - All Items on a new Material Order must be ''adds''!'
               exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               if @rcode <> 0 goto bspexit
            	goto INMB_loop
               end
   		-- validate JC Co#
           if not exists(select 1 from dbo.JCCO where JCCo = @jcco)
   			begin
               select @errortext = @errorstart + ' - Invalid JC Co#: ' + convert(varchar(3),@jcco)
               exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               if @rcode <> 0 goto bspexit
               goto INMB_loop
               end
   		-- validate Status
           if @status <> 0     -- open
               begin
               select @errortext = @errorstart + ' - Status on new Material Orders must be ''open''!'
               exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               if @rcode <> 0 goto bspexit
               goto INMB_loop
               end
   		end
   
   	if @transtype = 'C'     -- validation for Change 
   		begin
   		-- validate JC Co# change
   		if @jcco <> @oldjcco
   			begin
   			if exists(select 1 from dbo.INMI with(nolock) where INCo = @co and MO = @mo)
   				begin
   				select @errortext = @errorstart + 'Cannot change JC Company #'
              		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
              		if @rcode <> 0 goto bspexit
              		goto INMB_loop
   		    	end
   			end
   		-- validate Status changes
   		if @status = 2 and @oldstatus <> 2
   			begin
   			select @errortext = @errorstart + 'Cannot change Status to ''Closed''.  Must use Material Order Close program.'
              	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
              	if @rcode <> 0 goto bspexit
              	goto INMB_loop
   
   		    end
   		end
   	if @transtype in ('A','C')
   		begin
   			--Validate that Job Exists
   			if not exists(select 1 from dbo.JCJM with(nolock) where JCCo=@jcco and Job=@headerjob)
   			begin
   				select @errortext = @errorstart + 'Invalid Job. Job does not exist.'
   	           	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	           	if @rcode <> 0 goto bspexit
   	           	goto INMB_loop
   			end
   		end
   	if @transtype = 'D'     -- validation for Delete only
   		begin
           -- all Items in batch must be 'deletes'
           if exists(select 1 from dbo.INIB with(nolock) where Co = @co and Mth = @mth and BatchId = @batchid
   			and BatchSeq = @seq and BatchTransType <> 'D')
               begin
               select @errortext = @errorstart + ' - Cannot delete a Material Order with ''add'' or ''change'' Items.'
               exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      			if @rcode <> 0 goto bspexit
               goto INMB_loop
         		end
   		-- make sure all Items have been added to batch
           select @itemcount = count(*) from dbo.INMI with(nolock) where INCo = @co and MO = @mo
           select @deletecount = count(*)
           from dbo.INIB with(nolock)
           where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and BatchTransType = 'D'
           if @itemcount <> @deletecount
   			begin
               select @errortext = @errorstart + ' - Cannot delete a Material Order unless all of its Items have been included in the batch.'
               exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               if @rcode <> 0 goto bspexit
               goto INMB_loop
               end
   		end
   
   	-- create a cursor to validate all the Items for this MO
       declare bcINIB cursor for
   	select MOItem, BatchTransType, Loc, MatlGroup, Material, Description, 
	JCCo, Job, PhaseGroup, Phase, JCCType, 
	GLCo, GLAcct, 
	UM, OrderedUnits, UnitPrice, ECM, TotalPrice,
   	TaxGroup, TaxCode, TaxAmt, RemainUnits, 
	OldLoc, OldMatlGroup, OldMaterial, 
	OldJCCo, OldJob,
   	OldPhaseGroup, OldPhase, OldJCCType, 
	OldUM, OldOrderedUnits, OldUnitPrice, OldECM, OldTotalPrice, 
	OldTaxGroup, OldTaxCode, OldTaxAmt, OldRemainUnits
    from dbo.INIB with(nolock)
    where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   
       open bcINIB
       select @opencursorINIB = 1
   
    	INIB_loop:     -- get next Item
   		fetch next from bcINIB into @moitem, @itemtranstype, @loc, @matlgroup, @material, @itemdesc,
        @itemjcco, @job, @phasegroup, @phase, @jcctype, @glco, @glacct, @um, @orderunits, @unitprice,
   		@ecm, @totalprice, @taxgroup, @taxcode, @taxamt, @remainunits,  @oldloc, @oldmatlgroup, @oldmaterial,
   		@olditemjcco, @oldjob, @oldphasegroup, @oldphase, @oldjcctype, @oldum, @oldorderunits,
   		@oldunitprice, @oldecm, @oldtotalprice, @oldtaxgroup, @oldtaxcode, @oldtaxamt, @oldremainunits
   
           if @@fetch_status <> 0 goto INIB_end
   
           select @errorstart = 'Seq#: ' + convert(varchar(6),@seq) + ' Item: ' + convert(varchar(6),@moitem) + ' '
   
           -- validate transaction type
   		if @itemtranstype not in ('A','C','D')
   			begin
               select @errortext = @errorstart + ' -  Invalid transaction type, must be ''A'',''C'', or ''D''.'
               exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               if @rcode <> 0 goto bspexit
               goto INIB_loop
               end
   		-- validate JC Co#
   		if @itemjcco <> @jcco
   			begin
   			select @errortext = @errorstart + ' - JC Co# in Item must match header.'
               exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               if @rcode <> 0 goto bspexit
               goto INIB_loop
               end
   		-- validate GL Co#
   		if not exists(select 1 from dbo.JCCO  with(nolock) where JCCo = @jcco and GLCo = @glco)
   			begin
   			select @errortext = @errorstart + ' - GL Co# does not match currently assigned GL Company in Job Cost.'
               exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               if @rcode <> 0 goto bspexit
               goto INIB_loop
               end
   		-- validate Month in JC GL Co# - subledgers must be open
   		if @glco <> isnull(@lastglco,@glco) 
   			begin
   			exec @rcode = dbo.bspHQBatchMonthVal @glco, @mth, 'IN', @errmsg output
               if @rcode <> 0
               	begin
                   select @errortext = @errorstart + ' - ' + @errmsg
                   exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                   if @rcode <> 0 goto bspexit
   				goto INIB_loop
                   end
   			select @lastglco = @glco
   			end
   
          if @itemtranstype = 'A'
   			begin
   			-- check for unique Item #
   			if exists(select 1 from dbo.INMI with(nolock) where INCo = @co and MO = @mo and MOItem = @moitem)
   				begin
   				select @errortext = @errorstart + ' -  Item number already exists.'
   				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   				if @rcode <> 0 goto bspexit
   				goto INIB_loop
   				end
   			end
   
   		if @itemtranstype in ('A','C')		-- validation for 'add' and 'change' items
   			begin
   			-- validate Location
   			if not exists(select 1 from dbo.INLM with(nolock) where INCo = @co and Loc = @loc and Active = 'Y')
   				begin
                   select @errortext = @errorstart + ' - Invalid or inactive Location.'
                   exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                   if @rcode <> 0 goto bspexit
                   goto INIB_loop
                   end
   			-- validate Material
   			if not exists(select 1 from dbo.INMT with(nolock) where INCo = @co and Loc = @loc and MatlGroup = @matlgroup
   					and Material = @material and Active = 'Y')
   				begin
   				select @errortext = @errorstart + ' - Invalid or inactive Material at this Location.'
                   exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                   if @rcode <> 0 goto bspexit
                   goto INIB_loop
                   end
   			-- validate Job, Phase, and Cost Type
   			exec @rc = dbo.bspJobTypeVal @jcco, @phasegroup, @job, @phase, @jcctype, @jcum output, @errmsg output
   			if @rc <> 0
   				begin
   				select @errortext = @errorstart + ' - ' + @errmsg
                   exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                   if @rcode <> 0 goto bspexit
                   goto INIB_loop
                   end
   			-- validate GL Account - must be subledger type 'J'
   			exec @rc = dbo.bspGLACfPostable @glco, @glacct, 'J', @errmsg output
   			if @rc <> 0
   				begin
   				select @errortext = @errorstart + ' - ' + @errmsg
                   exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                   if @rcode <> 0 goto bspexit
                   goto INIB_loop
                   end
   			-- validate Material U/M
   			exec @rc = dbo.bspINMOMatlUMVal @co, @loc, @material, @matlgroup, @um, @conv = @umconv output, @msg = @errmsg output
   			if @rc <> 0
   				begin
   				select @errortext = @errorstart + ' - ' + @errmsg
                   exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                   if @rcode <> 0 goto bspexit
                   goto INIB_loop
                   end
   			-- validate Tax Code
   			select @taxrate = 0, @taxphase = @phase, @taxjcctype = @jcctype
   			if @taxcode is not null
   				begin
   				----#141031
   				select @taxgetdate = dbo.vfDateOnly()
   				exec @rc = dbo.bspHQTaxRateGet @taxgroup, @taxcode, @taxgetdate, @taxrate output,
   						@taxphase output, @taxjcctype output, @errmsg output
       			if @rc <> 0
   					begin
   					select @errortext = @errorstart + ' - ' + @errmsg 
   	                exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	                if @rcode <> 0 goto bspexit
   	                goto INIB_loop
   	                end
   				if @taxphase is null select @taxphase = @phase
   				if @taxjcctype is null select @taxjcctype = @jcctype
   				if @taxphase <> @phase or @taxjcctype <> @jcctype
   					begin
   					-- validate Tax Phase and Cost Type
   					exec @rc = dbo.bspJobTypeVal @jcco, @phasegroup, @job, @taxphase, @taxjcctype, @errmsg = @errmsg output
   					if @rc <> 0
   						begin
   						select @errortext = @errorstart + ' - ' + @errmsg
                   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                   		if @rcode <> 0 goto bspexit
                   		goto INIB_loop
                   		end
   					end
   				end
   			if @taxcode is null and @taxamt <> 0.00
   				begin
   				select @errortext = @errorstart + ' - Tax amount must be 0.00 if Tax Code is not specified.' + @errmsg
   	            exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	            if @rcode <> 0 goto bspexit
   	            goto INIB_loop
   	            end
   			-- determine conversion factor from posted UM to JC UM
               select @jcumconv = 0
               if isnull(@jcum,'') = @um select @jcumconv = 1
               if isnull(@jcum,'') <> @um
   				begin
                   exec @rcode = dbo.bspHQStdUMGet @matlgroup, @material, @jcum, @jcumconv output, @msg = @errmsg output
                   if @rcode <> 0
   					begin
                       select @errortext = @errorstart + '- JC UM: ' + @jcum + ' for Material: ' + @material + ' - ' + @errmsg
                       exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                       if @rcode <> 0 goto bspexit
                       goto INIB_loop
                       end
   				if @jcumconv <> 0 select @jcumconv = @umconv / @jcumconv
   				end
   			-- calculate total and remaining JC units
   			select @jcunits = @orderunits * @jcumconv, @jcremainunits = @remainunits * @jcumconv
   			end
   
   		if @itemtranstype in ('C','D')      -- validation specific to both 'change' and 'delete' Items
   			begin
              	-- get current values from Item
              	select @inmiloc = Loc, @inmimatlgroup = MatlGroup, @inmimaterial = Material, @inmijcco = JCCo,
   				@inmijob = Job, @inmiphasegroup = PhaseGroup, @inmiphase = Phase, @inmijcctype = JCCType,
   				@inmium = UM, @inmiorderunits = OrderedUnits, @inmiunitprice = UnitPrice, @inmiecm = ECM,
   				@inmitotalprice = TotalPrice, @inmitaxgroup = TaxGroup, @inmitaxcode = TaxCode,
   				@inmiconfirmedunits = ConfirmedUnits, @inmiremainunits = RemainUnits
                from dbo.INMI with(nolock)
                where INCo = @co and MO = @mo and MOItem = @moitem
                if @@rowcount = 0
                begin
					select @errortext = @errorstart + ' - Invalid Item!'
					exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
                    goto INIB_loop
                end

   				if @inmiloc <> @oldloc or @inmimatlgroup <> @oldmatlgroup or @inmimaterial <> @oldmaterial
				or @inmijcco <> @olditemjcco or @inmijob <> @oldjob or @inmiphasegroup <> @oldphasegroup
   				or @inmijcctype <> @oldjcctype or @inmium <> @oldum or @inmiorderunits <> @oldorderunits
   				or @inmiunitprice <> @oldunitprice or @inmiecm <> @oldecm or @inmitotalprice <> @oldtotalprice 
                or isnull(@inmitaxgroup,0) <> isnull(@oldtaxgroup,0) or isnull(@inmitaxcode,'') <> isnull(@oldtaxcode,'')
                or @inmiremainunits <> @oldremainunits 
               	begin
                	select @errortext = @errorstart + ' - ''Old'' batch values do not match current Item values!'
                	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                	if @rcode <> 0 goto bspexit
                	goto INIB_loop
                end

	   			-- cannot delete Item if confirmed units exist
   				if @inmiconfirmedunits <> 0 and @itemtranstype = 'D'
   				begin
   					select @errortext = @errorstart + ' - Item has confirmed units, cannot delete!'
                    exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                    if @rcode <> 0 goto bspexit
                    goto INIB_loop
                end
				
				/** Issue 125273 **/
				-- Item has confirmed units, Job, Phase or CostType cannot be changed!
   				if @inmiconfirmedunits <> 0 and @itemtranstype = 'C' and
			   (@inmijob <> @oldjob or @phase <> @oldphase or @inmijcctype <> @oldjcctype)
   				begin
   					select @errortext = @errorstart + ' - Item has confirmed units, Job, Phase or CostType cannot be changed!'
                    exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                    if @rcode <> 0 goto bspexit
                    goto INIB_loop
                end

   				-- validate Old Location
   				if not exists(select 1 from dbo.INLM with(nolock) where INCo = @co and Loc = @oldloc and Active = 'Y')
   				begin
               		select @errortext = @errorstart + ' - Invalid or inactive Location: ' + @oldloc 
               		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               		if @rcode <> 0 goto bspexit
               		goto INIB_loop
               	end
   
	   			-- validate Old Material
   				if not exists(select 1 from dbo.INMT with(nolock) where INCo = @co and Loc = @oldloc and MatlGroup = @oldmatlgroup
   				and Material = @oldmaterial and Active = 'Y')
   				begin
   					select @errortext = @errorstart + ' - Invalid or inactive Material: ' + @oldmaterial + ' at Location: ' + @oldloc
				   	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
               		goto INIB_loop
               	end

	   			-- validate Old Job, Phase, and Cost Type
   				exec @rc = dbo.bspJobTypeVal @oldjcco, @oldphasegroup, @oldjob, @oldphase, @oldjcctype, @oldjcum output, @errmsg output
   				if @rc <> 0
   				begin
   					select @errortext = @errorstart + ' - ' + @errmsg
               		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               		if @rcode <> 0 goto bspexit
               		goto INIB_loop
               	end

	   			-- validate Old Material U/M
   				exec @rc = dbo.bspINMOMatlUMVal @co, @oldloc, @oldmaterial, @oldmatlgroup, @oldum, @conv = @oldumconv output, @msg = @errmsg output
   				if @rc <> 0
   				begin
   					select @errortext = @errorstart + ' - ' + @errmsg
               		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               		if @rcode <> 0 goto bspexit
               		goto INIB_loop
               	end

	   			-- validate Tax Code 
   				select @oldtaxphase = @oldphase, @oldtaxjcctype = @oldjcctype, @oldtaxrate = 0
   				if @oldtaxcode is not null
   				begin
   				----#141031
   					select @taxgetdate = dbo.vfDateOnly()
   					exec @rc = dbo.bspHQTaxRateGet @oldtaxgroup, @oldtaxcode, @taxgetdate, @oldtaxrate output,
   					@oldtaxphase output, @oldtaxjcctype output, @errmsg output
   					if @rc <> 0
   					begin
   						select @errortext = @errorstart + ' - ' + @errmsg
                   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                   		if @rcode <> 0 goto bspexit
                   		goto INIB_loop
                  	 end
   				if @oldtaxphase is null select @oldtaxphase = @oldphase
   				if @oldtaxjcctype is null select @oldtaxjcctype = @oldjcctype
   				if @oldtaxphase <> @oldphase or @oldtaxjcctype <> @oldjcctype
   				begin
   				-- validate Old Tax Phase and Cost Type
   					exec @rc = bspJobTypeVal @oldjcco, @oldphasegroup, @oldjob, @oldtaxphase, @oldtaxjcctype, @errmsg = @errmsg output
   					if @rc <> 0
   						begin
   							select @errortext = @errorstart + ' - ' + @errmsg
               				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               				if @rcode <> 0 goto bspexit
               				goto INIB_loop
               			end
   				end
   			end
   			-- determine conversion factor from posted UM to JC UM
   			select @oldjcumconv = 0
           	if isnull(@oldjcum,'') = @oldum select @oldjcumconv = 1
           	if isnull(@oldjcum,'') <> @oldum
   				begin
               		exec @rcode = dbo.bspHQStdUMGet @oldmatlgroup, @oldmaterial, @oldjcum, @oldjcumconv output, @msg = @errmsg output
               		if @rcode <> 0
   					begin
                   		select @errortext = @errorstart + '- JC UM: ' + @oldjcum + ' for Material: ' + @oldmaterial + ' - ' + @errmsg
						exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
						if @rcode <> 0 goto bspexit
                   		goto INIB_loop
                   	end
   					if @oldjcumconv <> 0 select @oldjcumconv = @oldumconv / @oldjcumconv
   				end
   			end
   
   		update_audit:       -- update JC distributions
   			if @itemtranstype in ('D','C')        -- old entries
   				begin
   				-- calculate Old Total and Remaining JC Units
   				select @oldjcunits = @oldorderunits * @oldjcumconv, @oldjcremainunits = @oldremainunits * @oldjcumconv
   				-- calculate Total Committed Cost
  				select @totalamt = (-1 * @oldtotalprice)

   				-- if tax is not redirected, include with total committed cost 
   				if @oldtaxphase = @oldphase and @oldtaxjcctype = @oldjcctype select @totalamt = @totalamt + (-1 * @oldtaxamt)
   				
				-- calculate Remaining Committed Cost
   				select @factor = case @oldecm when 'M' then 1000 when 'C' then 100 else 1 end
   				select @remainamt = (-1 * @oldremainunits * @oldunitprice) / @factor
   				
				-- if tax is not redirected, include with remaining committed cost 
   				if @oldtaxphase = @oldphase and @oldtaxjcctype = @oldjcctype select @remainamt = (1 + @oldtaxrate) * @remainamt 
   
   	            insert dbo.INJC (INCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType,
   	            	BatchSeq, MOItem, OldNew, MO, Description, Loc, MatlGroup, Material, UM, OrderedUnits,
   					RemainUnits, TotalCmtdCost, RemainCmtdCost, JCUM, JCUnits, JCRemainUnits)
   	            values (@co, @mth, @batchid, @oldjcco, @oldjob, @oldphasegroup, @oldphase, @oldjcctype,
   	                @seq, @moitem, 0, @mo, @olditemdesc, @oldloc, @oldmatlgroup, @oldmaterial, @oldum,
   					(-1 * @oldorderunits), (-1 * @oldremainunits), @totalamt, @remainamt, @oldjcum,
   					(-1 * @oldjcunits), (-1 * @oldjcremainunits))
   
   				-- Tax is redirected to another Phase and/or Cost Type
   				if @oldtaxamt <> 0 and (@oldtaxphase <> @oldphase or @oldtaxjcctype <> @oldjcctype)
   					begin
   					insert dbo.INJC (INCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType,
   	            		BatchSeq, MOItem, OldNew, MO, Description, Loc, MatlGroup, Material, UM, OrderedUnits,
   						RemainUnits, TotalCmtdCost, RemainCmtdCost, JCUM, JCUnits, JCRemainUnits)
   	            	values (@co, @mth, @batchid, @oldjcco, @oldjob, @oldphasegroup, @oldtaxphase, @oldtaxjcctype,
   	                	@seq, @moitem, 0, @mo, @olditemdesc, @oldloc, @oldmatlgroup, @oldmaterial, @oldum, 0,
						/** Issue 125273 **/
   	 					0, (-1*@oldtaxamt), (-1*@oldtaxamt), @oldjcum, 0, 0)
						----(-1 * @totalamt * @oldtaxrate), (-1 * @remainamt * @oldtaxrate), @oldjcum, 0, 0)
   					end
 				end

   		
   			if @itemtranstype in ('A','C')        -- new entries
   				begin
   				-- calculate Total and Remaining JC Units
   				select @jcunits = @orderunits * @jcumconv, @jcremainunits = @remainunits * @jcumconv
   				-- calculate Total Committed Cost
   				select @totalamt = @totalprice
   				-- if tax is not redirected, include with total committed cost 
   				if @taxphase = @phase and @taxjcctype = @jcctype select @totalamt = @totalamt + @taxamt
   				-- calculate Remaining Committed Cost
   				select @factor = case @ecm when 'M' then 1000 when 'C' then 100 else 1 end
   				select @remainamt = (@remainunits * @unitprice) / @factor
   				-- if tax is not redirected, include with remaining committed cost 
   				if @taxphase = @phase and @taxjcctype = @jcctype select @remainamt = (1 + @taxrate) * @remainamt 
   
   	            insert dbo.INJC (INCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType,
   	            	BatchSeq, MOItem, OldNew, MO, Description, Loc, MatlGroup, Material, UM, OrderedUnits,
   					RemainUnits, TotalCmtdCost, RemainCmtdCost, JCUM, JCUnits, JCRemainUnits)
   	            values (@co, @mth, @batchid, @jcco, @job, @phasegroup, @phase, @jcctype,
   	                @seq, @moitem, 1, @mo, @itemdesc, @loc, @matlgroup, @material, @um, @orderunits,
   	 				@remainunits, @totalamt, @remainamt, @jcum, @jcunits, @jcremainunits)
   	
   				-- Tax is redirected to another Phase and/or Cost Type
   				if @taxamt <> 0 and (@taxphase <> @phase or @taxjcctype <> @jcctype) 
   					begin
   					insert dbo.INJC (INCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType,
   	            		BatchSeq, MOItem, OldNew, MO, Description, Loc, MatlGroup, Material, UM, OrderedUnits,
   						RemainUnits, TotalCmtdCost, RemainCmtdCost, JCUM, JCUnits, JCRemainUnits)
   	            	values (@co, @mth, @batchid, @jcco, @job, @phasegroup, @taxphase, @taxjcctype,
   	                	@seq, @moitem, 1, @mo, @itemdesc, @loc, @matlgroup, @material, @um, 0,
   	 					0, (@totalamt * @taxrate), (@remainamt * @taxrate), @jcum, 0, 0)
   					end
   				end
   
            	goto INIB_loop  -- next Item
   
   		INIB_end:
            	close bcINIB
            	deallocate bcINIB
            	select @opencursorINIB = 0
   
            	goto INMB_loop      -- next MO Header
   
   	INMB_end:
   		close bcINMB
   	    deallocate bcINMB
   	    select @opencursorINMB = 0
   
   
   -- check HQ Batch Errors and update HQ Batch Control status 
   select @status = 3  -- valid - ok to post 
   if exists(select 1 from dbo.HQBE with(nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
   	begin
       select @status = 2 -- validation errors 
       end
   update dbo.HQBC
   set Status = @status
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount <> 1
       begin
       select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
       goto bspexit
       end
   
   bspexit:
   	if @opencursorINIB = 1
   		begin
           close bcINIB
           deallocate bcINIB
           end
       if @opencursorINMB = 1
           begin
           close bcINMB
           deallocate bcINMB
           end
   
 --  	if @rcode <> 0 select @errmsg
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMBVal] TO [public]
GO
