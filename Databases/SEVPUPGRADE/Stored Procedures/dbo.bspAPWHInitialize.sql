SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspAPWHInitialize]

/***********************************************************
* CREATED BY: MV 10/16/01
* MODIFIED BY:kb 06/06/02 - #17588
*           kb 06/07/02 - #14160
*           kb 06/24/02 - #14160 - for notes update
*			kb 07/25/02 - #18096 - was not including trans based on cancelifdiscdate flag in error
*			kb 07/30/02 - #18141 - now will get prepaids that have been processed with open amounts
*			kb 07/30/02 - #18096 - to update discounts to APTD if they cancelled
*			kb 07/31/02 - #18149 - don't init to be paid if compliance checking and not complied
*			MV 12/03/02 - #18897 - Add conditions when DiscDate is compared to @sendduedate. 
*			MV 01/08/03 - #18897 - rej 1 fix	
*			MV 01/15/03 - #17821 - all invoice compliance
*			MV 07/23/03 - #21605 - don't flag to pay if APTD due date > sendduedate
*			MV 11/06/03 - #22959 - @cancelifdiscdate >= h.DiscDate
*			MV 11/12/03 - #22985 - don't flag to pay if discdate > sendduedate if use discdate checked
*			MV 11/17/03 - #22814 - include if discount is negative 'usediscdate = 'Y' and d.DiscTaken <> 0'
*			MV 01/09/04 - #23466 - don't flag to pay if SL out of compliance
*			MV 02/25/04 - #23664 - if DiscOnly is Y compare DiscTaken not DiscOffer amount
*			ES 03/12/04 - #23061 - ISNULL wrapping
*			MV 05/14/04 - #24277 - SELECT by CM Acct
*			MV 07/09/04 - #25076 - change @userid to bVPUserName
*			MV 01/04/07 - #28268 - 6X recode - if @sendpaytype = '' make it NULL
*			MV 01/05/07 - #121528 - Insert SeparatePayYN from APTH into APWH
*			MV 01/11/07 - #122337 - Compliance flag, track compl in detail
*			MV 03/13/07 - #28268 - separate @sendjcco FROM @sendjob
*			MV 04/23/07 - #28267 - improved check for trans already in a pay workfile
*			MV 10/12/07 - #125395 - don't write the UniqueAttchID from bAPTH to bAPWH
*			MV 08/28/08	- #127687 - and (@cancelifdiscdate is NULL or @cancelifdiscdate **<=** ISNULL(h.DiscDate,''))
*			MV 09/29/08 - #129923 - NULL out dates passed from form if they are empty strings.
*			MV 02/03/09 - #122906 - exclude vendors with a credit balance
*			DC 02/11/09 - #132186 - Add an APRef field in SL Compliance associated to AP Ref in Accounts payable
*			MV 03/17/09 - #132459 - Set Detail PayYN flag to 'N' if @cmacct is NULL
*			GP 06/28/10 - #135813 - change bSL to varchar(30) 
*			TRL 07/27/11 - TK-07143 - Expand bPO parameters/varialbles to varchar(30)
*			KK 01/12/12 - TK-11581 - Added new input @sendpaymethodcreditservice for Credit Service enhancement
* USAGE:
* Called by the AP Payment Control form (frmAPPAYWorkfile) to create new payment
* workfile entries.  Finds all 'open'and 'onhold' transactions meeting the restrictions
* passed to this procedure.
*
*  INPUT PARAMETERS
*  @co                 AP Company
*  @sendvendor         Vendor - if NULL, all Vendors
*  @sendjcco           JC Co# - if NULL, all JC Companies
*  @sendjob            Job - if NULL, all jobs
*  @restrictbypaycontrol 'Y' = restrict by payment control,if NULL all payment control codes
*  @sendpaycontrol     Payment Control - if NULL, all Payment Control codes
*  @sendpaytype        Payable Types - string of comma separated Pay Types - if NULL, all
*  @includeonhold      'Y' = include onhold payments too, status < 3
*  @sendpaymethodcheck 'Y' = include checks
*  @sendpaymethodeft  'Y' = include EFT payments
*  @sendpaymethodcreditservice 'Y' = include payments made by Credit Services
*  @sendduedate        Due Date - include trans due as of this date
*  @usediscdate       'Y' = if available, use Discount Date, 'N' = use due date
*  @disconly           'Y' = dicounted trans only, 'N' = all trans
*  @alldisc            'Y' = take all discounts, 'N' = cancel if past discount date (not used?????)
*  @cancelifdiscdate   Cancel if Discount Date is prior to this date - take all discounts if NULL
*  @dfltcmacct         Optional. The default cmacct to use if missing in APTH
*  @initializetobepaid 'Y' = set PayYN = 'Y' in APPW transactions for open lines/seq
*  @sendvendorgroup    Vendor Group - qualifies Vendor
*  @separtepayjobyn    'Y' = set SeparatePayJobYN = 'Y' in APPW
*  @separatepayslyn    'Y' = set SeparatePaySLYN = 'Y' in APPW
*  @userid              set UserId = user database login
*
* OUTPUT PARAMETERS
*  @msg                error message if error occurs
*
* RETURN VALUE
*  0                   success
*  1                   failure
************************************************************/      
(@co bCompany, 
 @sendvendor bVendor = NULL,
 @sendjcco bCompany = NULL, 
 @sendjob bJob = NULL,
 @restrictbypaycontrol bYN = NULL, 
 @sendpaycontrol varchar(10) = NULL, 
 @sendpaytype varchar(200) = NULL,
 @includeonhold bYN = NULL, 
 @sendpaymethodcheck bYN = NULL, 
 @sendpaymethodeft bYN = NULL,
 @sendpaymethodcreditservice bYN = NULL,
 @sendduedate bDate = NULL, 
 @usediscdate bYN = NULL, 
 @disconly bYN = NULL,
 @alldisc bYN = NULL,
 @cancelifdiscdate bDate = NULL, 
 @dfltcmacct bCMAcct, 
 @initializetobepaid bYN = NULL,
 @sendvendorgroup bGroup = NULL,
 @separtepayjobyn bYN,
 @separatepayslyn bYN,
 @userid bVPUserName,
 @sendapref bAPReference = NULL,
 @restrictbycmacct bYN,
 @sendcmacct bCMAcct = NULL, 
 @checktopaycomplianceyn bYN,
 @excludevendorcreditYN bYN, 
 @msg varchar(500) OUTPUT)

