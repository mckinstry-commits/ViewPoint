SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPBEditInit    Script Date: 8/28/99 9:34:01 AM ******/
CREATE          proc [dbo].[bspAPPBEditInit]
/****************************************************************************
* CREATED BY:   KF 10/21/97
* MODIFIED By : GG 04/30/99
*				kb 08/24/99 - per Fortney call when adding a trans in grid and part is on hold,
*							  check total in APPB not correct relating to APTB_Balance field not correct
*				GG 08/25/99 - added validation, removed PO/SL compliance check, removed 'D' option
*				kb 01/10/00 - #5865 - concerning cmaccounts in header vs trans where one might be null
*									  which is a valid situation.
*               EN 01/22/00 - expand dimension of @payname, @name & @pbname and include AddnlInfo in bAPPB initialization
*               kb 05/06/00 - #7000 -  added cmacct input
*               kb 05/16/00 - #7000 - rejection, added code so if the trans is added to
*									  payment batch in the grid and the cmacct for the trans is null
*									  it uses the cmacct from the payment header
*				GG 11/27/00 - changed datatype from bAPRef to bAPReference
*				kb 01/22/02 - #15845
*				MV 05/30/02 - #16956 - insert taxformcode and employee from APTH into APPB
*				kb 08/12/02 - #18261 - if adding from init at top of screen, wasn't initializing disctaken in APTB
*				MV 10/28/02 - #18037 - set pay address info
*				kb 10/28/02 - #18878 - fix double quotes
*				MV 02/18/04 - #18769 - Pay Category / #23061 isnull wrap
*				MV 01/15/07 - #122337 - add compliance checking for 'G' transactions entered through the grid.
*				MV 09/18/07 - #27759 - CMRef is OK for 'G' trans with ChkType = 'M' - Manual 
*				MV 02/27/08 - #127122 - For 'G' trans don't update disc to bAPTB, it happens in bspAPManualCheckProcess
*				MV 03/12/08 - #127347 - International addresses
*				MV 08/12/08	- #129351 - for 'G' update APTB with APTH.Description (form insert statement doesn't have description)
*				MV 09/10/08 - #128288 - update bAPDB with bAPTD.TotTaxAmount
*				MV 10/01/08 - #129429 - validate APPB country vs Transaction country separately.
*				DC 02/11/09 - #132186 - Add an APRef field in SL Compliance associated to AP Ref in Accounts payable
*				MV 07/01/09 - #134297 - For 'G' trans update disc to bAPTB if checktype = 'C', for manual it happens in bspManualCheckProcess
*				GP 06/28/10 - #135813 - Change bSL to varchar(30) 
*				TRL 07/27/11 - TK-07143 - Expand bPO parameters/varialbles to varchar(30)
*				EN 01/26/12 - TK-11583 - Modified to do special validation for Credit Service trans pay method
*										 using vspAPCOCreditServiceInfoCheck
*				KK 02/22/12 - TK-12462 - Added validation for PayMethods C and E with CSCMAcct to not allow trans into the batch
*				EN 04/25/2012 - TK-13965 - Use APVM address for Credit Service transactions				
*				KK 04/27/12	- B-09140 - Added back Add'l Info to address for CS
*				EN 5/2/2012 B-09241/TK-14618 Use default CM Acct to send to vspAPCOCreditServiceInfoCheck
*
*
* USAGE:
* Called from the AP Payment Posting/Edit Program to initialize a Payment Batch Sequence
* from a transaction, or add a transaction to an existing Payment Sequence.
*
*
*  INPUT PARAMETERS
*  @co             AP Company
*  @mth            Payment Month
*  @batchid        Batch Id
*  @batchseq       Payment Batch Sequence
*  @expmth         Transaction Expense Month
*  @aptrans        AP Transaction #
*  @mode           'A' = Add a Payment Batch Sequence Header and Detail based on a transaction
*                  'G' = add transaction to existing Payment Batch Sequence - called from grid
*
* OUTPUT PARAMETERS
*  @errmsg         error message
*
* RETURN VALUE
*   0              success
*   1              failure
****************************************************************************/
(@co bCompany = NULL, 
 @mth bMonth = NULL, 
 @batchid bBatchID = NULL, 
 @batchseq int = NULL,
 @expmth bMonth = NULL, 
 @aptrans bTrans = NULL, 
 @mode char(1) = NULL, 
 @sendcmacct bCMAcct = NULL,
 @errmsg varchar(255) OUTPUT)

