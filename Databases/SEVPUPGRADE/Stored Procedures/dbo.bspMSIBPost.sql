SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspMSIBPost]
/***********************************************************
* Created: GG 11/27/2000
* Modified: GG 03/16/2001 - fixed CustJob and CustPO updates to bARTL
*           MV 06/18/2001 - Issue 12967 BatchUserMemoUpdate
*   GG 09/25/2001 - #14237 - fix null APSeq in bMSIX
*   GG 01/24/2002 - #15948 - pull Vendor, Matl, and Tax Group based on 'sold to' Co# for interco invoices
*   GG 01/30/2002 - #14176 - set bMSIB.PrintedYN = 'N' to avoid auditing as detail is removed from the batch
*   GG 02/01/2002 - #14177 - auto apply payments with cash invoices
*   CMW 04/04/2002 - added bHQBC.Notes interface levels update (issue # 16692).
*   GG 04/08/2002 - #16702 - remove parameter from bspBatchUserMemoUpdate
*   GG 04/18/2002 - fixed removal of Invoice detail
*   GG 05/14/2002 - #14177 - fix to bMSIH update
*   GG 08/29/2002 - #18378 - fixed ARTL MatlUnits insert
*   GG 01/29/2003 - #20215 - failed to update bARTL with correct amount
*   GF 06/26/2003 - #21682 added with (nolock) to select statements
*   GF 08/22/2003 - #22172 - insert notes from bMSIB into bARTH. Was missing.
*   GF 11/26/2003 - issue #23139 - use new stored procedure to create user memo update statement.
*   GF 12/05/2003 - #23205 - check error messages, wrap concatenated values with isnull
*   GF 03/02/2004 - #18616 - update unique attach id and re-index
*   GF 06/30/2004 - #24924 - check ARInterfaceLvl for no interface
*   JE 09/23/2004 - #25631 additional restrictions to improve performance
*   GG 09/01/2006 - #122343 - corrected update to bMSIX
*   GF 03/17/2008 - issue #127082 international addresses
*   GP 10/31/2008 - Issue 130576, changed text datatype to varchar(max)
*   GF 02/11/2010 - issue #135580 - needed single quotes around @msinv when updating user memos.
*   ECV 06/14/2011 - Issue 142792 - Check for value in @matltotal before updating bMSIX and adding intercompany transaction.
*
* Called from MS Batch Processing form to post a validated
* batch of Invoices.
*
* Posts invoices to AR - inserts and applies invoice transactions and misc distribution.
* Posts interco invoices to bMSII and bMSIX.
* Updates bMSTD - sets MSInv on newly billed trans, removes MSInv if voided.
* Posts account distributions to GL.
*
* INPUT PARAMETERS:
*   @co             MS Co#
*   @mth            Batch Month
*   @batchid        Batch Id
*   @dateposted     Posting date
*
* OUTPUT PARAMETERS
*   @errmsg         error message if something went wrong
*
* RETURN
*  0 = success, 1 = error
*
*****************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @errmsg varchar(255) output)
as
set nocount on
   
   declare @rcode int, @status tinyint, @vendorgroup bGroup, @vendor bVendor, @arco bCompany, @openMSIBcursor tinyint,
       @seq int, @msinv varchar(10), @custgroup bGroup, @customer bCustomer, @custjob varchar(20), @custpo varchar(20),
       @description bDesc, @rectype tinyint, @payterms bPayTerms, @invdate bDate, @discdate bDate, @duedate bDate,
       @applytoinv varchar(10), @intercoinv bYN, @interfaced bYN, @void bYN, @artranstype char(1), @arinv varchar(10),
       @applymth bMonth, @applytrans bTrans, @openMSARcursor tinyint, @arfields char(125), @matlunits bUnits,
       @matltotal bDollar, @haultotal bDollar, @taxbasis bDollar, @taxtotal bDollar, @discoff bDollar, @taxdisc bDollar,
       @fromloc bLoc, @matlgroup bGroup, @material bMatl, @um bUM, @string varchar(20), @unitprice bUnitCost, @ecm bECM,
       @glco bCompany, @glacct bGLAcct, @taxgroup bGroup, @taxcode bTaxCode, @arcustjob varchar(20), @arcustpo varchar(20),
       @applyline smallint, @arline smallint, @artrans bTrans, @validcnt int, @soldtoco bCompany, @openMSIDcursor tinyint,
       @mstrans bTrans, @saletype char(1), @jcco bCompany, @job bJob, @phasegroup bGroup, @inco bCompany, @toloc bLoc,
       @matlphase bPhase, @matljcctype bJCCType, @haulphase bPhase, @hauljcctype bJCCType, @taxtype char(1), @apseq smallint,
    @autoapply bYN, @i smallint, @a varchar(10), @a1 varchar(10), @deposit bCMRef, @paymenttype char(1), @cmco bCompany,
    @cmacct bCMAcct, @checkno bCMRef, @lastcmco bCompany, @lastcmacct bCMAcct, @arpaytrans bTrans, @cminterface tinyint,
    @payamt bDollar, @cmglco bCompany, @cmglacct bGLAcct, @cmtrans bTrans, @cmsummarydesc varchar(60),
    @Notes varchar(400), @msibud_flag bYN, @join varchar(2000), @where varchar(2000), @update varchar(2000),
    @sql varchar(8000), @guid uniqueidentifier, @arinterfacelvl tinyint
   
   select @rcode = 0, @msibud_flag = 'N', @openMSIBcursor = 0
    
   -- check for Posting Date
   if @dateposted is null
    begin
       select @errmsg = 'Missing posting date!', @rcode = 1
   
       goto bspexit
       end
   
   -- call bspUserMemoQueryBuild to create update, join, and where clause
   -- pass in source and destination. Remember to use views only unless working
   -- with a Viewpoint (bidtek) connection.
   exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'MSIB', 'MSIH', @msibud_flag output,
      @update output, @join output, @where output, @errmsg output
   if @rcode <> 0 goto bspexit
   
   -- validate HQ Batch
   exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'MS Invoice', 'MSIB', @errmsg output, @status output
   if @rcode <> 0 goto bspexit
   if @status <> 3 and @status <> 4 -- valid - OK to post, or posting in progress
       begin
       select @errmsg = 'Invalid Batch status -  must be ''valid - OK to post'' or ''posting in progress''!', @rcode = 1
       goto bspexit
       end
   -- set HQ Batch status to 4 (posting in progress)
   update bHQBC
   set Status = 4, DatePosted = @dateposted
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
    begin
       select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
       goto bspexit
       end
   -- get HQ Company info, Vendor used for intercompany invoices
   select @vendor = Vendor -- VendorGroup will depend  on 'sold to' company
   from bHQCO with (nolock) where HQCo = @co
   if @@rowcount = 0
       begin
       select @errmsg = 'Invalid HQ Company number!', @rcode = 1
       goto bspexit
       end
   -- get MS Company info
   select @arco = ARCo, @autoapply = AutoApplyCash, @arinterfacelvl = ARInterfaceLvl
   from bMSCO with (nolock) where MSCo = @co
   if @@rowcount = 0
       begin
       select @errmsg = 'Invalid MS Co#!', @rcode = 1
       goto bspexit
       end
   -- get AR Company info
   select @cminterface = CMInterface, @cmsummarydesc = CMSummaryDesc
   from bARCO with (nolock) where ARCo = @arco
   if @@rowcount = 0
       begin
       select @errmsg = 'Invalid AR Co#!', @rcode = 1
       goto bspexit
       end
   
   -- declare cursor on MS Invoice Batch
   declare Invoice cursor LOCAL FAST_FORWARD
   for select BatchSeq, MSInv, CustGroup, Customer, CustJob, CustPO, Description, PaymentType,
    RecType, PayTerms, InvDate, DiscDate, DueDate, ApplyToInv, InterCoInv, Interfaced, Void,
    CheckNo, CMCo, CMAcct
   from bMSIB
   where Co = @co and Mth = @mth and BatchId = @batchid
   order by PaymentType, CMCo, CMAcct, MSInv -- process by payment type and cm info needed for auto apply
   -- open MS Invoice Batch cursor
   open Invoice
   select @openMSIBcursor = 1
   
   -- process through all entries in batch
   Invoice_loop:
   fetch next from Invoice into @seq, @msinv, @custgroup, @customer, @custjob, @custpo, @description, 
    @paymenttype, @rectype, @payterms, @invdate, @discdate, @duedate, @applytoinv, 
    @intercoinv, @interfaced, @void, @checkno, @cmco, @cmacct
   
   if @@fetch_status = -1 goto Invoice_end
   if @@fetch_status <> 0 goto Invoice_loop
   
   begin transaction   -- start a transaction, commit when all updates for this invoice are complete (except GL dist)
   
   if @interfaced = 'Y' and @void = 'N' goto Invoice_cleanup  -- existing invoice in batch for reprint only, no updates
   
   if @arinterfacelvl = 0 goto MSIH_update -- the interface level for AR is 0 - no interface
   
   select @artranstype = 'I'    -- default AR Trans type is Invoice
   
   if @void = 'Y' or @applytoinv is not null
    begin
    -- find 'apply to' transaction
    select @arinv = isnull(@applytoinv,@msinv)  -- if 'apply to' invoice exists use it, else apply trans to itself
    -- get first transaction with matching info
    select @applymth = @mth, @applytrans = null
    select top 1 @applymth = Mth, @applytrans = ARTrans
    from bARTH with (nolock) 
    where ARCo = @arco and ARTransType = 'I' and CustGroup = @custgroup 
    and Customer = @customer and Invoice = @arinv
    order by Mth, ARTrans
    if @applytrans is null
     begin
                select @errmsg = 'Apply To Invoice ' + isnull(@arinv,'') + ' for Customer ' + convert(varchar(6),isnull(@customer,'')) + ' does not exist in AR.'
                goto Invoice_error
                end
    select @artranstype = 'A'   -- will be posted as an Adjustment
    end
   
        -- get next AR Trans #
        exec @artrans = bspHQTCNextTrans 'bARTH', @arco, @mth, @errmsg output
        if @artrans = 0 goto Invoice_error
   
    -- reset applied info for invoice transactions
    if @artranstype = 'I' select @applymth = @mth, @applytrans = @artrans, @arinv = @msinv
   
        -- insert AR Transactions Header
        insert bARTH (ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer, CustRef, CustPO, RecType,
      Invoice, Source, MSCo, TransDate, DueDate, DiscDate, Description, PayTerms, AppliedMth,
      AppliedTrans, PurgeFlag, EditTrans, BatchId, Notes)
        select @arco, @mth, @artrans, @artranstype, @custgroup, @customer, @custjob, @custpo, @rectype,
      @arinv, 'MS', @co, @invdate, @duedate, @discdate, @description, @payterms, @applymth,
      @applytrans, 'N','Y', @batchid, 
      Notes from bMSIB with (nolock) where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
   
        -- declare cursor on MS Invoice Lines, ARFields based on AR interface level
        declare Lines cursor LOCAL FAST_FORWARD 
     for select ARFields, convert(numeric(12,3),sum(MatlUnits)), convert(numeric(12,2),sum(MatlTotal)),
            convert(numeric(12,2),sum(HaulTotal)), convert(numeric(12,2),sum(TaxBasis)),
            convert(numeric(12,2),sum(TaxTotal)), convert(numeric(12,2),sum(DiscOff)),
            convert(numeric(12,2),sum(TaxDisc))
        from bMSAR with (nolock) where MSCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
        group by ARFields
   
        -- open MS Invoice Lines cursor
        open Lines
        select @openMSARcursor = 1
   
        -- process through all Lines on the Invoice
        Lines_loop:
            fetch next from Lines into @arfields, @matlunits, @matltotal, @haultotal, @taxbasis, @taxtotal,
                @discoff, @taxdisc
   
            if @@fetch_status = -1 goto Lines_end
            if @@fetch_status <> 0 goto Lines_loop
   
            -- get values from ARFields
            select @fromloc = substring(@arfields,1,10)
            select @matlgroup = substring(@arfields,11,3)   -- blank if interface level < 2
            select @material = substring(@arfields,14,20)   -- blank if interface level < 2
            select @um = substring(@arfields,34,3)          -- blank if interface level < 2
            select @string = substring(@arfields,37,12)     -- blank if interface level < 3
            if @string = '' or @string is null select @string = '0'
            select @unitprice = convert(numeric(11,5),@string)
            select @ecm = substring(@arfields,49,1)         -- blank if interface level < 3
            select @glco = substring(@arfields,50,3)
            select @glacct = substring(@arfields,53,20)
            select @taxgroup = substring(@arfields,73,3)
            select @taxcode = substring(@arfields,76,10)
            select @arcustjob = substring(@arfields,86,20)
            select @arcustpo = substring(@arfields,106,20)
   
            if @material = '' select @matlgroup = null, @material = null, @um = null, @matlunits = 0
            if @unitprice = 0 select @ecm = null
            if @taxcode = '' select @taxgroup = null, @taxcode = null
            if @arcustjob = '' select @arcustjob = null
            if @arcustpo = '' select @arcustpo = null
   
            -- if Adjustment, determine 'apply to' line
            if @artranstype = 'A'
                begin
                -- look for matching line on 'apply to' trans
                select @applyline = null
                select top 1 @applyline = ARLine
                from bARTL with (nolock) 
                where ARCo = @arco and Mth = @applymth and ARTrans = @applytrans
                    and isnull(Material,'') = isnull(@material,'') and GLAcct = @glacct and Loc = @fromloc
                    and isnull(TaxCode,'') = isnull(@taxcode,'')  and isnull(UnitPrice,0) = @unitprice
                    and isnull(CustJob,'') = isnull(@arcustjob,'') and isnull(CustPO,'') = isnull(@arcustpo,'')
                if @applyline is null
                    begin
                    -- get next available line on 'apply to' trans
                    select @applyline = isnull(max(ARLine),0) + 1
                    from bARTL with (nolock) 
                    where ARCo = @arco and Mth = @applymth and ARTrans = @applytrans
                    if @applyline = 1
                        begin
                        select @errmsg = 'Cannot find last line on ''apply to'' AR transaction ' + convert(varchar(6),isnull(@applytrans,''))
                        goto Invoice_error
                        end
                    -- add new line to 'apply to' trans with 0 values
                    insert bARTL(ARCo, Mth, ARTrans, ARLine, ApplyTrans, MatlGroup, Material, RecType, LineType, Description,
                        GLCo, GLAcct, TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, RetgPct, Retainage, DiscOffered,
                        TaxDisc, DiscTaken, ApplyMth, ApplyLine, UM, INCo, Loc, UnitPrice, ECM, MatlUnits, CustJob, CustPO)
                    values(@arco, @applymth, @applytrans, @applyline, @applytrans, @matlgroup, @material, @rectype, 'M',
                        case when @matltotal <> 0 and @haultotal = 0 then 'Materials'
          when @matltotal <> 0 and @haultotal <> 0 then 'Materials & Hauling'
          when @matltotal = 0 and @haultotal <> 0 then 'Hauling' else '' end,
         @glco, @glacct, @taxgroup, @taxcode,
                        0, 0, 0, 0, 0, 0, 0, 0, @applymth, @applyline, @um, @co, @fromloc, @unitprice, @ecm, 0, @arcustjob, @arcustpo)
                    end
                end
   
            -- get next available line on new trans
            select @arline = isnull(max(ARLine),0) + 1
            from bARTL with (nolock) 
            where ARCo = @arco and Mth = @mth and ARTrans = @artrans
   
     if @artranstype = 'I' select @applyline = @arline -- invoice lines applied to themselves
   
     -- add new line to AR trans
           insert bARTL(ARCo, Mth, ARTrans, ARLine, ApplyTrans, MatlGroup, Material, RecType, LineType, Description,
               GLCo, GLAcct, TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, RetgPct, Retainage, DiscOffered,
               TaxDisc, DiscTaken, ApplyMth, ApplyLine, UM, INCo, Loc, UnitPrice, ECM, MatlUnits, CustJob, CustPO)
           values(@arco, @mth, @artrans, @arline, @applytrans, @matlgroup, @material, @rectype, 'M',
      case when @matltotal <> 0 and @haultotal = 0 then 'Materials'
       when @matltotal <> 0 and @haultotal <> 0 then 'Materials & Hauling'
       when @matltotal = 0 and @haultotal <> 0 then 'Hauling' else '' end,
               @glco, @glacct, @taxgroup, @taxcode,
      --case when @haultotal <> 0 then @haultotal else @matltotal + @taxtotal end,
   @matltotal + @haultotal + @taxtotal, -- #20215 sum of material, haul, and tax
               @taxbasis, @taxtotal, 0, 0, @discoff, @taxdisc, 0, @applymth, @applyline, @um, @co, @fromloc,
      @unitprice, @ecm, @matlunits, @arcustjob, @arcustpo)
   
           -- insert trigger on bARTL will update invoice totals in bARTH and bARMT
   
           -- remove MS AR Invoice Line (may be multiple rows)
           delete bMSAR
           where MSCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and ARFields = @arfields
   
           goto Lines_loop -- next AR Invoice Line
   
    Lines_end:  -- finished with AR Invoice Lines
       close Lines
           deallocate Lines
           select @openMSARcursor = 0
   
    -- add Misc Distributions - will only exist if Customer flagged for auto dist on Invoice
       select @validcnt = count(*) from bMSMX with (nolock) 
       where MSCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq  -- save count of Misc Dists
   
       insert bARMD(ARCo, Mth, ARTrans, CustGroup, MiscDistCode, DistDate, Description, Amount)
       select @arco, @mth, @artrans, @custgroup, m.MiscDistCode, @invdate, a.Description, m.Amount
       from bMSMX m with (nolock) 
       join bARMC a with (nolock) on m.MiscDistCode = a.MiscDistCode
       where m.MSCo = @co and m.Mth = @mth and m.BatchId = @batchid and m.BatchSeq = @seq
           and a.CustGroup = @custgroup
       if @@rowcount <> @validcnt
           begin
           select @errmsg = 'Unable to add one or more Misc Distributions to AR Invoice # ' + isnull(@msinv,'')
           goto Invoice_error
           end
       -- remove Misc Dists from batch table
       delete bMSMX
       where MSCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   
    -- auto apply payment to cash sale invoices
    if @autoapply = 'Y' and @paymenttype = 'C'
     begin
     -- get Deposit # for auto applied Payment
     if (@cmco <> isnull(@lastcmco,0) or @cmacct <> isnull(@lastcmacct,0))
      begin
      -- new deposit # required for each CMCo and CMAcct combo
      select @i = 1, @a = convert(varchar(6),@dateposted,12) + '-' -- yymmdd-###
      seqloop:
       select @a1 = @a + convert(varchar(3),@i)
       select @deposit = space(10-datalength(convert(varchar(10),@a1))) + convert(varchar(10),@a1) -- right justify
       if exists(select 1 from bCMDT with (nolock) where CMCo = @cmco and CMAcct = @cmacct
        and CMTransType = 2 and CMRef = @deposit) -- must be unique
        begin
        select @i = @i + 1
        if @i < 999 goto seqloop
        select @errmsg = 'Unable to create a unique Deposit#!'
           goto Invoice_error
           end
      select @lastcmco = @cmco, @lastcmacct = @cmacct
      end
     -- get next AR Trans #
         exec @arpaytrans = bspHQTCNextTrans 'bARTH', @arco, @mth, @errmsg output
         if @arpaytrans = 0 goto Invoice_error
   
         -- insert AR Transactions Header - Payment
         insert bARTH (ARCo, Mth, ARTrans, ARTransType, CustGroup, Customer, CustRef, CustPO, RecType,
      Invoice, CheckNo, Source, MSCo, TransDate, CheckDate, Description, CMCo, CMAcct,
      CMDeposit, CreditAmt, PurgeFlag, EditTrans, BatchId, Notes)
         select @arco, @mth, @arpaytrans, 'P', @custgroup, @customer, @custjob, @custpo, @rectype,
      null, @checkno, 'MS', @co, @invdate, @invdate, 'Auto Apply', @cmco, @cmacct,
      @deposit, 0, 'N','Y', @batchid,  -- initialize CreditAmt as 0.00
      Notes from bMSIB with (nolock) where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
   
     -- get count of lines to pay
     select @validcnt = count(*) from bARTL with (nolock) where ARCo = @arco and Mth = @mth and ARTrans = @artrans -- original invoice or adjustment trans
   
     -- add new line to AR trans
     -- all discounts offered are taken and tax basis is reduced by discount if tax discount exists
     insert bARTL(ARCo, Mth, ARTrans, ARLine, ApplyTrans, MatlGroup, Material, RecType, LineType, Description,
               GLCo, GLAcct, TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, RetgPct, Retainage, DiscOffered,
               TaxDisc, DiscTaken, ApplyMth, ApplyLine, UM, INCo, Loc, UnitPrice, ECM, MatlUnits, CustJob, CustPO)
     select ARCo, Mth, @arpaytrans, ARLine, ApplyTrans, MatlGroup, Material, RecType, LineType, Description,
      GLCo, null, TaxGroup, TaxCode, -Amount, case TaxDisc when 0 then 0 else -DiscOffered end, -TaxAmount, 0, 0, 0,
      -TaxDisc, -DiscOffered, ApplyMth, ApplyLine, UM, INCo, Loc, UnitPrice, ECM, MatlUnits, CustJob, CustPO
     from bARTL
     where ARCo = @arco and Mth = @mth and ARTrans = @artrans
     if @@rowcount <> @validcnt
                begin
                select @errmsg = 'Unable to insert payment lines in AR Transaction Lines!'
                goto Invoice_error
                end
   
     -- insert trigger on bARTL will update invoice totals in bARTH and bARMT
   
     -- update Credit Amount in AR Payment Trans Header
     select @payamt = isnull(sum(Amount - DiscOffered - TaxDisc),0)
     from bARTL with (nolock) where ARCo = @arco and Mth = @mth and ARTrans = @artrans
   
   
     update bARTH set CreditAmt = @payamt
     where ARCo = @arco and Mth = @mth and ARTrans = @arpaytrans
     if @@rowcount = 0
      begin
      select @errmsg = 'Unable to update payment amount total in AR Transaction Header!'
      goto Invoice_error
      end
   
     if @cminterface <> 0 -- no update to CM if interface level = 0
      begin
      -- get GL Account for CM Account
      select @cmglco = GLCo, @cmglacct = GLAcct
      from bCMAC with (nolock) where CMCo = @cmco and CMAcct = @cmacct
      if @@rowcount = 0
       begin
       select @errmsg = 'Invalid CM Account - unable to post deposit!'
       goto Invoice_error
       end
   
      -- update CM Detail with deposit info
      update bCMDT set Amount = Amount + @payamt
      where CMCo = @cmco and CMAcct = @cmacct and CMTransType = 2
       and CMRef = @deposit and CMRefSeq = 0
      if @@rowcount = 0
       begin
       -- get next available transaction # for CMDT */
                   exec @cmtrans = bspHQTCNextTrans 'bCMDT', @cmco, @mth, @errmsg output
                   if @cmtrans = 0 goto Invoice_error
   
                   insert bCMDT(CMCo, Mth, CMTrans, CMAcct, CMTransType, SourceCo, Source, ActDate,
        PostedDate, Description, Amount, ClearedAmt, BatchId, CMRef, CMRefSeq, GLCo,
        CMGLAcct, Void, Purge)
                   values (@cmco, @mth, @cmtrans, @cmacct, 2, @arco, 'AR Receipt', @invdate,
                       @dateposted, @cmsummarydesc, @payamt, 0, @batchid, @deposit, 0, @cmglco,
                       @cmglacct, 'N', 'N')
       end
      end
   
     end  -- finished with auto apply payments
   
   -- add/update MS Invoice Header and Detail tables
   MSIH_update:
   -- -- -- 
   if @arinterfacelvl = 0
    begin
    -- -- -- remove Misc Dists from batch table
    delete bMSMX
    where MSCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    -- -- -- remove MS AR Invoice Line (may be multiple rows)
    delete bMSAR
    where MSCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    end
   
   if @void = 'Y'
            begin
            -- remove Invoice Detail
            delete bMSIL where MSCo = @co and MSInv = @msinv
            -- flag Invoice Header as void
            update bMSIH set Void = 'Y', BatchId = @batchid
            where MSCo = @co and MSInv = @msinv
            if @@rowcount <> 1
                begin
                select @errmsg = 'Unable to void Invoice# ' + isnull(@msinv,'') + ' from MS Invoice tables!'
                goto Invoice_error
                end
            end
   else
            begin
            -- add MS Invoice Header
            insert bMSIH(MSCo, MSInv, Mth, CustGroup, Customer, CustJob, CustPO, Description,
                ShipAddress, City, State, Zip, ShipAddress2, PaymentType, RecType, PayTerms,
                InvDate, DiscDate, DueDate, ApplyToInv, InterCoInv, LocGroup, Location, PrintLvl,
                SubtotalLvl, SepHaul, BatchId, InUseBatchId, Void, Notes, CheckNo, CMCo, CMAcct,
    UniqueAttchID, Country)
            select Co, MSInv, Mth, CustGroup, Customer, CustJob, CustPO, Description,
                ShipAddress, City, State, Zip, ShipAddress2, PaymentType, RecType, PayTerms,
                InvDate, DiscDate, DueDate, ApplyToInv, InterCoInv, LocGroup, Location, PrintLvl,
                SubtotalLvl, SepHaul, BatchId, null, 'N', Notes, CheckNo, CMCo, CMAcct,
    UniqueAttchID, Country
            from bMSIB with (nolock)
            where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
            if @@rowcount <> 1
                begin
                select @errmsg = 'Unable to add Invoice# ' + isnull(@msinv,'') + ' to MS Invoice Header table!'
                goto Invoice_error
                end
   
            -- add MS Invoice Line Detail
            select @validcnt = count(*) from bMSID with (nolock) 
            where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq    -- save count of Invoice Detail
   
            insert bMSIL(MSCo, MSInv, MSTrans, CustJob, CustPO, SaleDate, FromLoc, MatlGroup, Material,
                UM, UnitPrice, Ticket)
            select Co, @msinv, MSTrans, CustJob, CustPO, SaleDate, FromLoc, MatlGroup, Material,
                UM, UnitPrice, Ticket
            from bMSID with (nolock)
            where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
            if @@rowcount <> @validcnt
                begin
                select @errmsg = 'Unable to add entries for Invoice# ' + isnull(@msinv,'') + ' to MS Invoice Detail table!'
                goto Invoice_error
                end
            end
   
   
   -- process Intercompany Invoices
   if @intercoinv = 'Y'
    begin
    -- -- -- when AR interface level 0 - no interface delete from bMSIX and bMSII
    if @arinterfacelvl = 0
     begin
     delete bMSIX where MSCo = @co and MSInv = @msinv    -- detail
          delete bMSII where MSCo = @co and MSInv = @msinv  -- header
     goto MSTD_update
     end
   
            if exists(select 1 from bMSII with (nolock) where MSCo = @co and MSInv = @msinv) and @void = 'Y'
                begin
                -- if invoice to be voided exists in the MS InterCo Invoice tables, just remove it
                delete bMSIX where MSCo = @co and MSInv = @msinv    -- detail
          delete bMSII where MSCo = @co and MSInv = @msinv  -- header
                end
            else
           begin
                -- get 'sold to' Company and Groups based Invoice Customer
                select top 1 @soldtoco = HQCo, @vendorgroup = VendorGroup, @matlgroup = MatlGroup, @taxgroup = TaxGroup
                from bHQCO with (nolock) where Customer = @customer -- don't use Customer Group when searching for Company
                if @@rowcount = 0
        begin
                select @errmsg = 'Cannot determine ''sold to'' Company from Customer# ' + convert(varchar(6),isnull(@customer,''))
                        + ' on Invoice# ' + isnull(@msinv,'')
                    goto Invoice_error
                    end
                -- add Intercompany Invoice Header
                insert bMSII(MSCo, MSInv, SoldToCo, Mth, VendorGroup, Vendor, Description, InvDate, DueDate)
                values(@co, @msinv, @soldtoco, @mth, @vendorgroup, @vendor, @description, @invdate, @duedate)
   
                -- declare cursor on Invoice Batch Detail
                declare Detail cursor LOCAL FAST_FORWARD
       for select MSTrans
                from bMSID with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                -- open MS Invoice Detail cursor
   
                open Detail
                select @openMSIDcursor = 1
   
                -- process all Detail on the Invoice
                Detail_loop:
                    fetch next from Detail into @mstrans
                    if @@fetch_status = -1 goto Detail_end
                    if @@fetch_status <> 0 goto Detail_loop
                    -- get MS Trans detail
                    select @saletype = SaleType, @jcco = JCCo, @job = Job, @phasegroup = PhaseGroup,
                        @inco = INCo, @toloc = ToLoc, @material = Material, @um = UM, @matlphase = MatlPhase,
						@matljcctype = MatlJCCType, @matlunits = MatlUnits, @unitprice = UnitPrice,
                        @ecm = ECM, @matltotal = MatlTotal, @haulphase = HaulPhase, @hauljcctype = HaulJCCType,
                        @haultotal = HaulTotal, @taxcode = TaxCode, @taxtype = TaxType,
                        @taxbasis = TaxBasis, @taxtotal = TaxTotal
                    from bMSTD with (nolock) 
                    where MSCo = @co and Mth = @mth and MSTrans = @mstrans
                    if @@rowcount = 0
                        begin
                        select @errmsg = 'Missing MS Trans# ' + convert(varchar(6),isnull(@mstrans,'')) + ' for Intercompany Invoice# ' + @msinv
                        goto Invoice_error
                        end
                    -- if void, reverse sign on units and dollars
                    if @void = 'Y'
                        begin
                        select @matlunits = -(@matlunits), @matltotal = -(@matltotal), @haultotal = -(@haultotal),
                            @taxbasis = -(@taxbasis), @taxtotal = -(@taxtotal), @discoff = -(@discoff)
                        end
                    -- Inventory sales
   
                    if @saletype = 'I'
                        begin
                        update bMSIX set MatlUnits = MatlUnits + @matlunits, MatlTotal = MatlTotal + @matltotal,
                            HaulTotal = HaulTotal + @haultotal, TaxBasis = TaxBasis + @taxbasis, TaxTotal = TaxTotal + @taxtotal
                        where MSCo = @co and MSInv = @msinv and SaleType = 'I' and INCo = @inco and ToLoc = @toloc
                            and MatlGroup = @matlgroup and Material = @material and UM = @um and UnitPrice = @unitprice
                            and ECM = @ecm and isnull(TaxGroup,0) = isnull(@taxgroup,0) and isnull(TaxCode,'') = isnull(@taxcode,'')
                        if @@rowcount = 0
                            begin
                            -- get next Intercompany Invoice Detail Seq#
                            select @apseq = isnull(max(APSeq),0) + 1
                            from bMSIX with (nolock) where MSCo = @co and MSInv = @msinv
                            -- add Intercompany Invoice Detail Seq#
                            insert bMSIX(MSCo, MSInv, APSeq, SaleType, INCo, ToLoc, MatlGroup, Material, UM, MatlUnits,
                                UnitPrice, ECM, MatlTotal, HaulTotal, TaxGroup, TaxCode, TaxBasis, TaxTotal)
						    values(@co, @msinv, @apseq, 'I', @inco, @toloc, @matlgroup, @material, @um, @matlunits,
							   @unitprice, @ecm, @matltotal, @haultotal, @taxgroup, @taxcode, @taxbasis, @taxtotal)
                            end
                        end     -- end of Inventory Line
       else
                begin
					-- Job sales (material and tax) 
					if (@matltotal<>0 AND NOT ISNULL(@matlphase,'')='') -- 142792
					begin -- 142792
						update bMSIX set MatlUnits = MatlUnits + @matlunits, MatlTotal = MatlTotal + @matltotal,
                            TaxBasis = TaxBasis + @taxbasis, TaxTotal = TaxTotal + @taxtotal
                        where MSCo = @co and MSInv = @msinv and SaleType = 'J' and JCCo = @jcco and Job = @job
                            and PhaseGroup = @phasegroup and Phase = @matlphase and JCCType = @matljcctype
							and MatlGroup = @matlgroup and Material = @material and UM = @um and UnitPrice = @unitprice
                            and ECM = @ecm and isnull(TaxGroup,0) = isnull(@taxgroup,0) and isnull(TaxCode,'') = isnull(@taxcode,'')
                        if @@rowcount = 0
                        begin
							-- get next Intercompany Invoice Detail Seq#
							select @apseq = isnull(max(APSeq),0) + 1
							from bMSIX with (nolock) where MSCo = @co and MSInv = @msinv
							-- add Intercompany Invoice Detail Seq#
							insert bMSIX(MSCo, MSInv, APSeq, SaleType, JCCo, Job, PhaseGroup, Phase, JCCType,
								MatlGroup, Material, UM, MatlUnits, UnitPrice, ECM, MatlTotal, HaulTotal, TaxGroup,
								TaxCode, TaxBasis, TaxTotal)
							values(@co, @msinv, @apseq, 'J', @jcco, @job, @phasegroup, @matlphase, @matljcctype,
								@matlgroup, @material, @um, @matlunits, @unitprice, @ecm, @matltotal, 0, @taxgroup,
								@taxcode, @taxbasis, @taxtotal)
                        end
					end -- 142792
                    -- Job sales (haul)
                    if (@haultotal <> 0 AND NOT ISNULL(@haulphase,'')='')
                    begin
                        update bMSIX set HaulTotal = HaulTotal + @haultotal
                        where MSCo = @co and MSInv = @msinv and SaleType = 'J' and JCCo = @jcco and Job = @job
                            and PhaseGroup = @phasegroup and Phase = @haulphase and JCCType = @hauljcctype
                            and MatlGroup = @matlgroup and Material = @material and UM = @um and UnitPrice = @unitprice
                            and ECM = @ecm and isnull(TaxGroup,0) = isnull(@taxgroup,0) and isnull(TaxCode,'') = isnull(@taxcode,'')
                        if @@rowcount = 0
                        begin
                        -- get next Intercompany Invoice Detail Seq#
                        select @apseq = isnull(max(APSeq),0) + 1
                        from bMSIX with (nolock) where MSCo = @co and MSInv = @msinv
						-- add Intercompany Invoice Detail Seq#
                        insert bMSIX(MSCo, MSInv, APSeq, SaleType, JCCo, Job, PhaseGroup, Phase, JCCType,
                            MatlGroup, Material, UM, MatlUnits, UnitPrice, ECM, MatlTotal, HaulTotal, TaxGroup,
                            TaxCode, TaxBasis, TaxTotal)
						values(@co, @msinv, @apseq, 'J', @jcco, @job, @phasegroup, @haulphase, @hauljcctype, -- #122343
                            @matlgroup, @material, @um, 0, @unitprice, @ecm, 0, @haultotal, @taxgroup,
                            @taxcode, 0, 0)
                        end
                    end
                end     -- end of Job Line

                goto Detail_loop    -- get next Invoice Batch Detail entry
   
                Detail_end:     -- finished with Detail on this Invoice
                    close Detail
                    deallocate Detail
                    select @openMSIDcursor = 0
   
                end
            end         -- finished with Intercompany Invoice
   
   MSTD_update:
   -- update (or reopen if void) MS Transactions with Invoice #
   select @validcnt = count(*) from bMSID with (nolock) 
   where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq    -- save count of MS Invoice Detail
   
   update bMSTD set MSInv = case @void when 'Y' then null else @msinv end
   from bMSTD t with (nolock) 
   join bMSID d with (nolock) on t.MSCo = d.Co and t.Mth = d.Mth and t.MSTrans = d.MSTrans
   where d.Co = @co and d.Mth = @mth and d.BatchId = @batchid and d.BatchSeq = @seq
   and t.MSCo=@co and t.Mth=@mth   --- Issue 25631 additional restrictions to improve performance
   
   if @@rowcount <> @validcnt
    begin
    select @errmsg = 'Unable to update MS Transaction detail properly for Invoice# ' + isnull(@msinv,'')
    goto Invoice_error
    end
   
   Invoice_cleanup:    -- completed all header and detail updates for the Invoice
   -- #14176 - reset Printed flag to avoid auditing as detail is removed from the batch
   update bMSIB set PrintedYN = 'N'
   where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   if @@rowcount <> 1
    begin
    select @errmsg = 'Unable to update audit flag in MS Invoice Batch Header!'
    goto Invoice_error
    end
   
   -- remove Invoice Batch detail
   delete bMSID
   where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   
