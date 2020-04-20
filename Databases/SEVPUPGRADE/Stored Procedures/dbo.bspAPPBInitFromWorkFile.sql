SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPBInitFromWorkFile    Script Date: 8/28/99 9:34:02 AM ******/
CREATE                    proc [dbo].[bspAPPBInitFromWorkFile]
/***********************************************************
* CREATED BY:   kb 10/18/01
* MODIFIED By : kb 05/22/02 - #14160
*               kb 05/28/02 - #14160
*				MV 05/30/02 - #16956 - added coding to handle EFT addenda info.
*				kb 07/22/02 - #18044 - changed from always deleting out workfile at end of proc
*					to leaving transactions that couldn't come into payment batch becuas would result
*					in a negative payment
*				kb 07/30/02 - #18096 - to update discounts to APTD if they cancelled
*				MV 08/08/02 - #18247 - add already processed prepaid workfile trans to payment batch
*				MV 10/03/02 - #18782 - get SeparatePayYN from bAPTH for insert into bAPPB
*				MV 10/28/02 - #18037 - set pay address info
*				MV 01/06/03 - #19734 - omit any trans with exp mth > pay mth, return a warning
*				MV 01/30/03	- #19734 - rej2 fix
*				MV 04/29/03 - #21122 - fix to #18247
*				MV 02/18/04 - #18769 - Pay Category / #23061 isnull wrap / performance enhancements with (NOLOCK)
*				MV 01/08/07 - #121528 - Use SeparatePayYN from APWH 
*				MV 02/13/07 - #122330 - SELECT workfile transactions in vendor SortName order
*				MV 03/12/08 - #127347 - International addresses
*				MV 09/10/08 - #128288 - update bAPDB with bAPTB TotTaxAmount
*				MV 01/12/09 - #131765 - restrict where clause in cursor to UserId=SUSER_NAME()
*				MV 07/20/09 - #134851 - tweaked @separatesubyn = 'Y' in SELECT from bAPPB 	 
*				GP 06/28/10 - #135813 - change bSL to varchar(30)
*				MV 10/14/10 - #139461 -  tweaked @separatejobyn = 'Y' in SELECT from bAPPB
*				KK 01/26/12 - TK-11581 - call to vspAPCOCreditServiceInfoCheck when to validate CM Acct (CS Enhancement)
*										 Refactored code to SSMS best practice
*				EN 03/13/12 - TK-12973 - force Credit Service transactions for a vendor into a single pay seq
*				KK 04/20/12 - B-09140 - Allow Credit Service transactions to default address info from APVM into Payment Processing
*				KK 04/27/12	- B-09140 - Added back Add'l Info to address for CS
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
*  @sendpaymethod      Payment Method - 'C' = check, 'E' = EFT, 'B' = both
*  @sendduedate        Due Date - include trans due as of this date
*  @senddiscdate       'Y' = if available, use Discount Date, 'N' = use due date
*  @disconly           'Y' = dicounted trans only, 'N' = all trans
*  @alldisc            'Y' = take all discounts, 'N' = cancel if past discount date (not used?????)
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
 @updateAPTDDisc bYN, 
 @msg varchar(255) OUTPUT)

AS
SET NOCOUNT ON
   
DECLARE @rcode int,				@retpaytype tinyint, 
		@openAPTD tinyint,		@apline smallint, 
		@apseq tinyint,			@paytype tinyint,
		@amount bDollar,		@disctaken bDollar, 
		@status tinyint,		@supplier bVendor, 
		@retg bDollar,			@prevpaid bDollar,
		@prevdisc bDollar,		@balance bDollar, 
		@disc bDollar,			@chktype char(1), 
		@firstsupplier tinyint, @gross bDollar,
		@openamt bDollar,		@grossamt bDollar, 
		@paycategory int,		@openAPWH int,
		@tottaxamount bDollar,	@rc tinyint
   
-- APTH declares
DECLARE @vendorgroup bGroup,	@vendor bVendor, 
		@apref bAPReference,	@description bDesc, 
		@invdate bDate,			@paymethod char(1),
		@cmco bCompany,			@cmacct bCMAcct, 
		@prepaidyn bYN,			@prepaidprocyn bYN, 
		@payoverrideyn bYN,		@payname varchar(60),
		@payaddinfo varchar(60), @addressseq tinyint, 
		@paycountry char(2),	@payaddress varchar(60), 
		@paycity varchar(30),	@paystate varchar(4), 
		@payzip bZip,			@openyn bYN, 
		@inusemth bMonth,		@inusebatchid bBatchID, 
		@inpaycontrol bYN, 		@APTHaddendatypeid tinyint, 
		@username bVPUserName

-- APVM declares
DECLARE @name varchar(60),		@addnlinfo varchar(60), 
		@address varchar(60),	@city varchar(30), 
		@state varchar(4),      @zip bZip, 
		@VMaddendatypeid tinyint, @batchseq int, 
		@country char(2)

-- APPB declares
DECLARE @pbcmco bCompany,		@pbcmacct bCMAcct, 
		@pbpaymethod char(1),	@pbcmref bCMRef, 
		@pbvendorgroup bGroup,	@pbvendor bVendor, 
		@pbname varchar(60),	@pbaddinfo varchar(60), 
		@pbaddress varchar(60), @pbcity varchar(30),
		@pbstate varchar(4),	@pbzip bZip, 
		@pbsupplier bVendor,	@APPBaddendatypeid tinyint, 
		@pbcountry char(2)

DECLARE @expmth bMonth,			@aptrans bTrans, 
		@sendcmacct bCMAcct,	@sl varchar(30),
		@job bJob,				@jcco bCompany, 
		@taxformcode varchar(10), @employee bEmployee,
		@separatesubyn bYN,		@separatejobyn bYN, 
		@separatepayyn bYN,		@alldisc bYN,	
		@discdate bDate,		@netamtopt bYN, 
		@slallowpay bYN,		@poallowpay bYN, 
		@dfltcmacct bCMAcct,	@paysum bDollar

SELECT	@rcode = 0, 
		@username = SUSER_SNAME(), 
		@openAPWH = 0, @msg = ''
   
-- get Retainage Pay Type from AP Company
SELECT  @retpaytype = RetPayType, 
		@netamtopt = NetAmtOpt, 
		@slallowpay = SLAllowPayYN,
		@poallowpay = POAllowPayYN, 
		@dfltcmacct = CMAcct
FROM APCO WHERE APCo = @co

IF @@rowcount = 0
BEGIN
	SELECT @msg = 'Invalid AP Company!'
	RETURN 1
END

-- SELECT workfile transactions in vendor SortName order
DECLARE bcAPWH CURSOR LOCAL FAST_FORWARD FOR SELECT
	w.Mth,				w.APTrans,			t.VendorGroup, 
	t.Vendor,			t.APRef,			t.Description, 
	t.InvDate,			t.PayMethod,		t.CMCo, 
	t.CMAcct,			t.PrePaidYN,		t.PrePaidProcYN,
	t.PayOverrideYN,	t.PayName,			t.PayAddInfo, 
	t.PayAddress,		t.PayCity,			t.PayState,
	t.PayZip,			t.OpenYN,			t.InUseMth, 
	t.InUseBatchId,		t.InPayControl,		t.AddendaTypeId,
	t.TaxFormCode,		t.Employee,			t.AddressSeq,
	w.TakeAllDiscYN,	w.DiscDate,			SeparatePaySLYN,
	SeparatePayJobYN,	w.SeparatePayYN,	t.PayCountry	         
FROM bAPWH w WITH (NOLOCK)
JOIN bAPTH t WITH (NOLOCK) ON w.APCo = t.APCo AND w.Mth = t.Mth AND w.APTrans = t.APTrans
JOIN bAPVM m ON t.VendorGroup=m.VendorGroup AND t.Vendor=m.Vendor
WHERE w.APCo = @co AND w.PayYN = 'Y' AND UserId=SUSER_NAME()
	AND (t.PrePaidYN = 'N' OR (t.PrePaidYN = 'Y' AND t.PrePaidProcYN = 'Y'))
ORDER BY m.SortName,w.Mth,w.APTrans

OPEN bcAPWH
SELECT @openAPWH = 1
  
APWH_loop:      -- loop through each trans in workfile
FETCH NEXT FROM bcAPWH 
		   INTO	@expmth,		@aptrans,		@vendorgroup, 
				@vendor,		@apref,		    @description, 
				@invdate,		@paymethod,		@cmco, 
				@cmacct,		@prepaidyn,		@prepaidprocyn, 
				@payoverrideyn,	@payname,		@payaddinfo, 
				@payaddress,    @paycity,		@paystate, 
				@payzip,		@openyn,		@inusemth, 
				@inusebatchid,	@inpaycontrol,	@APTHaddendatypeid,
				@taxformcode,	@employee,		@addressseq,
				@alldisc,		@discdate,		@separatesubyn,
				@separatejobyn, @separatepayyn, @paycountry 
	
	IF @@fetch_status <> 0 GOTO APWH_End

	-- omit any trans with an exp mth > than pay mth, return a warning
	IF @expmth > @mth	
	BEGIN 
		SELECT @msg = 'One or more transactions in the workfile cannot be added to the '
		SELECT @msg = @msg + 'payment batch because the Expense Month is greater than the Payment Month. ', @rcode=7
		GOTO APWH_loop
	END	
	 
	IF @openyn = 'N'
	BEGIN
		SELECT @msg = 'This transaction has been fully paid and/or cleared.', @rcode = 1
		GOTO bspexit
	END
	
	IF @prepaidyn = 'Y' AND @prepaidprocyn = 'N'
	BEGIN
	    SELECT @msg = 'The prepaid portion of this transaction has not been processed.', @rcode = 1
	    GOTO bspexit
	END
			
	--Check that all information is present and valid for Credit Service invoices
	EXEC	@rc = [dbo].[vspAPCOCreditServiceInfoCheck]
			@apco = @co,
			@cmco = @cmco,
			@cmacct = @cmacct,
			@vendorgrp = @vendorgroup,
			@vendor = @vendor,
			@paymethod = @paymethod,
			@msg = @msg OUTPUT
	IF @rc <> 0	OR @cmacct IS NULL GOTO APWH_loop

	-- get Vendor info
	SELECT @name = Name, 
		   @addnlinfo = AddnlInfo, 
		   @address = Address, 
		   @city = City, 
		   @state = State,
		   @zip = Zip, 
		   @VMaddendatypeid = AddendaTypeId, 
		   @country = Country
	FROM bAPVM WITH (NOLOCK)
	WHERE VendorGroup = @vendorgroup AND Vendor = @vendor
	IF @@rowcount = 0
	BEGIN
		SELECT @msg = 'Missing Vendor: ' + isnull(convert(varchar(8), @vendor),''), @rcode = 1
		GOTO bspexit
	END

	-- set pay address info - #18037
	IF @payoverrideyn = 'N' AND @addressseq IS NULL  -- use Vendor defaults
	BEGIN
		SELECT @payname = @name, 
			   @payaddinfo = @addnlinfo, 
			   @payaddress = @address,
			   @paycity = @city, 
			   @paystate = @state, 
			   @payzip = @zip, 
			   @paycountry=@country
	END
	
	IF @payoverrideyn = 'N' AND @addressseq IS NOT NULL -- use address from bAPAA additional addresses
	BEGIN
		SELECT @payaddinfo = Address2, 
			   @payaddress = Address,
			   @paycity = City, 
			   @paystate = State, 
			   @payzip = Zip, 
			   @paycountry=Country 
		FROM bAPAA WITH (NOLOCK) 
		WHERE VendorGroup= @vendorgroup AND Vendor = @vendor AND AddressSeq=@addressseq
		IF @@rowcount = 0
		BEGIN
			SELECT @msg = 'Invalid Additional Address Seq: ' + isnull(convert(varchar(3),@addressseq,1),''), @rcode = 1
			GOTO bspexit
		END
		SELECT @payname = @name	-- use APVM name
	END

	--TK-12973 - when pay method = Credit Service, set Pay Address info from APVM and use Separate Pay flag = 'N'
	--  so that entire payment to the vendor goes to the same pay sequence
		-- B-09140 Get address information from APVM for Paymethod credit service
	IF @paymethod = 'S'
	BEGIN
		SELECT  @separatepayyn = 'N'
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
		
    SELECT @balance = 0, 
		   @prevpaid = 0, 
		   @prevdisc = 0
    
    SELECT @balance = sum(Amount) 
    FROM bAPTD WITH (NOLOCK) 
    WHERE APCo = @co AND Mth = @expmth AND APTrans = @aptrans AND Status <3
    
    SELECT @prevpaid = sum(Amount), @prevdisc = sum(DiscTaken)
    FROM bAPTD WITH (NOLOCK) 
    WHERE APCo = @co AND Mth = @expmth AND APTrans = @aptrans AND Status >3
       
    SELECT @retg = sum(Amount) 
    FROM bAPTD d WITH (NOLOCK) 
    WHERE Status = 2 
		AND d.APCo = @co 
		AND d.Mth = @expmth 
		AND d.APTrans = @aptrans
		AND (	(d.PayCategory IS NULL AND d.PayType = @retpaytype) 
				OR (d.PayCategory IS NOT NULL 
					AND d.PayType = (SELECT c.RetPayType 
									FROM bAPPC c WITH (NOLOCK)
									WHERE c.APCo=@co AND c.PayCategory=d.PayCategory)
					)
			)
	/*AND PayType = @retpaytype*/
	SELECT @apline = min(APLine) 
	FROM bAPWD WITH (NOLOCK) 
	WHERE APCo = @co AND UserId = @username AND Mth = @expmth AND APTrans = @aptrans AND PayYN = 'Y'
	
	WHILE @apline IS NOT NULL
	BEGIN --While apline loop
		SELECT @sl = SL, @job = Job, @jcco = JCCo 
		FROM bAPTL WITH (NOLOCK) 
		WHERE APCo = @co AND Mth = @expmth AND APTrans = @aptrans AND APLine = @apline
			
		SELECT @apseq = min(APSeq) 
		FROM bAPWD WITH (NOLOCK) 
		WHERE APCo = @co 
			  AND UserId = @username 
			  AND PayYN = 'Y' 
			  AND Mth = @expmth
			  AND APTrans = @aptrans 
			  AND APLine = @apline
		WHILE @apseq IS NOT NULL
		BEGIN --While apseq loop
			SELECT @supplier = t.Supplier, 
				   @disctaken = w.DiscTaken, 
				   @amount = t.Amount,
                   @paytype = t.PayType, 
                   @paycategory = t.PayCategory, 
                   @tottaxamount=t.TotTaxAmount
			FROM bAPTD t WITH (NOLOCK)
			JOIN bAPWD w WITH (NOLOCK) ON w.APCo = t.APCo 
									  AND w.Mth = t.Mth
									  AND w.APTrans = t.APTrans 
									  AND w.APLine = t.APLine
									  AND w.APSeq = t.APSeq 
			WHERE t.APCo = @co
				AND t.Mth = @expmth 
				AND t.APTrans = @aptrans 
				AND t.APLine = @apline
				AND t.APSeq = @apseq
				
			--TK-12973 - when pay method = Credit Service, ignore Supplier so that entire payment to vendor 
			--  goes to the same pay sequence
			IF @paymethod = 'S'
			BEGIN
				SELECT @supplier = NULL
			END
			
			SELECT @batchseq = BatchSeq
		    FROM dbo.bAPPB 
	    	WHERE Co = @co
				AND Mth = @mth 
				AND BatchId = @batchid 
				AND CMCo = @cmco
				AND CMAcct = @cmacct 
				AND PayMethod = @paymethod 
				AND CMRef IS NULL
				AND VendorGroup = @vendorgroup 
				AND Vendor = @vendor
	            AND ISNULL(Name,'') = ISNULL(@payname,'')
				AND ISNULL(AddnlInfo,'') = ISNULL(@payaddinfo,'')
	            AND ISNULL(Address,'') = ISNULL(@payaddress,'')
				AND ISNULL(City,'') = ISNULL(@paycity,'')
				AND ISNULL(State,'') = ISNULL(@paystate,'')
	            AND ISNULL(Zip,'') = ISNULL(@payzip,'')
				AND ISNULL(Supplier,0) = ISNULL(@supplier,0)
			 	AND ISNULL(AddendaTypeId,0)= ISNULL(@APTHaddendatypeid,0)
	            AND ISNULL(TaxFormCode,'') = ISNULL (@taxformcode,'')
				AND ISNULL(Employee, 0) = ISNULL(@employee, 0)
				AND --#134851
				(	(@separatesubyn = 'N' OR @separatesubyn IS NULL)
					 OR
            		(@separatesubyn = 'Y' AND isnull(SL,'') = isnull(@sl,'') )
				) 
				AND	--#139461
				(	(@separatejobyn = 'N' OR @separatejobyn IS NULL) 
					 OR
					(	(@separatejobyn = 'Y' AND Job IS NULL)
						 OR
						(@separatejobyn = 'Y' AND Job = @job AND JCCo = @jcco) 
					)
				)
				--AND 
				--(	(@separatejobyn = 'N' or @separatejobyn is null) or
				--	(@separatejobyn = 'Y' AND Job = @job AND JCCo = @jcco)
				--) 
			 	AND 
			 	(	(	(@separatepayyn = 'N' OR @separatepayyn IS NULL)
						AND SeparatePayTrans IS NULL
					)
					OR 
					(@separatepayyn = 'Y' AND SeparatePayMth = @expmth AND SeparatePayTrans = @aptrans)
				)
				IF @@rowcount = 0
				BEGIN
                    SELECT @batchseq = ISNULL(MAX(BatchSeq),0)+1 
                    FROM bAPPB WITH (NOLOCK) 
                    WHERE Co = @co AND Mth = @mth AND BatchId = @batchid
				    
				    INSERT bAPPB(Co,			Mth,			 BatchId, 
								BatchSeq,		CMCo,			 CMAcct, 
								PayMethod,		ChkType,		 VendorGroup,
								Vendor,			Name,			 AddnlInfo, 
								Address,		City,			 State,
								Zip,			Country,		 Amount, 
								Supplier,		VoidYN,			 Overflow, 
								AddendaTypeId,	TaxFormCode,	 Employee, 
								SL,				JCCo,			 Job,
								SeparatePayMth,	SeparatePayTrans,SeparatePayYN)
								
	      			SELECT	@co,			@mth,				@batchid, 
	      					@batchseq,		@cmco,				@cmacct, 
	      					@paymethod, CASE WHEN @paymethod = 'C' THEN 'C' ELSE NULL END,
							@vendorgroup,	@vendor,			@payname, 
							@payaddinfo,	@payaddress,		@paycity,
							@paystate,		@payzip,			@paycountry, 
							0,				@supplier,			'N',
							'N',			@APTHaddendatypeid, @taxformcode, 
							@employee,
							CASE @separatesubyn WHEN 'Y' THEN @sl ELSE NULL END,
							CASE @separatejobyn WHEN 'Y' THEN @jcco ELSE NULL END,
							CASE @separatejobyn WHEN 'Y' THEN @job ELSE NULL END,
							CASE @separatepayyn WHEN 'Y' THEN @expmth ELSE NULL END,
							CASE @separatepayyn WHEN 'Y' THEN @aptrans ELSE NULL END,
							@separatepayyn	--#18782
				END
				
				IF NOT EXISTS(SELECT top 1 1 
							  FROM bAPTB WITH (NOLOCK) 
							  WHERE Co = @co 
								AND Mth = @mth
								AND BatchId = @batchid 
								AND APTrans = @aptrans 
								AND ExpMth = @expmth 
								AND BatchSeq = @batchseq)
				BEGIN
                    SELECT @grossamt = sum(Amount) 
                    FROM bAPTD WITH (NOLOCK) 
                    WHERE APCo = @co AND Mth = @expmth AND APTrans = @aptrans
					
					INSERT bAPTB(Co,				Mth,			BatchId, 
								BatchSeq,			ExpMth,			APTrans, 
								APRef,				Description,	InvDate, 
								Gross,				Retainage,		PrevPaid, 
								PrevDisc,			Balance,		DiscTaken)
     					VALUES (@co,				@mth,			@batchid, 
     							@batchseq,			@expmth,		@aptrans, 
     							@apref,				@description,	@invdate,
								ISNULL(@grossamt,0),0,				0,
								0,					0,				0)
				END

				SELECT @disc = @disctaken

                INSERT bAPDB (Co,			Mth,		BatchId, 
							  BatchSeq,		ExpMth,		APTrans, 
							  APLine,		APSeq,      PayType, 
							  Amount,		DiscTaken,	PayCategory,
							  TotTaxAmount)
      				  VALUES (@co,			@mth,		@batchid, 
      						  @batchseq,	@expmth,	@aptrans, 
      						  @apline,		@apseq,		@paytype, 
      						  @amount,		@disc,		@paycategory,
      						  @tottaxamount)
				UPDATE bAPTB SET DiscTaken = DiscTaken + ISNULL(@disc,0)
							 WHERE  Co = @co 
								AND Mth = @mth 
								AND BatchId = @batchid
								AND BatchSeq = @batchseq
								AND ExpMth = @expmth 
								AND APTrans = @aptrans
				
				SELECT @apseq = min(APSeq) 
				FROM bAPWD WITH (NOLOCK) 
				WHERE APCo = @co 
					AND UserId = @username 
					AND PayYN = 'Y' 
					AND Mth = @expmth
					AND APTrans = @aptrans 
					AND APLine = @apline 
					AND APSeq > @apseq
		END--While apseq loop
			
		SELECT @apline = min(APLine) 
		FROM bAPWD WITH (NOLOCK) 
		WHERE APCo = @co 
			AND UserId = @username 
			AND Mth = @expmth 
			AND APTrans = @aptrans
			AND PayYN = 'Y' 
			AND APLine > @apline
	END --While apline loop
	GOTO APWH_loop

