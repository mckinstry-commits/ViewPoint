SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspPRAPUpdate]
/***********************************************************
* CREATED: GG 08/14/98
* MODIFIED: GG 06/17/99
*           GG 01/11/00 - Fixed final AP Update check
*           GG 03/06/00 - AP Batches added as 'restricted', return Batch ID as @msg
*           GG 06/01/00 - Fixed to handle Employees flagged as 'X - No Pay'
*           GG 02/22/01 - added 'restricted batch' input parameter
*           GG 03/06/01 - assign unique AP Reference values
*           MV 09/04/01 - 10997 - EFT child support and tax payment addendas
*			MV 01/29/02 - 15469 - enhanced tax payment addenda coding
*			GG 07/09/02 - #10865 - use AP info from bPRCA on Craft D/Ls
*			MV 08/05/02 - #15113 - pass vendorgroup to bspAPHDRefUnique
*			EN 10/7/02 - issue 18877 change double quotes to single
*			MV 11/7/02 = #18889 - set prepaidprocyn to 'N'
*       	GH 1/03/03 - 19855 - changed single quotes from five of them to four on frequency formula
*			GG 1/07/03 - #19887 - correct updates to bPRCA and bPRDT for 'old' values
*			MV 01/28/03 - #18456 - set @separatepayyn to a default of 'N'
*			mv 02/27/03 - #20465 - separate line for Fed Tax Payment dlcodes
*			EN 12/03/03 - issue 23061  added isnull check, with (nolock), and dbo
*			EN 3/16/04 - issue 20559  add ability to update negative earnings to AP
*			EN 7/12/04 - issue 25046 Pay type sometimes defaults incorrectly for ded/liab update
*			GG 5/17/07 - #119674 - initialize APHB.AmtType3 and APHB.Amount3
*			GG 5/17/07 - #122538 - minor change to message text
*			mh 10/22/07 - #125755 - Override GL Account not getting reset for subsequent Employees.
*			EN 11/13/07 - #126106 - resolve possible bPRCA change error if @vendor is null
*			EN 8/07/08 - #127863  Add option to override the CMAcct value setup in APCO
*			TJL 02/11/09 - #124739 - Add CMAcct in APVM as default and use here.
*			MV 10/19/09 - #131826 - Use APVM default PayControl.
*			CHS	04/19/2012 - TK-14211 - added Pay Method for Credit Services
*
* USAGE:
* Called from the PR APUpdate form to create a batch of AP transactions.
*
* INPUT PARAMETERS
*   @prco   		PR Company
*   @prgroup  	PR Group to validate
*   @prenddate	Pay Period Ending Date
*   @paymth		Payment month - used to restrict processing, if null all months processed
*   @freqlist		Frequency list - used to restrict processing, if null all DLs processed
*   @expmth		Expense month used for new AP transactions - reversing trans posted in orig mth
*   @invdate		Invoice date used for all AP transactions
*   @rstrict      Restrict batch flag used when adding HQ Batch Control entries
*	@over_cmacct	CM Acct to override the one setup in APCo
*
* OUTPUT PARAMETERS
*   @msg          Batch ID or error message
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
   
(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @paymth bMonth = null,
 @freqlist varchar(255) = null, @expmth bMonth = null, @invdate bDate = null, @rstrict bYN = 'N',
 @over_cmacct bCMAcct = null, @msg varchar(1000) = null output)
as
set nocount on
   
declare @rcode int, @glco bCompany, @apco bCompany, @exppaytype tinyint, @status tinyint, @apinterface bYN,
	@inuseby bVPUserName, @vendorgroup bGroup, @vendor bVendor, @batchmth bMonth, @batchid int, @lastvendor bVendor,
	@lastedlcode bEDLCode, @openEmplSeq tinyint, @openEmplDetail tinyint, @openAP tinyint, @employee bEmployee,
	@paidmth bMonth, @edlcode bEDLCode, @useover bYN, @overamt bDollar, @oldvendor bVendor, @transbyemployee bYN,
	@freq bFreq, @apfields char(6), @oldapamt bDollar, @amt bDollar, @mth bMonth, @payterms bPayTerms, @appaymethod char(1),
	@eft char(1), @paytype tinyint, @discdate bDate, @payseq tinyint, @apdesc bDesc, @oldapmth bMonth, @description bDesc,
	@v1099 bYN, @glacct bGLAcct, @duedate bDate, @seq int, @v1099type varchar(10), @discrate bRate, @v1099box tinyint,
	@cmco bCompany, @cmacct bCMAcct, @overglacct bGLAcct, @errmsg varchar(255), @paymethod char(1), @i smallint, @rc tinyint,
	@apref bAPReference, @addendatypeid tinyint, @eftprco bCompany, @eftemployee bEmployee, @eftdlcode bEDLCode,
	@taxformcode varchar (10), @taxperiodenddate bDate, @amttype1 varchar (10),@amttype2 varchar (10),@amttype3 varchar (10),
	@amount bDollar,@amount2 bDollar, @amount3 bDollar, @category varchar (1), @fedtype varchar (1),
	@separatepayyn bYN, @source varchar(10), @apline int,@lineseq int, @edltype char(1), @lastedltype char(1),
	@apvmcmacct bCMAcct, @apvmpaycontrol varchar (10), @VendorPaymethod char(1), @ApcoCsCmAcct bCMAcct -- CHS TK-14211
   
select @rcode = 0, @openEmplSeq = 0, @openEmplDetail = 0, @openAP = 0, @msg = null

-- get PR Company info
select @glco = GLCo, @apco = APCo
from dbo.bPRCO with (nolock) where PRCo = @prco
if @@rowcount = 0
	begin
	select @msg = 'Invalid PR Company!', @rcode = 1
	goto bspexit
	end
   
-- check Invoice Date
if @invdate is null
	begin
	select @msg = 'Missing Invoice Date!', @rcode = 1
	goto bspexit
	end

-- get AP Company info
select @exppaytype = ExpPayType, @cmco = CMCo, @cmacct = CMAcct, @ApcoCsCmAcct = CSCMAcct -- CHS TK-14211
from dbo.bAPCO with (nolock) where APCo = @apco
if @@rowcount = 0
	begin
	select @msg = 'Invalid AP Company!  Check your setup in PR Company.', @rcode = 1
	goto bspexit
	end

-- if override cmacct is valid use it instead of the one read from bAPCO ... else return error
if @over_cmacct is not null
	begin
	if (select 1 from CMAC where CMCo = @cmco and CMAcct = @over_cmacct) <> 1
		begin
		select @msg = 'Override CM Account is invalid!', @rcode = 1
		goto bspexit
		end
		--select @cmacct = @over_cmacct			--REM'D PER ISSUE #124739
	end

-- get Pay Period info
select @status = Status, @apinterface = APInterface, @inuseby = InUseBy
from dbo.bPRPC with (nolock)
where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
if @@rowcount = 0
	begin
	select @msg = 'Missing Pay Period Control entry!', @rcode = 1
	goto bspexit
	end
if @status = 1 and @apinterface = 'Y'
	begin
	select @msg = 'Final AP Update has already been run for this Pay Period!', @rcode = 1
	goto bspexit
	end
if @inuseby is not null
	begin
	select @msg = 'Pay Period in use by ' + isnull(@inuseby,'') + '.  Cannot update at this time.', @rcode = 1
	goto bspexit
	end
   
-- lock Pay Period during the update
update dbo.bPRPC set InUseBy = SUSER_SNAME()
where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate

-- clear PR AP distributions
delete dbo.bPRAP where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   
-- process paid Employees using a cursor on bPRSQ
declare bcEmplSeq cursor for
select Employee, PaySeq, PayMethod, PaidMth
from dbo.bPRSQ with (nolock)
where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
and (PaidMth is not null or PayMethod = 'X') and Processed = 'Y'
   
open bcEmplSeq
select @openEmplSeq = 1
   
-- loop through Employee Sequences
next_EmplSeq:
	fetch next from bcEmplSeq into @employee, @payseq, @paymethod, @paidmth
    	if @@fetch_status = -1 goto end_EmplSeq
    	if @@fetch_status <> 0 goto next_EmplSeq
   
        -- check Paid Month restriction
        if @paymethod <> 'X'
			begin
        	if @paymth is not null and @paidmth <> @paymth goto next_EmplSeq
   
        	-- must be expensed in AP to a month equal to or later than the month paid in PR
        	if @expmth < @paidmth goto next_EmplSeq
            end
   
    	-- use a cursor to process Dedns/Liabs for current Employee/PaySeq
   		-- only DLs flagged for AutoAP should have Vendor info
   		-- Craft DLs in bPRDT will record Vendor from first Craft using that code, detail info in bPRCA
    	declare bcEmplDetail cursor for
   		-- pull Craft DLs first
   		select 'Craft', EDLType, EDLCode, sum(Amt), 'N', 0, VendorGroup, Vendor, APDesc, OldVendor, OldAPMth, sum(OldAPAmt)
   		from dbo.bPRCA with (nolock)
   		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
   			and PaySeq = @payseq and (Vendor is not null or OldVendor is not null)
   		group by EDLType, EDLCode, VendorGroup, Vendor, OldVendor, APDesc, OldAPMth
   		union
   		-- pull remaining EDLs from Employee Sequence Control - exclude Craft DLs
    	select 'Detail', EDLType, EDLCode, Amount, UseOver, OverAmt, VendorGroup, Vendor, APDesc, OldVendor, OldAPMth, OldAPAmt
    	from dbo.bPRDT d with (nolock)
    	where d.PRCo = @prco and d.PRGroup = @prgroup and d.PREndDate = @prenddate and d.Employee = @employee
    		and PaySeq = @payseq and (Vendor is not null or OldVendor is not null)
   		and (d.EDLType='E' or not exists(select 1 from dbo.bPRCA c with (nolock) where c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
   			and c.Employee = d.Employee and c.PaySeq = d.PaySeq and c.EDLType = d.EDLType and c.EDLCode = d.EDLCode))
    		
    	open bcEmplDetail
    	select @openEmplDetail = 1
   
    	-- loop through Dedns/Liabs
    	next_EmplDetail:
    		fetch next from bcEmplDetail into @source, @edltype, @edlcode, @amt, @useover, @overamt, @vendorgroup, @vendor,
    			@apdesc, @oldvendor, @oldapmth, @oldapamt
   
    		if @@fetch_status = -1 goto end_EmplDetail
        	if @@fetch_status <> 0 goto next_EmplDetail
   
        	if @useover = 'Y' select @amt = @overamt
   
   			if @edltype = 'E' --issue 20559 reverse sign for negative earnings
   				begin
   				select @amt = @amt * -1
   				select @oldapamt = @oldapamt * -1
   				end
	   
    		-- skip if no changes
    		if @vendor = @oldvendor and @expmth = @oldapmth and @amt = @oldapamt goto next_EmplDetail
	   
        		-- get std Earn or Dedn/Liab info
   			if @edltype = 'E'
   				begin
   	     		select @transbyemployee = TransByEmployee, @freq = Frequency
   	     		from dbo.bPREC with (nolock) where PRCo = @prco and EarnCode = @edlcode
   	     		if @@rowcount = 0
   	     			begin
   	     			select @msg = 'Missing Earnings code ' + convert(varchar(6),@edlcode) + '!', @rcode = 1
   	     			goto bspexit
   	     			end
   				end
   			else
   				begin
   	     		select @transbyemployee = TransByEmployee, @freq = Frequency
   	     		from dbo.bPRDL with (nolock) where PRCo = @prco and DLCode = @edlcode
   	     		if @@rowcount = 0
   	     			begin
   	     			select @msg = 'Missing Dedn/Liab code ' + convert(varchar(6),@edlcode) + '!', @rcode = 1
   	     			goto bspexit
   	     			end
   				end
   
        	-- check for Frequency restriction	- #19855
        	if @freqlist is not null and charindex('''' + isnull(rtrim(@freq),'') + '''',@freqlist) = 0 goto next_EmplDetail
   
        	-- AP Fields used to control interface level
        	select @apfields = space(6)
        	if @transbyemployee = 'Y' select @apfields = convert(char(6),@employee)
   
            -- get Vendor Group if missing
            if @vendorgroup is null
   				begin
   				select @vendorgroup = VendorGroup
   				from dbo.bHQCO with (nolock) where HQCo = @apco
   				end
   
        	-- add reversing entry for 'old' AP info
        	if @oldvendor is not null and @oldapamt <> 0
        		begin
        		update dbo.bPRAP set Amt = Amt - @oldapamt
        		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Mth = @expmth
        				and VendorGroup = @vendorgroup and Vendor = @oldvendor and EDLType = @edltype 
   					and EDLCode = @edlcode and APFields = @apfields
        		if @@rowcount = 0
        			insert dbo.bPRAP (PRCo, PRGroup, PREndDate, Mth, VendorGroup, Vendor, EDLType,
   					EDLCode, APFields, Amt, Description)
        			values (@prco, @prgroup, @prenddate, @expmth, @vendorgroup, @oldvendor, @edltype,
        					@edlcode, @apfields, -(@oldapamt), @apdesc)
        		end
   
        	-- add new entry for 'current' AP info
        	if @vendor is not null and @amt <> 0
        		begin
        		update dbo.bPRAP set Amt = Amt + @amt
        		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Mth = @expmth
        			and VendorGroup = @vendorgroup and Vendor = @vendor and EDLType = @edltype 
   				and EDLCode = @edlcode and APFields = @apfields
        		if @@rowcount = 0
        			insert dbo.bPRAP (PRCo, PRGroup, PREndDate, Mth, VendorGroup, Vendor, EDLType,
   					EDLCode, APFields, Amt, Description)
        			values (@prco, @prgroup, @prenddate, @expmth, @vendorgroup, @vendor, @edltype,
   					@edlcode, @apfields, @amt, @apdesc)
        		end
   
   			-- update 'old' AP info all Craft Accum records for this DL code and Vendor
   			if @edltype <> 'E'
   				begin
   				if @source = 'Craft'
   					begin
   					update dbo.bPRCA
   					set OldVendor = Vendor, OldAPMth = @expmth, OldAPAmt = Amt 	-- #19887 handle multiple rows
   	 				where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
   					and PaySeq = @payseq and EDLType in ('D','L') and EDLCode = @edlcode and isnull(Vendor,0) = isnull(@vendor,0) --#126106 handle possibility of @vendor being null
   					if @@rowcount = 0
   	     				begin
   	     				select @msg = 'Unable to update AP info in Craft Accumulations. ', @rcode = 1
   	     				goto bspexit
   	     				end
   					end
   				end
        	-- update 'old' AP info in bPRDT for all EDLs
    		update dbo.bPRDT
   			set OldVendor = Vendor, OldAPMth = @expmth, OldAPAmt = case when UseOver='Y' then OverAmt else Amount end -- #19887 handle multiple rows
    		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
               and PaySeq = @payseq and EDLType = @edltype and EDLCode = @edlcode
			if @@rowcount = 0
        		begin
        		select @msg = 'Unable to update AP info in Employee Sequence Detail. ', @rcode = 1
        		goto bspexit
        		end
   
    		goto next_EmplDetail
   
    	end_EmplDetail:
    		close bcEmplDetail
    		deallocate bcEmplDetail
    		select @openEmplDetail = 0
   
    		goto next_EmplSeq
   
    end_EmplSeq:
    	close bcEmplSeq
    	deallocate bcEmplSeq
    	select @openEmplSeq = 0
   
-- prepare to process PR AP entries
select @batchid = null, @batchmth = null, @lastvendor = null, @lastedltype = null, @lastedlcode = null

-- cursor on PR AP interface table
declare bcAP cursor for
select Mth, VendorGroup, Vendor, EDLType, EDLCode, Amt, Description, APFields
from dbo.bPRAP with (nolock)
where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate

open bcAP
select @openAP = 1

next_AP:
	fetch next from bcAP into @mth, @vendorgroup, @vendor, @edltype, @edlcode, @amt, @description, @apfields

	if @@fetch_status = -1 goto end_AP_update
	if @@fetch_status <> 0 goto next_AP

	if @amt = 0 goto next_AP
   
	-- get a new BatchId
	if @batchmth is null or @batchmth <> @mth
		begin
        -- before adding a new batch, remove InUseBy from current Batch Control entry
        if @batchid is not null
			begin
            update dbo.bHQBC set InUseBy = null
            where Co = @apco and Mth = @batchmth and BatchId = @batchid
            -- save batch info in return @msg
            select @msg = 'Successfully created AP Batch ID#: ' + convert(varchar(6),@batchid) + ' in ' +
				convert(varchar(3),@batchmth,1)+ substring(convert(varchar(8),@batchmth,1),7,2)
            end

		-- add a new Batch for each month updated in AP
		exec @batchid = bspHQBCInsert @apco, @mth, 'AP Entry', 'APHB', @rstrict, 'N', null, null, @errmsg output
        if @batchid = 0
			begin
		    select @msg = 'Unable to add a Batch to update AP!', @rcode = 1
		    goto bspexit
	        end

        select @batchmth = @mth
        end

    -- get Vendor info
    if @lastvendor is null or @lastvendor <> @vendor
    	begin
    	select @payterms = null, @v1099 = 'N', @eft = 'N', @separatepayyn = 'N'
    	select @payterms = PayTerms, @v1099 = V1099YN, @v1099type = V1099Type, @v1099box = V1099Box,
			@eft = EFT, @addendatypeid = AddendaTypeId, @separatepayyn = SeparatePayInvYN,
			@apvmcmacct = CMAcct, @apvmpaycontrol = PayControl,
			@VendorPaymethod = PayMethod	-- CHS TK-14211
    	from dbo.bAPVM with (nolock)
    	where VendorGroup = @vendorgroup and Vendor = @vendor
    	
    	
 		-- CHS TK-14211
		IF @VendorPaymethod = 'S'
			BEGIN
			SELECT @appaymethod='S', @separatepayyn = 'N', @over_cmacct = @ApcoCsCmAcct
			END

 		ELSE IF @eft='A'
			BEGIN
			SELECT @appaymethod='E'
			END
			
		ELSE
			BEGIN
			SELECT @appaymethod='C'
			END   
    	
    	
   
    	select @lastvendor = @vendor
    	end
    	

    	
    	
   
    -- get Earn or Dedn/Liab info
--Issue 125755 - If you have seperate transactions for each Employee using the same EDLCode on one of those Employee's
--uses a override GL account, that GL Account number will be used for the subsequent AP transactions.  Do not really
--need to make a check for a EDLType or EDLCode change.  Just repull the data each time through.  mh 10/22/07

--    if @lastedlcode is null or (@lastedltype <> @edltype or @lastedlcode <> @edlcode) --issue 25046 changed type/code compare from 'and' to 'or'
--    	begin
	select @paytype = @exppaytype, @glacct = null	-- default to Expense Pay Type from bAPCO
	if @edltype = 'E'
		begin
 		select @paytype = PayType, @glacct = GLAcct
 		from dbo.bPREC with (nolock)
 		where PRCo = @prco and EarnCode = @edlcode
		end
	else
		begin
		select @paytype = PayType, @glacct = GLAcct
		from dbo.bPRDL with (nolock)
		where PRCo = @prco and DLCode = @edlcode
		end

	select @lastedltype = @edltype, @lastedlcode = @edlcode
--    	end
   
   	select @eftprco = null ,@eftemployee = null, @eftdlcode = null , @taxformcode = null,
       	@taxperiodenddate = null, @amttype1 = null, @amttype2 = null, @amttype3 = null,
      	@amount = null, @amount2 = null, @amount3 = null
   	
   	-- issue 20559 the following applies to D/L's only
   	if @edltype <> 'E'
   		begin
    	-- if a single transaction per Employee, check for override GL Account
   	 	if @apfields <> ''
   	 		begin
   	 		select @overglacct = null
   	 		select @overglacct = OverGLAcct
   	 		from dbo.bPRED with (nolock)
   	 		where PRCo = @prco and Employee = convert(int,@apfields) and DLCode = @edlcode
   	 		if @overglacct is not null select @glacct = @overglacct
   	 		end
   
   		-- EFT addenda info
		if @addendatypeid is not null
   			begin
   	    	select @category = CalcCategory, @fedtype=FedType from dbo.bPRDL with (nolock)
   			where PRCo = @prco and DLCode=@edlcode
   	
   	        if @addendatypeid = 2 --child support
   	            begin
   	            select @eftprco = @prco, @eftemployee = @apfields, @eftdlcode = @edlcode
   	            end
   	        if @addendatypeid = 1 and @category = 'F' -- Fed tax payment
   	            begin
   				-- If an bAPHB record with formcode 94105 already exists, just update it.
   				if exists (select * from dbo.bAPHB with (nolock) where Co=@apco and Mth=@mth
					and BatchId=@batchid and Vendor=@vendor	and TaxFormCode='94105')
   					begin
   					if @fedtype in ('1','3','4') or @fedtype is null
   						begin
   						begin transaction
   						if @fedtype= '1'	--Witholding
   							begin
   		 				update dbo.bAPHB set InvTotal=(isnull(InvTotal,0)+@amt),AmtType3='3',Amount3=(isnull(Amount3,0)+@amt) where Co=@apco and Mth=@mth and
   					 	BatchId=@batchid and Vendor=@vendor and TaxFormCode='94105'
   						end
   					if @fedtype= '3'	--Social Security
   						begin
   						update dbo.bAPHB set InvTotal=(isnull(InvTotal,0)+@amt),AmountType='1',Amount=(isnull(Amount,0)+@amt) where Co=@apco and Mth=@mth and
   					 	BatchId=@batchid and Vendor=@vendor and TaxFormCode='94105'
   						end
   					if @fedtype= '4'	--Medicare
   						begin
   					 	update dbo.bAPHB set InvTotal=(isnull(InvTotal,0)+@amt),AmtType2='2',Amount2=(isnull(Amount2,0)+@amt) where Co=@apco and Mth=@mth and
   					 	BatchId=@batchid and Vendor=@vendor and TaxFormCode='94105'
   						end
   					if @fedtype is null	--default amt to withholding
   						begin
   		 				update dbo.bAPHB set InvTotal=(isnull(InvTotal,0)+@amt),AmtType3='3',Amount3=(isnull(Amount3,0)+@amt) where Co=@apco and Mth=@mth and
   					 	BatchId=@batchid and Vendor=@vendor and TaxFormCode='94105'
   						end
   	
   					-- get next available apline number
   		 			select @apline = isnull(max(APLine),0)+1, @lineseq = max(h.BatchSeq)
   		 			From dbo.bAPLB l with (nolock) join dbo.bAPHB h with (nolock) on l.Co=h.Co and l.Mth=h.Mth and l.BatchId=h.BatchId
   						and l.BatchSeq=h.BatchSeq
   					Where l.Co=@apco and l.Mth=@mth and l.BatchId=@batchid and h.TaxFormCode='94105'
   	
   					-- #20465 create a separate line for each Fed taxpayment dlcode
   					insert into dbo.bAPLB(Co, Mth, BatchId, BatchSeq, APLine, BatchTransType, LineType, GLCo, GLAcct, Description,
   	            		Units, UnitCost, PayType, GrossAmt, MiscAmt, MiscYN, TaxBasis, TaxAmt, Retainage, Discount, BurUnitCost)
   	        		values (@apco, @mth, @batchid, @lineseq, @apline, 'A', 3, @glco, @glacct, @description,
   	            		0, 0, @paytype, @amt, 0, 'N', 0, 0, 0, 0, 0)
   					--update line with @amt
   					/*update bAPLB set GrossAmt = (GrossAmt + @amt)
   						From bAPLB l join bAPHB h on l.Co=h.Co and l.Mth=h.Mth and l.BatchId=h.BatchId
   							and l.BatchSeq=h.BatchSeq
   						Where l.Co=@apco and l.Mth=@mth and l.BatchId=@batchid and h.TaxFormCode='94105'*/
   					goto Delete_PRAP							
   		       		end
   				end
   			--Set tax addenda info
			if @fedtype in ('2','3','4') select @amttype3 = '3', @amount3 = 0	-- #119674 initialize tax payment type and amount
   	    	if @fedtype = '1'	--withholding
   				begin
   				select @taxformcode = '94105', @taxperiodenddate = @prenddate, @amttype3='3',@amount3=@amt --Fed W/H
   				end
   	        if @fedtype='2'		--FUTA
   				begin
   				select @taxformcode = '09405', @taxperiodenddate = @prenddate, @amttype1 = '09405',@amount = @amt
   				end
   			if @fedtype='3'		--Social Security
   				begin
   				select @taxformcode = '94105', @taxperiodenddate = @prenddate, @amttype1 = '1',@amount = @amt
   				end
   			if @fedtype='4'		--Medicare
   				begin
   				select @taxformcode = '94105', @taxperiodenddate = @prenddate, @amttype2 = '2', @amount2 = @amt
   				end
   			if @fedtype is null	--default amt to withholding
   				begin
   				select @taxformcode = '94105', @taxperiodenddate = @prenddate, @amttype3='3',@amount3=@amt
   				end
   	        end
   		end
   	end