AS
SET NOCOUNT ON

DECLARE @rcode int,						@retpaytype tinyint, 
		@openAPTD tinyint,				@apline smallint, 
		@apseq tinyint,					@paytype tinyint,
		@amount bDollar,				@disctaken bDollar, 
		@status tinyint,				@supplier bVendor, 
		@retg bDollar,					@prevpaid bDollar,
		@prevdisc bDollar,				@balance bDollar, 
		@disc bDollar,					@chktype char(1), 
		@firstsupplier tinyint,			@gross bDollar,
		@openamt bDollar,				@grossamt bDollar, 
		@paycategory int,			 	@DontAllowPaySL bYN, 
		@DontAllowPayPO bYN,			@po varchar(30), 
		@rc tinyint,					@POSLComply bYN, 
		@sl varchar(30),				@DontAllowPayAllinv bYN, 
		@AllInvComply bYN,				@linetype int, 
		@tottaxamount bDollar

-- APTH declares
DECLARE @vendorgroup bGroup,			@vendor bVendor, 
		@apref bAPReference,			@description bDesc, 
		@invdate bDate,					@paymethod char(1),
		@cmco bCompany,					@cmacct bCMAcct, 
		@prepaidyn bYN,					@prepaidprocyn bYN, 
		@payoverrideyn bYN,				@payname varchar(60),
		@payaddinfo varchar(60),		@payaddress varchar(60), 
		@paycity varchar(30),			@paystate varchar(4), 
		@payzip bZip,					@openyn bYN,
		@inusemth bMonth,				@inusebatchid bBatchID, 
		@inpaycontrol bYN,				@APTHaddendatypeid tinyint, 
		@taxformcode varchar (10), 		@employee bEmployee, 
		@addressseq tinyint,			@paycountry char(2)

-- APVM declares
DECLARE @name varchar(60),				@addnlinfo varchar(60), 
		@address varchar(60),			@city varchar(30), 
		@state varchar(4),				@zip bZip, 
		@VMaddendatypeid tinyint,		@country char(2)

-- APPB declares
DECLARE @pbcmco bCompany,				@pbcmacct bCMAcct, 
		@pbpaymethod char(1),			@pbcmref bCMRef, 
		@pbvendorgroup bGroup,			@pbvendor bVendor, 
		@pbname varchar(60),			@pbaddinfo varchar(60), 
		@pbaddress varchar(60),			@pbcity varchar(30), 
		@pbstate varchar(4),			@pbzip bZip, 
		@pbsupplier bVendor,			@APPBaddendatypeid tinyint, 
		@pbcountry char(2)

SELECT @rcode = 0, @POSLComply = 'Y' 

-- get Retainage Pay Type from AP Company
SELECT @retpaytype = RetPayType
FROM bAPCO WHERE APCo = @co

 -- get Transaction info
 SELECT	@vendorgroup = VendorGroup,		@vendor = Vendor,	
		@apref = APRef,					@description = [Description],	
		@invdate = InvDate,				@paymethod = PayMethod,
		@cmco = CMCo,					@cmacct = CMAcct,	
		@prepaidyn = PrePaidYN,			@prepaidprocyn = PrePaidProcYN,	
		@payoverrideyn = PayOverrideYN,	@payname = PayName, 
		@payaddinfo = PayAddInfo,		@payaddress = PayAddress,			
		@paycity = PayCity,				@paystate = PayState,			
		@payzip = PayZip,				@openyn = OpenYN, 
		@paycountry=PayCountry,			@inusemth = InUseMth,				
		@inusebatchid = InUseBatchId,	@inpaycontrol = InPayControl,	
		@addressseq=AddressSeq,			@APTHaddendatypeid = AddendaTypeId, 
		@taxformcode=TaxFormCode,		@employee=Employee, 
		@payoverrideyn=PayOverrideYN