AS
SET NOCOUNT ON
      
DECLARE @rcode int, 
		@openTransCheck tinyint, 
		@paycontrol varchar (10), 
		@payyn bYN,
		@mth bMonth, 
		@aptrans bTrans, 
		@vendorgroup bGroup, 
		@vendor bVendor,
		@onhold bYN,
		@discdate bDate, 
		@paymethod char(1),
		@openLineCheck tinyint, 
		@detail bYN, 
		@holdyn bYN,
		@apline smallint,
		@linetype tinyint, 
		@jcco bCompany, 
		@job bJob, 
		@cmco bCompany,
		@COUNT int,
		@cmacct bCMAcct, 
		@cscmacct bCMAcct,
		@openDetailCheck tinyint,
		@paytype tinyint, 
		@disctaken bDollar,
		@duedate bDate, 
		@savesupplier bVendor, 
		@openAddDetail tinyint, 
		@payamt bDollar,
		@apseq tinyint,
		@status tinyint, 
		@supplier bVendor, 
		@unpaidamt bDollar, 
		@amount bDollar,
		@discoffered bDollar, 
		@validcnt int, 
		@validcnt2 int, 
		@openTransDetail tinyint, 
		@inpaycontrol bYN, 
		@DontAllowPaySL bYN, 
		@DontAllowPayPO bYN, 
		@po varchar(30), 
		@rc tinyint, 
		@POSLComply bYN, 
		@sl varchar(30),
		@invdate bDate, 
		@DontAllowPayAllinv bYN, 
		@VendorComply bYN, 
		@APTDduedate bDate, 
		@separatepayyn bYN,
		@apref bAPReference  --DC #132186
      