-- get Discount and Due Dates based on Vendor's Pay Terms
exec @rcode = bspHQPayTermsDateCalc @payterms, @invdate, @discdate output, @duedate output,
	@discrate output, @errmsg output
if @rcode = 1	-- if error, use defaults
    begin
    select @discdate = null, @duedate = @invdate, @discrate = 0
    select @rcode = 0, @errmsg = null
    end
   
if @duedate is null select @duedate = @invdate	-- make sure we have a due date
   
-- assign unique AP Reference
select @i = 0
assign_apref:
	if @i > 999 goto add_trans   -- limit # of interations
    select @apref = convert(varchar(8),@prenddate,1) + '-' + convert(varchar(3),@i)
    exec @rc = bspAPHDRefUnique @apco, @mth, @batchid, 0, @vendor, @apref, @vendorgroup, @errmsg output
    if @rc <> 0
		begin
        select @i = @i + 1  -- failed, increment seq#
        goto assign_apref
        end
   
add_trans:    -- Add an AP batch entry
	begin transaction

	-- get next available sequence for this AP Batch
    select @seq = isnull(max(BatchSeq),0)+1
    from dbo.bAPHB with (nolock)
    where Co = @apco and Mth = @mth and BatchId = @batchid

    -- add a Header
    insert into dbo.bAPHB (Co, Mth, BatchId, BatchSeq, BatchTransType, APTrans, VendorGroup, Vendor,
		APRef, Description, InvDate, DiscDate, DueDate, InvTotal, PayMethod, CMCo, CMAcct, PrePaidYN,
        V1099YN, V1099Type, V1099Box, PayOverrideYN, AddendaTypeId, PRCo, Employee, DLcode, TaxFormCode,
        TaxPeriodEndDate, AmountType, AmtType2, AmtType3, Amount, Amount2, Amount3, SeparatePayYN,PrePaidProcYN, PayControl)
    values (@apco, @mth, @batchid, @seq, 'A', null, @vendorgroup, @vendor,
        @apref, @description, @invdate, @discdate, @duedate, @amt, @appaymethod, @cmco, isnull(@over_cmacct, isnull(@apvmcmacct, @cmacct)), 'N',
        @v1099, @v1099type, @v1099box, 'N',@addendatypeid, @eftprco, @eftemployee,@eftdlcode, @taxformcode,
        @taxperiodenddate, @amttype1,@amttype2, @amttype3,@amount,@amount2, @amount3, @separatepayyn, 'N', @apvmpaycontrol)

    -- add a single Expense Line
    insert into dbo.bAPLB(Co, Mth, BatchId, BatchSeq, APLine, BatchTransType, LineType, GLCo, GLAcct, Description,
        Units, UnitCost, PayType, GrossAmt, MiscAmt, MiscYN, TaxBasis, TaxAmt, Retainage, Discount, BurUnitCost)
    values (@apco, @mth, @batchid, @seq, 1, 'A', 3, @glco, @glacct, @description,
		0, 0, @paytype, @amt, 0, 'N', 0, 0, 0, 0, 0)
   
