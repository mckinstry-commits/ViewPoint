SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPBInitialize    Script Date: 8/28/99 9:34:02 AM ******/
CREATE proc [dbo].[bspAPPBInitialize]
/***********************************************************
* CREATED BY:   kb 10/21/97
* MODIFIED By:  GG 06/24/99
*       GG 11/12/99 - added check to compare bAPTB with bAPDB (Fortney problem)
*       kb 12/22/99 - if you had a transaction that was split out with part having a supplier
*                     and you had already added part of it to the batch and then wanted
*                     to run the initialize program to bring in the rest it couldnt find it
*                     because it was not adding those that were in use in a batch. Issue #4810.
*       EN 01/22/00 - expand dimension of @payname & @name and include AddnlInfo in initialization
*       kb 05/02/00 - this is a fix to the fix I made on 12/22 for issue #4810 and is
*                     written up in issue #6901. Problem was that transactions were getting
*                     initialized twice when re-initialize for same data. Added check to
*                     skip an AP Trans/Line/Seq if exists in APDB.
*       GG 05/10/00 - added @transcount output parameter
*       kb 05/06/00 - #7000, added cmacct input
*	    GH 08/02/00 - #9939 added a check against @alldisc
*       kb 08/28/00 - #10173 handling the use discdate instead of duedate wrong
*       kb 09/12/00 - #10508 re cancelifdiscdate and alldisc
*       GG 11/27/00 - changed datatype from bAPRef to bAPReference
*       kb 07/25/01 - #13736
*       MV 09/07/01 - #10997 - EFT addenda records
*       kb 09/12/01 - #14314
*       MV 09/28/01 - #10997 - redid AddendaTypeId coding
*       MV 10/08/01 - #10997 - create a payment for each diff tax payment to the IRS
*                                    or each employee to the same State
*       kb 10/22/01 - #14160
*       kb 10/22/01 - #15028 - separate pay per job
*	    mv 12/04/01 - #15489 - 
*       kb 01/22/02 - #15845
*		MV 10/28/02 - #18037 set pay address info
*		MV 10/28/02 - #18878 quoted identifier cleanup.
*		MV 12/03/02 - #18897 - Add conditions when DiscDate is compared to @sendduedate. 
*		MV 01/08/03 - #18897 - rej 1 fix
*		MV 01/14/03 - #17821 - all invoice compliance 
*	    mv 02/20/03 - #18037 - rej 2 fix 
*		mv 03/27/03 - #20845 - don't add trans if no detail open to pay 
*		MV 11/06/03 - #22959 - cancelifdiscdate >= discdate
* 		MV 11/17/03 - #22814 - include if discount is negative senddiscdate = 'Y' and d.DiscTaken <> 0
*		MV 02/18/04 - #23664 - if @disconly=Y include all detail for a line if any detail
*								in the line has a discount
*		MV 02/18/04 - #18769 - Pay Category 
*		MV 02/25/04 - #23889 - get linetype so PO and SL compliance checking happens / performance enhancements
*		ES 03/11/04 - #23061 - isnull wrapping
*		MV 04/14/04 - #24333 - don't open detail cursor if already open
*		MV 04/15/04 - #24360 - correct paytype isnull wrap
*		MV 03/03/05 - #27168 - corrected count and transcount
*		MV 03/09/05 - #27168 - reduce APDB transcount when negative or 0 amounts removed
*		MV 02/15/08 - #127103 - if @sendjob comes in as '' make it null
*		MV 03/12/08 - #127347 - International addresses
*		MV 09/10/08 - #128288 - update bAPDB with TotTaxAmount from bAPTD
*		MV 09/29/08 - #129923 - null out dates passed from form if they are empty strings.
*		MV 10/29/08	- #127687 - and (@cancelifdiscdate is null or @cancelifdiscdate **<=** isnull(h.DiscDate,''))
*		MV 02/03/09 - #122906 - exclude vendors with a credit balance
*		DC 02/11/09 - #132186 - Add an APRef field in SL Compliance associated to AP Ref in Accounts payable
*		MV 07/20/09 - #134851 - tweaked @separatesubyn = 'Y' for select from bAPPB
*		MV 09/28/09 - #135689 - isnull wrapped SL for separatesubyn test in line check
*		GP 06/28/10 - #135813 - change bSL to varchar(30) 
*		MV 10/14/10 - #139461 - tweaked Job and JobCo for separatejobyn test in line check
*	   TRL 07/27/11 - TK-07143 - Expand bPO parameters/varialbles to varchar(30)
*		EN 01/20/12 - TK-11583 - Add Credit Service to potential pay methods ... to achieve this I replaced the
*								@sendpaymethod input param with separate params to specify which pay methods
*								to include because any combination of 2 or 3 pay methods is now acceptable
*								... also modified to default cscmacct for Credit Service transactions
*								... also modified to do special validation for Credit Service trans pay method
*									using vspAPCOCreditServiceInfoCheck
*								... also ensure that Credit Service trans are processed with SeparatePayYN = 'N'
*		KK 02/09/12 - TK-12462 - Added validation for PayMethods C and E with CSCMAcct to not allow trans into the batch
*		EN 03/13/12 - TK-12973 - force Credit Service transactions for a vendor into a single pay seq
*		KK 04/20/12 - B-09140 - Allow Credit Service transactions to default address info from APVM into Payment Processing
*
*
* USAGE:
* Called by the AP Payment Initialization form to create new payment
* batch entries.  Finds all 'open' transactions meeting the restrictions
* passed to this procedure.
*
* A transaction may exist on more than one payment within a batch.  If a
* transaction is posted to multiple Suppliers or Subcontracts, each 'open'
* portion may be included on a separate payment.
*
*  INPUT PARAMETERS
*  @co                 AP Company
*  @mth                Batch Month - payment month
*  @batchid            BatchId
*  @sendcmco           CM Co# - if null, all CM Companies
*  @sendcmacct         CM Account - if null, all CM Accounts
*  @sendvendor         Vendor - if null, all Vendors
*  @sendpaycontrol     Payment Control - if null, all Payment Control codes
*  @sendpaytype        Payable Types - string of comma separated Pay Types - if null, all
*  @includecheckpayments	'Y' = include check payments
*  @includeeftpayments		'Y' = include eft payments
*  @includecreditservicepayments	'Y' = include credit service payments
*  @sendduedate        Due Date - include trans due as of this date
*  @senddiscdate       'Y' = if available, use Discount Date, 'N' = use due date
*  @disconly           'Y' = dicounted trans only, 'N' = all trans
*  @alldisc            'Y' = take all discounts, 'N' = cancel if past discount date (not used?????)
*  @cancelifdiscdate   Cancel if Discount Date is prior to this date - take all discounts if null
*  @separatesub        'Y' = separate payment per Subcontract, 'N' = consolidate
*  @sendvendorgroup    Vendor Group - qualifies Vendor
*  @sendjcco           JC Co# - if null, all JC Companies
*  @sendjob            Job - if null, all jobs
*
* OUTPUT PARAMETERS
*  @count              # of payments added to the batch
*  @transcount         # of transactions added to payment batch
*  @msg                error message if error occurs
*
* RETURN VALUE
*  0                   success
*  1                   failure
************************************************************/       
(@co bCompany, 
 @mth bMonth, 
 @batchid bBatchID, 
 @sendcmco bCompany = NULL, 
 @sendcmacct bCMAcct = NULL,
 @sendvendor bVendor = NULL, 
 @sendpaycontrol varchar(10) = NULL, 
 @sendpaytype varchar(200) = NULL,
 @includecheckpayments char(1) = NULL,
 @includeeftpayments char(1) = NULL,
 @includecreditservicepayments char(1) = NULL,
 @sendduedate bDate = NULL, 
 @senddiscdate bYN = NULL, 
 @disconly bYN = NULL,
 @alldisc bYN = NULL, 
 @cancelifdiscdate bDate = NULL, 
 @separatesubyn bYN = NULL, 
 @sendvendorgroup bGroup = NULL,
 @sendjcco bCompany = NULL, 
 @sendjob bJob = NULL, 
 @dfltcmacct bCMAcct,
 @separatejobyn bYN = NULL, 
 @count int OUTPUT, 
 @transcount int OUTPUT, 
 @excludevendorcreditYN bYN = 'N',
 @msg varchar(255) OUTPUT)
 
