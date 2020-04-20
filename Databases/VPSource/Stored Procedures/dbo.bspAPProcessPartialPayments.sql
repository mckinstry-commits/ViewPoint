SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPProcessPartialPayments    Script Date: 8/28/99 9:34:03 AM ******/
        CREATE                       procedure [dbo].[bspAPProcessPartialPayments]
    
    
        /***********************************************************
         * CREATED BY: EN 10/30/97
         * MODIFIED BY: EN 4/3/98
         *              EN 5/4/00 - status of inserted detail was getting assigned hold code; s/b open
         *              EN 5/4/00 - not allowing partial payment of single line/seq
         *              EN 5/9/00 - do not apply hold code to non-retainage details if it is the retainage hold code
         *              EN 5/9/00 - return error message if try to apply retainage hold code to a specified non-retainage line/sequence,
         *                          and set up warning for not assigning retainage hold code to non-retainage portions
         *              kb 11/6/00 - not allowing partial payments of neg amts to negative invoices issue #11279
         *		    MV 03/18/02 - 14160 - insert partial payments in bAPWD
    	 *			kb 5/27/2 - issue #14160
    	 *          kb 10/29/2 - issue #18878 - fix double quotes
         *			MV 12/04/02 - #18756 - supplier in partial payments for selected line/seq
         *			MV 12/27/02 - #19701 - supplier in partial payments for entire transaction
    	 *			MV 01/10/03 - #19701 - rej 1 fix - removed supplier from bAPWD update		
    	 *			MV 01/22/03 - #19967 - added 'begin and end' statements for setting retainage holdcode msgs.	
    	 *			MV 03/26/03 - #20723 - allow a mix of negative and positive trans detail in the partial payment process.
    	 *			MV 11/05/03 - #22928 - fix to holdcodes assigned during partial payment split.
         *			MV 02/16/04 - #18769 - Pay Category
         *			MV 02/17/04 - #23549 - fix to #20723 for negative trans in partial pay process
         *			ES 03/11/04 - #23061 isnull wrapping
        			MV 07/12/04 - #25076 - @userid should have datatype bVPUserName
         *			MV 07/16/04 - #25136 - applying holdcode - holdcode and paytype are both part of 'if not' test
		 *			MV 09/10/08 - #128288 - distribute APTD tax amounts
		 *			MV 09/02/09 - #130949 - make @userid nullable to skip insert/update to bAPWD for non workfile partial payments
		 *			MV 12/21/09 - #137034 - partial payment with multiple suppliers. 
		 *			MV 01/28/10 - #136500 - changed APTD 'TaxAmount' to 'GSTtaxAmt'
		 *			MV 05/25/10 - #136500 - Update retainage split with new GST tax amount
		 *			MV 08/04/10 - #140765 - fixed update to @amtreleased on partial pay for entire transaction (all lines)
		 *			MV 08/10/10 - #140898 - Fix for #137034 caused this problem, rolling back that fix, corrected this issue. Redid fix for #137034.
		 *
         * USAGE:
         * Process a partial payment for an entire transaction or for
         * an individual line/seq.
         *
         *  INPUT PARAMETERS
         *   @apco	AP company #
         *   @mth	expense month of transaction
         *   @aptrans	transaction # to update
         *   @apline	transaction line to restrict by (null for all)
         *   @apseq	transaction line sequence to restrict by (null for all)
         *   @payamount	amount of partial payment
         *   @supplier	supplier to assign for payment (optional)
         *   @origholdflag	'Y' if putting original amounts on hold
         *   @holdcode	hold code to use if putting orig amounts on hold
         *   @distribflag	'Y' if distributing discounts on a split detail
         *
         * OUTPUT PARAMETERS
         *   @msg      error message if error occurs
         *
         * RETURN VALUE
         *   0   success
         *   1   fail
         *   5   couldn't do partial payment on full amount requested
        *********************************
        **********************************/
    
        (@apco bCompany, @mth bMonth, @aptrans bTrans, @apline smallint = null, @apseq tinyint = null,
        @payamount bDollar, @supplier bVendor = null, @origholdflag bYN = 'N', @holdcode bHoldCode = null,
        @distribflag bYN = 'N', @userid bVPUserName = null, @distributetax bYN = 'N',@ApplyCurrTaxRateYN bYN = 'N',
		@msg varchar(90) output)
    
        as
        set nocount on
    
        declare @rcode tinyint, @APTDopened tinyint, @dtlapline smallint, @dtlapseq tinyint,
        	@dtlpaytype tinyint, @dtlamount bDollar, @dtldiscoffer bDollar, @dtldisctaken bDollar,
        	@dtlduedate bDate, @dtlpaidmth bMonth, @dtlpaiddate bDate, @dtlcmco bCompany,
        	@dtlcmacct bCMAcct, @dtlpaymethod varchar(1), @dtlcmref bCMRef, @dtlcmrefseq tinyint,
        	@dtleftseq smallint, @dtlvendgroup bGroup, @dtlsupplier bVendor, @ttlamount bDollar,
        	@discoffer bDollar, @disctaken bDollar, @newseq tinyint, @amt bDollar, @amtreleased bDollar,
            @releaseamt bDollar, @paycategory int, @retholdcode bHoldCode, @paytype tinyint,
    		@retpaytype tinyint, @dtlpaycategory int,@mixedyn bYN, @dtltaxamount bDollar,
			@dtlgsttaxamount bDollar,@tottaxamt bDollar, @gsttaxamt bDollar,@dtloldgsttaxamt bDollar,
			@dtlexpenseGSTyn bYN, @oldgsttaxamt bDollar, @dtlstatus int
    
        select @rcode=0
        select @ttlamount=0, @amtreleased=0, @releaseamt=0
    
        /* validate amount */
        if @payamount = 0 or @payamount is null
        	begin
        	select @msg = 'Cannot process a partial payment of $0!', @rcode=1
        	goto bspexit
        	end
    
    
        if @apline is not null
        	begin
        	 select @amt=sum(Amount) from APTD
        		where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=@apline
        		and APSeq=@apseq and (Status=1 or Status=2)
    
        	 if sign(@amt) <> sign(@payamount)
        	 	begin
        	 	 if @amt > 0
        	 	 	begin
        	 		 select @msg = 'Must select a positive amount!', @rcode=1
        	 		 goto bspexit
        	 		end
        	 	 if @amt < 0
        	 	 	begin
        	 	 	 select @msg = 'Must select a negative amount!', @rcode=1
        	 	 	 goto bspexit
        	 	 	end
        	 	end
        	end
    
        select @amt=sum(Amount) from APTD
        	where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=isnull(@apline,APLine)
        	and APSeq=isnull(@apseq,APSeq) and ((@apline is null and Status=1) or (@apline is not null and Status in (1,2)))
        	/*and sign(Amount)=sign(@payamount)*/	--#20733 select trans detail with both positive and negative amounts.
    
        if @amt=0 or @amt is null
        	begin
        	 select @msg = 'Nothing to release!', @rcode=1
        	 goto bspexit
        	end
        if @payamount > 0 and @payamount > @amt
        	begin
        	 select @msg = 'Can only create partial payment on up to $' + isnull(convert(varchar,@amt), ''), @rcode=1  --#23061
        	 goto bspexit
        	end
        if @payamount < 0 and @payamount < @amt
        	begin
        	 select @msg = 'Can only create partial payment on maximum credit of $' + isnull(convert(varchar,abs(@amt)), ''), @rcode=1  --#23061
        	 goto bspexit
        	end
    
    	/* #23549 - check for mixed credits and payments. If the trans detail is all positive or
    		all negative amounts then using abs() works.  If they are a mix, then using abs() causes
    		incorrect cumulative released amounts. */
    	select @mixedyn = 'N'
    	if exists (select top 1 1 from bAPTD with (nolock)
    		where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=isnull(@apline,APLine)
        	and APSeq=isnull(@apseq,APSeq)
    		and ((@apline is null and Status=1) or (@apline is not null and Status in (1,2)))
    		and Amount < 0)	--check for negative pay amounts
    		begin
    			if exists (select top 1 1 from bAPTD with (nolock)
    				where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=isnull(@apline,APLine)
    		    	and APSeq=isnull(@apseq,APSeq)
    				and ((@apline is null and Status=1) or (@apline is not null and Status in (1,2)))
    				and Amount > 0)	--check for postive pay amounts
    			begin
    			select @mixedyn = 'Y'
    			end
    		end
    
        /* validate line */
        if @apline is not null
        	begin
        	if not exists (select * from APTD where APCo=@apco and Mth=@mth and APTrans=@aptrans
        			and APLine=@apline)
        		begin
        		select @msg = 'Invalid Line!' , @rcode=1
        		goto bspexit
        		end
        	end
    
        /* validate seq */
        if @apseq is not null
        	begin
        	if not exists (select * from APTD where APCo=@apco and Mth=@mth and APTrans=@aptrans
        			and APLine=@apline and APSeq=@apseq)
        		begin
        		select @msg = 'Invalid Sequence!' ,@rcode=1
        		goto bspexit
        		end
        	end
    
        -- if line/seq was selected, check PayType against HoldCode
    		select @retholdcode= RetHoldCode, @retpaytype=RetPayType from APCO with (nolock) where APCo=@apco
    		--check against a specific line and seq
    		if @apline is not null and @apseq is not null and @holdcode = @retholdcode
    			begin
    			select @paycategory = PayCategory, @paytype=PayType 
    			from APTD with (nolock) where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=@apline and APSeq=@apseq
    			if (@paycategory is null and @paytype <> @retpaytype)
    				or (@paycategory is not null and @paytype <>
    					(select RetPayType from APPC with (nolock) where APCo=@apco and PayCategory = @paycategory)) 
    				begin
    		        select @msg = 'Cannot assign retainage hold code to non-retainage portion.', @rcode = 1
    		        goto bspexit
    		        end
    			end
    		-- set message to inform user that retainage hold code will not be assigned to non-retainage portions
    		if @apline is null and @apseq is null and @holdcode = @retholdcode
    			begin
    			if (@retpaytype not in (select PayType from bAPTD with (nolock) where APCo=@apco
    				 and Mth=@mth and APTrans=@aptrans and PayCategory is null
    				 and Status = 1 and sign(Amount)=sign(@payamount)))
    			    or (exists (select top 1 1 from bAPTD d with (nolock)
    					join bAPPC c with (nolock) on d.APCo=c.APCo and d.PayCategory=c.PayCategory
    					where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans and d.PayCategory is not null
    						and d.Status=1 and sign(d.Amount) = sign (@payamount) and d.PayType = c.RetPayType))
    				Begin
    	     		select @msg = 'Hold Code is for retainage only and was not applied to any non-retainage portions.',@rcode = 6
    				end 
    			end
    
        /* initialize open cursor flag to false */
        select @APTDopened = 0
    
        /* initialize cursor for AP detail */
		IF @supplier IS NOT NULL -- new fix for #137034 
		BEGIN
			DECLARE bcAPTD CURSOR
        		FOR SELECT APLine, APSeq, PayType, Amount, DiscOffer, DiscTaken, DueDate,
        		PaidMth, PaidDate, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq,
        		VendorGroup, Supplier, PayCategory,TotTaxAmount,GSTtaxAmt, OldGSTtaxAmt,
				ExpenseGST, Status 
        		FROM dbo.bAPTD
        		WHERE APCo=@apco AND Mth=@mth AND APTrans=@aptrans
        		AND APLine=isnull(@apline,APLine) AND APSeq=isnull(@apseq,APSeq)
        		AND ((@apline IS NULL AND Status = 1) OR (@apline IS NOT NULL AND Status IN (1, 2)))
				AND Supplier IS NULL
		END
		ELSE
		BEGIN
			DECLARE bcAPTD CURSOR
        		FOR SELECT APLine, APSeq, PayType, Amount, DiscOffer, DiscTaken, DueDate,
        		PaidMth, PaidDate, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq,
        		VendorGroup, Supplier, PayCategory,TotTaxAmount,GSTtaxAmt, OldGSTtaxAmt,
				ExpenseGST, Status 
        		FROM dbo.bAPTD
        		WHERE APCo=@apco AND Mth=@mth AND APTrans=@aptrans
        		AND APLine=isnull(@apline,APLine) AND APSeq=isnull(@apseq,APSeq)
        		AND ((@apline IS NULL AND Status = 1) OR (@apline IS NOT NULL AND Status IN (1, 2)))
		END
    
        /* open cursor */
        open bcAPTD
    
        /* set open cursor flag to true */
        select @APTDopened = 1
    
        begin transaction
    
        /* loop through all rows in this batch */
        detail_loop:
        	fetch next from bcAPTD into @dtlapline, @dtlapseq, @dtlpaytype, @dtlamount,
        		@dtldiscoffer, @dtldisctaken, @dtlduedate, @dtlpaidmth, @dtlpaiddate,
        		@dtlcmco, @dtlcmacct, @dtlpaymethod, @dtlcmref, @dtlcmrefseq, @dtleftseq,
        		@dtlvendgroup, @dtlsupplier, @dtlpaycategory,@dtltaxamount, @dtlgsttaxamount,
				@dtloldgsttaxamt, @dtlexpenseGSTyn, @dtlstatus
    
        	if @@fetch_status <> 0 and abs(@ttlamount) < abs(@payamount) select @rcode = 5
        	if @@fetch_status <> 0 goto trans_complete
    
            /* if total amount to release has not all been released ... */
    		IF (@mixedyn = 'N' AND abs(@amtreleased) < abs(@payamount))	--23549
    			OR (@mixedyn='Y' AND @amtreleased < @payamount)
                BEGIN
                /* if dtl amt <= amt left to release ... */
    			IF (@mixedyn = 'N' AND abs(@dtlamount) <= abs(@payamount - @amtreleased))	--23549
    				OR @mixedyn = 'Y' AND @dtlamount <= (@payamount - @amtreleased)
                /*if abs(@dtlamount) <= abs(@payamount - @amtreleased)*/
				BEGIN
					/* release entire detail */
					IF @dtlsupplier IS NULL AND @supplier IS NOT NULL
					BEGIN
							UPDATE dbo.bAPWD				
        						SET Supplier=@supplier
        					WHERE APCo=@apco 
								AND Mth=@mth 
								AND APTrans=@aptrans
        						AND APLine=@dtlapline 
								AND APSeq=@dtlapseq
					END

					SELECT @amtreleased = @amtreleased + @dtlamount -- #140765
					GOTO detail_loop_end
				END
    
                /* if current bAPTD Amount > amount left to release ... */
    			if (@mixedyn = 'N' and abs(@dtlamount) > abs(@payamount - @amtreleased))	--23549
    				or (@mixedyn = 'Y' and @dtlamount > (@payamount - @amtreleased))
    	            begin
					select @releaseamt = @payamount - @amtreleased
                	/* split trans detail opening part of if for payment */
            		-- calculate discount amounts for split
            		select @discoffer=0
            		select @disctaken=0
					select @tottaxamt=0,@gsttaxamt=0
            		if @distribflag='Y'
            			begin
            			select @discoffer = @dtldiscoffer * @releaseamt / @dtlamount 
            			select @disctaken = @dtldisctaken * @releaseamt / @dtlamount 
            			end
					-- calculate tax distribution for split
					if isnull(@distributetax,'N') = 'Y'
						begin
						select @tottaxamt = isnull(@dtltaxamount,0) * (@releaseamt/ @dtlamount)
						select @gsttaxamt = isnull(@dtlgsttaxamount,0) * (@releaseamt/@dtlamount)
						select @oldgsttaxamt = isnull(@dtloldgsttaxamt,0) * (@releaseamt/@dtlamount)
						end
					else
						begin
						select @tottaxamt = 0
						select @gsttaxamt = 0
						select @oldgsttaxamt = 0
						end
            		-- find next sequence number for split
            		select @newseq = max(APSeq)+1 from APTD
            			where APCo=@apco
            			and Mth=@mth
            			and APTrans=@aptrans
            			and APLine=@dtlapline
            		if @@rowcount = 0
            			begin
            			select @msg = 'Could not determine new sequence number.  Update cancelled!', @rcode=1
            			rollback transaction
            			goto bspexit
            			end

            		-- add new detail for open portion (split)
            		insert bAPTD (APCo,Mth,APTrans ,APLine ,APSeq ,PayType,Amount,DiscOffer,DiscTaken,DueDate,Status,
     			  		PaidMth,PaidDate,CMCo,CMAcct,PayMethod,CMRef,CMRefSeq, EFTSeq ,VendorGroup,Supplier,PayCategory,
						TotTaxAmount,GSTtaxAmt,OldGSTtaxAmt,ExpenseGST)
            			values (@apco, @mth, @aptrans, @dtlapline, @newseq, @dtlpaytype,@releaseamt,@discoffer,@disctaken,
    					@dtlduedate, 1,@dtlpaidmth, @dtlpaiddate, @dtlcmco, @dtlcmacct, @dtlpaymethod,@dtlcmref,
     					@dtlcmrefseq, @dtleftseq, @dtlvendgroup, isnull(@supplier,@dtlsupplier),@dtlpaycategory,
						@tottaxamt,@gsttaxamt,@oldgsttaxamt,@dtlexpenseGSTyn)
            		if @@rowcount = 0
            			begin
            			select @msg = 'Could not add transaction detail to bAPTD.  Update cancelled!', @rcode=1
            			rollback transaction
            			goto bspexit
            			end
					-- update amount released #137034