FROM dbo.bAPTH
WHERE APCo = @co 
  AND Mth = @expmth
  AND APTrans = @aptrans
     
if @@rowcount = 0
begin
	select @errmsg = 'Invalid Mth: ' 
				   + isnull(convert(varchar(3),@expmth,1),'')
				   + isnull(substring(convert(varchar(8),@expmth,1),7,2),'')
				   + ' Trans#: ' + isnull(convert(varchar(8),@aptrans),''), 
		   @rcode = 1
    goto bspexit
end
if @inpaycontrol = 'Y'
begin
	select @errmsg = 'This transaction is currently in use by Payment Control.', @rcode = 1
    goto bspexit
end
if @openyn = 'N'
begin
    select @errmsg = 'This transaction has been fully paid and/or cleared.', @rcode = 1
    goto bspexit
end
if @prepaidyn = 'Y' and @prepaidprocyn = 'N'
begin
    select @errmsg = 'The prepaid portion of this transaction has not been processed.', @rcode = 1
    goto bspexit
end
if (@inusemth is not null and @inusemth <> @mth) and (@inusebatchid is not null and @inusebatchid <> @batchid)
begin
    select @errmsg = 'Currently in use. Mth: ' 
				   + isnull(convert(varchar(3),@inusemth,1),'')
 				   + isnull(substring(convert(varchar(8),@inusemth,1),7,2),'')
				   + ' Batch#: ' + isnull(convert(varchar(8),@inusebatchid),''),
		   @rcode = 1
    goto bspexit
end
 
-- get Vendor info
select @name = Name, 
	   @addnlinfo = AddnlInfo, 
	   @address = Address, 
	   @city = City, 
	   @state = State, 
	   @zip = Zip, 
	   @country= Country
from bAPVM
where VendorGroup = @vendorgroup and Vendor = @vendor
 
if @@rowcount = 0
begin
	select @errmsg = 'Missing Vendor: ' + isnull(convert(varchar(8), @vendor),''), @rcode = 1
    goto bspexit
end

--TK-13965 - when pay method is 'Credit Service' set Pay Address info from APVM and Pay Override flag to 'N'
IF @paymethod = 'S'
BEGIN
	SELECT  @payoverrideyn = 'Y',
			@payname = @name, 
			@payaddinfo = @addnlinfo, -- B-09140 Added
			@payaddress = @address,
			@paycity = @city, 
			@paystate = @state, 
			@payzip = @zip, 
			@paycountry = @country
END
 
-- set pay address info - #18037
if @payoverrideyn = 'N' and @addressseq is null  -- use Vendor defaults
begin
	select @payname = @name, 
		   @payaddinfo = @addnlinfo, 
		   @payaddress = @address,
 		   @paycity = @city, 
 		   @paystate = @state,  
 		   @payzip = @zip, 
 		   @paycountry = @country
end
if @payoverrideyn = 'N' and @addressseq is not null -- use address from bAPAA additional addresses
begin
	select @payaddinfo = Address2, 
		   @payaddress = Address,
 		   @paycity = City, 
 		   @paystate = State, 
 		   @payzip = Zip, 
 		   @paycountry=Country 
 	from bAPAA 
 	where VendorGroup = @vendorgroup and Vendor = @vendor and AddressSeq=@addressseq
 	if @@rowcount = 0
 	begin
 		select @errmsg = 'Missing Addtional Address Sequence: ' + isnull(convert(varchar(3), @addressseq),''), @rcode = 1
     	goto bspexit
    end
 	select @payname = @name	-- use APVM name
end
 
/*if @payoverrideyn = 'N'   -- use Vendor defaults
begin
	select @payname = @name, @payaddinfo = @addnlinfo, @payaddress = @address, @paycity = @city,
 		   @paystate = @state, @payzip = @zip
end*/
 