SELECT @rcode = 0, @holdyn = 'N', @payyn = 'N', @COUNT = 0, @POSLComply='Y', @VendorComply = 'Y'
	
IF @restrictbypaycontrol IS NULL SELECT @restrictbypaycontrol = 'N'
IF @includeonhold IS NULL SELECT @includeonhold = 'N'
IF @sendpaymethodcheck IS NULL SELECT @sendpaymethodcheck = 'N'
IF @sendpaymethodeft IS NULL SELECT @sendpaymethodeft = 'N'
IF @sendpaymethodcreditservice IS NULL SELECT @sendpaymethodcreditservice = 'N'
IF @usediscdate IS NULL SELECT @usediscdate = 'N'
IF @disconly IS NULL SELECT @disconly = 'N'
IF @alldisc IS NULL SELECT @alldisc = 'N'
IF @initializetobepaid IS NULL SELECT @initializetobepaid = 'N'
IF @separtepayjobyn IS NULL SELECT @separtepayjobyn = 'N'
IF @separatepayslyn IS NULL SELECT @separatepayslyn = 'N'
IF @restrictbycmacct IS NULL SELECT @restrictbycmacct = 'N'
IF @sendpaytype = '' SELECT @sendpaytype = NULL
-- IF @sendjob IS NULL SELECT @sendjcco = NULL
IF @checktopaycomplianceyn IS NULL SELECT @checktopaycomplianceyn = 'Y'
IF @sendduedate = '' SELECT @sendduedate = NULL
IF @cancelifdiscdate = '' SELECT @cancelifdiscdate = NULL
IF @excludevendorcreditYN IS NULL SELECT @excludevendorcreditYN = 'N'
    
-- get info from AP Company
SELECT @DontAllowPaySL = SLAllowPayYN, 
	   @DontAllowPayPO = POAllowPayYN, 
	   @DontAllowPayAllinv = AllAllowPayYN,
	   @cscmacct = CSCMAcct --Credit Service CMAcct
FROM APCO WITH (NOLOCK) WHERE APCo = @co
      
TransCheck:
-- create a CURSOR on Transactions matching criteria passed to this procedure
DECLARE bcTransCheck CURSOR LOCAL FAST_FORWARD FOR
SELECT DISTINCT h.Mth, 
				h.APTrans, 
				h.VendorGroup, 
				h.Vendor, 
				h.DiscDate, 
				h.DueDate, 
				h.PayControl,
				h.PayMethod, 
				h.CMCo, 
				h.CMAcct, 
				h.InPayControl, 
				InvDate, 
				h.SeparatePayYN,
				h.APRef  --DC #132186
FROM bAPTH h WITH (NOLOCK) 
JOIN bAPTD d ON d.APCo = h.APCo 
		    AND d.Mth = h.Mth 
	 	    AND d.APTrans = h.APTrans