APWH_End:
IF @openAPWH = 1
BEGIN
	CLOSE bcAPWH
	DEALLOCATE bcAPWH
	SELECT @openAPWH = 0
END

  
-- Delete Loop
DECLARE bcDelete CURSOR FOR
SELECT BatchSeq
FROM bAPPB
WHERE Co = @co AND Mth = @mth AND BatchId = @batchid
   
OPEN bcDelete
Delete_loop:
	FETCH NEXT FROM bcDelete INTO @batchseq
	IF @@fetch_status <> 0 GOTO Delete_end
	SELECT @paysum = 0
	SELECT @paysum = sum(Amount - DiscTaken)
	FROM bAPDB WITH (NOLOCK)
	WHERE Co = @co AND Mth = @mth AND BatchId = @batchid AND BatchSeq = @batchseq
	
	IF @paysum <= 0  -- remove any Payment Batch entries with negative or zero totals
	BEGIN
		DELETE FROM bAPDB WHERE Co = @co 
							AND Mth = @mth 
							AND BatchId = @batchid 
							AND BatchSeq = @batchseq
		DELETE FROM bAPTB WHERE Co = @co 
							AND Mth = @mth 
							AND BatchId = @batchid 
							AND BatchSeq = @batchseq
		DELETE FROM bAPPB WHERE Co = @co 
							AND Mth = @mth 
							AND BatchId = @batchid 
							AND BatchSeq = @batchseq
		SELECT @rcode = 2, 
			   @msg = ' Some payment sequences could not be created because they were for negative or zero amounts.',
			   @rcode= 7
	END
	
	ELSE
	BEGIN
   		SELECT @expmth = min(ExpMth) 
   		FROM bAPTB WITH (NOLOCK) 
   		WHERE Co = @co AND Mth = @mth AND BatchId = @batchid AND BatchSeq = @batchseq
	   	
   		WHILE @expmth IS NOT NULL
   		BEGIN --While expmth loop Delete
   			SELECT @aptrans = min(APTrans) 
   			FROM bAPTB WITH (NOLOCK) 
   			WHERE Co = @co 
   				AND Mth = @mth
   				AND BatchId = @batchid 
   				AND BatchSeq = @batchseq 
   				AND ExpMth = @expmth
   			WHILE @aptrans IS NOT NULL
   			BEGIN --While aptrans loop Delete
   				DELETE FROM bAPWH 
   				WHERE APCo = @co AND UserId = @username AND Mth = @expmth AND APTrans = @aptrans
		   		
   				SELECT @aptrans = min(APTrans) 
   				FROM bAPTB WITH (NOLOCK) 
   				WHERE Co = @co 
   					AND Mth = @mth 
   					AND BatchId = @batchid 
   					AND BatchSeq = @batchseq
   					AND ExpMth = @expmth 
   					AND APTrans > @aptrans
   			END --While aptrans loop Delete
	   	
   		SELECT @expmth = min(ExpMth) 
   		FROM bAPTB WITH (NOLOCK) 
   		WHERE Co = @co AND Mth = @mth AND BatchId = @batchid AND BatchSeq = @batchseq AND ExpMth > @expmth
		
		END --While expmth loop Delete