Delete_PRAP:
	-- delete PR AP entry
	delete dbo.bPRAP where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
		and Mth = @mth and VendorGroup = @vendorgroup and Vendor = @vendor and EDLType = @edltype
		and EDLCode = @edlcode and APFields = @apfields

	commit transaction

   	goto next_AP
   
   
AP_error:
	rollback transaction
	goto bspexit

end_AP_update:
    close bcAP
    deallocate bcAP
    select @openAP = 0
   
if @batchid is null select @msg = 'Successfully processed, but no AP Batch was created.'
   
-- remove InUseBy from last Batch Control entry
if @batchid is not null
    begin
    update dbo.bHQBC set InUseBy = null
    where Co = @apco and Mth = @batchmth and BatchId = @batchid

    -- save batch info in return @msg
    if @msg is null
       select @msg = 'Successfully created AP Batch ID#: ' + convert(varchar(6),@batchid) + ' in '  +
           convert(varchar(3),@batchmth,1)+ substring(convert(varchar(8),@batchmth,1),7,2) 
	else
		select @msg = isnull(@msg,'') + ' and Batch ID#: ' + convert(varchar(6),@batchid) + ' in ' + 
           convert(varchar(3),@batchmth,1)+ substring(convert(varchar(8),@batchmth,1),7,2) 
    end
   
