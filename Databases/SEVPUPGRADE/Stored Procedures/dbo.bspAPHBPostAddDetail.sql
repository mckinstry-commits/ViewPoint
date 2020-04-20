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
   (@co bCompany, @mth bMonth, @aptrans int, @apline smallint, @paytype tinyint, @discount bDollar,
    @duedate bDate, @aptdstatus tinyint, @svendorgroup bGroup, @supplier bVendor, @holdcode bHoldCode,
    @grossamt bDollar, @miscamt bDollar, @miscyn bYN, @taxtype tinyint, @taxamt bDollar,@retainage bDollar,
    @retpaytype tinyint, @retholdcode bHoldCode, @vendorgroup bGroup,@vendor bVendor, @prepaidyn bYN,
    @chkrev bYN, @paycategory int,@taxgroup bGroup,@taxcode bTaxCode)
   
   as
   set nocount on
   
   DECLARE @rcode int, @amt bDollar, @retstatus tinyint, @seq tinyint

    -- GST/PST declares
	DECLARE @taxrate bRate,				@pstrate bRate,			@gstrate bRate,				@dbtRetgGLAcct bGLAcct,	@dbtGLAcct bGLAcct,
			@retgGstTaxAmt bDollar,		@payTaxAmt bDollar,		@retgTaxAmt bDollar,		@gstTaxAmt bDollar,		@pstTaxAmt bDollar,
			@crdRetgGSTGLAcct bGLAcct,	@expenseGstYN bYN,		@crdRetgPSTGLAcct bGLAcct,	@retgPSTTaxAmt bDollar,	@RetgOnlyYN bYN,
			@APCOTaxBasisNetRetg bYN 

    --initialize variables
   SELECT	@rcode = 0,		@seq = 0,		@taxrate=0,		@pstrate=0,				@gstrate=0,			@retgGstTaxAmt=0,	@payTaxAmt=0,
			@retgTaxAmt=0,	@gstTaxAmt = 0, @pstTaxAmt=0,	@expenseGstYN = 'N',	@retgPSTTaxAmt = 0

	-- get AP Company info
	SELECT @APCOTaxBasisNetRetg = TaxBasisNetRetgYN
	FROM bAPCO WITH (NOLOCK)
	WHERE APCo = @co

	--Calculate retainage %
	SELECT @RetgOnlyYN = CASE WHEN @retainage = 0 THEN 'N' ELSE CASE WHEN @grossamt/@retainage = 1 THEN 'Y' ELSE 'N' END END

		/* update bAPTD.GSTtaxAmt with GST tax on open payable, retgGST on retainage payable. 
			This is used later when retainage is paid, the retgGST is rolled into GST Expense
		   update bAPTD.TotTaxAmount with total tax on open payable, retgTax on retainage payable*/
		IF isnull(@taxtype,0)=3 
        BEGIN
			--get PST/GST tax information.
			exec @rcode = bspHQTaxRateGetAll @taxgroup, @taxcode, null, null, @taxrate output,
				@gstrate output, @pstrate output,null,null, @dbtGLAcct output,@dbtRetgGLAcct output,
				null, null, @crdRetgGSTGLAcct output, @crdRetgPSTGLAcct output
							
			-- GST is expensed so calculate GST/retgGST to update GSTtaxAmt
			if @dbtGLAcct is not null
			begin
			if @pstrate = 0
			begin
				/* When @pstrate = 0:  Either VAT SingleLevel using GST only, or VAT MultiLevel with PST set to 0.00 tax rate.*/
				if @dbtRetgGLAcct is not null
					begin
					if  isnull(@APCOTaxBasisNetRetg, 'N') = 'N' or @chkrev = 'Y' --#133107 Check reversal on GST
						begin -- GST tax basis is not net of retainage - calculate on full gross
						select @retgTaxAmt = @retainage * @taxrate --TK-17202 case @grossamt when 0 then 0 else (@retainage/@grossamt) * @taxamt end
						select @gstTaxAmt = CASE WHEN @RetgOnlyYN = 'Y' THEN @taxamt ELSE @taxamt - @retgTaxAmt END
						select @taxamt = @gstTaxAmt
						select @retgGstTaxAmt = @retgTaxAmt
						end
					else  -- GST tax basis is net of retainage 
						begin
						select @retgTaxAmt = @retainage * @taxrate --TK-17202 case @grossamt when 0 then 0 else (@grossamt * @taxrate) * (@retainage/@grossamt) end 
						select @gstTaxAmt = @taxamt -- GST was calculated on taxbasis net retainage in the form
						select @retgGstTaxAmt = @retgTaxAmt
						end
					end
				if @dbtRetgGLAcct is null
					begin
					select @gstTaxAmt = @taxamt - @retgTaxAmt
					select @taxamt = @taxamt - @retgTaxAmt
					select @retgGstTaxAmt = @retgTaxAmt
					end
					
				IF @APCOTaxBasisNetRetg = 'Y' AND (@crdRetgGSTGLAcct IS NOT NULL OR @crdRetgPSTGLAcct IS NOT NULL)SELECT @expenseGstYN = 'Y' 
			end
			else
			begin
				-- PST/GST
				if  isnull(@APCOTaxBasisNetRetg, 'N') = 'N' or @chkrev = 'Y' 
				BEGIN
					if @dbtRetgGLAcct is not null -- Retainage GST is broken out into it's own amount.
					BEGIN
						select @retgTaxAmt = @retainage * @taxrate --TK-17202 case @grossamt when 0 then 0 else (@retainage/@grossamt) * @taxamt end
					END
						select @payTaxAmt = CASE WHEN @RetgOnlyYN = 'Y' THEN @taxamt ELSE @taxamt - @retgTaxAmt END
						select @gstTaxAmt = case @taxrate when 0 then 0 else (@payTaxAmt * @gstrate) / @taxrate end	
						select @pstTaxAmt = @payTaxAmt - @gstTaxAmt	
						select @retgGstTaxAmt = case @taxrate when 0 then 0 else (@retgTaxAmt * @gstrate) / @taxrate end
						select @retgPSTTaxAmt = @retgTaxAmt - @retgGstTaxAmt
						select @taxamt = @payTaxAmt
				END
				ELSE -- taxbasis is net of holdback/retention.  Tax amt does not include holdback/retention tax
				BEGIN
					if @dbtRetgGLAcct is not null -- Retainage GST is broken out into it's own amount.
					BEGIN
						select @retgTaxAmt = @retainage * @taxrate 
					END
						select @payTaxAmt = @taxamt 
						select @gstTaxAmt = (@payTaxAmt * @gstrate)/@taxrate 	
						select @pstTaxAmt = CASE WHEN @RetgOnlyYN = 'Y' THEN @payTaxAmt ELSE @payTaxAmt - @gstTaxAmt END	
						select @retgGstTaxAmt = @retainage * @gstrate
						select @retgPSTTaxAmt = @retainage * @pstrate
				END
				IF @APCOTaxBasisNetRetg = 'Y' AND (@crdRetgGSTGLAcct IS NOT NULL OR @crdRetgPSTGLAcct IS NOT NULL)SELECT @expenseGstYN = 'Y'       
			end
			-- retainage only line - GST all goes on retainage Seq 
			--if @grossamt = 0 and @retainage <> 0
			--	begin
			--	select @retgGstTaxAmt = @gstTaxAmt, @gstTaxAmt=0 
			--	end
			end
        END
    
   -- add AP Detail for Pay Type - Seq #1 - Amt may include MiscAmt and Tax, but excludes Retainage
   select @amt = isnull(@grossamt,0) + case @miscyn when 'Y' then isnull(@miscamt,0) else 0 end
           + case @taxtype when 2 then 0 else isnull(@taxamt,0) end - isnull(@retainage,0)
