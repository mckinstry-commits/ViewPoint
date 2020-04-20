SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************/
CREATE procedure [dbo].[bspMSInvInit]
/***********************************************************
    * Created: GG 11/09/00
    * Modified: GF 01/04/2000 Added restriction for Payment Type
    *          RM 03/26/01 - Modified to allow for range of locations
    *          GG 04/06/01 - fixed updates to bMSIB for Address overrides
    *          bc 06/06/01 - make sure DueDate is not null when inserting records into MSIB
    *          GG 07/03/01 - add hierarchal Quote search  - #13888
    *			GG 09/25/01 - #14237 set payment type for interco Job and IN sales
    *			GG 01/17/02 - #15839 - use AR Co# Customer Group w/interco invoices
    *			GG 01/18/02 - #15948 - interco invoices by Job
    *			GG 01/30/02 - #14176 - initalize bMSIB.PrintedYN 
    *			GG 02/01/02 - #14177 - if auto apply payments, create separate invoice per CheckNo, CMCo, and CMAcct
    *			GF 09/05/02 - #17910 - added ending location group to restrictions
    *			GF 06/20/03 - #21577 - only write location group into table when begin or end range specified.
    *			GF 06/27/03 - #20288 - added create separate invoice per location group parameter.
    *			GF 11/05/03 - issue #18762 - use the MSQH.PayTerms when initializing
    *			GF 03/16/04 - issue #24054 - need to populate CMAcct when cash and no check #
    *			GF 03/17/04 - issue #24064 - need to turn off then on auditing for last invoice # in MSCO/ARCO
    *			TJL 03/17/04 - Issue #18413,   Allow Invoice #s greater than 4000000000
    *			GG 02/24/05 - #27184 - sort by customer
    *			GF 07/05/2005 - issue #29203 remmed out customer sort order
    *			GF 09/01/2005 - issue #29715 cannot insert null for @rectype, skip if null (invalid)
    *			GF 02/06/2007 - issue #123745 next invoice number needs to be BigInt
	*			GF 10/05/2007 - issue #120311 do not allow inter-company sales where the Sale types are
	*							different for the tickets to be on the same invoice.
*				GF 01/31/2008 - issue #120116 added option to order MSTD in customer or transaction.
*				GF 03/11/2008 - issue #127082 added MSQH.Country, MSTD.Country
*				GF 08/25/2012 TK-17369 fix problem if restrict by billing frequency pulling in ones that are null
	*
    *
    *
    *
    *
    * Called from the MS Invoice Initialization form to create
    * invoices from billable ticket and haul detail.
    *
    * INPUT PARAMETERS
    *   @co                 MS Co#
    *   @mth                Batch Month
    *   @batchid            Batch ID
    *   @xlocgroup          Begin Location Group restriction
    *	 @xendlocgroup		 Ending location group restriction
    *   @xbeginloc          Beginning Location restriction
    *   @xendloc            End Location restriction
    *   @xcustgroup         Customer Group restriction
    *   @xcustomer          Customer # restriction
    *   @restrictcustjob    'Y' = restrict on Cust Job, 'N' = Cust Job not restricted
    *   @xcustjob           Customer Job restrinction
    *   @restrictcustpo     'Y' = restrict on Cust PO, 'N' = Cust PO not restricted
    *   @xcustpo            Customer PO restriction
    *   @xfreq              Billing Frequency restriction
    *   @xpaymenttype       Payment Type restriction
    *   @xbegindate         Beginning Sale Date restriction
    *   @xenddate           Ending Sale Date restriction
    *   @invdate            Invoice Date - required
    *   @invbyloc           Invoice By Location - if Y, create a separate invoice for each location
    *
    * OUTPUT PARAMETERS
    *   @msg            success or error message
    *
    * RETURN VALUE
    *   0               success
    *   1               fail
    *****************************************************/