WHERE h.APCo = @co 
		AND h.VendorGroup = ISNULL(@sendvendorgroup, h.VendorGroup)
		AND (h.Vendor = ISNULL(@sendvendor, h.Vendor))
		AND (ISNULL(h.APRef,'') = ISNULL(ISNULL(@sendapref, h.APRef),''))
		AND ( (@restrictbycmacct = 'Y' AND ISNULL(h.CMAcct,'') = ISNULL(@sendcmacct,''))
		   OR (@restrictbycmacct = 'N'))	--24277
		AND ( (@restrictbypaycontrol='Y' 
			   AND ISNULL(h.PayControl,'') = ISNULL(@sendpaycontrol,''))
		   OR (@restrictbypaycontrol='N' 
			   AND ISNULL(h.PayControl,'') = ISNULL(ISNULL(@sendpaycontrol,h.PayControl),'')))
		AND ( (@usediscdate = 'N'AND h.DueDate <= ISNULL(@sendduedate, h.DueDate))	--18897
		   OR (@usediscdate = 'Y' AND d.DiscTaken = 0 AND h.DueDate <= ISNULL(@sendduedate, h.DueDate))
		   OR (@usediscdate = 'Y' 
			   AND @cancelifdiscdate IS NOT NULL 
			   AND h.DiscDate IS NOT NULL
			   AND @cancelifdiscdate >= h.DiscDate
			   AND h.DueDate <= ISNULL(@sendduedate, h.DueDate))
		   OR (@usediscdate = 'Y' 
			   AND d.DiscTaken <> 0
			   AND (@cancelifdiscdate IS NULL OR @cancelifdiscdate <= ISNULL(h.DiscDate,'')) 
			   AND CASE WHEN h.DiscDate IS NULL THEN h.DueDate 
					    ELSE h.DiscDate 
				   END <=ISNULL(@sendduedate, h.DueDate) ) )
		-- AND ((((@usediscdate='Y' AND h.DiscDate IS not NULL AND h.DiscDate <= ISNULL(ISNULL(@sendduedate, h.DueDate),'')))
		-- or ((@usediscdate='Y' AND h.DiscDate is NULL AND ISNULL(h.DueDate,'') <= ISNULL(ISNULL(@sendduedate, h.DueDate),''))))
		-- or (@usediscdate='N' AND ISNULL(h.DueDate,'') <= ISNULL(ISNULL(@sendduedate, h.DueDate),'')))
		AND ( (h.PayMethod = 'C' AND @sendpaymethodcheck = 'Y')
		   OR (h.PayMethod = 'E' AND @sendpaymethodeft = 'Y')
		   OR (h.PayMethod = 'S' AND @sendpaymethodcreditservice = 'Y'))
		AND (h.OpenYN = 'Y')
		AND (h.InUseMth IS NULL AND h.InUseBatchId IS NULL)
		AND ( (h.PrePaidYN = 'N') 
		   OR (h.PrePaidYN = 'Y' AND h.PrePaidProcYN = 'Y'))
		-- AND (h.PrePaidYN <> 'Y') --issue #18141
  		
OPEN bcTransCheck
SELECT @openTransCheck = 1
  
