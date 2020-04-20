SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************************************/
CREATE      proc [dbo].[bspAPIntercoInvInit]
/***********************************************************
* CREATED:		GG	08/10/2001
* MODIFIED:		GG	11/12/2001	- #15244 - pull Vendor Group based on current AP Co#
*				DANF 09/05/2002 - 17738 - Added Phase group to bspJCCAGlacctDflt
*				MV	02/11/2004	- #18769 - Get PayTypes from Pay Category 
*				ES	03/11/2004	- #23061 wrap isnull
*				GF	07/07/2008	- issue #128290 MS International tax enhancement
*				MV	10/06/2008	- #129923 - International dates - if begin end dates are empty strings make them null
*				CHS	04/20/2012	- TK-14210 added paymethod credit service.
*
* USAGE:
*  Called from the AP Intercompany Invoice processing form to add
*     or remove entries from an AP Entry batch
*
*  INPUT PARAMETERS
*   @co            AP Co#
*   @mth           Batch Month
*   @batchid       Batch ID#
*   @msco			MS Co# - restrict to invoices posted from this MS Co#
*   @xsoldtoco		Sold To Co# - restrict to these JC and IN Co#s, if null include all
*   @begininvdate	Beginning Invoice Date - used when adding invoices
*   @endinvdate	Ending Invoice Date - used when adding invoices
*   @mode			Mode - 'A' add, 'D' delete
*   @begininv      Beginning MS Invoice - used when deleting invoices
*   @endinv        Ending MS Invoice - used when deleting invoices
*
* OUTPUT PARAMETERS
*   @msg           message
*
* RETURN VALUE
*   @rcode        0 = success, 1 = error
*****************************************************/
(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @msco bCompany = null,
 @xsoldtoco bCompany = null, @begininvdate bDate = null, @endinvdate bDate = null, @mode char(1) = null,
 @begininv varchar(10) = null, @endinv varchar(10) = null, @msg varchar(255) output)
as
set nocount on
   