AS
SET NOCOUNT ON
   
DECLARE @retpaytype tinyint,		@netamtopt bYN,				@slallowpay bYN,			
		@poallowpay bYN,			@openTransCheck tinyint,	@expmth bMonth,
		@aptrans bTrans,			@vendorgroup bGroup,		@vendor bVendor, 
		@apref bAPReference,		@description bDesc,			@invdate bDate,
		@discdate bDate,			@paymethod char(1),			@cmco bCompany, 
		@cmacct bCMAcct,			@payoverrideyn bYN,			@payname varchar(60),
		@payaddinfo varchar(60),	@payaddress varchar(60),	@paycity varchar(30),
		@paystate varchar(4),		@payzip bZip,				@paycountry char(2),
		@savesl varchar(30),		@lastvendor bVendor,		@name varchar(60),
		@addnlinfo varchar(60),		@address varchar(60),		@city varchar(30),
		@state varchar(4),			@zip bZip,					@country char(2),
		@openLineCheck tinyint,		@detail bYN,				@apline smallint,
		@linetype tinyint,			@po varchar(30),			@jcco bCompany,
		@job bJob,@rc int,			@openDetailCheck tinyint,	@paytype tinyint,
		@disctaken bDollar,			@duedate bDate,				@savesupplier bVendor,
		@lastsl varchar(30),		@batchseq int,				@chktype char(1),
		@openAddDetail tinyint,		@sl varchar(30),			@apseq tinyint,
		@amount bDollar,			@status tinyint,			@supplier bVendor,
		@retg bDollar,				@prevpaid bDollar,			@prevdisc bDollar,
		@balance bDollar,			@disc bDollar,				@paysum bDollar,
		@sortname varchar(15),		@dbtotal bDollar,			@tbtotal bDollar,
		@APTHaddendatypeid tinyint,	@APPBaddendatypeid tinyint,	@taxformcode varchar (10),
		@employee bEmployee,		@separatepayyn bYN,			@apdbline smallint,
		@apdbseq tinyint,			@grossamt bDollar,			@aptdtotal bDollar,
		@addressseq tinyint,		@allallowpay bYN,			@allinvcomplied bYN,
		@paycategory int,			@tottaxamount bDollar,		@cscmacct bCMAcct
   
SELECT	@count = 0, 
		@transcount = 0, 
		@openAddDetail = 0, 
		@aptdtotal = 0 
   
