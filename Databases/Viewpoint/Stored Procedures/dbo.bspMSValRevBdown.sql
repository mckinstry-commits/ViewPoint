SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************/
   CREATE procedure [dbo].[bspMSValRevBdown]
   /*****************************************************************************
    * Created By:	GG 04/17/01
    * Modified By:	GF 12/05/2003 - #23205 - check error messages, wrap concatenated values with isnull
    *				GF 03/10/2005 - issue #27357 if @bdownrate = 0 and @rate = 0 set @bdownamt = @revtotal
	*				DAN SO 03/26/2009 - #132808 - If GLAcct is null - call bspHQBEInsert
    *
    *
    *
    * USAGE:
    *   Called by bspMSTBValRev and bspMSLBValRev to create Equipment Revenue
    *   Breakdown distributions when a ticket or hauler time sheet is posted with EM revenue amount.
    *
    *   Adds/updates entries in bMSRB and bMSGL.
    *
    *   Errors in batch added to bHQBE using bspHQBEInsert
    *
    * INPUT PARAMETERS
    *     @msco           MS/IN Co#
    *     @mth            Batch month
    *     @batchid        Batch ID
    *     @seq            Batch Sequence
    *     @haulline       Haul Line (0 for tickets)
    *     @oldnew         0 = old (use old values from bMSTB, reverse sign on amounts),
    *                     1 = new (use current values from bMSTB)
    *     @fromloc        Sold from IN Location
    *     @saletype       Sale type: 'C'=Customer, 'J'=Job, 'I'=Inventory
    *     @matlgroup      Material Group
    *     @material       Material sold
    *     @msglco         MS/IN GL Co#
    *     @revtotal       Total EM Revenue
    *     @mstrans        MS Trans#   (null on new entries)
    *     @ticket         Ticket #
    *     @saledate       Sale Date
    *     @custgroup      Customer Group
    *     @customer       Customer
    *     @custjob        Customer Job
    *     @jcco           JC Co#
    *     @job            Job
    *     @inco           Sold to IN Co#
    *     @toloc          Sold to IN Location
    *     @emco           EM Co#
    *     @equipment      Equipment
    *     @emgroup        EM Group
    *     @revcode        Revenue Code
    *     @revglacct      EM Revenue GL Account
    *     @emglco         EM GL Co#
    *     @emdept         Equipment department
    *     @category       Equipment category
    *
    * OUTPUT PARAMETERS
    *   @errmsg        error message
    *
    * RETURN
    *   0 = successs, 1 = error
    *
    *******************************************************************************/
       (@msco bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @seq int = null, @haulline smallint = null,
        @oldnew tinyint = null, @fromloc bLoc = null, @saletype char(1) = null, @matlgroup bGroup = null,
        @material bMatl = null, @msglco bCompany = null, @revtotal bDollar = null, @mstrans bTrans = null,
        @ticket bTic = null, @saledate bDate = null, @custgroup bGroup = null, @customer bCustomer = null,
        @custjob varchar(20) = null, @jcco bCompany = null, @job bJob = null, @inco bCompany = null,
        @toloc bLoc = null, @emco bCompany = null, @equipment bEquip = null, @emgroup bGroup = null,
        @revcode bRevCode = null, @revglacct bGLAcct = null, @emglco bCompany = null, @emdept bDept = null,
        @category varchar(10) = null, @errmsg varchar(255) output)
   
   as
   
   set nocount on

   declare @rcode int, @errorstart varchar(10), @revtemp varchar(10), @revtemptype char(1), @errortext varchar(255),
       @rate bDollar, @tedisc bPct, @totbdownamt bDollar, @bdowncode bRevCode, @bdownrate bDollar, @bdownamt bDollar,
       @glacct bGLAcct, @tcdisc bPct, @lastbdowncode bRevCode, @disc bPct, @arglacct bGLAcct, @apglacct bGLAcct
   
   select @rcode = 0, @errorstart = 'Seq#' + convert(varchar(6),@seq)
   
   -- *** process Equipment Revenue Breakdowns ***
   
   -- check for a Revenue Template
   select @revtemp = RevTemplate
   from bEMJT where EMCo = @emco and JCCo = @jcco and Job = @job
   if @revtemp is not null
       begin
       -- get Revenue Template type (Percent or Override)
       select @revtemptype = TypeFlag
       from bEMTH where EMCo = @emco and RevTemplate = @revtemp
       if @@rowcount = 0
           begin
           select @errortext = @errorstart + ' - Invalid EM Revenue Template: ' + isnull(@revtemp,''), @rcode = 1
           exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
       	goto bspexit
           end
       -- check Template Equipment
       select @rate = Rate, @tedisc = DiscFromStdRate
       from bEMTE
       where EMCo = @emco and RevTemplate = @revtemp and Equipment = @equipment and EMGroup = @emgroup and RevCode = @revcode
       if @@rowcount = 1 and @revtemptype = 'O'
           begin
           -- pull breakdown codes from bEMTF only if Template is an override type and a rate exists for the equipment
           select @totbdownamt = 0     -- total revenue distributed to breakdown codes
           -- cycle through Breakdown codes in bEMTF, must exist if override template with rates by Equipment
           select @bdowncode = null
           select @bdowncode = min(RevBdownCode)   -- get first
           from bEMTF
           where EMCo = @emco and RevTemplate = @revtemp and Equipment = @equipment
               and EMGroup = @emgroup and RevCode = @revcode
           if @bdowncode is null
               begin
               select @errortext = @errorstart + ' - Missing Breakdown Codes for Template: '
                   + isnull(@revtemp,'') + ' Equipment: ' + isnull(@equipment,'') + ' and Revenue Code: ' + isnull(@revcode,'')
               exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
       	    goto bspexit
               end
           while @bdowncode is not null
               begin
               -- get Breakdown Rate
               select @bdownrate = Rate
               from bEMTF
               where EMCo = @emco and RevTemplate = @revtemp and Equipment = @equipment
                   and EMGroup = @emgroup and RevCode = @revcode and RevBdownCode = @bdowncode
               -- if exists, use Dept Revenue GL Account for Revenue Code
               select @glacct = @revglacct
               if @glacct is null -- else use Dept Revenue GL Account for Breakdown code
                   begin
                   select @glacct = GLAcct
                   from bEMDB
                   where EMCo = @emco and Department = @emdept and EMGroup = @emgroup and RevBdownCode = @bdowncode
                   end

               -- calculate Breakdown revenue
               select @bdownamt = 0
   			if @bdownrate = 0 and @rate = 0
   				select @bdownamt = @revtotal
   			else
               	if @rate <> 0 select @bdownamt = (@bdownrate / @rate) * @revtotal    -- proportional based on rates
   			-- -- -- if @bdownamt <> 0 insert revenue breakdown
               if @bdownamt <> 0
                   begin
                   -- add distribution for Revenue Breakdown
                   insert bMSRB(MSCo, Mth, BatchId, EMCo, Equipment, EMGroup, RevCode, SaleType, RevBdownCode,
                       BatchSeq, HaulLine, OldNew, Amount, GLCo, GLAcct)
                   values (@msco, @mth, @batchid, @emco, @equipment, @emgroup, @revcode, @saletype, @bdowncode,
                       @seq, @haulline, @oldnew, @bdownamt, @emglco, @glacct)
   
                   -- validate Equipment Revenue Account
                   exec @rcode = dbo.bspGLACfPostable @emglco, @glacct, 'E', @errmsg output
                   if @rcode <> 0
                       begin
                       select @errortext = @errorstart + ' - Equipment Revenue Account ' + isnull(@errmsg,'')
                       exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
       	            goto bspexit
                       end
                   -- Revenue credit for breakdown amount posted in EM GL Co#
                   update bMSGL set Amount = Amount - @bdownamt
                   where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @emglco and GLAcct = @glacct
                       and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
                   if @@rowcount = 0
                   insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                       FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
                   values(@msco, @mth, @batchid, @emglco, @glacct, @seq, @haulline, @oldnew, @mstrans, @ticket, @saledate,
                       @fromloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob, @jcco, @job,
                       @inco, @toloc, -@bdownamt)
                   end
   
               select @totbdownamt = @totbdownamt + @bdownamt  -- accumulate distributed Breakdown revenue
               -- get next Breakdown code
               select @bdowncode = min(RevBdownCode)
               from bEMTF
               where EMCo = @emco and RevTemplate = @revtemp and Equipment = @equipment
                   and EMGroup = @emgroup and RevCode = @revcode and RevBdownCode > @bdowncode
               end
   
           goto update_diff
           end
   
       -- Equipment not on Template, check for Template Category
       select @rate = Rate, @tcdisc = DiscFromStdRate
       from bEMTC
       where EMCo = @emco and RevTemplate = @revtemp and Category = @category and EMGroup = @emgroup and RevCode = @revcode
       if @@rowcount = 1 and @revtemptype = 'O'
           begin
           -- pull breakdown codes from bEMTD only if Template is an override type and a rate exists for the category
           select @totbdownamt = 0     -- total revenue distributed to breakdown codes
           -- cycle through Breakdown codes in bEMTD
           select @bdowncode = null
           select @bdowncode = min(RevBdownCode)   -- get first
           from bEMTD
           where EMCo = @emco and RevTemplate = @revtemp and Category = @category
               and EMGroup = @emgroup and RevCode = @revcode
           if @bdowncode is null
               begin
               select @errortext = @errorstart + ' - Missing Breakdown Codes for Template: '
                   + isnull(@revtemp,'') + ' Category: ' + isnull(@category,'') + ' and Revenue Code: ' + isnull(@revcode,'')
               exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
       	    goto bspexit
               end
           while @bdowncode is not null
               begin
               -- get Breakdown rate
               select @bdownrate = Rate
               from bEMTD
               where EMCo = @emco and RevTemplate = @revtemp and Category = @category
                   and EMGroup = @emgroup and RevCode = @revcode and RevBdownCode = @bdowncode
               -- if exists, use Dept Revenue GL Account for Revenue Code
               select @glacct = @revglacct
               if @glacct is null -- else use Dept Revenue GL Account for Breakdown code
                   begin
                   select @glacct = GLAcct
                   from bEMDB
                   where EMCo = @emco and Department = @emdept and EMGroup = @emgroup and RevBdownCode = @bdowncode
                   end
               -- calculate Breakdown revenue
               select @bdownamt = 0
   			if @bdownrate = 0 and @rate = 0
   				select @bdownamt = @revtotal
   			else
               	if @rate <> 0 select @bdownamt = (@bdownrate / @rate) * @revtotal    -- proportional based on rates
   			-- -- -- if @bdownamt <> 0 insert revenue breakdown
               if @bdownamt <> 0
                   begin
                   -- add distribution for Revenue Breakdown
                   insert bMSRB(MSCo, Mth, BatchId, EMCo, Equipment, EMGroup, RevCode, SaleType, RevBdownCode,
                       BatchSeq, HaulLine, OldNew, Amount, GLCo, GLAcct)
                   values (@msco, @mth, @batchid, @emco, @equipment, @emgroup, @revcode, @saletype, @bdowncode,
                       @seq, @haulline, @oldnew, @bdownamt, @emglco, @glacct)
   
                   -- validate Equipment Revenue Account
                   exec @rcode = dbo.bspGLACfPostable @emglco, @glacct, 'E', @errmsg output
                   if @rcode <> 0
                       begin
                       select @errortext = @errorstart + ' - Equipment Revenue Account ' + isnull(@errmsg,'')
                       exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
       	            goto bspexit
                       end
                   -- Revenue credit for breakdown amount posted in EM GL Co#
                   update bMSGL set Amount = Amount - @bdownamt
                   where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @emglco and GLAcct = @glacct
                       and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
                   if @@rowcount = 0
                       insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                           FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
                       values(@msco, @mth, @batchid, @emglco, @glacct, @seq, @haulline, @oldnew, @mstrans, @ticket, @saledate,
                           @fromloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob, @jcco, @job,
                           @inco, @toloc, -@bdownamt)
                   end
   
               select @totbdownamt = @totbdownamt + @bdownamt  -- accumulate distributed Breakdown revenue
               -- get next Breakdown code
               select @bdowncode = min(RevBdownCode)
               from bEMTD
               where EMCo = @emco and RevTemplate = @revtemp and Category = @category
                   and EMGroup = @emgroup and RevCode = @revcode and RevBdownCode > @bdowncode
               end
   
           goto update_diff
           end
       end
   
   -- drop through if no Revenue Template or Template w/o override rates (all type P and type O w/o entries for the Equip or Category)
   
   -- assign discount from std rate, will be 0 unless setup in Template
   select @disc = coalesce(@tedisc,@tcdisc,0)
   
   -- check for Revenue Rate override by Equipment
   select @rate = Rate
   from bEMRH where EMCo = @emco and Equipment = @equipment and EMGroup = @emgroup and RevCode = @revcode
       and ORideRate = 'Y'
   if @@rowcount = 1
       begin
       select @rate = (1 - (@disc/100)) * @rate -- apply discount
   
       -- pull breakdown codes from bEMBE if rate exists for the Equipment
       select @totbdownamt = 0     -- total revenue distributed to breakdown codes
   
       -- cycle through Breakdown codes in bEMBE, must exist if override rates setup by Equipment
       select @bdowncode = null
       select @bdowncode = min(RevBdownCode)   -- get first
       from bEMBE
       where EMCo = @emco and Equipment = @equipment and EMGroup = @emgroup and RevCode = @revcode
       if @bdowncode is null
           begin
           select @errortext = @errorstart + ' - Missing Breakdown Codes for Equipment: '
               + isnull(@equipment,'') + ' and Revenue Code: ' + isnull(@revcode,'')
           exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
       	goto bspexit
           end
       while @bdowncode is not null
           begin
           -- get Breakdown rate
           select @bdownrate = Rate
           from bEMBE
           where EMCo = @emco and Equipment = @equipment and EMGroup = @emgroup and RevCode = @revcode
               and RevBdownCode = @bdowncode
   
           -- if exists, use Dept Revenue GL Account for Revenue Code
           select @glacct = @revglacct
           if @glacct is null -- else use Dept Revenue GL Account for Breakdown code
               begin
               select @glacct = GLAcct
               from bEMDB
               where EMCo = @emco and Department = @emdept and EMGroup = @emgroup and RevBdownCode = @bdowncode
               end
   
           -- calculate Breakdown revenue
           select @bdownamt = 0
   		if @bdownrate = 0 and @rate = 0
   			select @bdownamt = @revtotal
   		else
               if @rate <> 0 select @bdownamt = (@bdownrate / @rate) * @revtotal    -- proportional based on rates
   		-- -- -- if @bdownamt <> 0 insert revenue breakdown
           if @bdownamt <> 0
               begin
               -- add distribution for Revenue Breakdown
               insert bMSRB(MSCo, Mth, BatchId, EMCo, Equipment, EMGroup, RevCode, SaleType, RevBdownCode,
                   BatchSeq, HaulLine, OldNew, Amount, GLCo, GLAcct)
               values (@msco, @mth, @batchid, @emco, @equipment, @emgroup, @revcode, @saletype, @bdowncode,
                   @seq, @haulline, @oldnew, @bdownamt, @emglco, @glacct)
   
               -- validate Equipment Revenue Account
               exec @rcode = dbo.bspGLACfPostable @emglco, @glacct, 'E', @errmsg output
               if @rcode <> 0
                   begin
                   select @errortext = @errorstart + ' - Equipment Revenue Account ' + isnull(@errmsg,'')
                   exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
       	        goto bspexit
                   end
               -- Revenue credit for breakdown amount posted in EM GL Co#
               update bMSGL set Amount = Amount - @bdownamt
               where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @emglco and GLAcct = @glacct
                   and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
               if @@rowcount = 0
                   insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
   					FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
                   values(@msco, @mth, @batchid, @emglco, @glacct, @seq, @haulline, @oldnew, @mstrans, @ticket, @saledate,
                       @fromloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob, @jcco, @job,
                       @inco, @toloc, -@bdownamt)
               end
   
           select @totbdownamt = @totbdownamt + @bdownamt  -- accumulate distributed Breakdown revenue
           -- get next Breakdown code
           select @bdowncode = min(RevBdownCode)
           from bEMBE
           where EMCo = @emco and Equipment = @equipment and EMGroup = @emgroup and RevCode = @revcode
               and RevBdownCode > @bdowncode
           end
   
       goto update_diff
       end
   
   -- no Equipment Rates, check for Category Rate - last stop
   select @rate = Rate
   from bEMRR
   where EMCo = @emco and Category = @category and EMGroup = @emgroup and RevCode = @revcode
   if @@rowcount = 0
         begin
         select @errortext = @errorstart + 'Invalid EM Category: ' + isnull(@category,'') + ' and Revenue Code: ' + isnull(@revcode,'')
         exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
         goto bspexit
         end
   
   select @rate = (1 - (@disc/100)) * @rate -- apply discount
   
   -- pull breakdown codes from bEMBG
   select @totbdownamt = 0     -- total revenue distributed to breakdown codes
   
   -- cycle through Breakdown codes in bEMBG
   select @bdowncode = null
   select @bdowncode = min(RevBdownCode)   -- get first
   from bEMBG
   where EMCo = @emco and Category = @category and EMGroup = @emgroup and RevCode = @revcode
   if @bdowncode is null
       begin
       select @errortext = @errorstart + ' - Missing Breakdown Codes for Category: '
           + isnull(@category,'') + ' and Revenue Code: ' + isnull(@revcode,'')
       exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
       goto bspexit
       end
   while @bdowncode is not null
       begin
       -- get Breakdown rate
       select @bdownrate = Rate
       from bEMBG
       where EMCo = @emco and Category = @category and EMGroup = @emgroup and RevCode = @revcode
           and RevBdownCode = @bdowncode
   
       -- if exists, use Dept Revenue GL Account for Revenue Code
       select @glacct = @revglacct
       if @glacct is null -- else use Dept Revenue GL Account for Breakdown code
           begin
           select @glacct = GLAcct
           from bEMDB
           where EMCo = @emco and Department = @emdept and EMGroup = @emgroup and RevBdownCode = @bdowncode
           end

	  -- CHECK AGAIN FOR GLAcct = NULL -- #132808
	  if @glacct is null
		   begin
		   select @errortext = @errorstart + ' - Missing GLAcct for Breakdown Code: ' +
							isnull(cast(@bdowncode as varchar(10)),'NULL') + '  for Department: ' +
							isnull(cast(@emdept as varchar(10)),'NULL')
		   exec @rcode = dbo.bspHQBEInsert @emco, @mth, @batchid, @errortext, @errmsg output
			set @rcode = 1
		   goto bspexit
		   end

       -- calculate Breakdown revenue
       select @bdownamt = 0
   	if @bdownrate = 0 and @rate = 0
   		select @bdownamt = @revtotal
   	else
   		if @rate <> 0 select @bdownamt = (@bdownrate / @rate) * @revtotal    -- proportional based on rates
   	-- -- -- if @bdownamt <> 0 insert revenue breakdown

       if @bdownamt <> 0
           begin
           -- add distribution for Revenue Breakdown
           insert bMSRB(MSCo, Mth, BatchId, EMCo, Equipment, EMGroup, RevCode, SaleType, RevBdownCode,
               BatchSeq, HaulLine, OldNew, Amount, GLCo, GLAcct)
           values (@msco, @mth, @batchid, @emco, @equipment, @emgroup, @revcode, @saletype, @bdowncode,
               @seq, @haulline, @oldnew, @bdownamt, @emglco, @glacct)
   
           -- validate Equipment Revenue Account
           exec @rcode = dbo.bspGLACfPostable @emglco, @glacct, 'E', @errmsg output
           if @rcode <> 0
               begin
               select @errortext = @errorstart + ' - Equipment Revenue Account ' + isnull(@errmsg,'')
               exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
       	    goto bspexit
               end
           -- Revenue credit for breakdown amount posted in EM GL Co#
           update bMSGL set Amount = Amount - @bdownamt
           where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @emglco and GLAcct = @glacct
               and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
           if @@rowcount = 0
               insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                   FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
   			values(@msco, @mth, @batchid, @emglco, @glacct, @seq, @haulline, @oldnew, @mstrans, @ticket, @saledate,
                   @fromloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob, @jcco, @job,
                   @inco, @toloc, -@bdownamt)
           end
   
       select @totbdownamt = @totbdownamt + @bdownamt  -- accumulate distributed Breakdown revenue
       -- get next Breakdown code
       select @bdowncode = min(RevBdownCode)
       from bEMBG
       where EMCo = @emco and Category = @category and EMGroup = @emgroup and RevCode = @revcode
           and RevBdownCode > @bdowncode
       end
   
   update_diff:  -- add any difference to last Breakdown code
       if @totbdownamt <> @revtotal
           begin
    	    -- get last Breakdown code
    	    select @lastbdowncode = max(RevBdownCode)
           from bMSRB
           where MSCo = @msco and Mth = @mth and BatchId = @batchid and EMCo = @emco
               and Equipment = @equipment and EMGroup = @emgroup and RevCode = @revcode and SaleType = @saletype
               and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
   
    		-- get GL Account from last Breakdown code
           select @glacct = GLAcct
           from bMSRB
           where MSCo = @msco and Mth = @mth and BatchId = @batchid and EMCo = @emco
               and Equipment = @equipment and EMGroup = @emgroup and RevCode = @revcode and SaleType = @saletype
               and RevBdownCode = @lastbdowncode and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
    		if @@rowcount = 0
               begin
               select @errortext = 'Unable to find last EM Revenue Breakdown code for Equipment: '
                   + isnull(@equipment,'') + ' and Revenue Code: ' + isnull(@revcode,'')
               exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
    		    goto bspexit
               end
           -- update difference to MS Revenue Breakdown
           update bMSRB set Amount = Amount + (@revtotal - @totbdownamt)
           where MSCo = @msco and Mth = @mth and BatchId = @batchid and EMCo = @emco
               and Equipment = @equipment and EMGroup = @emgroup and RevCode = @revcode and SaleType = @saletype
               and RevBdownCode = @lastbdowncode and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
           if @@rowcount <> 1
               begin
               select @errortext = 'Unable to fully distribute EM Revenue to Breakdown codes.'
               exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
               goto bspexit
               end
   
           -- update difference as credit for breakdown amount posted in EM GL Co#
           update bMSGL set Amount = Amount - (@revtotal - @totbdownamt)
           where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @emglco and GLAcct = @glacct
               and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
           if @@rowcount = 0
               insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                   FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
               values(@msco, @mth, @batchid, @emglco, @glacct, @seq, @haulline, @oldnew, @mstrans, @ticket, @saledate,
                   @fromloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob, @jcco, @job,
                   @inco, @toloc, -(@revtotal - @totbdownamt))
           end
   
   -- add interco AP/AR entries as needed
     if @msglco <> @emglco
         begin
         -- get interco GL Accounts
         select @arglacct = ARGLAcct, @apglacct = APGLAcct
         from bGLIA where ARGLCo = @emglco and APGLCo = @msglco
         if @@rowcount = 0
             begin
             select @errortext = @errorstart + ' - Intercompany Accounts not setup in GL for companies ' + convert(varchar(3),@emglco)
               + ' and ' + convert(varchar(3),@msglco)
             exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
       	  goto bspexit
             end
         -- validate Intercompany AR GL Account
    exec @rcode = dbo.bspGLACfPostable @emglco, @arglacct, 'R', @errmsg output
         if @rcode <> 0
             begin
             select @errortext = @errorstart + ' - Intercompany AR GL Account  ' + isnull(@errmsg,'')
             exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
       	  goto bspexit
             end
         -- Intercompany AR debit (posted in EM GL Co#)
         update bMSGL set Amount = Amount + @revtotal
         where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @emglco and GLAcct = @arglacct
             and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
         if @@rowcount = 0
             insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                 FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
             values(@msco, @mth, @batchid, @emglco, @arglacct, @seq, @haulline, @oldnew, @mstrans, @ticket, @saledate,
                 @fromloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob, @jcco, @job, @inco, @toloc, @revtotal)
         -- validate Intercompany AP GL Account
         exec @rcode = dbo.bspGLACfPostable @msglco, @apglacct, 'P', @errmsg output
         if @rcode <> 0
             begin
             select @errortext = @errorstart + ' - Intercompany AP GL Account  ' + isnull(@errmsg,'')
             exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
       	  goto bspexit
             end
         -- Intercompany AP credit (posted in MS GL Co#)
         update bMSGL set Amount = Amount - @revtotal
         where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @msglco and GLAcct = @apglacct
             and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
        if @@rowcount = 0
             insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                 FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
             values(@msco, @mth, @batchid, @msglco, @apglacct, @seq, @haulline, @oldnew, @mstrans, @ticket, @saledate,
                 @fromloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob, @jcco, @job, @inco, @toloc, -@revtotal)
         end
   
   
   
   bspexit:
   	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSValRevBdown] TO [public]
GO