(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @xlocgroup bGroup = null,
 @xbeginloc bLoc = null, @xcustgroup bGroup = null, @xcustomer bCustomer = null, @restrictcustjob char(1) = 'N',
 @xcustjob varchar(20) = null, @restrictcustpo char(1) = 'N', @xcustpo varchar(20) = null, @xfreq bFreq = null,
 @xpaymenttype varchar(1) = null, @xbegindate bDate = null, @xenddate bDate = null, @invdate bDate = null,
 @xendloc bLoc = null, @invbyloc bYN, @xendlocgroup bGroup = null, @invbylocgroup bYN, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @invcount int, @transcount int, @skippedcount int, @status tinyint, @arco bCompany, @invopt char(2),
		@datesort bYN, @locsort bYN, @intercoinv bYN, @openMSTD tinyint, @mstrans bTrans, @saledate bDate,
		@fromloc bLoc, @ticket bTic, @saletype char(1), @custgroup bGroup, @customer bCustomer, @custjob varchar(20),
		@custpo varchar(20), @paymenttype char(1), @jcco bCompany, @inco bCompany, @matlgroup bGroup,
		@material bMatl, @um bUM, @unitprice bUnitCost, @locgroup bGroup, @intercosale bYN, @toco bCompany,
		@arcmrectype tinyint, @payterms bPayTerms, @arcminvlvl tinyint, @arcmfreq bFreq, @arcmprintlvl tinyint,
		@arcmsubtotallvl tinyint, @arcmsephaul bYN, @sepinv bYN, @msqhfreq bFreq, @msibcustjob varchar(20),
		@msibcustpo varchar(20), @description bDesc, @shipaddress varchar(60), @city varchar(30), @state varchar(4),
		@zip bZip, @shipaddress2 varchar(60), @msqhprintlvl tinyint, @msqhsubtotallvl tinyint, @msqhsephaul bYN,
		@printlvl tinyint, @subtotallvl tinyint, @sephaul bYN, @inlmrectype tinyint, @inlorectype tinyint,
		@category varchar(10), @rectype tinyint, @rc int, @discrate bPct, @discdate bDate, @duedate bDate,
		@batchseq int, @msinv varchar(10), @msidsaledate bDate, @msidfromloc bLoc, @ticshipaddress varchar(60),
		@ticcity varchar(30),@ticstate varchar(4),@ticzip bZip, @arcustgroup bGroup, @job bJob, @autoapply bYN,
		@checkno bCMRef, @arcmco bCompany, @arcmacct bCMAcct, @inlmcmco bCompany, @inlmcmacct bCMAcct,
		@cmco bCompany, @cmacct bCMAcct, @arcm_payterms bPayTerms, @msqh_payterms bPayTerms,
		@invinitorder bYN, @country varchar(2), @ticcountry varchar(2)

select @rcode = 0, @invcount = 0, @transcount = 0, @skippedcount = 0

---- TK-17369
IF ISNULL(@xfreq,'') = '' SET @xfreq = NULL

---- validate HQ Batch
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'MS Invoice', 'MSIB', @msg output, @status output
if @rcode <> 0 goto bspexit
if @status <> 0     -- must be open
	begin
	select @msg = 'Invalid Batch status - must be Open!', @rcode = 1
	goto bspexit
	end

---- get MS company info
select @arco = ARCo, @invopt = InvOpt, @datesort = DateSort, @locsort = LocSort,
		@intercoinv = InterCoInv, @autoapply = AutoApplyCash, @invinitorder=InvInitOrder
from MSCO with (nolock) where MSCo = @co
if @@rowcount = 0
	begin
	select @msg = 'Missing MS Company!', @rcode = 1
	goto bspexit
	end

---- get AR Co# info, used for intercompany invoices and payments
select @arcustgroup = CustGroup
from HQCO with (nolock) where HQCo = @arco
if @@rowcount = 0
	begin
	select @msg = 'Missing HQ Company ' + convert(varchar,@arco), @rcode = 1
	goto bspexit
	end

---- get default CM Co# and CM Account used for auto payments
select @arcmco = CMCo, @arcmacct = CMAcct
from ARCO with (nolock) where ARCo = @arco
if @@rowcount = 0
	begin
	select @msg = 'Missing AR Company ' + convert(varchar,@arco), @rcode = 1
	goto bspexit
	end

---- use a cursor to cycle through MSTD billable detail
---- there are 2 ways this cursor can be created depending on
---- whether the MSCO.InvInitOrder is 'Y' - then in customer order otherwise MS Transaction order
if @invinitorder = 'Y'
	begin
	declare bcMSTD cursor LOCAL FAST_FORWARD
		for select MSTrans, SaleDate, FromLoc, Ticket, SaleType, CustGroup, Customer, CustJob,
				CustPO, PaymentType, CheckNo, JCCo, Job, INCo, MatlGroup, Material, UM, UnitPrice,
				ShipAddress, City, State, Zip, Country
	from MSTD where MSCo = @co and Mth = @mth
	and SaleDate >= isnull(@xbegindate,SaleDate) and SaleDate <= isnull(@xenddate,SaleDate)
	and FromLoc >= isnull(@xbeginloc,FromLoc) and FromLoc <= isnull(@xendloc,FromLoc)
	and (SaleType = 'C' or @intercoinv = 'Y')   -- include all Sales Types if intercompany invoicing
	and ((@restrictcustjob = 'Y' and CustJob = isnull(@xcustjob,CustJob)) or @restrictcustjob = 'N')
	and ((@restrictcustpo = 'Y' and CustPO = isnull(@xcustpo,CustPO)) or @restrictcustpo = 'N')
	and Hold = 'N' and Void = 'N'       -- not on hold or void
	and MSInv is null and InUseBatchId is null  -- not invoiced or in a batch
	order by CustGroup, Customer, CustJob, CustPO, MSTrans	---- #120116 add customer order by
	end
else
	begin
	declare bcMSTD cursor LOCAL FAST_FORWARD
		for select MSTrans, SaleDate, FromLoc, Ticket, SaleType, CustGroup, Customer, CustJob,
				CustPO, PaymentType, CheckNo, JCCo, Job, INCo, MatlGroup, Material, UM, UnitPrice,
				ShipAddress, City, State, Zip, Country
	from MSTD where MSCo = @co and Mth = @mth
	and SaleDate >= isnull(@xbegindate,SaleDate) and SaleDate <= isnull(@xenddate,SaleDate)
	and FromLoc >= isnull(@xbeginloc,FromLoc) and FromLoc <= isnull(@xendloc,FromLoc)
	and (SaleType = 'C' or @intercoinv = 'Y')   -- include all Sales Types if intercompany invoicing
	and ((@restrictcustjob = 'Y' and CustJob = isnull(@xcustjob,CustJob)) or @restrictcustjob = 'N')
	and ((@restrictcustpo = 'Y' and CustPO = isnull(@xcustpo,CustPO)) or @restrictcustpo = 'N')
	and Hold = 'N' and Void = 'N'       -- not on hold or void
	and MSInv is null and InUseBatchId is null  -- not invoiced or in a batch
	end


---- open cursor
open bcMSTD
select @openMSTD = 1


MSTD_loop:
fetch next from bcMSTD into @mstrans, @saledate, @fromloc, @ticket, @saletype, @custgroup,
		@customer, @custjob, @custpo, @paymenttype, @checkno, @jcco, @job, @inco, @matlgroup,
		@material, @um, @unitprice, @ticshipaddress, @ticcity, @ticstate, @ticzip, @ticcountry

if @@fetch_status = -1 goto MSTD_end
if @@fetch_status <> 0 goto MSTD_loop

-- check Location Group restriction
select @locgroup = LocGroup from INLM with (nolock) where INCo = @co and Loc = @fromloc



-- beginning location group restriction
if isnull(@xlocgroup,0) > 0
if @locgroup < @xlocgroup goto MSTD_loop
-- ending location group restriction
if isnull(@xendlocgroup,0) > 0
if @locgroup > @xendlocgroup goto MSTD_loop

-- check Payment Type restriction
if @saletype in ('J','I') select @paymenttype = 'A'	-- Job/IN sales are 'on account'
if isnull(@xpaymenttype,@paymenttype) <> @paymenttype goto MSTD_loop

select @intercosale = 'N'
    
	if @saletype in ('J','I')    -- job and inventory sales
		begin
		select @intercosale = 'Y'
		-- check for intercompany sale
		select @toco = case @saletype when 'J' then @jcco else @inco end
		if @toco = @co goto MSTD_loop   -- skip if sold to current Co#

		-- get 'sell to' Company Customer #
		select @custgroup = @arcustgroup, @custjob = @job	-- use AR Co# Customer Group, use Job for Customer Job
		select @customer = Customer
		from bHQCO with (nolock) where HQCo = @toco
		if @@rowcount = 0 goto MSTD_loop    -- invalid Company
		end
    
--check Customer restriction
if @custgroup <> isnull(@xcustgroup,@custgroup) or @customer <> isnull(@xcustomer,@customer) goto MSTD_loop

----get Customer info, if used for intercompany invoicing must be setup in each Customer Group referenced
set @arcm_payterms = NULL
select @arcmrectype = RecType, @arcm_payterms = PayTerms, @arcminvlvl = InvLvl, @arcmfreq = BillFreq, 
   @arcmprintlvl = PrintLvl, @arcmsubtotallvl = SubtotalLvl, @arcmsephaul = SepHaul
from bARCM with (nolock) 
where CustGroup = @custgroup and Customer = @customer and Status <> 'I'
if @@rowcount = 0 goto MSTD_loop    -- invalid Customer
    
       --check Quote for Bill Freq and whether a separate Invoice needs to be created
       select @sepinv = null, @msqhfreq = null, @msqh_payterms = null
       select @sepinv = SepInv, @msqhfreq = BillFreq, @msqh_payterms = PayTerms
       from bMSQH with (nolock) 
       where MSCo = @co and QuoteType = 'C' and CustGroup = @custgroup and Customer = @customer
             and isnull(CustJob,'') = isnull(@custjob,'') and isnull(CustPO,'') = isnull(@custpo,'') and Active = 'Y' -- must be Active
         if @@rowcount = 0
            begin
            -- if no active Quote found at Customer PO level, check for one at Customer Job level
            select @sepinv = SepInv, @msqhfreq = BillFreq, @msqh_payterms = PayTerms
            from bMSQH with (nolock) 
            where MSCo = @co and QuoteType = 'C' and CustGroup = @custgroup and Customer = @customer
                and isnull(CustJob,'') = isnull(@custjob,'') and CustPO is null and Active = 'Y'
            if @@rowcount = 0
                begin
                -- if no active Quote found at Customer Job level, check for one at Customer
                select @sepinv = SepInv, @msqhfreq = BillFreq, @msqh_payterms = PayTerms
                from bMSQH with (nolock) 
                where MSCo = @co and QuoteType = 'C' and CustGroup = @custgroup and Customer = @customer
                    and CustJob is null and CustPO is null and Active = 'Y'
                end
            end

----TK-17369
IF ISNULL(@msqhfreq,'') = '' SET @msqhfreq = NULL
IF ISNULL(@arcmfreq,'') = '' SET @arcmfreq = NULL
---- check Billing Frequency restriction
IF @xfreq IS NOT NULL AND @xfreq <> COALESCE(@msqhfreq, @arcmfreq, '!NO!MATCH!') GOTO MSTD_loop
--if @xfreq is not null and @xfreq <> isnull(isnull(@msqhfreq,@arcmfreq),@xfreq) goto MSTD_loop

-- use payterms from MSQH if exists else from ARCM
 
   	  set @payterms = isnull(@msqh_payterms, @arcm_payterms)
   
         -- assign Customer Job and PO for Invoice based on most detailed level of invoice requested
         select @msibcustjob = null, @msibcustpo = null
         if @arcminvlvl > 0 or @sepinv = 'Y' select @msibcustjob = @custjob
         if @arcminvlvl > 1 or @sepinv = 'Y' select @msibcustpo = @custpo
    
         -- pull Address info and Invoice overrides from Quote based on invoicing level
         select @description = 'Material Sales', @shipaddress = null, @city = null, @state = null, @zip = null,
                @shipaddress2 = null, @msqhprintlvl = null, @msqhsubtotallvl = null, @msqhsephaul = null,
				@country = null
         select @description = Description, @shipaddress = ShipAddress, @city = City, @state = State, @zip = Zip,
				@shipaddress2 = ShipAddress2, @msqhprintlvl = PrintLvl, @msqhsubtotallvl = SubtotalLvl,
				@msqhsephaul = SepHaul, @country=Country
         from bMSQH with (nolock) 
         where MSCo = @co and QuoteType = 'C' and CustGroup = @custgroup and Customer = @customer
             and isnull(CustJob,'') = isnull(@msibcustjob,'') and isnull(CustPO,'') = isnull(@msibcustpo,'') and Active = 'Y' -- must be Active
        if @@rowcount = 0
            begin
            -- if no active Quote found at Customer PO level, check for one at Customer Job level
            select @description = Description, @shipaddress = ShipAddress, @city = City, @state = State, @zip = Zip,
            		@shipaddress2 = ShipAddress2, @msqhprintlvl = PrintLvl, @msqhsubtotallvl = SubtotalLvl,
					@msqhsephaul = SepHaul, @country=Country
            from bMSQH with (nolock) 
            where MSCo = @co and QuoteType = 'C' and CustGroup = @custgroup and Customer = @customer
                and isnull(CustJob,'') = isnull(@msibcustjob,'') and CustPO is null and Active = 'Y'
            -- if no active Quote found at Customer Job level, check for one at Customer
            if @@rowcount = 0
                begin
                select @description = Description, @shipaddress = ShipAddress, @city = City, @state = State,
                    	@zip = Zip, @shipaddress2 = ShipAddress2, @msqhprintlvl = PrintLvl, @msqhsubtotallvl = SubtotalLvl,
						@msqhsephaul = SepHaul, @country=Country
                from bMSQH with (nolock) 
                where MSCo = @co and QuoteType = 'C' and CustGroup = @custgroup and Customer = @customer
                and CustJob is null and CustPO is null and Active = 'Y'
                end
            end
    
        --use Quote address unless overridden by ticket
        if @ticshipaddress is not null select @shipaddress2 = null   -- address 2 only used with Quote
        select @shipaddress = isnull(@ticshipaddress,@shipaddress),
				@city = isnull(@ticcity,@city),
            	@state = isnull(@ticstate,@state),
				@zip = isnull(@ticzip,@zip),
				@country = isnull(@ticcountry,@country)
    
        -- assign Invoice print options
        select @printlvl = isnull(@msqhprintlvl,@arcmprintlvl), @subtotallvl = isnull(@msqhsubtotallvl,@arcmsubtotallvl),
             	@sephaul = isnull(@msqhsephaul,@arcmsephaul)
    
         -- determine Receivable Type, may be overridden by Loc and/or Category
         select @inlmrectype = RecType, @inlmcmco = CMCo, @inlmcmacct = CMAcct
         from bINLM with (nolock) where INCo = @co and Loc = @fromloc and Active = 'Y'
         if @@rowcount = 0 goto MSTD_loop    -- invalid Location
    
         --get Material Category
         select @inlorectype = null
         select @category = Category
         from bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
         if @@rowcount <> 0
             begin
             select @inlorectype = RecType
             from bINLO with (nolock) where INCo = @co and Loc = @fromloc and MatlGroup = @matlgroup and Category = @category
             end
    
        -- assign Receivable Type for this transaction
        select @rectype = isnull(isnull(@inlorectype,@inlmrectype),@arcmrectype)
   		if @rectype is null 
		begin
			select @skippedcount = @skippedcount + 1
			goto MSTD_loop -- -- -- missing receivable type issue #29715
		end
    
         -- determine Discount and Due dates based on Customer's Payment Terms and Invoice date
         exec @rc = bspHQPayTermsDateCalc @payterms, @invdate, @discdate output, @duedate output, @discrate output, @msg output
         if @rc <> 0 select @discdate = @invdate, @duedate = @invdate
    
         -- @duedate can return from bspHQPayTermsDateCalc equal to Null without there being an error to set @rc = 1
         -- and DueDate is a required field in MSIB
         if @duedate is null select @duedate = @invdate
   
   	  -- #14177 - use CheckNo only if auto applying payments to cash invoices
   	  if @autoapply = 'N' or @paymenttype <> 'C' select @checkno = null
   	  -- assign CM Co# and Account for auto payment
   	  select @cmco = null, @cmacct = null
   	  -- #24054 - need to assign CM info for cash sales reguardless of check no.
   	  -- -- if @checkno is not null select @cmco = isnull(@inlmcmco,@arcmco), @cmacct = isnull(@inlmcmacct, @arcmacct)
   	  if @autoapply = 'Y' and @paymenttype = 'C' select @cmco = isnull(@inlmcmco,@arcmco), @cmacct = isnull(@inlmcmacct, @arcmacct)
   	

	---- check for existing Invoice Batch Header
	select @batchseq = BatchSeq
	from bMSIB with (nolock) 
	where Co = @co and Mth = @mth and BatchId = @batchid and CustGroup = @custgroup and Customer = @customer
	and isnull(CustJob,'') = isnull(@msibcustjob,'') and isnull(CustPO,'') = isnull(@msibcustpo,'')
	and PaymentType = @paymenttype and RecType = @rectype and InvDate = @invdate and ApplyToInv is null
	and ((LocGroup = @locgroup and @invbylocgroup = 'Y') or @invbylocgroup = 'N')
	and ((Location = @fromloc and @invbyloc = 'Y' ) or @invbyloc = 'N')
	and Interfaced = 'N' and Void = 'N'
	and isnull(ShipAddress,'') = isnull(@shipaddress,'') and isnull(City,'') = isnull(@city,'')
	and isnull(State,'') = isnull(@state,'') and isnull(Zip,'') = isnull(@zip,'')
	and isnull(ShipAddress2,'') = isnull(@shipaddress2,'')
	and isnull(Country,'') = isnull(@country,'')	-- #127082
	and isnull(CheckNo,'') = isnull(@checkno,'')	-- #14177 - separate invoice per check #
	and isnull(CMCo,0) = isnull(@cmco,0) and isnull(CMAcct,0) = isnull(@cmacct,0) -- CM Co# and CMAcct for payments
	if @@rowcount = 0
		begin
		next_Invoice:     -- get next Invoice #
		if @invopt = 'MS'
			begin
			select @msinv = convert(varchar(10),convert(bigint,isnull(LastInv,'0')) + 1)
			from bMSCO with (nolock) where MSCo = @co
			---- turn off then on auditing
			update bMSCO set LastInv = @msinv, AuditYN='N' where MSCo = @co    -- update last invoice #
			update bMSCO set AuditYN='Y' where MSCo=@co
			end
		else
			begin
			select @msinv = convert(varchar(10),convert(bigint,isnull(InvLastNum,'0')) + 1) from bARCO with (nolock) where ARCo=@arco
			---- turn off then on auditing
			update bARCO set InvLastNum = convert(bigint,@msinv), AuditYN='N' where ARCo=@arco    -- update last invoice #
			update bARCO set AuditYN='Y' where ARCo=@arco
			end
   
		---- invoice should be right justified 10 chars
		select @msinv = space(10 - datalength(@msinv)) + @msinv
		---- skip Invoice # if already used
		if exists(select 1 from bMSIH with (nolock) where MSCo = @co and MSInv = @msinv) goto next_Invoice
		if exists(select 1 from bMSIB with (nolock) where Co = @co and MSInv = @msinv) goto next_Invoice
    
		---- get next Batch Sequence #
		select @batchseq = isnull(max(BatchSeq),0) + 1
		from bMSIB with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid
		---- add Invoice Batch Header
		insert bMSIB(Co, Mth, BatchId, BatchSeq, MSInv, CustGroup, Customer, CustJob, CustPO, Description,
                 ShipAddress, City, State, Zip, ShipAddress2, PaymentType, RecType, PayTerms, InvDate, DiscDate,
                 DueDate, ApplyToInv, InterCoInv, LocGroup, Location, PrintLvl, SubtotalLvl, SepHaul, Interfaced,
                 Void, Notes, PrintedYN, CheckNo, CMCo, CMAcct, Country)
		values(@co, @mth, @batchid, @batchseq, @msinv, @custgroup,@customer, @msibcustjob, @msibcustpo, @description,
				@shipaddress, @city, @state, @zip, @shipaddress2, @paymenttype, @rectype, @payterms, @invdate, @discdate,
				@duedate, null, @intercosale, 
				case @invbylocgroup when 'Y' then @locgroup else null end, 
				case @invbyloc when 'Y' then @fromloc else null end,
				@printlvl, @subtotallvl, @sephaul, 'N','N', null, 'N', @checkno, @cmco, @cmacct, @country)
    
		select @invcount = @invcount + 1    -- # of new invoices
		end
	else
		begin
		---- if intercompany invoices, make sure we are not combining ticket sale types. issue #120311
		if @intercosale = 'Y' and exists(select b.SaleType from MSID a with (nolock)
									join MSTD b with (nolock) on a.Co=b.MSCo and a.Mth=b.Mth and a.MSTrans=b.MSTrans
									where a.Co=@co and a.Mth=@mth and a.BatchId=@batchid and a.BatchSeq=@batchseq
									and b.SaleType <> @saletype)
			begin
			goto next_Invoice
			end
		end



---- assign Batch Detail Sale Date and Loc based on MS Co Sort options
select @msidsaledate = null, @msidfromloc = null
if @datesort = 'Y' select @msidsaledate = @saledate
if @locsort = 'Y' select @msidfromloc = @fromloc

---- add Invoice Batch Detail - insert trigger on bMSID will lock bMSTD entry
insert bMSID(Co, Mth, BatchId, BatchSeq, MSTrans, CustJob, CustPO, SaleDate, FromLoc, MatlGroup,
			Material, UM, UnitPrice, Ticket)
values(@co, @mth, @batchid, @batchseq, @mstrans, @custjob, @custpo, @msidsaledate, @msidfromloc, @matlgroup,
			@material, @um, @unitprice, @ticket)

select @transcount = @transcount + 1    -- # of billed transactions

goto MSTD_loop  -- next transaction





MSTD_end:	    -- no more rows to process
	close bcMSTD
	deallocate bcMSTD
	select @openMSTD = 0



bspexit:
	if @openMSTD = 1
		begin
		close bcMSTD
		deallocate bcMSTD
		end

	if @rcode = 0 select @msg = 'Created ' + convert(varchar(6),@invcount) + ' new invoices, and billed ' + convert(varchar(8),@transcount) + ' transactions.' + char(13) + char(10) + 'Skipped ' + convert(varchar(8), @skippedcount) + ' tickets because incomplete Receivable Type setup.'
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSInvInit] TO [public]
GO