IF @sendcmacct IS NULL		SELECT @sendcmco = NULL
IF @sendvendor IS NULL		SELECT @sendvendorgroup = NULL
IF @separatesubyn IS NULL	SELECT @separatesubyn  = 'N'
IF @separatejobyn IS NULL	SELECT @separatejobyn  = 'N'
IF @sendjob = ''			SELECT @sendjob = NULL
IF @sendduedate =''			SELECT @sendduedate = NULL
IF @cancelifdiscdate = ''	SELECT @cancelifdiscdate = NULL
   
-- get info from AP Company
SELECT	@retpaytype = RetPayType, 
		@netamtopt = NetAmtOpt, 
		@slallowpay = SLAllowPayYN, 
		@poallowpay = POAllowPayYN,
		@allallowpay = AllAllowPayYN,
		@cscmacct = CSCMAcct
FROM dbo.APCO 
WHERE APCo = @co

IF @@ROWCOUNT = 0
BEGIN
	SELECT @msg = 'Invalid AP Company!'
	RETURN 1
END
  
--determine if ALL pay methods are to be included
DECLARE @IncludeAllPayments bYN

IF @includecheckpayments = 'N' AND @includeeftpayments = 'N' AND @includecreditservicepayments = 'N'
BEGIN
	SELECT @IncludeAllPayments = 'Y'
END
ELSE
BEGIN
	SELECT @IncludeAllPayments = 'N'
END
	
-- create a cursor on 'open' Transactions matching criteria passed to this procedure
DECLARE bcTransCheck CURSOR LOCAL FAST_FORWARD FOR
  
--this is the new one below
SELECT DISTINCT h.Mth,				h.APTrans,		h.VendorGroup,		h.Vendor,
				v.SortName,			h.APRef,		h.[Description],	h.InvDate, 
				h.DiscDate,			h.PayMethod,	h.CMCo,				h.CMAcct, 
				h.PayOverrideYN,	h.PayName,		h.PayAddInfo,		h.PayAddress, 
				h.PayCity,			h.PayState,		h.PayZip,			d.Supplier, 
				h.AddendaTypeId,	h.TaxFormCode,	h.Employee,			h.SeparatePayYN, 
				h.AddressSeq,		h.PayCountry
FROM dbo.bAPTH h WITH (NOLOCK)
JOIN dbo.bAPVM v WITH (NOLOCK) ON	v.VendorGroup = h.VendorGroup AND 
									v.Vendor = h.Vendor
JOIN dbo.bAPTD d WITH (NOLOCK) ON	d.APCo = h.APCo AND 
									d.Mth = h.Mth AND 
									d.APTrans = h.APTrans
WHERE	h.APCo = @co 
		AND h.VendorGroup = ISNULL(@sendvendorgroup, h.VendorGroup)
		AND h.Vendor = ISNULL(@sendvendor, h.Vendor)
		AND ISNULL(h.CMAcct,0) = ISNULL(ISNULL(@sendcmacct,h.CMAcct),0)
		AND ISNULL(h.PayControl,'') = ISNULL(ISNULL(@sendpaycontrol,h.PayControl),'')
		AND (
				 (@senddiscdate = 'N' AND 
			      h.DueDate <= ISNULL(@sendduedate, h.DueDate)
				 )	--18897
			 OR
			 	 (@senddiscdate = 'Y' AND 
				  d.DiscTaken = 0 AND 
				  h.DueDate <= ISNULL(@sendduedate, h.DueDate)
				 )
			 OR
			 	 (@senddiscdate = 'Y' AND 
				  @cancelifdiscdate IS NOT NULL AND 
				  h.DiscDate IS NOT NULL AND
				  @cancelifdiscdate >= h.DiscDate AND 
				  h.DueDate <= ISNULL(@sendduedate, h.DueDate)
				 )
			 OR
			 	 (@senddiscdate = 'Y' AND 
				  d.DiscTaken <> 0 AND 
				  (@cancelifdiscdate IS NULL OR @cancelifdiscdate <= ISNULL(h.DiscDate,'')) AND 
				  (CASE WHEN h.DiscDate IS NULL THEN h.DueDate ELSE h.DiscDate END) <= ISNULL(@sendduedate, h.DueDate)
				  )
			)	
		AND (
			 @IncludeAllPayments = 'Y' OR
			 (
			  (@includecheckpayments = 'Y' AND h.PayMethod = 'C') OR
			  (@includeeftpayments = 'Y' AND h.PayMethod = 'E') OR
			  (@includecreditservicepayments = 'Y' AND h.PayMethod = 'S')
			  )
			 )
		AND (
			 h.PrePaidYN = 'N' OR 
			 (h.PrePaidYN = 'Y' AND h.PrePaidProcYN = 'Y')
			)
		AND h.OpenYN = 'Y' 
		AND (
			 h.InUseMth IS NULL OR 
			 (h.InUseMth = @mth AND h.InUseBatchId = @batchid)
			)
		-- allows trans already in current batch
		AND h.InPayControl = 'N' 
		AND h.Mth <= @mth	
ORDER BY v.SortName, h.Vendor, d.Supplier    -- include Supplier in order to create separate payments
   
OPEN bcTransCheck
SELECT @openTransCheck = 1