--					select @amtreleased = @amtreleased + @releaseamt
     			/* insert new detail in bAPWD */
				if @userid is not null
					begin
     				insert bAPWD (APCo,UserId,Mth,APTrans ,APLine,APSeq ,HoldYN,PayYN,DiscOffered,DiscTaken,
     				  DueDate,Supplier,VendorGroup ,Amount)
     				select @apco,@userid,@mth,@aptrans,@dtlapline,@newseq,'N',PayYN,@discoffer,@disctaken,
     						@dtlduedate,/*isnull(@dtlsupplier,@supplier)*/isnull(@supplier,@dtlsupplier),
    						@dtlvendgroup,@releaseamt
							from bAPWD where APCo=@apco and Mth=@mth and APTrans=@aptrans
            					and APLine=@dtlapline and APSeq=@dtlapseq
     				if @@rowcount = 0
     					begin
    					select @msg = 'Could not add transaction detail to bAPWD.  Update cancelled!', @rcode=1
    					rollback transaction
    					goto bspexit
    					end
					end
    
            		-- calculate discount amounts for Original
            		if @distribflag='Y'
            			begin
            			select @discoffer = @dtldiscoffer - @discoffer
            			select @disctaken = @dtldisctaken - @disctaken
            			end
            		else
            			begin
            			select @discoffer = @dtldiscoffer
            			select @disctaken = @dtldisctaken
            			end
					-- calculate tax distribution amounts for original
					if isnull(@distributetax,'N') = 'Y'
						begin
						select @tottaxamt = isnull(@dtltaxamount,0) - @tottaxamt
						select @gsttaxamt = isnull(@dtlgsttaxamount,0) - @gsttaxamt
						select @oldgsttaxamt = isnull(@dtloldgsttaxamt,0) - @oldgsttaxamt
						end
					else
						begin
						select @tottaxamt = isnull(@dtltaxamount,0) 
						select @gsttaxamt = isnull(@dtlgsttaxamount,0)
						select @oldgsttaxamt = 0
						end
    
            		-- update detail for hold portion (original)
            		update bAPTD
            			set Amount = @dtlamount - @releaseamt,TotTaxAmount = @tottaxamt,GSTtaxAmt = @gsttaxamt
            			where APCo=@apco and Mth=@mth and APTrans=@aptrans
            			and APLine=@dtlapline and APSeq=@dtlapseq
    
     				-- update discoffered, disctaken in bAPWD which updates bAPTD
					if @userid is not null
						begin 
     					update bAPWD set Amount = @dtlamount - @releaseamt,
            				DiscOffered = @discoffer, DiscTaken = @disctaken
            				where APCo=@apco and Mth=@mth and APTrans=@aptrans
            				and APLine=@dtlapline and APSeq=@dtlapseq
						end

					-- Update Holdback GST tax amounts. -- #136500
					-- criteria to meet to update GST tax amounts: 
					--  1. APTD.ExpenseGST = 'Y' (CA holdback detail with tax basis net holdback, holdback GST in it's own payable, expense holdback GST when released and paid)
					--	2. AP Addtl Pay Control form - Distribute Tax = 'Y', Apply current tax rate to split = 'Y'
					--  3. The APTD detail rec has not already had the GST tax updated - APTD.OldGSTtaxAmt = 0 (if it has already been udpated, OldGSTtaxAmt will not be 0)
					if isnull(@distributetax,'N') = 'Y' and isnull(@ApplyCurrTaxRateYN,'N') = 'Y' and isnull(@dtlexpenseGSTyn,'N') = 'Y' and @dtloldgsttaxamt = 0
					begin
						--Update Retainage split with new tax amount
						Update APTD set OldGSTtaxAmt=GSTtaxAmt, GSTtaxAmt = ((d.Amount - d.GSTtaxAmt) * t.NewRate),
							 TotTaxAmount = ((d.Amount - d.GSTtaxAmt) * t.NewRate)
						from APTD d
						join APTL l on d.APCo=l.APCo and d.Mth=l.Mth and d.APTrans=l.APTrans and d.APLine=l.APLine 
						left join HQTX t on l.TaxGroup = t.TaxGroup and l.TaxCode=t.TaxCode
						where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans and d.APLine=@dtlapline and d.APSeq=@newseq
						-- Now update Retainage APTD with new Amount
						Update APTD set Amount = ((d.Amount - d.OldGSTtaxAmt) + d.GSTtaxAmt)
						from APTD d
						where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans and d.APLine=@dtlapline and d.APSeq=@newseq
						--Update split Amount in APWD
						Update APWD set Amount = d.Amount 
						from APWD w join APTD d on w.APCo=d.APCo and w.Mth=d.Mth and w.APTrans=d.APTrans and w.APLine=d.APLine and w.APSeq=d.APSeq
						where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans 
            			and d.APLine=@dtlapline and d.APSeq=@newseq


						--Update Original if not on hold or being put on hold
						if isnull(@origholdflag,'N') = 'N' and @dtlstatus = 1 
						begin
						Update APTD set OldGSTtaxAmt=GSTtaxAmt, GSTtaxAmt = ((d.Amount - d.GSTtaxAmt) * t.NewRate),
							 TotTaxAmount = ((d.Amount - d.GSTtaxAmt) * t.NewRate)
						from APTD d
						join APTL l on d.APCo=l.APCo and d.Mth=l.Mth and d.APTrans=l.APTrans and d.APLine=l.APLine 
						left join HQTX t on l.TaxGroup = t.TaxGroup and l.TaxCode=t.TaxCode
						where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans and d.APLine=@dtlapline and d.APSeq=@dtlapseq
						-- Now update Retainage APTD with new Amount
						Update APTD set Amount =  ((d.Amount - d.OldGSTtaxAmt) + d.GSTtaxAmt)
						from APTD d
						where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans and d.APLine=@dtlapline and d.APSeq=@dtlapseq
						--Update orig Amount in APWD
						Update APWD set Amount = d.Amount 
						from APWD w join APTD d on w.APCo=d.APCo and w.Mth=d.Mth and w.APTrans=d.APTrans and w.APLine=d.APLine and w.APSeq=d.APSeq
						where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans 
        				and d.APLine=@dtlapline and d.APSeq=@dtlapseq
						end
					end -- END Update Holdback GST tax amounts. -- #136500

    	            -- apply hold code if selected	#22928
	        		if @origholdflag = 'Y' goto apply_holdcode
	
	                select @amtreleased = @amtreleased + @releaseamt --#137034
	                goto detail_loop_end
	                end   
                END
    
            /* if amount to release has all been released ... */
            if @amtreleased >= @payamount
                begin
                if @origholdflag = 'N'
					goto trans_complete
				else
        			goto apply_holdcode
                end
    
        	detail_loop_end:
    
        	    select @ttlamount = @ttlamount + @dtlamount
    
        		if @ttlamount <> @amt and @apline is null
					goto detail_loop
				else
					goto trans_complete
    
    
        apply_holdcode:
    
        	/* add APHD entry */
   			if not (@holdcode = @retholdcode /*)*/ -- #25136 - both holdcode and paytype test are part of the 'if not'
    				and ((@dtlpaycategory is null and @dtlpaytype <> @retpaytype)
    					 or (@dtlpaycategory is not null and @dtlpaytype <> (select RetPayType from
    						 bAPPC with (nolock) where APCo=@apco and PayCategory = @dtlpaycategory))))
    				and not exists (select 1 from bAPHD with (nolock) where APCo=@apco and Mth=@mth and
    					APTrans=@aptrans and APLine=@dtlapline and APSeq=@dtlapseq and HoldCode=@holdcode)
        		begin
        		insert bAPHD (APCo ,Mth   ,APTrans ,APLine ,APSeq   ,HoldCode)
     			values (@apco, @mth, @aptrans, @dtlapline, @dtlapseq, @holdcode)
        		if @@rowcount = 0
        			begin
        			select @msg = 'Could not add hold detail.  Update cancelled!', @rcode=1
        			rollback transaction
        			goto bspexit
        			end
        		end
    
        	goto detail_loop_end
    
    
        trans_complete:
    
        	commit transaction
    
    
        bspexit:
        	if @APTDopened = 1
        		begin
        		close bcAPTD
        		deallocate bcAPTD
        		end
    
        	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPProcessPartialPayments] TO [public]
GO