--            + case @taxtype when 1 then isnull(@taxamt,0) else 0 end - isnull(@retainage,0)
   	select @seq = 1	
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
       if @holdcode is not null
           begin
           insert into bAPHD(APCo, Mth, APTrans, APLine, APSeq, HoldCode)
           values(@co, @mth, @aptrans, @apline, @seq, @holdcode)
           end
       -- add Vendor Hold Codes 
       if @prepaidyn = 'N' -- #15190 - don't add if prepaid
           begin
           insert into bAPHD(APCo, Mth, APTrans, APLine, APSeq, HoldCode)
           select d.APCo, d.Mth, d.APTrans, d.APLine, d.APSeq, v.HoldCode
           from bAPTD d with (nolock)
           join bAPVH v with (nolock) on d.APCo = v.APCo
           where d.APCo = @co and d.Mth = @mth and d.APTrans = @aptrans and d.APLine = @apline and d.APSeq = @seq
           and v.VendorGroup = @vendorgroup and v.Vendor = @vendor
           and not exists(select top 1 1 from bAPHD d2 with (nolock) where d2.APCo = d.APCo and d2.Mth = d.Mth
                   and d2.APTrans = d.APTrans and d2.APLine = d.APLine and d2.APSeq = d.APSeq and d2.HoldCode = v.HoldCode)
           -- add PO Hold Code
           select @holdcode = HoldCode from bPOHD p with (nolock) 
   		join bAPTL l with (nolock) on p.POCo = l.APCo and p.PO = l.PO where l.APCo = @co and l.Mth = @mth 
   		and l.APTrans = @aptrans and l.APLine = @apline and p.HoldCode is not null
           if @@rowcount > 0
               begin
               if not exists(select top 1 1 from bAPHD with (nolock) where APCo = @co and Mth = @mth
   					and APTrans = @aptrans and APLine = @apline and APSeq = @seq and HoldCode = @holdcode)
                   begin
                   insert bAPHD (APCo, Mth, APTrans, APLine, APSeq, HoldCode)
                   select @co, @mth, @aptrans, @apline, @seq, @holdcode
                   end
               end
   
   		-- add SL Hold Code
   		select @holdcode = HoldCode from bSLHD p with (nolock)
   		join bAPTL l with (nolock) on p.SLCo = l.APCo and p.SL = l.SL where l.APCo = @co and l.Mth = @mth 
   		and l.APTrans = @aptrans and l.APLine = @apline and p.HoldCode is not null
           if @@rowcount > 0
               begin
               if not exists(select top 1 1 from bAPHD with (nolock) where APCo = @co and Mth = @mth
   					and APTrans = @aptrans and APLine = @apline and APSeq = @seq and HoldCode = @holdcode)
                   begin
                   insert bAPHD (APCo, Mth, APTrans, APLine, APSeq, HoldCode)
                   select @co, @mth, @aptrans, @apline, @seq, @holdcode
                   end
               end
           end
      -- end
   
   -- add AP Detail for Retainage - next Seq #
   IF @retainage <> 0 AND @retpaytype IS NOT NULL
   BEGIN
		--select @seq = @seq + 1, @retstatus = 2   -- default status is 'hold'
   		SELECT @seq = @seq + 1, @retstatus = CASE WHEN @chkrev ='Y' THEN 1 ELSE 2 END   -- 17663 don't put paid retainage on hold
   		
       -- if retainage only and prepaid transaction, use transaction status
       IF  @RetgOnlyYN = 'Y' AND @prepaidyn = 'Y' SELECT @retstatus = @aptdstatus
   
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
   
       if @retstatus = 2
           begin
           -- add AP Hold Detail for Retainage
           if @retholdcode is not null
               begin
               insert into bAPHD(APCo, Mth, APTrans, APLine, APSeq, HoldCode)
               values(@co, @mth, @aptrans, @apline, @seq, @retholdcode)
               end
   
           -- add Transaction Hold Code
           if @holdcode is not null and @holdcode <> @retholdcode
               begin
               insert into bAPHD(APCo, Mth, APTrans, APLine, APSeq, HoldCode)
               values(@co, @mth, @aptrans, @apline, @seq, @holdcode)
               end
   
           -- add all Vendor Hold Codes for Seq #2
           insert into bAPHD(APCo, Mth, APTrans, APLine, APSeq, HoldCode)
           select d.APCo, d.Mth, d.APTrans, d.APLine, d.APSeq, v.HoldCode
           from bAPTD d with (nolock)
           join bAPVH v with (nolock) on d.APCo = v.APCo
           where d.APCo = @co and d.Mth = @mth and d.APTrans = @aptrans and d.APLine = @apline and d.APSeq = @seq
   		and v.VendorGroup = @vendorgroup and v.Vendor = @vendor
   		and not exists(select top 1 1 from bAPHD d2 with (nolock) where d2.APCo = d.APCo and d2.Mth = d.Mth
   		and d2.APTrans = d.APTrans and d2.APLine = d.APLine and d2.APSeq = d.APSeq and d2.HoldCode = v.HoldCode)
           end
       end
   
   
   
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPHBPostAddDetail] TO [public]
GO