if @msibud_flag = 'Y'
    begin
    ---- #135580 @msinv is a alphanumeric so we need single quotes around values otherwise transact-sql thinks numeric.
 set @sql = @update + @join + @where + ' and b.MSInv = ' + CHAR(39) + isnull(@msinv,'') + CHAR(39) + ' and MSIH.MSInv = ' + CHAR(39) + isnull(@msinv,'') + CHAR(39)
    exec (@sql)
    end
   
set @guid = null
select @guid from bMSIB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
-- remove Invoice Batch Header
delete bMSIB
where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
if @@rowcount <> 1
 begin
 select @errmsg = 'Unable to remove MS Invoice Batch Header!'
 goto Invoice_error
 end
   
   
   commit transaction
   
   --Refresh indexes for this header if attachments exist
   if @guid is not null
    begin
    exec dbo.bspHQRefreshIndexes null, null, @guid, null
    end
   
   goto Invoice_loop
   
   Invoice_error:       -- error during Invoice processing
    rollback transaction
    select @rcode = 1
    goto bspexit
   
   Invoice_end: -- finished with all Invoices in the batch
    close Invoice
    deallocate Invoice
    select @openMSIBcursor = 0
   
   --General Ledger update
   exec @rcode = bspMSIBPostGL @co, @mth, @batchid, @dateposted, @errmsg output
   if @rcode <> 0 goto bspexit
   
   -- make sure all AR Invoice Line distributions have been processed
   if exists(select 1 from bMSAR with (nolock) where MSCo = @co and Mth = @mth and BatchId = @batchid)
        begin
        select @errmsg = 'Not all Invoice Line updates to AR were posted - unable to close the batch!', @rcode = 1
        goto bspexit
        end
   -- make sure all AR Invoice Misc distributions have been processed
   if exists(select 1 from bMSMX with (nolock) where MSCo = @co and Mth = @mth and BatchId = @batchid)
        begin
        select @errmsg = 'Not all Misc Distribution updates to AR were posted - unable to close the batch!', @rcode = 1
        goto bspexit
        end
    -- make sure all Invoice Batch Detail has been processed
    if exists(select 1 from bMSID with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
        begin
        select @errmsg = 'Not all Invoice detail updates to MS were posted - unable to close the batch!', @rcode = 1
        goto bspexit
        end
    -- make sure all Invoice Batch Headers have been processed
    if exists(select 1 from bMSIB with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
        begin
       select @errmsg = 'Not all Invoice header updates to MS were posted - unable to close the batch!', @rcode = 1
        goto bspexit
        end
    -- make sure all GL Distributions have been processed
    if exists(select 1 from bMSIG with (nolock) where MSCo = @co and Mth = @mth and BatchId = @batchid)
        begin
        select @errmsg = 'Not all updates to GL were posted - unable to close the batch!', @rcode = 1
        goto bspexit
        end
   
-- set interface levels note string
select @Notes=Notes from bHQBC with (nolock) 
where Co = @co and Mth = @mth and BatchId = @batchid
if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
select @Notes=@Notes +
 'AR Interface Level set at: ' + convert(char(1), a.ARInterfaceLvl) + char(13) + char(10) +
 'EM Interface Level set at: ' + convert(char(1), a.EMInterfaceLvl) + char(13) + char(10) +
 'GL Invoice Interface Level set at: ' + convert(char(1), a.GLInvLvl) + char(13) + char(10) +
 'GL Ticket Interface Level set at: ' + convert(char(1), a.GLTicLvl) + char(13) + char(10) +
 'IN Sales Interface Level set at: ' + convert(char(1), a.INInterfaceLvl) + char(13) + char(10) +
 'IN Production Interface Level set at: ' + convert(char(1), a.INProdInterfaceLvl) + char(13) + char(10) +
 'JC Interface Level set at: ' + convert(char(1), a.JCInterfaceLvl) + char(13) + char(10)
from bMSCO a with (nolock) where MSCo=@co

-- delete HQ Close Control entries
delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid

-- set HQ Batch status to 5 (posted)
update bHQBC
set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
 begin
 select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
 goto bspexit
 end


---- may need to reindex biMSTDMSInv index
----if exists(select * from sys.indexes where object_id = OBJECT_ID(N'[dbo].[bMSTD]') AND name = N'biMSTDMSInv')
---- begin
---- dbcc DBREINDEX('bMSTD','biMSTDMSInv',85)
---- end



bspexit:
 if @openMSIBcursor = 1
  begin
  close Invoice
  deallocate Invoice
  end
 if @openMSARcursor = 1
  begin
  close Lines
  deallocate Lines
  end
 if @openMSIDcursor = 1
  begin
  close Detail
  deallocate Detail
  end

 if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
 return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspMSIBPost] TO [public]
GO