-- AP update successfully completed, set Final AP Interface flag is Pay Period is closed
if @status = 1
	begin
	-- check that all AP updates have been made
	if exists(select 1 from dbo.bPRDT with (nolock)
		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
			and (Vendor is not null or OldVendor is not null)
           and (isnull(Vendor,-1) <> isnull(OldVendor,-1)
               or (UseOver = 'Y' and OverAmt <> OldAPAmt) or (UseOver = 'N' and Amount <> OldAPAmt)))
		begin
		if @msg is not null select @msg = isnull(@msg,'') + char(13) + char(10) 
		select @msg = isnull(@msg,'') + 'Warning - Not all deductions and liabilities were included in the update.  Final AP Interface flag has not been set.'
		goto bspexit
		end
   
	if exists(select 1 from dbo.bPRCA with (nolock)
		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
				and (Vendor is not null or OldVendor is not null)
			   and (isnull(Vendor,-1) <> isnull(OldVendor,-1) or (Amt <> OldAPAmt)))
		begin
		if @msg is not null select @msg = isnull(@msg,'') + char(13) + char(10) 
		select @msg = isnull(@msg,'') + 'Warning - Not all Craft deductions and liabilities were included in the update.  Final AP Interface flag has not been set.'
		goto bspexit
		end 
   
	update dbo.bPRPC
   	set APInterface = 'Y'  -- final AP interface is complete
	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
	end
   
bspexit:
	if @openEmplSeq = 1
		begin
		close bcEmplSeq
		deallocate bcEmplSeq
		end
	if @openEmplDetail = 1
		begin
		close bcEmplDetail
		deallocate bcEmplDetail
		end
	if @openAP = 1
		begin
		close bcAP
		deallocate bcAP
		end
   
	-- unlock Pay Period
	if @inuseby is null 	-- should be null prior to locking the Pay Period
		begin
		update dbo.bPRPC set InUseBy = null
		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
		end
   
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPRAPUpdate] TO [public]
GO