TransCheck_loop:
	FETCH NEXT FROM bcTransCheck 
			 INTO @mth, 
				  @aptrans, 
				  @vendorgroup, 
				  @vendor, 
				  @discdate, 
				  @duedate,
				  @paycontrol, 
				  @paymethod,
				  @cmco, 
				  @cmacct, 
				  @inpaycontrol, 
				  @invdate, 
				  @separatepayyn,
				  @apref  --DC #132186 
  
	IF @@fetch_status <> 0 GOTO TransCheck_end

	-- IF trans is already in a workfile, to to next
	IF EXISTS(SELECT 1 FROM bAPWH WITH (NOLOCK) 
			   WHERE APCo = @co AND Mth = @mth AND APTrans = @aptrans)
	BEGIN
		GOTO TransCheck_loop
	END
  
	IF @inpaycontrol = 'Y' 
		AND NOT EXISTS(SELECT * FROM APWH 
						WHERE APCo = @co AND Mth = @mth AND APTrans = @aptrans AND UserId = @userid)
	BEGIN
		GOTO TransCheck_loop
	END

    IF @cmacct IS NULL
    BEGIN
		IF @paymethod IN ('C','E') AND @dfltcmacct IS NOT NULL SELECT @cmacct = @dfltcmacct
		ELSE IF @paymethod = 'S' AND @cscmacct IS NOT NULL SELECT @cmacct = @cscmacct
		ELSE SELECT @cmacct = NULL
	END    
    
    SELECT @payamt = 0, @unpaidamt = 0
  
    SELECT @validcnt = COUNT(*) FROM bAPTD WITH (NOLOCK)
	 WHERE APCo = @co AND Mth = @mth AND APTrans = @aptrans AND Status < 3

	IF @validcnt = 0 GOTO TransCheck_loop
  
  	/*Check if all detail is on hold before writing out APWH header.*/
  	IF @includeonhold = 'N'
  	BEGIN
  	    SELECT @validcnt2 = COUNT(*) FROM bAPTD WITH (NOLOCK)
		 WHERE APCo = @co AND Mth = @mth AND APTrans = @aptrans AND Status = 2
		IF @validcnt2 = @validcnt goto TransCheck_loop
  	END
  	
	IF @sendjcco IS NOT NULL
	BEGIN
		SELECT @validcnt = COUNT(*) FROM bAPTL l WITH (NOLOCK)
		JOIN bAPTD d ON l.APCo = d.APCo 
					AND l.Mth = d.Mth 
					AND l.APTrans = d.APTrans
					AND l.APLine = d.APLine
		 WHERE l.APCo = @co 
			   AND l.Mth = @mth 
			   AND l.APTrans = @aptrans
			   AND d.Status < 3
			   AND l.JCCo = @sendjcco
  
		IF @validcnt = 0 GOTO TransCheck_loop
	END

	IF @sendjob IS NOT NULL
	BEGIN
		SELECT @validcnt = COUNT(*) FROM bAPTL l WITH (NOLOCK)
		JOIN bAPTD d ON l.APCo = d.APCo 
					AND l.Mth = d.Mth 
					AND l.APTrans = d.APTrans
					AND l.APLine = d.APLine
         WHERE l.APCo = @co 
			   AND l.Mth = @mth 
			   AND l.APTrans = @aptrans
			   AND d.Status < 3
			   AND (l.JCCo = @sendjcco 
			   AND l.Job = @sendjob)
		IF @validcnt = 0 GOTO TransCheck_loop
	END

	IF @sendpaytype IS NOT NULL
    BEGIN
		SELECT @validcnt = COUNT(*) FROM bAPTD WITH (NOLOCK) 
		 WHERE APCo = @co 
			   AND Mth = @mth 
			   AND APTrans = @aptrans 
			   AND Status < 3 
			   AND charindex(',' + ISNULL(CONVERT(varchar(3), PayType), '') + ',',@sendpaytype) > 0  --#23061
        IF @validcnt = 0 GOTO TransCheck_loop
    END
  
	IF @disconly = 'Y'
	BEGIN
		SELECT @validcnt = COUNT(*) FROM bAPTD WITH (NOLOCK)
		 WHERE APCo = @co 
			   AND Mth = @mth
               AND APTrans = @aptrans 
               AND /*DiscOffer #23664*/ DiscTaken <> 0 
               AND Status = 1
        IF @validcnt = 0 GOTO TransCheck_loop
    END

	--Check for credit vendor balance
	IF @excludevendorcreditYN = 'Y' 
	BEGIN
		SELECT @payamt = sum(d.Amount) FROM bAPTD d 
		JOIN bAPTH h ON d.APCo=h.APCo 
					AND d.Mth=h.Mth	
					AND d.APTrans=h.APTrans
		 WHERE d.Status IN (1, 2) 
			   AND d.APCo= @co 
			   AND h.VendorGroup = @vendorgroup 
			   AND h.Vendor=@vendor 
		IF @payamt <= 0 GOTO TransCheck_loop
	END
			
	-- Check Vendor compliance 
	SELECT @VendorComply = 'Y'
	EXEC @rc = bspAPComplyCheckAll @co,@vendorgroup, @vendor, @invdate,@VendorComply OUTPUT