-- Adding a transaction to existing Payment Batch Header from AP Pay Edit grid
IF @mode = 'G'
BEGIN
	-- get info from AP Company
	SELECT @DontAllowPaySL = SLAllowPayYN, 
		   @DontAllowPayPO = POAllowPayYN,
		   @DontAllowPayAllinv=AllAllowPayYN
	FROM APCO WITH(NOLOCK) 
	WHERE APCo = @co
	BEGIN
		-- get Payment Batch Header info
		SELECT @pbcmco = CMCo, 
			   @pbcmacct = CMAcct, 
			   @pbpaymethod = PayMethod, 
			   @pbcmref = CMRef,
			   @chktype=ChkType, 
			   @pbvendorgroup = VendorGroup, 
			   @pbvendor = Vendor, 
			   @pbname = Name, 
			   @pbaddinfo = AddnlInfo,
			   @pbaddress = Address,
			   @pbcity = City, 
			   @pbstate = State, 
			   @pbzip = Zip, 
			   @pbsupplier = Supplier,
			   @pbcountry=Country
        FROM bAPPB
        WHERE Co = @co AND Mth = @mth AND BatchId = @batchid AND BatchSeq = @batchseq
		IF @@rowcount = 0
        BEGIN
			select @errmsg = 'Missing Payment Batch Header entry.', @rcode = 1
			goto bspexit
        END
		-- make sure transaction can be added to this Payment Sequence
		select @cmacct = isnull(@cmacct,@pbcmacct)
		if @cmco <> @pbcmco or (@cmacct <> @pbcmacct and @cmacct is not null and @pbcmacct is not null)
        begin
			select @errmsg = 'Payment Sequence and Transaction CM Co#/CM Account do not match.', @rcode = 1
			goto bspexit 
        end
		if @paymethod <> @pbpaymethod
        begin
			select @errmsg = 'Payment Sequence and Transaction payment method do not match.', @rcode = 1
			goto bspexit 
        end
		if @pbcmref is not null and @chktype <> 'M' 
        begin
			select @errmsg = 'Payment Sequence already has been assigned a CM Reference #.', @rcode = 1
			goto bspexit 
        end
		if @vendorgroup <> @pbvendorgroup 
		   OR @vendor <> @pbvendor 
		   OR isnull(@payname,'') <> isnull(@pbname,'')
		   OR isnull(@payaddinfo,'') <> isnull(@pbaddinfo,'') 
		   OR isnull(@payaddress,'') <> isnull(@pbaddress,'')
		   OR isnull(@paycity,'') <> isnull(@pbcity,'')
		   OR isnull(@paystate,'') <> isnull(@pbstate,'')
		   OR isnull(@payzip,'') <> isnull(@pbzip,'')
        begin
			select @errmsg = 'Payment Sequence and Transaction payment information does not match.', @rcode = 1
			goto bspexit 
        end
		if @paycountry is not null and @pbcountry is not null
		begin
			if isnull(@paycountry,'') <> isnull(@pbcountry,'')
			begin
				select @errmsg = 'Payment Sequence and Transaction payment country does not match.', @rcode = 1
				goto bspexit 
			end
		end

		-- make sure something is open
		select @apline = null, @apseq = null, @openamt = 0
		select @apline = min(APLine)
		from bAPTL where APCo = @co and Mth = @expmth and APTrans = @aptrans
		
		while @apline is not null
        begin
			-- check line level PO or SL compliance 
			select @linetype = LineType from bAPTL
			where APCo = @co and Mth = @expmth and APTrans = @aptrans and APLine=@apline
			if @linetype in (6,7) and @POSLComply = 'Y'
		 	begin
				exec @rc = bspAPComplyCheck @co, @mth, @aptrans, @apline, @invdate, @apref, @errmsg output  --DC #132186
  		   		if @rc <> 0	
				begin
					select @POSLComply = 'N'
					if (@linetype= 7 and @DontAllowPaySL = 'Y') or (@linetype=6 and @DontAllowPayPO = 'Y')
					begin
						select @errmsg = 'Warning: Transaction is out of compliance. '
						select @errmsg = @errmsg + 'Company setting to not add out of compliance transactions to payment batch will be overridden.',
						@rcode = 7
					end
				else
				begin
					select @errmsg = 'Warning: Transaction is out of compliance.',@rcode = 7
				end
			end
		end
		
		-- get first sequence for line
        select @apseq = min(APSeq) from bAPTD 
        where APCo = @co and Mth = @expmth 
						 and APTrans = @aptrans 
						 and APLine = @apline
        while @apseq is not null
        begin
			-- do not include if already in Payment Batch
            if not exists(select * from bAPDB 
						  where Co = @co and ExpMth = @expmth
										 and APTrans = @aptrans 
										 and APLine = @apline 
										 and APSeq = @apseq)
            begin
				select @openamt = @openamt + isnull(Amount,0) from bAPTD
                where APCo = @co 
				  and Mth = @expmth 
				  and APTrans = @aptrans
				  and APLine = @apline 
				  and APSeq = @apseq 
				  and Status = 1
				  and isnull(Supplier,0) = isnull(@pbsupplier,0) -- must be open and matching Supplier
            end
            select @apseq = min(APSeq) from bAPTD
            where APCo = @co 
              and Mth = @expmth 
              and APTrans = @aptrans 
              and APLine = @apline 
              and APSeq > @apseq
   		    if @@rowcount = 0 select @apseq = null
		end
        select @apline = min(APLine) from bAPTL
        where APCo = @co 
          and Mth = @expmth 
          and APTrans = @aptrans 
          and APLine > @apline
        if @@rowcount = 0 select @apline = null
	END
    -- make sure something is open
    if @openamt = 0
    begin
		select @errmsg = 'Nothing open on this transaction.', @rcode = 1
        goto bspexit
    end
 
    -- make sure Transaction has been added via Payment Edit grid
    select @gross = Gross, 
		   @retg = Retainage, 
		   @prevpaid = PrevPaid, 
		   @prevdisc = PrevDisc,
		   @balance = Balance, 
		   @disc = DiscTaken
    from bAPTB where Co = @co 
				 and Mth = @mth 
				 and BatchId = @batchid
				 and BatchSeq = @batchseq 
				 and ExpMth = @expmth 
				 and APTrans = @aptrans
    if @@rowcount = 0
    begin
		select @errmsg = 'Transaction does not exist on this Payment Batch Sequence.', @rcode = 1
        goto bspexit
    end
    if (@gross <> 0 or @retg <> 0 or @prevpaid <> 0 or @prevdisc <> 0 or @balance <> 0 or @disc <> 0) and @chktype <> 'M'
    begin
		select @errmsg = 'Payment Batch Transaction totals must be 0.00.', @rcode = 1
        goto bspexit
    end

	-- check compliance
	-- all invoice compliance 
 	select @AllInvComply = 'Y'	
 	exec @rc = bspAPComplyCheckAll @co, @vendorgroup, @vendor, @invdate, @AllInvComply output
	if @AllInvComply = 'N' 
	begin
		if @DontAllowPayAllinv = 'Y' 
		begin
			select @errmsg = 'Warning: Transaction is out of compliance. '
			select @errmsg = @errmsg + 'Company setting to not add out of compliance transactions to payment batch will be overridden.',
			@rcode = 7
		end
		else
		begin
			select @errmsg = 'Warning: Transaction is out of compliance.',@rcode = 7
		end
	end
		
				
    -- create a cursor to process all Lines and Detail for this Transaction
    declare bcAPTD cursor for
    select APLine, APSeq, PayType, Amount, DiscTaken, Status, Supplier, PayCategory, TotTaxAmount
    from bAPTD
    where APCo = @co and Mth = @expmth and APTrans = @aptrans
 
    open bcAPTD
    select @openAPTD = 1
 
    APTD_loop:     -- get next Line/Detail
    fetch next from bcAPTD into @apline, @apseq, @paytype, @amount, @disctaken,
 			 @status, @supplier, @paycategory, @tottaxamount
		if @@fetch_status <> 0 goto APTD_end
 
 
        select @retg = 0, @prevpaid = 0, @prevdisc = 0, @balance = 0, @disc = 0
 
        -- accumulate 'held' retainage
 		if (@paycategory is null and @paytype = @retpaytype and @status = 2) 
 			or (@paycategory is not null and @paytype = (select RetPayType from bAPPC with (nolock)
 										where APCo=@co and PayCategory=@paycategory) and @status = 2)
 		begin
 			select @retg = @amount
 		end
        /*if @paytype = @retpaytype and @status = 2 select @retg = @amount*/
 
        -- accumulate previous paid and discount taken
        if @status > 2 select @prevpaid = (@amount - @disctaken), @prevdisc = @disctaken
 
        -- if open or on hold but not retainage, assume as balance unless all restrictions are passed
 		if @status = 1 
 		or ((@status = 2 and @paycategory is null and @paytype <> @retpaytype)
 		or (@status = 2 and @paycategory is not null and @paytype <>
 		(select RetPayType from bAPPC with (nolock)where APCo=@co and PayCategory=@paycategory)))
 		begin
 			select @balance = @amount
 		end
        /*if @status = 1 or (@status = 2 and @paytype <> @retpaytype) select @balance = @amount*/
 
        if @status <> 1 goto PayTransUpdate     -- must be 'open'
 
        if isnull(@pbsupplier,0) <> isnull(@supplier,0) goto PayTransUpdate   -- skip if different Supplier
 
        -- make sure detail not already in Payment Batch - maybe under another Seq
        if exists(select * from bAPDB where Co = @co and Mth = @mth and BatchId = @batchid
           and ExpMth = @expmth and APTrans = @aptrans and APLine = @apline
           and APSeq = @apseq) goto PayTransUpdate
 
        select @balance = 0     -- will be included in payment, reset balance
 
        select @disc = @disctaken  -- take any discounts offered
 
        -- add Payment Detail entry
        insert bAPDB(Co, Mth, BatchId, BatchSeq, ExpMth, APTrans, APLine, APSeq,
             PayType, Amount, DiscTaken, PayCategory, TotTaxAmount)
        values (@co, @mth, @batchid, @batchseq, @expmth, @aptrans, @apline, @apseq,
             @paytype, @amount, @disc,@paycategory, @tottaxamount)
 
        PayTransUpdate:     -- update amounts in Payment Batch Transaction - trigger will update bAPPB
        select @grossamt = sum(Amount) from bAPTD where APCo = @co and Mth = @expmth
           and APTrans = @aptrans
        update bAPTB set Gross = @grossamt, Description=@description, DiscTaken = case @chktype when 'C' then (DiscTaken + @disc) else 0 end
        from bAPTB where Co = @co and Mth = @mth and BatchId = @batchid
           and BatchSeq = @batchseq and ExpMth = @expmth and APTrans = @aptrans
             /*update bAPTB set Gross = Gross + @amount, Retainage = Retainage + @retg,
                 PrevPaid = PrevPaid + @prevpaid, PrevDisc = PrevDisc + @prevdisc,
                 Balance = Balance + @balance, DiscTaken = DiscTaken + @disc
             where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
                 and ExpMth = @expmth and APTrans = @aptrans
             if @@rowcount <> 1
                 begin
                 select @errmsg = 'Unable to update Payment Batch Transaction.', @rcode = 1
                 goto bspexit
                 end*/
 
		goto APTD_loop
		
	APTD_end:
		close bcAPTD
        deallocate bcAPTD
        select @openAPTD = 0
		 
	end
