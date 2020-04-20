
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE             proc [dbo].[vspIMUploadAPDB]
   	
   /***********************************************************
    * CREATED BY: MV   08/25/09
    * MODIFIED By :	MV	05/25/10 - #136500 - added param 'N' to bspProcessPartialPayment for '@ApplyCurrTaxRateYN' 
    *				GF 08/15/2010 - issue #135813 change for subcontract expanded
	*				MV 02/07/2011 - #142713 - validate AmountToPay against Invoice amount.
	*				ECV 05/25/11 - TK-05443 - Add SMPayType parameter to bspAPPayTypeGet
	*				MV 03/21/13 - TFS 44601 - validate input parameters specific to retainage/non-retg payments
	*				MV 04/15/2013 - TFS 47145 - Corrected where clause for open to pay select 
    *
    * USAGE: called from vspIMUploadHeaderDetailTextura. It
	*	creates bAPDB records for bAPTB and bAPPB records 
	*	created by vspIMUPloadHeaderDetailTextura.  Or for
	*	retainage, it creates bAPTBs and bAPDBs as necessary
	*	for released retainage.
    *
    * INPUT PARAMETERS
    *   VendorGroup   vendorgroup associated with the vendor
    *   Vendor	    Vendor
    *	AddressSeq    sequence # for the vendor address
    *	
    * OUTPUT PARAMETERS
    *	@msg   		error message
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   (@co bCompany,		@batchmth bDate,	@batchid int,		@batchseq int,		@ExpMth bDate,		@APTrans bTrans,
	@APRef varchar(15),	@InvDate bDate,		@RetainageFlag bYN,	@AmtToPay bDollar,	@SL varchar(30),	@TexturaYN bYN,
	@errmsg varchar(200) output)
	 
   AS
   SET NOCOUNT ON
   
   DECLARE	@rcode int,				@RetPayType int,		@ReleasedAmt bDollar,	@vendor bVendor,
			@vendorgroup bGroup,	@opencursorAPTD int,	@APTDMth bDate,			@APTDAPTrans bTrans,
			@APTDAPRef varchar(15), @APTDInvDate bDate,		@APTDLine int,			@APTDSeq int,
			@APTDAmt bDollar,		@APTDDesc varchar(30),	@AmtLeftToPay bDollar,	@AmtToSplit bDollar,
			@GrossAmt bDollar,		@Description bDesc,		@AmtOpenToPay bDollar

   
   SELECT @rcode = 0, @opencursorAPTD = 0,@AmtLeftToPay = 0, @AmtToSplit = 0, @GrossAmt = 0, @AmtOpenToPay = 0
   
   IF @RetainageFlag IS NULL
		BEGIN
		SELECT @RetainageFlag = 'N'
		END

   IF @co IS NULL
   	BEGIN
   	SELECT @errmsg = 'Missing AP Company!', @rcode = 1
   	GOTO bspexit
   	END
   
   IF @batchmth IS NULL
   	BEGIN
   	SELECT @errmsg = 'Missing Batch Mth!', @rcode = 1
   	GOTO bspexit
   	END
   
   IF @batchid IS NULL
   	BEGIN
   	SELECT @errmsg = 'Missing Batch Seq!', @rcode = 1
   	GOTO bspexit
   	END

	IF @InvDate IS NULL
   	BEGIN
   	SELECT @errmsg = 'Missing Inv Date!', @rcode = 1
   	GOTO bspexit
   	END

	IF @AmtToPay IS NULL
   	BEGIN
   	SELECT @errmsg = 'Missing Amount!', @rcode = 1
   	GOTO bspexit
   	END
	
	--validaton specific to non retainage payments
	IF @RetainageFlag <> 'R'
	BEGIN
		IF @ExpMth IS NULL
   			BEGIN
   			SELECT @errmsg = 'Missing Exp Mth!', @rcode = 1
   			GOTO bspexit
   			END

		IF @APTrans IS NULL
   		BEGIN
   			SELECT @errmsg = 'Missing AP Trans!', @rcode = 1
   			GOTO bspexit
   		END

		IF @APRef IS NULL
   		BEGIN
   			SELECT @errmsg = 'Missing AP Ref!', @rcode = 1
   			GOTO bspexit
   		END
	END

	--validate specific to Textura retainage payments
	IF isnull(@TexturaYN,'N') = 'Y'
	BEGIN
		IF @SL IS NULL and @RetainageFlag = 'R'
		BEGIN
		SELECT @errmsg = 'Missing SL!', @rcode = 1
		GOTO bspexit
		END
	END
	
	--get default retainage pay type 
	EXEC @rcode = dbo.bspAPPayTypeGet @co, null, null, null,null,null,
    	@RetPayType output, null,null,null, @errmsg output

	-- get vendor group and vendor
	SELECT @vendor=Vendor, @vendorgroup = VendorGroup 
	FROM dbo.APPB (nolock) 
	WHERE Co=@co and Mth=@batchmth and BatchId=@batchid and BatchSeq=@batchseq
 
--	 Regular Invoices - Non Retainage 
	IF ISNULL(@RetainageFlag, 'N') = 'N'
	BEGIN
		-- make sure the bAPTB record exists  
		IF NOT EXISTS (SELECT * 
						FROM
						dbo.APTB (nolock) WHERE
						Co=@co and Mth=@batchmth and BatchId=@batchid and
						BatchSeq=@batchseq and ExpMth=@ExpMth and APTrans=@APTrans and APRef=@APRef)
		BEGIN
			SELECT @errmsg = 'APTB payment transaction record does not exist for ExpMth: ' + convert(varchar(8),@ExpMth,1) +
				' APTrans: ' + convert(varchar(4),@APTrans) 
			SELECT @rcode = 1
			GOTO bspexit
		END

		--	 make sure APTD exists - 
	   IF NOT EXISTS (SELECT * 
						FROM dbo.APTD d (nolock) 
						JOIN dbo.APTH h (nolock) on d.APCo=h.APCo and d.Mth=h.Mth and d.APTrans=h.APTrans 
						WHERE d.APCo=@co and d.Mth=@ExpMth and d.APTrans=@APTrans and h.APRef = @APRef) 
		BEGIN
			SELECT @errmsg = 'APTD payment transaction detail does not exist for Mth: ' + convert(varchar(8),@ExpMth,1) +
				' APTrans: ' + convert(varchar(4),@APTrans) + ' APRef: ' + @APRef 
			SELECT @rcode = 1
			GOTO bspexit
		END

		--validate open to pay against amount to pay
		IF ISNULL(@TexturaYN,'N') ='N'
		BEGIN
			SELECT @AmtOpenToPay = SUM(d.Amount - d.DiscTaken)
			FROM dbo.APTD d (NOLOCK) 
			JOIN dbo.APTH h (NOLOCK) ON d.APCo=h.APCo AND d.Mth=h.Mth AND d.APTrans=h.APTrans 
			WHERE d.APCo=@co AND d.Mth=@ExpMth AND d.APTrans=@APTrans AND h.APRef = @APRef AND d.Status=1
			-- Amount open to pay exceeds the import check amount.
			IF @AmtOpenToPay < @AmtToPay
			BEGIN
				SELECT @errmsg = 'Check amount exceeds open to pay for Mth: ' + CONVERT(VARCHAR(8),@ExpMth,1) +
					' APTrans: ' + CONVERT(varchar(4),@APTrans) + ' APRef: ' + @APRef 
				SELECT @rcode = 1
				GOTO bspexit
			END
			-- Amount open to pay is less than the import check amount.
			IF @AmtOpenToPay > @AmtToPay
			BEGIN
				SELECT @errmsg = 'Check amount is less than amount open to pay for Mth: ' + CONVERT(VARCHAR(8),@ExpMth,1) +
					' APTrans: ' + CONVERT(VARCHAR(4),@APTrans) + ' APRef: ' + @APRef 
				SELECT @rcode = 1
				GOTO bspexit
			END
		END
		ELSE
		BEGIN
			SELECT @AmtOpenToPay = SUM(d.Amount - d.DiscTaken)
			FROM dbo.APTD d (NOLOCK) 
			JOIN dbo.APTH h (NOLOCK) ON d.APCo=h.APCo AND d.Mth=h.Mth AND d.APTrans=h.APTrans 
			WHERE d.APCo=@co AND d.Mth=@ExpMth AND d.APTrans=@APTrans AND h.APRef = @APRef 
				AND d.Status=1 
				AND 
					((d.PayCategory IS NULL AND d.PayType <> @RetPayType )
					OR 
						(
							d.PayCategory IS NOT NULL AND d.PayType <> 
																(
																	SELECT RetPayType 
																	FROM dbo.APPC c 
																	WHERE c.APCo = @co AND c.PayCategory = d.PayCategory
																)
						))
			-- Amount open to pay exceeds the import check amount.
			IF @AmtOpenToPay < @AmtToPay
			BEGIN
				SELECT @errmsg = 'Check amount exceeds open to pay for Mth: ' + CONVERT(VARCHAR(8),@ExpMth,1) +
					' APTrans: ' + CONVERT(varchar(4),@APTrans) + ' APRef: ' + @APRef 
				SELECT @rcode = 1
				GOTO bspexit
			END
			-- Amount open to pay is less than the import check amount.
			IF @AmtOpenToPay > @AmtToPay
			BEGIN
				SELECT @errmsg = 'Check amount is less than amount open to pay for Mth: ' + CONVERT(VARCHAR(8),@ExpMth,1) +
					' APTrans: ' + CONVERT(VARCHAR(4),@APTrans) + ' APRef: ' + @APRef 
				SELECT @rcode = 1
				GOTO bspexit
			END
		END

		--	 Create bAPDB recs 
		IF ISNULL(@TexturaYN,'N') ='N'
		BEGIN
			INSERT INTO dbo.APDB (
					Co,                            
					Mth,                           
					BatchId,                       
					BatchSeq,                      
					ExpMth,                        
					APTrans,                       
					APLine,                        
					APSeq,                         
					PayType,                       
					Amount,                        
					DiscTaken,                     
					PayCategory,                   
					TotTaxAmount)
				SELECT @co,@batchmth,@batchid,@batchseq,@ExpMth,@APTrans,d.APLine,d.APSeq,d.PayType,d.Amount,d.DiscTaken,d.PayCategory,d.TotTaxAmount
				FROM dbo.APTD d join dbo.APTH h on d.APCo=h.APCo and d.Mth=h.Mth and d.APTrans=h.APTrans 
				WHERE d.APCo=@co and d.Mth=@ExpMth and d.APTrans=@APTrans and h.APRef = @APRef and d.Status=1 
				
				IF @@rowcount = 0
					BEGIN
						SELECT @errmsg = 'APDB payment transaction detail was not created for Mth: ' + convert(varchar(8),@ExpMth,1) +
							' APTrans: ' + convert(varchar(4),@APTrans) + ' APRef: ' + @APRef + '.'
						SELECT @rcode = 1
						GOTO bspexit
					END
				ELSE
					BEGIN
						-- update APTB with gross, description
						SELECT @GrossAmt = sum(Amount) FROM dbo.APTD WHERE APCo = @co and Mth = @ExpMth and APTrans = @APTrans
						SELECT @Description 
						FROM dbo.APTH 
						WHERE APCo = @co and Mth = @ExpMth and APTrans = @APTrans
						UPDATE dbo.APTB set Gross = @GrossAmt, Description=@Description
					   FROM dbo.APTB WHERE Co = @co and Mth = @batchmth and BatchId = @batchid
					   and BatchSeq = @batchseq and ExpMth = @ExpMth and APTrans = @APTrans
					END
		END				
		ELSE
		BEGIN
			insert into dbo.APDB (
				Co,                            
				Mth,                           
				BatchId,                       
				BatchSeq,                      
				ExpMth,                        
				APTrans,                       
				APLine,                        
				APSeq,                         
				PayType,                       
				Amount,                        
				DiscTaken,                     
				PayCategory,                   
				TotTaxAmount)
			SELECT @co,@batchmth,@batchid,@batchseq,@ExpMth,@APTrans,d.APLine,d.APSeq,d.PayType,d.Amount,d.DiscTaken,d.PayCategory,d.TotTaxAmount
			FROM dbo.APTD d join dbo.APTH h on d.APCo=h.APCo and d.Mth=h.Mth and d.APTrans=h.APTrans 
			WHERE d.APCo=@co and d.Mth=@ExpMth and d.APTrans=@APTrans and h.APRef = @APRef and d.Status=1
			AND 
					((d.PayCategory IS NULL AND d.PayType <> @RetPayType )
					OR 
						(
							d.PayCategory IS NOT NULL AND d.PayType <> 
																(
																	SELECT RetPayType 
																	FROM dbo.APPC c 
																	WHERE c.APCo = @co AND c.PayCategory = d.PayCategory
																)
						)) 
			IF @@rowcount = 0
				BEGIN
				SELECT @errmsg = 'APDB payment transaction detail was not created for Mth: ' + convert(varchar(8),@ExpMth,1) +
					' APTrans: ' + convert(varchar(4),@APTrans) + ' APRef: ' + @APRef + '.'
				SELECT @rcode = 1
				GOTO bspexit
				END
			ELSE
				BEGIN
					-- update APTB with gross, description
					SELECT @GrossAmt = sum(Amount) FROM dbo.APTD WHERE APCo = @co and Mth = @ExpMth and APTrans = @APTrans
					SELECT @Description FROM dbo.APTH WHERE APCo = @co and Mth = @ExpMth and APTrans = @APTrans
					UPDATE dbo.APTB set Gross = @GrossAmt, Description=@Description
					FROM dbo.APTB WHERE Co = @co and Mth = @batchmth and BatchId = @batchid
					and BatchSeq = @batchseq and ExpMth = @ExpMth and APTrans = @APTrans
				END
		END	
	END 

	-- Released retainage payments - This should be Textura only
	IF @RetainageFlag = 'R' and @TexturaYN = 'Y'
	BEGIN
	-- validate that there is enough released retainage for what is being paid
	SELECT @ReleasedAmt = sum(d.Amount) 
	FROM dbo.APTD d (nolock) 
	JOIN dbo.APTL l (nolock) on d.APCo=l.APCo and d.Mth=l.Mth and d.APTrans=l.APTrans and d.APLine=l.APLine
	JOIN dbo.APTH h (nolock) on d.APCo=h.APCo and d.Mth=h.Mth and d.APTrans=h.APTrans
	WHERE d.APCo=@co and h.VendorGroup=@vendorgroup	and h.Vendor=@vendor and l.LineType=7 and l.SL=@SL 
	AND 
			((d.PayCategory IS NULL AND d.PayType=@RetPayType )
			OR 
				(
					d.PayCategory IS NOT NULL AND d.PayType = 
														(
															SELECT RetPayType 
															FROM dbo.APPC c 
															WHERE c.APCo = @co AND c.PayCategory = d.PayCategory
														)
				)) 
	
	AND d.Status=1
	IF @ReleasedAmt < @AmtToPay
	BEGIN
		SELECT @errmsg = 'Retainage paid exceeds released retainage for Mth: ' + convert(varchar(8),@ExpMth,1) +
			' APTrans: ' + convert(varchar(4),@APTrans) + ' SL: ' + @SL + '.'
		SELECT @rcode = 1
		GOTO bspexit
	END

	--create a cursor to spin through released retainage for this SL
	DECLARE bcAPTDr cursor local fast_forward for
   	SELECT l.Mth,l.APTrans,h.APRef,h.InvDate,l.Description, l.APLine,d.APSeq,d.Amount
	FROM dbo.APTD d (nolock) 
	JOIN dbo.APTL l (nolock) on d.APCo=l.APCo and d.Mth=l.Mth and d.APTrans=l.APTrans and d.APLine=l.APLine
	JOIN dbo.APTH h (nolock) on d.APCo=h.APCo and d.Mth=h.Mth and d.APTrans=h.APTrans
	WHERE d.APCo=@co and h.VendorGroup=@vendorgroup	and h.Vendor=@vendor and l.LineType=7 
		and l.SL=@SL and 
			((d.PayCategory IS NULL AND d.PayType=@RetPayType )
			OR 
				(
					d.PayCategory IS NOT NULL AND d.PayType = 
														(
															SELECT RetPayType 
															FROM dbo.APPC c 
															WHERE c.APCo = @co AND c.PayCategory = d.PayCategory
														)
				))
		and d.Status=1
	ORDER BY d.Mth
   
   	-- open cursor
   	OPEN bcAPTDr
   	SELECT @opencursorAPTD = 1
   
   	APDB_loop:	-- process each APTD
   		FETCH NEXT FROM bcAPTDr into @APTDMth,@APTDAPTrans,@APTDAPRef,@APTDInvDate,@APTDDesc,@APTDLine,@APTDSeq,@APTDAmt 
   
   		IF @@fetch_status <> 0 GOTO APTD_end
		-- If there is still retainage to pay continue processing
		IF @AmtLeftToPay < @AmtToPay 
		BEGIN
			-- Insert APTB if needed
			IF NOT EXISTS (
							SELECT * 
							FROM dbo.APTB 
							WHERE Co=@co and Mth=@batchmth and BatchId=@batchid and BatchSeq=@batchseq
							AND ExpMth=@APTDMth and APTrans=@APTDAPTrans and APRef=@APTDAPRef
						   )
			BEGIN
				INSERT INTO dbo.APTB(
				Co,                            
				Mth,                           
				BatchId,                       
				BatchSeq,                      
				ExpMth,                        
				APTrans,                       
				APRef,                         
				Description,                   
				InvDate,                       
				Gross,                         
				Retainage,                     
				PrevPaid,                      
				PrevDisc,                      
				Balance,                       
				DiscTaken)
			SELECT @co,@batchmth,@batchid,@batchseq,@APTDMth,@APTDAPTrans,@APTDAPRef,@APTDDesc,@APTDInvDate,0,0,0,0,0,0
			IF @@ROWCOUNT = 0
				BEGIN
				SELECT @errmsg = 'APTB transaction payment rec was not created for ExpMth: ' + convert(varchar(8),@APTDMth,1) +
				' APTrans: ' + convert(varchar(4),@APTDAPTrans) + ' SL: ' + @SL + '.'
				SELECT @rcode = 1
				GOTO APTD_end
				END
			END 

			-- insert APDB 
			IF NOT EXISTS (SELECT * 
							FROM dbo.APDB 
							WHERE Co=@co and Mth=@batchmth and BatchId=@batchid and BatchSeq=@batchseq
							and ExpMth=@APTDMth and APTrans=@APTDAPTrans and APLine=@APTDLine and APSeq=@APTDSeq)
			BEGIN	
			-- split APTD if Amount is more than what is left to pay on retainage
			if @APTDAmt > (@AmtToPay - @AmtLeftToPay)
--			@APTDAmt >   (@AmtToPay - @AmtLeftToPay)
--			   150   > 100 (500     -    400)			
--			Seq 2 = 100 
--			Seq 3 =  50
--			Send over $50
			-- split APTD retainage payment
			BEGIN
				SELECT @AmtToSplit = @APTDAmt - (@AmtToPay - @AmtLeftToPay)
				EXEC @rcode = bspAPProcessPartialPayments @co, @APTDMth, @APTDAPTrans,@APTDLine, @APTDSeq,
				   @AmtToSplit, null, 'N', null,'Y', null, 'Y', 'N', @errmsg output
				IF @rcode <> 0
				BEGIN
					SELECT @errmsg = @errmsg + ' - APTD payment split was not made for Mth: ' + convert(varchar(8),@APTDMth,1) +
					' APTrans: ' + convert(varchar(4),@APTDAPTrans) + ' SL: ' + @SL + '.'
					SELECT @rcode = 1
					GOTO APTD_end
				END
				ELSE
					--set APTD Amount - Amount minus what was split out
					SELECT @APTDAmt = @APTDAmt - @AmtToSplit
			END

			-- Insert APDB	
			INSERT INTO dbo.APDB (
				Co,                            
				Mth,                           
				BatchId,                       
				BatchSeq,                      
				ExpMth,                        
				APTrans,                       
				APLine,                        
				APSeq,                         
				PayType,                       
				Amount,                        
				DiscTaken,                     
				PayCategory,                   
				TotTaxAmount)
			SELECT @co,@batchmth,@batchid,@batchseq,@APTDMth,@APTDAPTrans,@APTDLine,@APTDSeq,PayType,@APTDAmt,DiscTaken,PayCategory,TotTaxAmount
			FROM dbo.APTD 
			WHERE APCo=@co and Mth=@APTDMth and APTrans=@APTDAPTrans and APLine=@APTDLine and APSeq=@APTDSeq
			IF @@ROWCOUNT = 0
			BEGIN
				SELECT @errmsg = 'APDB payment transaction detail was not created for ExpMth: ' + convert(varchar(8),@APTDMth,1) +
					' APTrans: ' + convert(varchar(4),@APTDAPTrans) + ' SL: ' + @SL + '.'
				SELECT @rcode = 1
				GOTO APTD_end
			END
			ELSE
			BEGIN
				SELECT @AmtLeftToPay = @AmtLeftToPay + @APTDAmt
				-- update APTB with gross, description
				SELECT @GrossAmt = sum(Amount) 
				FROM dbo.APTD 
				WHERE APCo = @co and Mth = @APTDMth and APTrans = @APTDAPTrans

				SELECT @Description 
				FROM dbo.APTH 
				WHERE APCo = @co and Mth = @APTDMth and APTrans = @APTDAPTrans

				UPDATE dbo.APTB set Gross = @GrossAmt, Description=@Description
				FROM dbo.APTB 
				WHERE Co = @co and Mth = @batchmth and BatchId = @batchid
				   and BatchSeq = @batchseq and ExpMth = @APTDMth and APTrans = @APTDAPTrans
			END 
		END	
		END
		GOTO APDB_loop

		APTD_end:	
       	CLOSE bcAPTDr
           deallocate bcAPTDr
   		SELECT @opencursorAPTD = 0

	END

   
   bspexit:
   	RETURN @rcode


GO

GRANT EXECUTE ON  [dbo].[vspIMUploadAPDB] TO [public]
GO
