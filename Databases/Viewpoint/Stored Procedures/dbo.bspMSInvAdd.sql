SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspMSInvAdd]
    /***********************************************************
    * Created: GG 11/14/00
    * Modified: 	MV 07/05/01 - Issue 12769 BatchUserMemoInsertExsiting
    *        		GF 09/17/01 - Issue 14631 Missing LocGroup and Location in query restrictions.
    *				GG 01/30/02 - #14176 - initialize bMSIB.PrintedYN 
    *				GG 02/01/02 - #14177 - initialize CheckNo, CMCo, and CMAcct to bMSIB
    *				GF 02/06/02 - #16179 - If LocGroup or Location is null on both sides in the query,
    *						  no invoices are being added to batch. Changed to a coalesce on right side.
	*				GF 03/17/2008 - issue #127082 international addresses
	*				GP 7/29/2011 - TK-07143 changed @PO from varchar(10) to varchar(30)
	*
    *
    *
    * Called from the MS Invoice Add form to pull previously interfaced
    * invoices into an Invoice Batch for reprint.
    *
    * INPUT PARAMETERS
    *   @co                 MS Co#
    *   @mth                Batch Month
    *   @batchid            Batch ID
    *   @xlocgroup          Location Group restriction
    *   @xloc               Location restriction
    *   @xcustgroup         Customer Group restriction
    *   @xcustomer          Customer restriction
    *   @restrictcustjob    'Y' = restrict on Cust Job, 'N' = Cust Job not restricted
    *   @xcustjob           Customer Job restriction
    *   @retrictcustpo      'Y' = restrict on Cust PO, 'N' = Cust PO not restricted
    *   @xcustpo            Customer PO restriction
    *   @xinvdate           Invoice Date restriction
    *   @xmsinv             Invoice restriction
    *
    * OUTPUT PARAMETERS
    *   @msg            success or error message
    *
    * RETURN VALUE
    *   0               success
    *   1               fail
    *****************************************************/
   (@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @xlocgroup bGroup = null,
    @xloc bLoc = null, @xcustgroup bGroup = null, @xcustomer bCustomer = null, @restrictcustjob char(1) = 'N',
    @xcustjob varchar(20) = null, @restrictcustpo char(1) = 'N', @xcustpo varchar(30) = null,
    @xinvdate bDate = null, @xmsinv varchar(10) = null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @invcount int, @status tinyint, @opencursor tinyint, @msinv varchar(10), @batchseq int, 
   		@linecount int
   
   select @rcode = 0, @invcount = 0
   
    -- validate HQ Batch
    exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'MS Invoice', 'MSIB', @msg output, @status output
    if @rcode <> 0 goto bspexit
    if @status <> 0     -- must be open
        begin
        select @msg = 'Invalid Batch status - must be Open!', @rcode = 1
        goto bspexit
        end
   
   -- use a cursor to cycyle through existing Invoices
   declare bcMSIH cursor LOCAL FAST_FORWARD
   for select MSInv
   from bMSIH
   where MSCo = @co and Mth = @mth and CustGroup = isnull(@xcustgroup,CustGroup)
        and Customer = isnull(@xcustomer,Customer)
        and ((@restrictcustjob = 'Y' and isnull(CustJob,'') = isnull(@xcustjob,'')) or @restrictcustjob = 'N')    -- null Cust Job is valid
        and ((@restrictcustpo = 'Y' and isnull(CustPO,'') = isnull(@xcustpo,'')) or @restrictcustpo = 'N')    -- null Cust PO is valid
        and InvDate = isnull(@xinvdate,InvDate) and MSInv = isnull(@xmsinv,MSInv)
   	 and isnull(LocGroup,0) = coalesce(@xlocgroup,LocGroup,0) -- and LocGroup = isnull(@xlocgroup,LocGroup)
   	 and isnull(Location,'') = coalesce(@xloc,Location,'') -- and Location = isnull(@xloc,Location)
        and Void = 'N' and InUseBatchId is null  -- skip if voided or in a batch
   
    -- open cursor
    open bcMSIH
    select @opencursor = 1
   
    MSIH_loop:
        fetch next from bcMSIH into @msinv
   
        if @@fetch_status = -1 goto MSIH_end
        if @@fetch_status <> 0 goto MSIH_loop
   
        -- count # of Invoice Lines
        select @linecount = count(*) from bMSIL with (nolock) where MSCo = @co and MSInv = @msinv
   
        -- passed validation, add to Invoice Batch using a transaction to make sure Header and all Lines are added
        begin transaction
   
        -- get next Batch Sequence #
        select @batchseq = isnull(max(BatchSeq),0) + 1
        from bMSIB with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid
   
        -- add Invoice Batch Header, entry will be locked in bMSIH via insert trigger on bMSIB
        insert bMSIB(Co, Mth, BatchId, BatchSeq, MSInv, CustGroup, Customer, CustJob, CustPO, Description,
            ShipAddress, City, State, Zip, ShipAddress2, PaymentType, RecType, PayTerms, InvDate, DiscDate,
            DueDate, ApplyToInv, InterCoInv, LocGroup, Location, PrintLvl, SubtotalLvl, SepHaul, Interfaced,
            Void, Notes, PrintedYN, CheckNo, CMCo, CMAcct, Country)
        select MSCo, Mth, @batchid, @batchseq, MSInv, CustGroup, Customer, CustJob, CustPO, Description,
            ShipAddress, City, State, Zip, ShipAddress2, PaymentType, RecType, PayTerms, InvDate, DiscDate,
            DueDate, ApplyToInv, InterCoInv, LocGroup, Location, PrintLvl, SubtotalLvl, SepHaul, 'Y',
            'N', Notes, 'N', CheckNo, CMCo, CMAcct, Country
        from bMSIH where MSCo = @co and MSInv = @msinv
        if @@rowcount <> 1 goto MSIH_error
   
   
   	-- BatchUserMemoInsertExisting - update the user memo in the batch record
   	if exists(select * from syscolumns where name like 'ud%'and id = object_id('dbo.MSIB'))
   		begin
   		exec @rcode =  bspBatchUserMemoInsertExisting @co, @mth, @batchid, @batchseq, 'MS Invoice', 0, @msg output
   		if @rcode <> 0
   			begin
   			select @msg = 'Unable to update User Memos in MSIB', @rcode = 1
   			goto MSIH_error
   			end
   		end
   
        -- add all Invoice Lines to batch
        insert bMSID(Co, Mth, BatchId, BatchSeq, MSTrans, CustJob, CustPO, SaleDate, FromLoc,
            MatlGroup, Material, UM, UnitPrice, Ticket)
        select MSCo, @mth, @batchid, @batchseq, MSTrans, CustJob, CustPO, SaleDate, FromLoc,
            MatlGroup, Material, UM, UnitPrice, Ticket
        from bMSIL where MSCo = @co and MSInv = @msinv
        if @@rowcount <> @linecount goto MSIH_error
   
        commit transaction
   
        select @invcount = @invcount + 1    -- # of invoices added to batch
   
        goto MSIH_loop  -- next invoice
   
   MSIH_error: -- problem adding Invoice or Lines to the Batch, skip it and go to the next
        rollback transaction
        goto MSIH_loop
   
   MSIH_end:
        close bcMSIH
        deallocate bcMSIH
        select @opencursor = 0
   
   
   
   
   bspexit:
       if @opencursor = 1
            begin
            close bcMSIH
            deallocate bcMSIH
            end
       if @rcode = 0 select @msg = 'Sucessfully added ' + convert(varchar(6),@invcount) + ' invoices to the batch.'
       if @rcode <> 0 select @msg = isnull(@msg,'')
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSInvAdd] TO [public]
GO