END --End adding transaction from AP Pay Edit grid
   
-- Add Payment Batch Header
IF @mode = 'A'
BEGIN
	--apply default CM Acct as needed
	SELECT @cmacct = ISNULL(@cmacct,@sendcmacct)
	
	--CMAccount Validation for all Pay Methods
	EXEC	@rc = [dbo].[vspAPCOCreditServiceInfoCheck]
			@apco = @co,
			@cmco = @cmco,
			@cmacct = @cmacct,
			@vendorgrp = @vendorgroup,
			@vendor = @vendor,
			@paymethod = @paymethod,
			@msg = @errmsg OUTPUT
	IF @rc = 1 OR @cmacct IS NULL RETURN 1 --returns @errmsg
		
    -- make sure something is open before adding a Payment Batch Header entry
    select @apline = null, @apseq = null, @openamt = 0
    select @apline = min(APLine)
    from bAPTL where APCo = @co and Mth = @expmth and APTrans = @aptrans
    while @apline is not null
    begin
		select @apseq = min(APSeq)    -- get first sequence for line
		from bAPTD where APCo = @co and Mth = @expmth and APTrans = @aptrans and APLine = @apline
		while @apseq is not null
		begin
			-- do not include if already in Payment Batch
			if not exists(select * from bAPDB 
						  where Co = @co 
							and ExpMth = @expmth
							and APTrans = @aptrans 
							and APLine = @apline 
							and APSeq = @apseq)
			begin
				select @openamt = @openamt + isnull(Amount,0) from bAPTD
                where APCo = @co 
				  and Mth = @expmth 
				  and APTrans = @aptrans
				  and APLine = @apline 
				  and APSeq = @apseq 
				  and Status = 1  -- must be open
            end
            
            select @apseq = min(APSeq) from bAPTD
            where APCo = @co 
              and Mth = @expmth 
              and APTrans = @aptrans 
              and APLine = @apline 
              and APSeq > @apseq
     		if @@rowcount = 0 select @apseq = null
		end
        select @apline = min(APLine) from bAPTL
        where APCo = @co 
          and Mth = @expmth 
          and APTrans = @aptrans 
          and APLine > @apline
        if @@rowcount = 0 select @apline = null
	end
   
	if @openamt = 0
	begin
		select @errmsg = 'Nothing open on this transation.', @rcode = 1
		goto bspexit
	end
	
	select @chktype = null
	if @paymethod = 'C' select @chktype = 'C'
   
	select @firstsupplier = 0, @pbsupplier = null   -- initialize Supplier for Payment Batch Header
   
	-- add Payment Batch Header - 0.00 amount
	insert bAPPB(Co,			Mth,			BatchId, 
				 BatchSeq,		CMCo,			CMAcct, 
				 PayMethod,		ChkType,		VendorGroup,
				 Vendor,		Name,			AddnlInfo, 
				 Address,		City,			State, 
				 Zip,			Amount,			Supplier, 
				 VoidYN,		Overflow,		AddendaTypeId,
   				 TaxFormCode,	Employee,		PayOverrideYN, 
   				 AddressSeq,	Country)
		values (@co,			@mth,			@batchid, 
				@batchseq,		@cmco,			@cmacct, 
				@paymethod,		@chktype,		@vendorgroup,
				@vendor,		@payname,		@payaddinfo, 
				@payaddress,	@paycity,		@paystate, 
				@payzip,		0,				@pbsupplier, 
				'N',			'N',   			@APTHaddendatypeid, 
				@taxformcode,	@employee,		@payoverrideyn, 
				@addressseq,	@paycountry)
   
	select @grossamt = sum(Amount), @disctaken = sum(DiscTaken) from bAPTD 
	where APCo = @co and Mth = @expmth and APTrans = @aptrans
	-- add Payment Transaction entry - intialize amounts as 0.00
	insert bAPTB(Co,			Mth,			BatchId, 
				 BatchSeq,		ExpMth,			APTrans, 
				 APRef,			Description,	InvDate,
				 Gross,			Retainage,		PrevPaid, 
				 PrevDisc,		Balance,		DiscTaken)
		values (@co,			@mth,			@batchid, 
				@batchseq,		@expmth,		@aptrans,	
				@apref,			@description,	@invdate,
				@grossamt,		0,				0,
				0,				0,				@disctaken)
   
	-- create a cursor to process all Lines and Detail for this Transaction
	declare bcAPTD cursor for
	select APLine, APSeq, PayType, Amount, DiscTaken, Status, Supplier, PayCategory, TotTaxAmount 
	from bAPTD
	where APCo = @co and Mth = @expmth and APTrans = @aptrans
   
	open bcAPTD
	select @openAPTD = 1
   
	APTD_loop1:     -- get next Line/Detail
	fetch next from bcAPTD into @apline, @apseq, @paytype, @amount, @disctaken, @status, @supplier,
								@paycategory, @tottaxamount
	if @@fetch_status <> 0 goto APTD_end1
   
	select @retg = 0, @prevpaid = 0, @prevdisc = 0, @balance = 0, @disc = 0
   
	-- accumulate 'held' retainage
	if (@paycategory is null and @paytype = @retpaytype and @status = 2) 
   		OR (@paycategory is not null and @paytype = (select RetPayType from bAPPC with (nolock)
   													 where APCo=@co and PayCategory=@paycategory) 
   			and @status = 2)
	begin
		select @retg = @amount
	end
	
	/*if @paytype = @retpaytype and @status = 2 select @retg = @amount*/
	-- accumulate previous paid and discount taken
	if @status > 2 select @prevpaid = (@amount - @disctaken), @prevdisc = @disctaken
   
	-- if open or on hold but not retainage, assume as balance unless all restrictions are passed
	if @status = 1 
   	   OR ((@status = 2 and @paycategory is null and @paytype <> @retpaytype)
   		    OR (@status = 2 and @paycategory is not null and @paytype <> (select RetPayType from bAPPC with (nolock)
   																		  where APCo=@co and PayCategory=@paycategory)))
   	begin
   		select @balance = @amount
   	end
	/*if @status = 1 or (@status = 2 and @paytype <> @retpaytype) select @balance = @amount*/
   
	if @status <> 1 goto PayTransUpdate1     -- must be 'open'
   
	if @firstsupplier <> 0 and isnull(@pbsupplier,0) <> isnull(@supplier,0) goto PayTransUpdate1   -- skip if different Supplier
   
	-- make sure detail not already in Payment Batch - maybe under another Seq
	if exists(select * from bAPDB where Co = @co and Mth = @mth and BatchId = @batchid
               and ExpMth = @expmth and APTrans = @aptrans and APLine = @apline
               and APSeq = @apseq) goto PayTransUpdate1
   
	select @balance = 0     -- will be included in payment, reset balance
   
	select @disc = @disctaken   -- take any discounts offered
   
	if @firstsupplier = 0
	begin
		-- update 1st supplier to Payment Header
		update bAPPB set Supplier = @supplier
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
   
        select @firstsupplier = 1, @pbsupplier = @supplier -- save 1st supplier
	end
   
	-- add Payment Detail entry
	insert bAPDB (Co,				Mth,			BatchId, 
				  BatchSeq,			ExpMth,			APTrans, 
				  APLine,			APSeq,          PayType, 
				  Amount,			DiscTaken,		PayCategory, 
				  TotTaxAmount)
		  values (@co,				@mth,			@batchid, 
				  @batchseq,		@expmth,		@aptrans, 
				  @apline,			@apseq,			@paytype, 
				  @amount,			@disc,			@paycategory, 
				  @tottaxamount)
   
	PayTransUpdate1:     -- update amounts in Payment Batch Transaction - trigger will update bAPPB
	/*update bAPTB set Gross = Gross + @amount, Retainage = Retainage + @retg,
	PrevPaid = PrevPaid + @prevpaid, PrevDisc = PrevDisc + @prevdisc,
	Balance = Balance + @balance, DiscTaken = DiscTaken + @disc
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
	and ExpMth = @expmth and APTrans = @aptrans
	if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to update Payment Batch Transaction.', @rcode = 1
	goto bspexit
	end*/
   
	goto APTD_loop1
   
	APTD_end1:
	close bcAPTD
	deallocate bcAPTD
	select @openAPTD = 0
end
   
bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPPBEditInit] TO [public]
GO