TransCheck_loop:
--BEGIN TransCheck_loop
	FETCH NEXT FROM bcTransCheck INTO	@expmth,			@aptrans,		@vendorgroup,	@vendor, 
										@sortname,			@apref,			@description,	@invdate, 
										@discdate,			@paymethod,		@cmco,			@cmacct, 
										@payoverrideyn,		@payname,		@payaddinfo,	@payaddress,
										@paycity,			@paystate,		@payzip,		@savesupplier, 
										@APTHaddendatypeid,	@taxformcode,	@employee,		@separatepayyn,
										@addressseq,		@paycountry

	IF @@FETCH_STATUS <> 0 GOTO TransCheck_end
       
	--if cmacct is null set it to the default cmacct
	IF @paymethod = 'S' 
	BEGIN
		SELECT @cmacct = ISNULL(@cmacct, @cscmacct)
		IF @separatepayyn = 'Y' SELECT @separatepayyn = 'N' --ensure CS trans are not entered w/Separate Pay
		
		--TK-12973 - when pay method = Credit Service, set Pay Address info from APVM so that entire payment for the vendor 
		--  goes to same pay sequence
		-- B-09140 Get address information from APVM for Paymethod credit service
		SELECT	@payoverrideyn = 'Y',
				@payname = Name, 
				@payaddinfo = AddnlInfo, -- B-09140 Added
				@payaddress = Address,
				@paycity = City, 
				@paystate = State, 
				@payzip = Zip, 
				@paycountry = Country
		FROM dbo.bAPVM WITH(NOLOCK)
		WHERE VendorGroup = @vendorgroup AND Vendor = @vendor
	END
	ELSE
	BEGIN
		SELECT @cmacct = ISNULL(@cmacct, @dfltcmacct)
	END
	
	--CMAccount Validation for all Pay Methods
	EXEC	@rc = [dbo].[vspAPCOCreditServiceInfoCheck]
			@apco = @co,
			@cmco = @cmco,
			@cmacct = @cmacct,
			@vendorgrp = @vendorgroup,
			@vendor = @vendor,
			@paymethod = @paymethod,
			@msg = @msg OUTPUT
	IF @rc = 1 OR @cmacct IS NULL GOTO TransCheck_loop
		
	-- get Vendor payment info
	IF @lastvendor <> @vendor OR @lastvendor IS NULL
	BEGIN
		SELECT	@name = Name, 
				@addnlinfo = AddnlInfo, 
				@address = [Address], 
				@city = City, 
				@state = [State], 
				@zip = Zip, 
				@country = Country
		FROM dbo.bAPVM WITH (NOLOCK) 
		WHERE VendorGroup = @vendorgroup AND Vendor = @vendor
		
		IF @@ROWCOUNT = 0 GOTO TransCheck_loop     -- skip trans if invalid vendor
		
		SELECT @lastvendor = @vendor
	END

	--TK-12973 - when pay method = Credit Service, set Pay Address info from APVM so that entire payment for the vendor 
	  --goes to same pay sequence
	 -- B-09140 Get address information from APVM for Paymethod credit service
	IF @paymethod = 'S' 
	BEGIN
		SELECT	@payoverrideyn = 'Y',
				@payname = Name, 
				@payaddinfo = AddnlInfo, -- B-09140 Added
				@payaddress = Address,
				@paycity = City, 
				@paystate = State, 
				@payzip = Zip, 
				@paycountry = Country
		FROM dbo.bAPVM WITH (NOLOCK)
		WHERE VendorGroup = @vendorgroup AND Vendor = @vendor
	END

	--Check for credit vendor balance
	IF @excludevendorcreditYN = 'Y' 
	BEGIN
		SELECT @aptdtotal = SUM(d.Amount) 
		FROM dbo.bAPTD d 
		JOIN dbo.bAPTH h ON d.APCo = h.APCo AND 
							d.Mth = h.Mth AND 
							d.APTrans = h.APTrans
		WHERE	d.Status IN (1, 2) AND 
				h.VendorGroup = @vendorgroup AND 
				h.Vendor = @vendor 
				
		IF @aptdtotal <= 0 GOTO TransCheck_loop
	END

	-- check all invoice compliance	
	IF @allallowpay = 'Y'
	BEGIN
		SELECT @allinvcomplied = 'Y'
		
		EXEC @rc = bspAPComplyCheckAll @co, @vendorgroup, @vendor, @invdate, @allinvcomplied OUTPUT
		
		IF @allinvcomplied = 'N' GOTO TransCheck_loop
	END
   
	-- set pay address info - #18037
	IF @payoverrideyn = 'N' AND @addressseq IS NULL  -- use Vendor defaults
	BEGIN
		SELECT	@payname = @name, 
				@payaddinfo = @addnlinfo, 
				@payaddress = @address,
				@paycity = @city, 
				@paystate = @state, 
				@payzip = @zip, 
				@paycountry=@country
	END
	
	IF @payoverrideyn = 'N' AND @addressseq IS NOT NULL -- use address from bAPAA additional addresses
	BEGIN
		SELECT	@payaddinfo = Address2, 
				@payaddress = [Address],
				@paycity = City, 
				@paystate = [State], 
				@payzip = Zip, 
				@paycountry = Country 
		FROM dbo.bAPAA WITH (NOLOCK) 
		WHERE	VendorGroup = @vendorgroup AND 
				Vendor = @vendor AND 
				AddressSeq = @addressseq
				
		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @msg = 'Missing Additional Address Seq: '+ ISNULL(convert(varchar(3),@addressseq), '') --#23061
			RETURN 1
		END
		
		SELECT @payname = @name	-- use APVM name
	END
   
	-- create a cursor to check for 'open' Lines on this Transaction
	DECLARE bcLineCheck CURSOR LOCAL FAST_FORWARD FOR
	
	SELECT	APLine, LineType, PO, JCCo, Job, SL
	FROM dbo.bAPTL WITH (NOLOCK)
	WHERE	APCo = @co AND 
			Mth = @expmth AND 
			APTrans = @aptrans

	OPEN bcLineCheck
	SELECT @openLineCheck = 1, @detail = 'N'    -- flag used to indicate whether something is payable on this Trans#

	LineCheck_loop:
	--BEGIN LineCheck_loop
		FETCH NEXT FROM bcLineCheck INTO @apline, @linetype, @po, @jcco, @job, @sl

		IF @@FETCH_STATUS <> 0 GOTO LineCheck_end

		-- check Line level restrictions
		IF @sendjcco IS NOT NULL AND ISNULL(@jcco, 0) <> @sendjcco GOTO LineCheck_loop
		IF @sendjob IS NOT NULL AND ISNULL(@job, '') <> @sendjob GOTO LineCheck_loop

		-- PO and SL compliance checks
		IF (@linetype = 6 AND @poallowpay = 'Y') OR (@linetype = 7 AND @slallowpay = 'Y')
		BEGIN
			EXEC @rc = bspAPComplyCheck @co, @expmth, @aptrans, @apline, @invdate, @apref, @msg OUTPUT --DC #132186
			IF @rc <> 0	GOTO LineCheck_loop
		END
   
		-- create a cursor to search for 'open' Detail on this Line
		DECLARE bcDetailCheck CURSOR LOCAL FAST_FORWARD FOR
		
		SELECT APSeq, PayType, DiscTaken, DueDate
		FROM dbo.bAPTD WITH (NOLOCK)
		WHERE	APCo = @co AND 
				Mth = @expmth AND 
				APTrans = @aptrans AND 
				APLine = @apline AND 
				Status = 1 AND
				--TK-12973 - when pay method = Credit Service, ignore Supplier so that entire payment for the vendor 
				--  goes to same pay seq 
				(
				 (@paymethod = 'S') OR 
				 (@paymethod <> 'S' AND ISNULL(Supplier,0) = ISNULL(@savesupplier,0))
				)

		OPEN bcDetailCheck
		SELECT @openDetailCheck = 1
   
		DetailCheck_loop:
		--BEGIN DetailCheck_loop
			FETCH NEXT FROM bcDetailCheck INTO @apseq, @paytype, @disctaken, @duedate
			
			IF @@fetch_status <> 0 GOTO DetailCheck_end
			
			-- skip if already in Payment Detail Batch (same trans may be processed multiple times)
			IF EXISTS  (SELECT 1 FROM dbo.bAPDB WITH (NOLOCK) 
						WHERE	APTrans = @aptrans AND 
								Co = @co AND 
								ExpMth = @expmth AND 
								APLine = @apline AND 
								APSeq = @apseq
					   ) 
			BEGIN
				GOTO DetailCheck_loop
			END
			
			-- skip if not one of the selected Pay Types
			IF  @sendpaytype IS NOT NULL AND 
				CHARINDEX(',' + ISNULL(CONVERT(varchar(3),@paytype),'') + ',', @sendpaytype) = 0 
			BEGIN
				GOTO DetailCheck_loop -- #24360
			END
			
			-- skip if not yet due
			IF @senddiscdate = 'N' AND @duedate > @sendduedate GOTO DetailCheck_loop
			
			-- skip if no discount to be taken, and paying discount only trans
			IF @disconly = 'Y'	--23664 - include all detail if any detail has a discount
			BEGIN
				SELECT TOP 1 1 
				FROM dbo.bAPTD WITH (NOLOCK)
				WHERE	APCo = @co AND 
						Mth = @expmth AND 
						APTrans = @aptrans AND 
						DiscTaken <> 0 AND 
						Status = 1
						
				IF @@ROWCOUNT = 0 GOTO DetailCheck_end
			END

			-- at least one detail sequence passed all restrictions, prepare to add to Payment Batch
			SELECT @detail = 'Y'
		--END DetailCheck_loop
		DetailCheck_end:
		CLOSE bcDetailCheck
		DEALLOCATE bcDetailCheck
		SELECT @openDetailCheck = 0
   
		IF @detail <> 'Y' GOTO LineCheck_loop -- no detail for this line is 'open'
	--END LineCheck_loop ... at this point at least one detail sequence for at least one detail passed all restrictions
	LineCheck_end:
	CLOSE bcLineCheck
	DEALLOCATE bcLineCheck
	SELECT @openLineCheck = 0

	IF @detail <> 'Y' GOTO TransCheck_loop    -- no detail for the trans is 'open'
   
	--now start cycling through the lines again to pay
 	SELECT DISTINCT @apline = MIN(l.APLine) 
 	FROM dbo.bAPTL l WITH (NOLOCK) 
 	JOIN dbo.bAPTD d WITH (NOLOCK) ON	l.APCo = d.APCo AND 
 										l.Mth = d.Mth AND
 										l.APTrans = d.APTrans AND 
 										l.APLine = d.APLine			
  	WHERE	l.APCo = @co AND 
  			l.Mth = @expmth AND 
  			l.APTrans = @aptrans AND 
  			d.Status = 1	--20845
  			
   	WHILE @apline IS NOT NULL
   	BEGIN
   		SELECT	@sl = SL, 
   				@job = Job, 
   				@jcco = JCCo 
   		FROM dbo.bAPTL WITH (NOLOCK) 
   		WHERE	APCo = @co AND 
   				Mth = @expmth AND 
   				APTrans = @aptrans AND 
   				APLine = @apline
   
		-- lookup up existing Payment Batch Header
		SELECT @batchseq = BatchSeq
		FROM dbo.bAPPB 
		WHERE	Co = @co AND 
				Mth = @mth AND 
				BatchId = @batchid AND 
				CMCo = @cmco AND 
				CMAcct = @cmacct AND 
				PayMethod = @paymethod AND 
				CMRef IS NULL AND 
				VendorGroup = @vendorgroup AND 
				Vendor = @vendor AND 
				ISNULL(Name,'') = ISNULL(@payname,'') AND 
				ISNULL(AddnlInfo,'') = ISNULL(@payaddinfo,'') AND 
				ISNULL(Address,'') = ISNULL(@payaddress,'') AND 
				ISNULL(City,'') = ISNULL(@paycity,'') AND 
				ISNULL(State,'') = ISNULL(@paystate,'') AND 
				ISNULL(Zip,'') = ISNULL(@payzip,'') AND 
				--TK-12973 - when pay method = Credit Service, ignore Supplier so that entire payment for the vendor 
				--  goes to same pay sequence
				(
				 (@paymethod = 'S') OR 
				 (@paymethod <> 'S' AND ISNULL(Supplier,0) = ISNULL(@savesupplier,0))
				) AND 
				ISNULL(TaxFormCode,'') = ISNULL (@taxformcode,'') AND 
				ISNULL(Employee, 0) = ISNULL(@employee, 0) AND 
				ISNULL(AddendaTypeId, 0) = ISNULL(@APTHaddendatypeid, 0) AND --#15489 and #134851
				(
				 (@separatesubyn = 'N' OR @separatesubyn IS NULL) OR
				 (@separatesubyn = 'Y' AND ISNULL(SL,'') = ISNULL(@sl,''))
				) AND --#139461
				( 
				 (@separatejobyn = 'N' OR @separatejobyn IS NULL) OR
				 (
				  (@separatejobyn = 'Y' AND Job IS NULL) OR
				  (@separatejobyn = 'Y' AND Job = @job AND JCCo = @jcco) 
				 )
				) AND 
				(@separatepayyn = 'N' AND 
				 SeparatePayTrans IS NULL OR 
				 (@separatepayyn = 'Y' AND 
				  SeparatePayMth = @expmth AND 
				  SeparatePayTrans = @aptrans)
				)
				
		IF @@ROWCOUNT > 0
		BEGIN
			GOTO AddPayTrans -- jump down to add payment batch transaction
		END
		
		AddPayHeader:       -- add Payment Batch Header
		
		SELECT @batchseq = ISNULL(MAX(BatchSeq),0) + 1
		FROM dbo.bAPPB WITH (NOLOCK)
		WHERE	Co = @co AND 
				Mth = @mth AND 
				BatchId = @batchid

   		SELECT @chktype = NULL
		IF @paymethod = 'C' SELECT @chktype = 'C'

		INSERT bAPPB   (Co,				Mth,			BatchId,		BatchSeq, 
						CMCo,			CMAcct,			PayMethod,		ChkType, 
						VendorGroup,	Vendor,			Name,			AddnlInfo, 
						[Address],		City,			[State],		Zip,
						Country,		Amount,			Supplier,		VoidYN,
						Overflow,		AddendaTypeId,	TaxFormCode,	Employee,
						SL,				JCCo,			Job,			SeparatePayMth,
						SeparatePayTrans)
		SELECT	@co,			@mth,				@batchid,		@batchseq, 
				@cmco,			@cmacct,			@paymethod,		@chktype, 
				@vendorgroup,	@vendor,			@payname,		@payaddinfo, 
				@payaddress,	@paycity,			@paystate,		@payzip,
				@paycountry,	0,					@savesupplier,	'N',
				'N',			@APTHaddendatypeid,	@taxformcode,	@employee,
				CASE @separatesubyn WHEN 'Y' THEN @sl ELSE NULL END,
				CASE @separatejobyn WHEN 'Y' THEN @jcco ELSE NULL END,
				CASE @separatejobyn WHEN 'Y' THEN @job ELSE NULL END,
				CASE @separatepayyn WHEN 'Y' THEN @expmth ELSE NULL END,
				CASE @separatepayyn WHEN 'Y' THEN @aptrans ELSE NULL END

		SELECT @count = @count + 1  -- # of payments added to batch

		AddPayTrans:     -- add Payment Batch Transaction - bAPTH updated as 'in use' via trigger
		
		CheckIfExists:  -- this check should not be necessary
		IF NOT EXISTS  (SELECT 1 FROM dbo.bAPTB WITH (NOLOCK) 
						WHERE	Co = @co AND 
								Mth = @mth AND
								BatchId = @batchid AND 
								BatchSeq = @batchseq AND 
								ExpMth = @expmth AND
								APTrans = @aptrans)
		BEGIN
			SELECT @grossamt = SUM(Amount) 
			FROM dbo.bAPTD WITH (NOLOCK) 
			WHERE	APCo = @co AND
					Mth = @expmth AND 
					APTrans = @aptrans
			INSERT dbo.bAPTB   (Co,			Mth,		BatchId,	BatchSeq, 
								ExpMth,		APTrans,	APRef,		[Description], 
								InvDate,	Gross,		Retainage,	PrevPaid, 
								PrevDisc,	Balance,	DiscTaken)
			VALUES (@co,		@mth,		@batchid,	@batchseq, 
					@expmth,	@aptrans,	@apref,		@description, 
					@invdate,	@grossamt,	0,			0,
					0,			0,			0)
			IF @@ROWCOUNT > 0
			BEGIN
				SELECT @transcount = @transcount + 1 --#27168
			END
		END

        -- create a cursor to process ALL Lines and Detail for this Transaction
		IF @openAddDetail = 0  -- #24333 
		BEGIN
              DECLARE bcAddDetail CURSOR LOCAL FAST_FORWARD FOR
              
              SELECT	l.LineType,	d.APLine,		d.APSeq,	d.PayType, 
						d.Amount,	d.DiscTaken,	d.DueDate,	d.[Status], 
						d.Supplier,	d.PayCategory,	d.TotTaxAmount
              FROM dbo.bAPTD d WITH (NOLOCK)
              JOIN dbo.bAPTL l WITH (NOLOCK) ON l.APCo = d.APCo AND 
												l.Mth = d.Mth AND 
												l.APTrans = d.APTrans AND 
												l.APLine = d.APLine
              WHERE	d.APCo = @co AND 
					d.Mth = @expmth AND 
					d.APTrans = @aptrans AND 
					d.APLine = @apline

              OPEN bcAddDetail
              SELECT @openAddDetail = 1
		END
		
		AddDetail_loop:     -- get next Line/Detail
		--BEGIN AddDetail_loop
			FETCH NEXT FROM bcAddDetail INTO	@linetype,	@apline,		@apseq,		@paytype,
												@amount,	@disctaken,		@duedate,	@status, 
												@supplier,	@paycategory,	@tottaxamount

			IF @@FETCH_STATUS <> 0 GOTO AddDetail_end

			IF EXISTS  (SELECT 1 FROM dbo.bAPDB WITH (NOLOCK) 
						WHERE	Co = @co AND 
								ExpMth = @expmth AND
								APTrans = @aptrans AND 
								APLine = @apline AND 
								APSeq = @apseq) 
			BEGIN
				GOTO AddDetail_loop
			END

			SELECT @retg = 0, @prevpaid = 0, @prevdisc = 0, @balance = 0, @disc = 0

			-- accumulate 'held' retainage  
			IF  (@paycategory IS NULL AND 
				 @paytype = @retpaytype AND 
				 @status = 2
				) 
				OR 
				(
				 @paycategory IS NOT NULL AND 
				 @paytype = (SELECT RetPayType 
							 FROM dbo.bAPPC WITH (NOLOCK)
							 WHERE	APCo=@co AND 
									PayCategory=@paycategory
							) AND 
				 @status = 2
				)
			BEGIN
				SELECT @retg = @amount
			END

			-- accumulate previous paid and discount taken
			IF @status > 2 
			BEGIN
				SELECT @prevpaid = (@amount - @disctaken), @prevdisc = @disctaken
			END

			-- if open or on hold but not retainage, assume as balance unless all restrictions are passed
			IF	@status = 1 OR 
				(
				 (@status = 2 AND 
				  @paycategory IS NULL AND 
				  @paytype <> @retpaytype
				 )
				 OR 
				 (@status = 2 AND 
				  @paycategory IS NOT NULL AND 
				  @paytype <>  (SELECT RetPayType 
								FROM dbo.bAPPC WITH (NOLOCK)
								WHERE	APCo=@co AND 
										PayCategory=@paycategory
							    )
				 )
				)
			BEGIN
				SELECT @balance = @amount
			END

			-- check for payment restrictions
			IF @status <> 1 GOTO PayTransUpdate     -- must be 'open'

			IF ISNULL(@savesupplier,0) <> ISNULL(@supplier,0) GOTO PayTransUpdate   -- different Supplier

			IF	@sendpaytype IS NOT NULL AND 
				CHARINDEX (',' + ISNULL(CONVERT(varchar(3), @paytype), '') + ',', @sendpaytype) = 0 
			BEGIN
				GOTO PayTransUpdate --#24360
			END

			IF @senddiscdate = 'N' AND @duedate > @sendduedate GOTO PayTransUpdate  -- not due yet

			IF	@separatesubyn = 'Y' AND 
				NOT EXISTS (SELECT 1 FROM dbo.bAPPB 
							WHERE Co = @co AND 
							Mth = @mth AND
							BatchSeq = @batchseq AND 
							ISNULL(SL, '') = ISNULL(@sl,'')) --#135689
			BEGIN
				GOTO AddPayHeader
			END

			IF (@linetype = 6 AND @poallowpay = 'Y') OR (@linetype = 7 AND @slallowpay = 'Y')
			BEGIN
				EXEC @rc = bspAPComplyCheck	@co, @expmth, @aptrans, @apline, @invdate, @apref, @msg OUTPUT    --DC #132186
				IF @rc <> 0 GOTO PayTransUpdate
			END

			--23664 - include all detail in a Transaction if any of the detail has a discount
			IF @disconly = 'Y'	
			BEGIN
				SELECT TOP 1 1 
				FROM dbo.bAPTD WITH (NOLOCK) 
				WHERE	APCo = @co AND 
						Mth = @expmth AND 
						APTrans = @aptrans AND 
						DiscTaken <> 0 AND 
						[Status] = 1
				IF @@ROWCOUNT = 0 GOTO PayTransUpdate
			END

			IF EXISTS  (SELECT 1 FROM dbo.bAPDB WITH (NOLOCK) 
						WHERE	Co = @co AND 
								ExpMth = @expmth AND
								APTrans = @aptrans AND 
								APLine = @apline AND 
								APSeq = @apseq) -- already in Payment Batch
			BEGIN
				GOTO AddDetail_loop
			END

			-- passed all restrictions, detail will be included in this payment
			SELECT @balance = 0     -- reset balance

			-- check to cancel discount
			SELECT @disc = @disctaken
			
			IF	@alldisc = 'N' AND 
				@cancelifdiscdate IS NOT NULL AND 
				(@discdate < @cancelifdiscdate OR @discdate IS NULL) AND 
				@netamtopt = 'N' 
			BEGIN
				SELECT @disc = 0
			END
   
			INSERT dbo.bAPDB   (Co,			Mth,		BatchId,	BatchSeq, 
								ExpMth,		APTrans,	APLine,		APSeq,
								PayType,	Amount,		DiscTaken,	PayCategory, 
								TotTaxAmount)
			VALUES (@co,		@mth,		@batchid,	@batchseq, 
					@expmth,	@aptrans,	@apline,	@apseq,
					@paytype,	@amount,	@disc,		@paycategory, 
					@tottaxamount)
			IF @@ROWCOUNT > 0
			BEGIN
				SELECT @transcount = @transcount + 1 --#27168
			END
   
			PayTransUpdate:     -- update amounts in Payment Batch Transaction
			UPDATE dbo.bAPTB SET DiscTaken = DiscTaken + @disc
			WHERE	Co = @co AND 
					Mth = @mth AND 
					BatchId = @batchid AND 
					BatchSeq = @batchseq AND 
					ExpMth = @expmth AND 
					APTrans = @aptrans
			IF @@ROWCOUNT <> 1
			BEGIN
				SELECT @msg = 'Unable to update Payment Batch Transaction.'
				RETURN 1
			END

			GOTO AddDetail_loop
		--END AddDetail_loop
    
		AddDetail_end:
		CLOSE bcAddDetail
		DEALLOCATE bcAddDetail
		SELECT @openAddDetail = 0
		
		SELECT DISTINCT @apline = MIN(l.APLine) 
		FROM dbo.bAPTL l WITH (NOLOCK) 
		JOIN dbo.bAPTD d ON l.APCo=d.APCo AND 
							l.Mth=d.Mth AND
							l.APTrans=d.APTrans AND 
							l.APLine=d.APLine			
		WHERE	l.APCo = @co AND 
				l.Mth = @expmth AND 
				l.APTrans = @aptrans AND 
				l.APLine > @apline AND 
				d.Status = 1	--20845
	END

	GOTO TransCheck_loop