--  SELECT @validcnt = COUNT(*) FROM bAPWH WITH (NOLOCK) WHERE APCo = @co AND Mth = @mth
--  AND APTrans = @aptrans
--	IF @validcnt = 0
	IF NOT EXISTS(SELECT 1 FROM bAPWH WITH (NOLOCK) 
				   WHERE APCo = @co AND Mth = @mth AND APTrans = @aptrans) 
    BEGIN
		INSERT bAPWH
			   (APCo,			UserId,				Mth, 
				APTrans,		PayYN,				UnpaidAmt,
				PayAmt,			DiscDate,			DueDate, 
				PayControl,		PayMethod,			CMCo, 
				CMAcct,			HoldYN,				VendorGroup, 
				Supplier,		SeparatePayJobYN,	SeparatePaySLYN,
				TakeAllDiscYN,	DiscCancelDate,		ManualAddYN,
				Notes,			CompliedYN,			SeparatePayYN)
				     
		SELECT @co,				@userid,			@mth, 
			   @aptrans,		'N',				0,
			   0,				@discdate,			@duedate,
			   @paycontrol,		@paymethod,			@cmco, 
			   @cmacct,			'N',				@vendorgroup,
			   @savesupplier,   @separtepayjobyn,   @separatepayslyn, 
			   @alldisc,		@cancelifdiscdate,	'N', 
			   Notes,			@VendorComply,		@separatepayyn  
		FROM bAPTH WHERE APCo = @co 
					 AND Mth = @mth 
					 AND APTrans = @aptrans
    
		SELECT @COUNT = @COUNT + 1
    END
  
	DECLARE bcDetail CURSOR LOCAL FAST_FORWARD FOR
	SELECT d.APLine, d.APSeq, l.LineType, l.PO, l.SL, d.DueDate, d.Status
 	FROM bAPTD d WITH (NOLOCK) 
 	JOIN bAPTL l WITH (NOLOCK) ON l.APCo = d.APCo 
 						      AND l.Mth = d.Mth
 						      AND l.APTrans = d.APTrans 
 						      AND l.APLine = d.APLine
     WHERE d.APCo = @co 
		   AND d.Mth = @mth 
		   AND d.APTrans = @aptrans
		   AND (@sendjcco IS NULL OR (JCCo IS NOT NULL 
									  AND @sendjcco IS NOT NULL 
									  AND JCCo = @sendjcco))
           AND (@sendjob IS NULL OR (Job IS NOT NULL 
									 AND @sendjob IS NOT NULL
									 AND Job = @sendjob))
           AND (@sendpaytype IS NULL 
				OR (@sendpaytype IS NOT NULL 
					AND charindex(',' + ISNULL(convert(varchar(3), d.PayType), '') + ',',@sendpaytype) > 0))
           AND (d.Status =1 OR (d.Status = 2 AND @includeonhold = 'Y'))  --#23061
  
	OPEN bcDetail
	SELECT @openTransDetail = 1
  
	Detail_loop:
    FETCH NEXT FROM bcDetail INTO @apline, @apseq, @linetype, @po, @sl, @APTDduedate, @status
  
		IF @@fetch_status <> 0 GOTO Detail_end
 
		--Check line level PO/SL compliance 
		SELECT @POSLComply ='Y'
		IF @linetype = 6 or @linetype=7 
		BEGIN
			EXEC @rc = bspAPComplyCheck @co, @mth, @aptrans, 
										@apline, @invdate, 
										@apref, @msg OUTPUT  --DC #132186
			IF @rc <> 0	-- IF rc <> 0 the line did not comply
			BEGIN 
				SELECT @POSLComply = 'N'
			END
		END
  
		-- set PayYN flag 
		IF @initializetobepaid = 'N' OR @status = 2 OR @cmacct IS NULL
		BEGIN
			SELECT @payyn = 'N'
		END
		ELSE
		BEGIN
			IF	/*out of compl AND Don't allow in payment batch */
			(@VendorComply = 'N' AND @DontAllowPayAllinv = 'Y') 
			OR (@POSLComply = 'N' 
				AND @linetype = 6 
				AND @DontAllowPayPO = 'Y')
			OR (@POSLComply = 'N' 
				AND @linetype = 7 
				AND @DontAllowPaySL = 'Y') 
			/*out of compl AND okay to allow in payment batch but check-to-pay = N (overrides APCO flag)*/
			OR (@VendorComply = 'N' 
				AND @DontAllowPayAllinv = 'N' 
				AND @checktopaycomplianceyn = 'N') 
			OR (@POSLComply = 'N' 
				AND @linetype = 6 
				AND @DontAllowPayPO = 'N' 
				AND @checktopaycomplianceyn = 'N') 
			OR (@POSLComply = 'N' 
				AND @linetype = 7 
				AND @DontAllowPaySL = 'N' 
				AND @checktopaycomplianceyn = 'N') 
			OR ((@usediscdate = 'N' 
					AND @APTDduedate > ISNULL(@sendduedate,@APTDduedate))	
				OR (@usediscdate = 'Y'
					AND ISNULL(@discdate,@APTDduedate)> ISNULL(ISNULL(@sendduedate,@discdate),@APTDduedate)))
			SELECT @payyn = 'N'
			ELSE SELECT @payyn = 'Y'
		END 
               
        IF NOT EXISTS(SELECT 1 FROM bAPWD WITH (NOLOCK) 
					   WHERE APCo = @co
							 AND Mth = @mth 
							 AND APTrans = @aptrans 
							 AND APLine = @apline
							 AND APSeq = @apseq)
		BEGIN
 			INSERT bAPWD(APCo, Mth, APTrans, APLine, APSeq, UserId,
                 	     HoldYN,PayYN,Supplier, DiscTaken,DiscOffered, 
                 	     DueDate, VendorGroup, Amount,CompliedYN)
   	        SELECT d.APCo, d.Mth, d.APTrans, d.APLine, d.APSeq, @userid,
				    CASE WHEN d.Status = 2 THEN 'Y' 
						 ELSE 'N' 
					END,	--HoldYN	
 			 	    @payyn,d.Supplier, 
 			 	    CASE WHEN @cancelifdiscdate IS NULL THEN d.DiscTaken
  						 WHEN @discdate < ISNULL(@cancelifdiscdate,@discdate)THEN 0 
  						 ELSE d.DiscTaken 
  					END, 
  			 	    d.DiscOffer, d.DueDate, @vendorgroup,Amount,
				    CASE @VendorComply WHEN 'N' THEN @VendorComply 
									  ELSE @POSLComply 
				    END
			FROM bAPTD d WITH (NOLOCK) 
			JOIN bAPTL l ON l.APCo = d.APCo 
						AND l.Mth = d.Mth
                		AND l.APTrans = d.APTrans 
                		AND l.APLine = d.APLine
             WHERE d.APCo = @co 
				   AND d.Mth = @mth 
				   AND d.APTrans = @aptrans
                   AND d.APLine = @apline 
                   AND d.APSeq = @apseq
                   AND (@sendjcco IS NULL OR (JCCo IS NOT NULL 
											  AND @sendjcco IS NOT NULL
											  AND JCCo = @sendjcco))
                   AND (@sendjob IS NULL OR (Job IS NOT NULL 
											 AND @sendjob IS NOT NULL
                   							 AND Job = @sendjob))
                   AND (@sendpaytype IS NULL 
						OR (@sendpaytype IS NOT NULL 
							AND charindex(',' + ISNULL(convert(varchar(3), d.PayType), '') + ',',@sendpaytype) > 0))  --#23061
		END
		GOTO Detail_loop
	Detail_end:
	
	IF @openTransDetail = 1
    BEGIN
		CLOSE bcDetail
        DEALLOCATE bcDetail
    END
    
    SELECT @openTransDetail = 0
    GOTO TransCheck_loop
TransCheck_end:
CLOSE bcTransCheck
DEALLOCATE bcTransCheck
       
SELECT @openTransCheck = 0

IF @COUNT > 0
BEGIN
	SELECT @msg = convert(varchar (5), @COUNT) + ' new transactions were added to your workfile.'
END
ELSE
BEGIN
	SELECT @msg = 'no new transactions were added to your workfile.'
END
  
IF @openTransDetail = 1
BEGIN
	CLOSE bcDetail
	DEALLOCATE bcDetail
END
IF @openTransCheck = 1
BEGIN
	CLOSE bcTransCheck
	DEALLOCATE bcTransCheck
END

RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPWHInitialize] TO [public]
GO