declare @rcode int, @numrows int,  @exppaytype tinyint, @jobpaytype tinyint, @cmco bCompany, @cmacct bCMAcct,
   	@openMSII tinyint, @msinv varchar(10), @soldtoco bCompany, @vendorgroup bGroup, @vendor bVendor,
   	@description bDesc, @invdate bDate, @duedate bDate, @v1099yn bYN, @v1099type varchar(10), @v1099box tinyint,
   	@seq int, @openMSIX tinyint, @apseq smallint, @saletype char(1), @jcco bCompany, @job bJob, @phasegroup bGroup,
   	@phase bPhase, @jcctype bJCCType, @inco bCompany, @toloc bLoc, @matlgroup bGroup, @material bMatl, @um bUM,
   	@matlunits bUnits, @unitprice bUnitCost, @ecm bECM, @matltotal bDollar, @haultotal bDollar, @taxgroup bGroup,
   	@taxcode bTaxCode, @taxbasis bDollar, @taxtotal bDollar,  @glco bCompany, @glacct bGLAcct,
   	@burunitcost bUnitCost, @becm bECM, @linetype tinyint, @paytype tinyint, @paymethod char(1), @rc int,
   	@burdenyn bYN , @eft char(1), @errmsg varchar(60), @override char(1), @usingpaycategoryyn bYN,
	@paycategory int, @valueadd varchar(1), @taxtype tinyint, 
	@SeparatePayInvYN bYN, @VendorPaymethod char(1), @ApcoCsCmAcct bCMAcct -- CHS TK-14210
   
   select @rcode = 0, @numrows = 0

	if @begininvdate = '' select @begininvdate = null
	if @endinvdate = '' select @endinvdate = null
   
   if @co is null or @mth is null or @batchid is null
       begin
       select @msg = 'Missing AP Co#, Month, and/or BatchID#!', @rcode = 1
       goto bspexit
       end
   if @msco is null
   	begin
   	select @msg = 'Missing MS Co#!', @rcode = 1
   	goto bspexit
   	end
   if @mode not in ('A','D')
       begin
       select @msg = 'Invalid processing option, must be ''A'' or ''D''!', @rcode = 1
       goto bspexit
       end
   
   if @mode = 'D'	-- delete intercompany invoices from the batch
       begin
    	-- delete batch lines - triggers will unlock MS intercompany invoice entries in bMSII and bMSIX
    	delete bAPLB
       from bAPLB l
       join bAPHB h on h.Co = l.Co and h.Mth = l.Mth and h.BatchId = l.BatchId and h.BatchSeq = l.BatchSeq
       where h.Co = @co and h.Mth = @mth and h.BatchId = @batchid
       	and h.MSCo = @msco and h.MSInv >= isnull(@begininv,'') and h.MSInv <= isnull(@endinv,'~~~~~~~~~~')
       -- delete batch headers
    	delete bAPHB
       where Co = @co and Mth = @mth and BatchId = @batchid
   		and MSCo = @msco and MSInv >= isnull(@begininv,'') and MSInv <= isnull(@endinv,'~~~~~~~~~~')
   
    	select @numrows = @@rowcount   -- # of transactions deleted
   	if @numrows = 0
   		select @msg = 'No Intercompany Invoices were removed from the batch.'
   	else 
   		select @msg = 'Successfully removed ' + isnull(convert(varchar(8),@numrows), '')
   			+ ' Intercompany Invoices from the current batch.'
    			+ char(13) + ' These invoices will be available for posting at another time.' --#23061
   	goto bspexit
    	end
   
   if @mode = 'A'    -- add intercompany invoices to the batch
   	begin
   	-- get AP Company default info
   	select @exppaytype = ExpPayType, @jobpaytype = JobPayType, @cmco = CMCo, @cmacct = CMAcct,
   		@usingpaycategoryyn = PayCategoryYN, @paycategory = PayCategory, @ApcoCsCmAcct = CSCMAcct
   	from bAPCO
   	where APCo = @co
   	if @@rowcount = 0
   		begin
   		select @msg = 'Invalid AP Co#!', @rcode = 1
   		goto bspexit
   		end
   	-- If using Pay Category, get PayTypes from PayCategory
   	if @usingpaycategoryyn = 'Y' and @paycategory is not null
   		begin
   		select @exppaytype = ExpPayType, @jobpaytype = JobPayType
   				from bAPPC where PayCategory = @paycategory
   		if @@rowcount=0
   			begin
   			select @msg = 'Invalid Pay Category!', @rcode = 1
   			goto bspexit
   			end
   		end
   	-- get AP Company Vendor Group - intercompany vendors must be valid in multiple groups
   	select @vendorgroup = VendorGroup
   	from bHQCO where HQCo = @co
   	if @@rowcount = 0
   		begin
   		select @msg = 'Invalid HQ Co#!', @rcode = 1
   		goto bspexit
   		end
    	-- create a cursor on intercompany invoices eligible for posting
    	declare bcMSII cursor for
    	select MSInv, SoldToCo, Vendor, Description, InvDate, DueDate
    	from bMSII
       where MSCo = @msco and SoldToCo = isnull(@xsoldtoco,SoldToCo) and Mth = @mth
   		and InvDate > = isnull(@begininvdate,InvDate) and InvDate <= isnull(@endinvdate,InvDate)
   		and InUseAPCo is null and InUseBatchId is null
       order by MSInv
   
    	-- open cursor
    	open bcMSII
    	select @openMSII = 1
   
    	next_MSII:
   		fetch next from bcMSII into @msinv, @soldtoco, @vendor, @description,
   			@invdate, @duedate
    
           if @@fetch_status <> 0 goto end_MSII
   
   		-- get Vendor info
   		select @v1099yn = V1099YN, @v1099type = V1099Type, @v1099box = V1099Box, @eft = EFT, 
   			@SeparatePayInvYN = SeparatePayInvYN, @VendorPaymethod = PayMethod	-- CHS TK-14210
   		from bAPVM
   		where VendorGroup = @vendorgroup and Vendor = @vendor
   		if @@rowcount = 0 
   			begin
   			select @msg = 'Invalid Vendor#!', @rcode = 1
   			goto bspexit
   			end
   	  		
   			-- CHS TK-14210
			IF @VendorPaymethod = 'S'
				BEGIN
				SELECT @paymethod='S', @SeparatePayInvYN = 'N', @cmacct = @ApcoCsCmAcct
				END

     		ELSE IF @eft='A'
				BEGIN
				SELECT @paymethod='E'
				END
				
			ELSE
				BEGIN
				SELECT @paymethod='C'
				END
   
           -- get next available batch seq#
   		select @seq = isnull(max(BatchSeq),0) + 1
           from bAPHB
           where Co = @co and Mth = @mth and BatchId = @batchid
   
    		begin transaction
   
           -- add batch header - insert trigger will lock bMSII
    		insert bAPHB (Co, Mth, BatchId, BatchSeq, BatchTransType, VendorGroup, Vendor, APRef, 
   			Description, InvDate, DueDate, InvTotal, PayMethod, CMCo, CMAcct,
    			PrePaidYN, V1099YN, V1099Type, V1099Box, PayOverrideYN, MSCo, MSInv)
           values(@co, @mth, @batchid, @seq, 'A', @vendorgroup, @vendor, @msinv,
   			@description, @invdate, @duedate, 0, @paymethod, @cmco, @cmacct,
               'N', @v1099yn, @v1099type, @v1099box, 'N', @msco, @msinv)
   		if @@rowcount <> 1 
   			begin
   			select @msg = 'Unable to add Invoice Header to Batch!', @rcode = 1
   			goto error_MSII
   			end
   
   		-- create a cursor to process invoice lines
   		declare bcMSIX cursor for
   		select APSeq, SaleType, JCCo, Job, PhaseGroup, Phase, JCCType, INCo, ToLoc,
   			MatlGroup, Material, UM, MatlUnits, UnitPrice, ECM, MatlTotal, HaulTotal,
   			TaxGroup, TaxCode, TaxBasis, TaxTotal
   		from bMSIX
   		where MSCo = @msco and MSInv = @msinv
   
   		-- open cursor
    		open bcMSIX
    		select @openMSIX = 1
   
   		next_MSIX:
   			fetch next from bcMSIX into @apseq, @saletype, @jcco, @job, @phasegroup, @phase,
   				@jcctype, @inco, @toloc, @matlgroup, @material, @um, @matlunits, @unitprice,
   				@ecm, @matltotal, @haultotal, @taxgroup, @taxcode, @taxbasis, @taxtotal
   
   			if @@fetch_status <> 0 goto end_MSIX
   
   			-- get Material description
   			select @description = null
   			select @description = Description
   			from bHQMT where MatlGroup = @matlgroup and Material = @material
   			select @glco = null, @glacct = null, @burunitcost = @unitprice, @becm = @ecm

			---- get value add flag from HQTX for tax code #128290
			set @valueadd = 'N'
			set @taxtype = 1
			if isnull(@taxcode,'') <> ''
				begin
				select @valueadd = ValueAdd
				from bHQTX with (nolock) where TaxGroup=@taxgroup and TaxCode=@taxcode
				if @@rowcount = 0 set @valueadd = 'N'
				---- if valueadd flag is 'Y' then tax type = 3 else 1
				if isnull(@valueadd,'N') = 'Y' set @taxtype = 3
				end

   			
			---- job sales
   			if @saletype = 'J'
   				begin
   				select @linetype = 1, @paytype = @jobpaytype
   				-- get GL Co# from JC
   				select @glco = GLCo
   				from bJCCO where JCCo = @jcco
   				if @glco is null select @glco = @jcco	
   				-- get GL Expense Account				
   				exec @rc = bspJCCAGlacctDflt @jcco, @job, @phasegroup, @phase, @jcctype, 'N', @glacct output, @errmsg output
   				if @glacct is null select @glacct = ''	-- if invalid use an empty value, will be validated later
   				end
   
   			if @saletype = 'I'	-- Inventory sales
   				begin
   				select @linetype = 2, @paytype = @exppaytype
   				-- get info from IN Company
   				select @glco = GLCo, @burdenyn = BurdenCost
   				from bINCO where INCo = @inco
   				if @glco is null select @glco = @inco
   				-- get GL Inventory Account
   				exec @rc = bspINGlacctDflt @inco, @toloc, @material, @matlgroup, @glacct output, @override output, @errmsg output
   				if @glacct is null select @glacct = ''	-- if invalid use an empty value, will be validated later
   				-- Burden unit cost
   				if @burdenyn = 'Y' and @matlunits <> 0
   					begin
   					select @burunitcost = (@matltotal + @haultotal + @taxtotal) / @matlunits
   					select @becm = 'E'
   					end
   				end
   
           	-- insert batch lines 
           	insert bAPLB (Co, Mth, BatchId, BatchSeq, APLine, BatchTransType, LineType,
					JCCo, Job, PhaseGroup, Phase, JCCType, INCo, Loc,
					MatlGroup, Material, GLCo, GLAcct, Description, UM, Units,
					UnitCost, ECM, PayType, GrossAmt, MiscAmt, MiscYN, TaxGroup,
					TaxCode, TaxType, TaxBasis, TaxAmt, Retainage, Discount, BurUnitCost, BECM, SMChange)
           	values(@co, @mth, @batchid, @seq, @apseq, 'A', @linetype,
					@jcco, @job, @phasegroup, @phase, @jcctype, @inco, @toloc, 
					@matlgroup, @material, @glco, @glacct, @description, @um, @matlunits,
					@unitprice, @ecm, @paytype, @matltotal, @haultotal, 'Y', @taxgroup,
					@taxcode, @taxtype, @taxbasis, @taxtotal, 0, 0, @burunitcost, @becm, 0)
   			if @@rowcount <> 1
   				begin
   				select @msg = 'Unable to add Invoice Line to Batch!', @rcode = 1
   				goto error_MSII
   				end
   
   			-- update Invoice Total in Header
   			update bAPHB
   			set InvTotal = InvTotal + (@matltotal + @haultotal + @taxtotal)
   			where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   			if @@rowcount <> 1
   				begin
   				select @msg = 'Unable to update Invoice Total in Batch Header!', @rcode = 1
   				goto error_MSII
   				end
               goto next_MSIX
   
   		end_MSIX:
   			commit transaction  -- header and all lines added
   
   			close bcMSIX
   			deallocate bcMSIX
   			select @openMSIX = 0
   
    			select @numrows = @numrows + 1 -- # of invoices added to batch
   
               goto next_MSII  -- next intercompany invoice
   
           error_MSII: -- handle error during transaction
               if @@trancount > 0 rollback transaction
   			goto bspexit
   
           end_MSII:   -- finished with intercompany invoices
               close bcMSII
               deallocate bcMSII
               select @openMSII = 0
   			if @numrows = 0
   				select @msg = 'No Intercompany Invoices were added to the batch.'
   			else
   				select @msg = 'Successfully added ' 
   					+ isnull(convert(varchar(8),@numrows), '')
   					+ ' Intercompany Invoices to the current batch.' --#23061
   		end
   
   bspexit:
       if @openMSIX = 1
    		begin
    		close bcMSIX
     		deallocate bcMSIX
    		end
       if @openMSII = 1
           begin
           close bcMSII
           deallocate bcMSII
           end 
   
   	if @rcode <> 0 select @msg = @msg + char(13) + char(10) + '[bspAPIntercoInvInit]'
    	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspAPIntercoInvInit] TO [public]
GO
