SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPHBPostAddDetail    Script Date: 8/28/99 9:33:59 AM ******/
   CREATE    procedure [dbo].[bspAPHBPostAddDetail]
   /***********************************************************
   * CREATED BY: GG 12/14/98
   * MODIFIED By : EN 1/23/99
   *               GG 9/15/99 - change to retainage status - not always on hold
   *               kb 1/3/2 - issue #15190
   *               kb 1/23/2 - issue #15938
   *				GG 02/21/02 - #16274 - don't add bAPTD if amount is 0.00
   *               kb 10/28/2 - issue #18878 - fix double quotes
   *				GF 08/11/2003 - issue #22112 - performance improvement
   *				MV 09/04/03 - #22188 - create APTD if misc amt or use tax
   *				MV 12/16/03 - #23158 reverse #16274 - add bAPTD if amount is 0.00
   *				MV 02/10/04 - #18769 Pay Category
   *                MV 07/01/08 - #128288 - retgGST/GST tax amount
   *				MV 09/09/08 - #128288 - Tax amount for partial payments	
   *				MV 10/20/08 - #128288 - redid PST/GST tax calc	
   *				MV 01/28/10 - #136500 - changed bAPTD TaxAmount to GSTtaxAmt
   *				MV 02/10/10 - #136500 - taxbasis net retainage GST tax calc, ExpenseGST flag
   *				MV 05/19/10 - #136500 - tweaked if/else logic for @pstrate=0
   *				MV 07/15/10 - #133107 - Check Reversal
   *				MV 11/30/10 - #141846 - Apply Tax Code Retg GST payables GL Acct only if APCO TaxBasisNetRetg is 'Y'
   *				MV 10/25/11 - TK-09243 - return @crdRetgPSTGLAcct from bspHQTaxRateGetAll
   *				MV 10/31/11 - TK-09243 - Calculate holdback/retention PST
   *				MV 08/16/12 - TK-17202 - fix GST/PST distributions when the calculated Tax Amount is overidden.
   *				MV 06/10/13 - TFS-51252 - GST incorrectly distributed on prior month check reversal
   *				MV 08/29/13	- TFS-60544 - fixed tax only invoice with 0 gross/retg/taxbasis, corrected @amt for open when retg only
   *				MV/KK 09/02/13 - TFS-60544 - modified the value retgTaxAmt gets when retainage only being processed
   *				MV 01/08/14 - TFS-69676 - fixed bug introduced in TFS-60544.  Retg only invoices should not have APTD Seq #1 amounts zeroed out. 
   *										  They must counterbalance APTD Seq #2 Retainage amounts.
   *
   * USAGE:
   * Called from bspAPHBPost procedure to add Transaction and
   * Hold Detail (bAPTD and bAPHD) entries for a Line.
   *
   * INPUT PARAMETERS:
   *   @co             AP Co#
   *   @mth            Batch Month
   *   @aptrans        AP Trans #
   *   @apline         AP Line #
   *   @paytype        Pay Type posted with Line
   *   @discount       Discount amount entered with Line
   *   @duedate        Due Date from Trans header
   *   @aptdstatus     1 if Vendor has Hold Codes, else 0 - used for APTD Status
   *   @svendorgroup   Vendor Group for supplier
   *   @supplier       Supplier entered with Line
   *   @holdcode       Hold Code entered with Trans header
   *   @grossamt       Gross Amount on Line
   *   @miscamt        Misc Amount on Line
   *   @miscyn         'Y' if Misc Amt payable on this Trans, else 'N'
   *   @taxtype        1 if Sales Tax payable on this Trans, 2 if Use Tax
   *   @taxamt         Tax Amount on Line
   *   @retainage      Retainage on Line
   *   @retpaytype     Retainage Pay Type
   *   @retholdcode    Retainage Hold Code
   *   @vendorgroup    Vendor Group for vendor
   *   @vendor         Vendor on Trans
   *   @prepaidyn      Prepaid Transaction 'Y' or 'N'
   *
   * OUTPUT PARAMETERS
   *   none
   *
   * RETURN VALUE:
   *   0               success
   *   1               fail
   *****************************************************/
  (
	@co bCompany,		@mth bMonth,		@aptrans int,			@apline smallint,		@paytype tinyint,
	@discount bDollar,	@duedate bDate,		@aptdstatus tinyint,	@svendorgroup bGroup,	@supplier bVendor,
	@holdcode bHoldCode,@grossamt bDollar,	@miscamt bDollar,		@miscyn bYN,			@taxtype tinyint,
	@taxamt bDollar,    @retainage bDollar,	@retpaytype tinyint,	@retholdcode bHoldCode,	@vendorgroup bGroup,
	@vendor bVendor,    @prepaidyn bYN,		@chkrev bYN,			@paycategory int,		@taxgroup bGroup,
	@taxcode bTaxCode
    )
   
   AS
   SET NOCOUNT ON
   
   DECLARE @rcode int, @amt bDollar, @retstatus tinyint, @seq tinyint

    -- GST/PST declares
	DECLARE @taxrate bRate,				@pstrate bRate,			@gstrate bRate,				@dbtRetgGLAcct bGLAcct,	@dbtGLAcct bGLAcct,
			@retgGstTaxAmt bDollar,		@payTaxAmt bDollar,		@retgTaxAmt bDollar,		@gstTaxAmt bDollar,		@pstTaxAmt bDollar,
			@crdRetgGSTGLAcct bGLAcct,	@expenseGstYN bYN,		@crdRetgPSTGLAcct bGLAcct,	@retgPSTTaxAmt bDollar,	@APCOTaxBasisNetRetg bYN 

    --initialize variables
   SELECT	@rcode = 0,		@seq = 0,		@taxrate=0,		@pstrate=0,				@gstrate=0,			@retgGstTaxAmt=0,	
			@retgTaxAmt=0,	@gstTaxAmt = 0, @pstTaxAmt=0,	@expenseGstYN = 'N',	@retgPSTTaxAmt = 0,	@payTaxAmt = 0

	-- get AP Company info
	SELECT @APCOTaxBasisNetRetg = TaxBasisNetRetgYN
	FROM dbo.bAPCO WITH (NOLOCK)
	WHERE APCo = @co
	
	--Calculate VAT taxes for distribution to bAPTD records
	IF ISNULL(@taxtype,0)=3 --Taxtype 3 is VAT 
    BEGIN
		--get PST/GST tax information.
		EXEC @rcode = bspHQTaxRateGetAll	@taxgroup,			@taxcode,			NULL,	NULL,
											@taxrate output,	@gstrate output,	@pstrate output,
											NULL,				NULL,				@dbtGLAcct output,
											@dbtRetgGLAcct output,		NULL,		NULL,
											@crdRetgGSTGLAcct output,	@crdRetgPSTGLAcct output
							
		-- GST is expensed to a Contra account
		IF @dbtGLAcct IS NOT NULL
		BEGIN
			/* When @pstrate = 0:  taxcode is either a VAT SingleLevel using GST only, or VAT MultiLevel with PST set to 0.00 tax rate.*/
			IF @pstrate = 0 
			BEGIN
				-- Retainage GST is expensed to a Contra account
				IF @dbtRetgGLAcct IS NOT NULL
				BEGIN
					IF  ISNULL(@APCOTaxBasisNetRetg, 'N') = 'N' or @chkrev = 'Y' --#133107 Check reversal on GST
					BEGIN -- GST tax basis is not net of retainage - calculate on full gross
						SELECT @retgTaxAmt = @retainage * @taxrate --TK-17202 case @grossamt when 0 then 0 else (@retainage/@grossamt) * @taxamt end
						SELECT @gstTaxAmt = @taxamt - @retgTaxAmt 
						SELECT @taxamt = @gstTaxAmt
						SELECT @retgGstTaxAmt = @retgTaxAmt
					END
					
					ELSE  -- GST tax basis is net of retainage. Retainage tax is not included in tax amt.
					BEGIN
						SELECT @retgTaxAmt = @retainage * @taxrate --TK-17202 case @grossamt when 0 then 0 else (@retainage/@grossamt) * @taxamt end
						SELECT @gstTaxAmt = @taxamt -- Tax was calculated on taxbasis net retainage in the form
						SELECT @retgGstTaxAmt = @retgTaxAmt
					END
				END
				IF @dbtRetgGLAcct IS NULL -- Retainage GST is not expensed to a Contra account separate from GST
				BEGIN
					SELECT @gstTaxAmt = @taxamt - @retgTaxAmt
					SELECT @taxamt = @taxamt - @retgTaxAmt
					SELECT @retgGstTaxAmt = @retgTaxAmt
				END
				IF @APCOTaxBasisNetRetg = 'Y' AND (@crdRetgGSTGLAcct IS NOT NULL OR @crdRetgPSTGLAcct IS NOT NULL)
				BEGIN
					SELECT @expenseGstYN = 'Y' 
				END
			END
			
			ELSE
			BEGIN -- PST/GST taxcode is a VAT MultiLevel with PST and GST taxcodes assigned to it.
				-- tax basis is not net of retainage - calculate on full gross
				IF  ISNULL(@APCOTaxBasisNetRetg, 'N') = 'N' or @chkrev = 'Y' 
				BEGIN
					IF @dbtRetgGLAcct IS NOT NULL -- Retainage GST is broken out into it's own amount.
					BEGIN
						SELECT @retgTaxAmt = @retainage * @taxrate --TK-17202 case @grossamt when 0 then 0 else (@retainage/@grossamt) * @taxamt end
					END
					
					SELECT @payTaxAmt = @taxamt - @retgTaxAmt 
					SELECT @gstTaxAmt = case @taxrate when 0 then 0 else (@payTaxAmt * @gstrate) / @taxrate end	
					SELECT @pstTaxAmt = @payTaxAmt - @gstTaxAmt	
					SELECT @retgGstTaxAmt = case @taxrate when 0 then 0 else (@retgTaxAmt * @gstrate) / @taxrate end
					SELECT @retgPSTTaxAmt = @retgTaxAmt - @retgGstTaxAmt
					SELECT @taxamt = @payTaxAmt
				END
				
				ELSE -- taxbasis is net of holdback/retention.  Tax amt does not include holdback/retention tax
				BEGIN
					SELECT @payTaxAmt = @taxamt
					SELECT @gstTaxAmt = (@payTaxAmt * @gstrate)/@taxrate 	
					SELECT @pstTaxAmt = @payTaxAmt - @gstTaxAmt 	
					SELECT @retgGstTaxAmt = @retainage * @gstrate
					SELECT @retgPSTTaxAmt = @retainage * @pstrate
					SELECT @retgTaxAmt = @retgGstTaxAmt + @retgPSTTaxAmt
				END
				IF @APCOTaxBasisNetRetg = 'Y' AND (@crdRetgGSTGLAcct IS NOT NULL OR @crdRetgPSTGLAcct IS NOT NULL)SELECT @expenseGstYN = 'Y'       
			END
			
		END -- End @dbtGLAcct IS NOT NULL
    END -- end VAT tax type
    
   -- add AP Detail for Pay Type - Seq #1 - Amt may include MiscAmt and Tax, but excludes Retainage
	SELECT @amt = ISNULL(@grossamt,0) 
			+ CASE @miscyn WHEN 'Y' THEN ISNULL(@miscamt,0) ELSE 0 END
			+ CASE @taxtype WHEN 2 THEN 0 ELSE ISNULL(@taxamt,0) END - ISNULL(@retainage,0)
   -- write out Open APTD
   	SELECT @seq = 1	
   	INSERT INTO dbo.bAPTD
   						(
   							APCo,		Mth,			APTrans,	APLine,			APSeq,		PayType,		Amount,		DiscOffer,
   							DiscTaken,	DueDate,		Status,		PaidMth,		PaidDate,	CMCo,			CMAcct,		CMRef,
   							CMRefSeq,	VendorGroup,	Supplier,	PayCategory,	GSTtaxAmt,	TotTaxAmount,	ExpenseGST,	PSTtaxAmt
   						)
   	VALUES	
   						(	@co,		@mth,			@aptrans,	@apline,		@seq,		@paytype,		@amt,		@discount,
   							@discount,	@duedate,		@aptdstatus,null,			null,		null,			null,		null, 
   							null,		@svendorgroup,	@supplier,	@paycategory,	@gstTaxAmt,	@taxamt,		'N',		@pstTaxAmt
   						)
   
       -- add Transaction Hold Code
       IF @holdcode is not null
       BEGIN
           INSERT INTO bAPHD	(
								APCo, Mth, APTrans, APLine, APSeq, HoldCode
								)
           VALUES	(
					@co, @mth, @aptrans, @apline, @seq, @holdcode
					)
       END
       -- add Vendor Hold Codes 
       IF @prepaidyn = 'N' -- #15190 - don't add if prepaid
       BEGIN
           INSERT INTO bAPHD(APCo, Mth, APTrans, APLine, APSeq, HoldCode)
           SELECT d.APCo, d.Mth, d.APTrans, d.APLine, d.APSeq, v.HoldCode
           FROM bAPTD d WITH (NOLOCK)
           JOIN bAPVH v WITH (NOLOCK) on d.APCo = v.APCo
           WHERE d.APCo = @co and d.Mth = @mth and d.APTrans = @aptrans and d.APLine = @apline and d.APSeq = @seq
				AND v.VendorGroup = @vendorgroup and v.Vendor = @vendor
				AND NOT EXISTS 
					(
						SELECT TOP 1 1 
						FROM bAPHD d2 WITH (NOLOCK) 
						WHERE d2.APCo = d.APCo and d2.Mth = d.Mth
							AND d2.APTrans = d.APTrans and d2.APLine = d.APLine and d2.APSeq = d.APSeq and d2.HoldCode = v.HoldCode
					)
           -- add PO Hold Code
           SELECT @holdcode = HoldCode
		   FROM bPOHD p WITH (NOLOCK) 
   			JOIN bAPTL l WITH (NOLOCK) ON p.POCo = l.APCo and p.PO = l.PO 
			WHERE l.APCo = @co and l.Mth = @mth 
   				and l.APTrans = @aptrans and l.APLine = @apline and p.HoldCode is not null
           IF @@ROWCOUNT > 0
           BEGIN
               IF NOT EXISTS
							(
								SELECT TOP 1 1 
								FROM bAPHD WITH (NOLOCK) 
								WHERE APCo = @co and Mth = @mth
   								and APTrans = @aptrans and APLine = @apline and APSeq = @seq and HoldCode = @holdcode
							)
                BEGIN
					INSERT bAPHD (APCo, Mth, APTrans, APLine, APSeq, HoldCode)
					SELECT @co, @mth, @aptrans, @apline, @seq, @holdcode
                END
           END
   
   			-- add SL Hold Code
   			SELECT @holdcode = HoldCode
			FROM bSLHD p WITH (NOLOCK)
   			JOIN bAPTL l WITH (NOLOCK) on p.SLCo = l.APCo and p.SL = l.SL 
			WHERE l.APCo = @co and l.Mth = @mth 
   				and l.APTrans = @aptrans and l.APLine = @apline and p.HoldCode is not null
			IF @@ROWCOUNT > 0
			BEGIN
				IF NOT EXISTS	(
								SELECT TOP 1 1 
								FROM bAPHD WITH (NOLOCK) 
								WHERE APCo = @co and Mth = @mth
   								AND APTrans = @aptrans and APLine = @apline and APSeq = @seq and HoldCode = @holdcode
								)
				BEGIN
					INSERT bAPHD (APCo, Mth, APTrans, APLine, APSeq, HoldCode)
					SELECT @co, @mth, @aptrans, @apline, @seq, @holdcode
				END
			END
        END
 
   
   -- add AP Detail for Retainage - next Seq #
   IF @retainage <> 0 AND @retpaytype IS NOT NULL
   BEGIN
		--select @seq = @seq + 1, @retstatus = 2   -- default status is 'hold'
   		SELECT @seq = @seq + 1, @retstatus = CASE WHEN @chkrev ='Y' THEN 1 ELSE 2 END   -- 17663 don't put paid retainage on hold
   		
       -- if prepaid transaction, use transaction status
       IF  @prepaidyn = 'Y' SELECT @retstatus = @aptdstatus
   
       INSERT INTO dbo.bAPTD
						(
   							APCo,		Mth,			APTrans,	APLine,			APSeq,		PayType,		Amount,		DiscOffer,
   							DiscTaken,	DueDate,		Status,		PaidMth,		PaidDate,	CMCo,			CMAcct,		CMRef,
   							CMRefSeq,	VendorGroup,	Supplier,	PayCategory,	GSTtaxAmt,	TotTaxAmount,	ExpenseGST,	PSTtaxAmt
   						)
       VALUES			(
							@co,		@mth,			@aptrans,	@apline,		@seq,			@retpaytype,	(@retainage + isnull(@retgTaxAmt,0)), 0,
							0,			@duedate,		@retstatus, null,			null,			null,			null,			null, 
							null,		@svendorgroup,	@supplier,	@paycategory,	@retgGstTaxAmt, @retgTaxAmt,	@expenseGstYN,	@retgPSTTaxAmt
						)
   
       IF @retstatus = 2
       BEGIN
           -- add AP Hold Detail for Retainage
           IF @retholdcode IS NOT NULL
           BEGIN
               INSERT INTO bAPHD(APCo, Mth, APTrans, APLine, APSeq, HoldCode)
               VALUES (@co, @mth, @aptrans, @apline, @seq, @retholdcode)
           END
   
           -- add Transaction Hold Code
           IF @holdcode IS NOT NULL AND @holdcode <> @retholdcode
           BEGIN
               INSERT INTO bAPHD(APCo, Mth, APTrans, APLine, APSeq, HoldCode)
               VALUES(@co, @mth, @aptrans, @apline, @seq, @holdcode)
           END
   
           -- add all Vendor Hold Codes for Seq #2
           INSERT INTO bAPHD(APCo, Mth, APTrans, APLine, APSeq, HoldCode)
           SELECT d.APCo, d.Mth, d.APTrans, d.APLine, d.APSeq, v.HoldCode
           FROM bAPTD d WITH (NOLOCK)
           JOIN bAPVH v WITH (NOLOCK) on d.APCo = v.APCo
           WHERE d.APCo = @co and d.Mth = @mth and d.APTrans = @aptrans and d.APLine = @apline and d.APSeq = @seq
   			AND v.VendorGroup = @vendorgroup and v.Vendor = @vendor
   			AND NOT EXISTS (
							SELECT TOP 1 1
							FROM bAPHD d2 WITH (NOLOCK)
							WHERE d2.APCo = d.APCo and d2.Mth = d.Mth
   								and d2.APTrans = d.APTrans and d2.APLine = d.APLine and d2.APSeq = d.APSeq and d2.HoldCode = v.HoldCode
							)
       END
   END

   bspexit:
       RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPHBPostAddDetail] TO [public]
GO