END --Delete_loop
GOTO Delete_loop
   
Delete_end:
CLOSE bcDelete
DEALLOCATE bcDelete
   
IF @updateAPTDDisc = 'Y'
BEGIN --UpdateAPTDDisc
	SELECT @expmth = min(Mth) 
	FROM bAPWH WITH (NOLOCK) 
	WHERE APCo = @co AND UserId = @username AND PayYN = 'N' AND DiscCancelDate IS NOT NULL

	WHILE @expmth IS NOT NULL
	BEGIN --While expmth loop
		SELECT @aptrans = min(APTrans) 
		FROM bAPWH WITH (NOLOCK) 
		WHERE APCo = @co AND UserId = @username AND Mth = @expmth AND PayYN = 'N' AND DiscCancelDate IS NOT NULL
	
		WHILE @aptrans IS NOT NULL
		BEGIN --While aptrans loop
			UPDATE bAPTD SET DiscTaken = w.DiscTaken 
						FROM bAPWD w 
						JOIN bAPTD t ON t.APCo = w.APCo 
									 AND t.Mth = w.Mth
									 AND t.APTrans = w.APTrans 
									 AND t.APLine = w.APLine
									 AND t.APSeq = w.APSeq 
						WHERE t.APCo = @co AND t.Mth = @expmth AND t.APTrans = @aptrans
	  
			SELECT @aptrans = min(APTrans) 
			FROM bAPWH WITH(NOLOCK) 
			WHERE APCo = @co
			  AND UserId = @username 
			  AND Mth = @expmth 
			  AND PayYN = 'N'
			  AND DiscCancelDate IS NOT NULL 
			  AND APTrans > @aptrans
		END --While aptrans loop
	
		SELECT @expmth = min(Mth) 
		FROM bAPWH WITH (NOLOCK) 
		WHERE APCo = @co 
			AND UserId = @username 
			AND PayYN = 'N' 
			AND DiscCancelDate IS NOT NULL 
			AND Mth > @expmth
	END --While expmth loop
END --UpdateAPTDDisc
			 
DELETE FROM bAPWH 
WHERE APCo = @co 
	AND UserId = @username 
	AND PayYN = 'N'
   
bspexit:
IF @openAPWH = 1
BEGIN
	CLOSE bcAPWH
	DEALLOCATE bcAPWH
END
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPPBInitFromWorkFile] TO [public]
GO