--END TransCheck_loop

TransCheck_end:
	CLOSE bcTransCheck
	DEALLOCATE bcTransCheck
	SELECT @openTransCheck = 0
      
   
bspexit:
IF @openAddDetail = 1
BEGIN
	CLOSE bcAddDetail
	DEALLOCATE bcAddDetail
END
IF @openDetailCheck = 1
BEGIN
	CLOSE bcDetailCheck
	DEALLOCATE bcDetailCheck
END
IF @openLineCheck = 1
BEGIN
	CLOSE bcLineCheck
	DEALLOCATE bcLineCheck
END
IF @openTransCheck = 1
BEGIN
	CLOSE bcTransCheck
	DEALLOCATE bcTransCheck
END
   
-- remove any Payment Batch entries with negative and zero totals
DECLARE bcDelete CURSOR LOCAL FAST_FORWARD FOR

SELECT BatchSeq
FROM dbo.bAPPB WITH (NOLOCK)
WHERE	Co = @co AND 
		Mth = @mth AND 
		BatchId = @batchid

OPEN bcDelete
   
Delete_loop:

FETCH NEXT FROM bcDelete INTO @batchseq

IF @@FETCH_STATUS <> 0 GOTO Delete_end

SELECT @paysum = 0

SELECT @paysum = SUM(Amount - DiscTaken)
FROM dbo.bAPDB WITH (NOLOCK)
WHERE	Co = @co AND 
		Mth = @mth AND 
		BatchId = @batchid AND 
		BatchSeq = @batchseq

IF @paysum <= 0
BEGIN
	DELETE FROM dbo.bAPDB 
	WHERE	Co = @co AND 
			Mth = @mth AND 
			BatchId = @batchid AND 
			BatchSeq = @batchseq
	SELECT @transcount = @transcount - @@ROWCOUNT -- adjust # of transactions added to batch
	DELETE FROM dbo.bAPTB 
	WHERE	Co = @co AND 
			Mth = @mth AND 
			BatchId = @batchid AND 
			BatchSeq = @batchseq
	SELECT @transcount = @transcount - @@ROWCOUNT -- adjust # of transactions added to batch
	DELETE FROM dbo.bAPPB 
	WHERE	Co = @co AND 
			Mth = @mth AND 
			BatchId = @batchid AND 
			BatchSeq = @batchseq
	SELECT @count = @count - 1  -- adjust # of payments added to batch
END
GOTO Delete_loop

Delete_end:
CLOSE bcDelete
DEALLOCATE bcDelete

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[bspAPPBInitialize] TO [public]
GO
