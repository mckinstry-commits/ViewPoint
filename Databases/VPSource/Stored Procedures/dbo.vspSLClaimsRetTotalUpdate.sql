SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE procedure [dbo].[vspSLClaimsRetTotalUpdate]
/*************************************
* Created By:	GF 12/15/2012 SL Claims Max Retention
* Modified By:	GF 03/20/2013 TFS-44418 need to get company flags for net retention and default country
*
*
* Called from SL Claims form.
* This procedure will take the amount to distribute and distribute
* to the claim items for the claim. The amount to distribute is not
* calculated here, but in the vspSLClaimRetTotalAmtGet and then passed to this procedure.
* 
* There will be 2 passes, the first pass will do a weighted distribution
* using the SLIT.WCRetpct. The second pass will apply any left over retention starting
* with the first item and applying left over up to but not
* to exceed the claim item approved amount.
*
* NOTE: If the amount to distribute is zero, then this procedure is basically zeroing
*		out the claim item retention.
*
* Pass:
* @SLCo				SL Company
* @Subcontract		Subcontract
* @ClaimNo			Claim Number
* @AmtToDistribute	retention amount to distribute to claim items
*
* Success returns:
*	0
*
* Error returns:
*	1 and error message
**************************************/
(@SLCo bCompany, @Subcontract VARCHAR(30), @ClaimNo INT
,@AmtToDistribute bDollar = 0
,@Msg VARCHAR(255) OUTPUT)

AS
SET NOCOUNT ON
 

DECLARE @rcode INT, @OpenCursor INT, @OpenCursorLeft INT, @DefaultCountry CHAR(2)
		,@SLClaimKeyID BIGINT, @TaxBasisNetRet CHAR(1), @ErrMsg VARCHAR(255)
		,@APInvNotClaimAmt bDollar, @ClaimPrevApproveAmt bDollar, @ClaimApproveAmt bDollar
		,@MaxRetgOpt CHAR(1), @WCRetPct NUMERIC(12,8)
		----
		,@SLRetBudget bDollar, @SLRetTaken bDollar, @SLRetRemain bDollar
		,@RetentionToTake bDollar, @RetentionAmtForThisClaim bDollar
		,@RetentionLeft bDollar, @ApproveRetPct bPct, @ApproveRetention bDollar
		,@OldApproveRetention bDollar, @TaxAmount bDollar 
		----
		,@SLItem bItem, @ApproveAmount bDollar, @SLITWCRetPct bPct,  @TaxRate bRate
  

SET @rcode = 0
SET @WCRetPct = 0

---- if missing a key value exit procedure without doing anything for now
IF @SLCo IS NULL OR @Subcontract IS NULL OR @ClaimNo IS NULL GOTO vspexit

---- TFS-44418 get default country, tax basis flag, and enforce catch up flag
select  @TaxBasisNetRet = a.TaxBasisNetRetgYN
		,@DefaultCountry = h.DefaultCountry
from dbo.bAPCO a
INNER JOIN dbo.bHQCO h ON h.HQCo=a.APCo
where APCo = @SLCo
IF @@ROWCOUNT = 0
	BEGIN
	SET @TaxBasisNetRet = 'N'
	SET @DefaultCountry = 'US'
	END

SET @RetentionLeft = @AmtToDistribute


/**********************************************************/
/*		START PROCESS TO DISTRIBUTION TO ITEMS            */
/**********************************************************/


BEGIN TRY
	---- start a transaction, commit after fully processed
    BEGIN TRANSACTION;

	---- declare cursor on vSLClaimItem
	---- Zero @RetentionLeft input must be processed incase user is zeroing out a previous entry
	DECLARE cSLClaimItem CURSOR LOCAL FAST_FORWARD FOR
			SELECT ci.SLItem, ISNULL(ci.ApproveAmount, 0), ISNULL(i.WCRetPct, 0),
					ISNULL(ci.ApproveRetention,0), ISNULL(ci.TaxAmount, 0), ISNULL(i.TaxRate, 0)

	FROM dbo.vSLClaimItem ci
	INNER JOIN dbo.vSLClaimHeader ch ON ch.SLCo=ci.SLCo AND ch.SL=ci.SL AND ch.ClaimNo=ci.ClaimNo
	INNER JOIN dbo.bSLHD h ON h.SLCo=ci.SLCo AND h.SL=ci.SL
	INNER JOIN dbo.bSLIT i ON i.SLCo=ci.SLCo AND i.SL=ci.SL AND i.SLItem=ci.SLItem
	WHERE ci.SLCo = @SLCo
		AND ci.SL = @Subcontract
		AND ci.ClaimNo = @ClaimNo

	----open
	OPEN cSLClaimItem
	SET @OpenCursor = 1

	----loop through all claim items
	cSLClaimItem_loop:
	FETCH NEXT FROM cSLClaimItem INTO @SLItem, @ApproveAmount, @SLITWCRetPct,
					@OldApproveRetention, @TaxAmount, @TaxRate

	IF @@fetch_status <> 0 GOTO cSLClaimItem_end

	SET @ApproveRetPct = 0
	SET @ApproveRetention = @OldApproveRetention

	SET @Msg = @Msg + dbo.vfToString(@SLItem) + ',' + dbo.vfToString(@SLITWCRetPct) + ',' 

	---- if the SLIT WCRetPct = 0 then we need to zero out approve retention values
	IF @SLITWCRetPct = 0
		BEGIN
		SET @ApproveRetention = 0
		END
	ELSE      
		BEGIN ----IF @SLITWCRetPct <> 0
--		/******************* Update the Claim Item approve retention **********************/
		/* The @WCRetPct - calculated contract pct is now used to recalculated Approve Retention */
		/* for each claim item. (Basically we are taking the calculated contract pct, as a whole */
		/* and recalculating Approve Retention values for each item) */

		IF (@RetentionLeft < 0 AND @ApproveAmount * @SLITWCRetPct > 0)
			OR (@RetentionLeft > 0 and @ApproveAmount * @SLITWCRetPct < 0)
   			BEGIN
   			---- Negative Item being processed. Will ultimately increase @wcretgleft.
   			SET @ApproveRetPct = @SLITWCRetPct
   			SET @ApproveRetention = @ApproveAmount * @SLITWCRetPct
   			END
		ELSE
			BEGIN
			---- Set Approve Retention % 
			IF @RetentionLeft = 0 or @ApproveAmount = 0
   				BEGIN
   				SET @ApproveRetPct = 0
   				END
			ELSE
   				BEGIN
   				select @ApproveRetPct =
							CASE WHEN ABS(@RetentionLeft) <= ABS(@ApproveAmount * @SLITWCRetPct)
   									THEN @RetentionLeft / @ApproveAmount
									ELSE @SLITWCRetPct
									END
   	   			END
   	   			
			---- Set Approve Retention
   			IF ABS(@RetentionLeft) <= ABS(@ApproveAmount * @SLITWCRetPct)
   				BEGIN
   				SET @ApproveRetention = @RetentionLeft
   				END
   			ELSE
   				BEGIN
   				SET @ApproveRetention = @ApproveAmount * @SLITWCRetPct
   				END
   			END
            
		END ---- END @SLITWCRetPct <> 0

	---- re-calculate tax if country not 'US' and APCo @TaxBasisNetRet = 'Y'
	IF @DefaultCountry <> 'US' AND @TaxBasisNetRet = 'Y'
		BEGIN
		SET @TaxAmount = (@ApproveAmount - @ApproveRetention) * @TaxRate
		END

	---- Update the claim item with the new calculated Approve retention Amount and percent
	---- if TaxBasisNetRet option is active, we will need to re-calculate tax amount as well
	UPDATE CI
		SET CI.ApproveRetention = @ApproveRetention,
   			CI.ApproveRetPct = @ApproveRetPct,
			CI.TaxAmount = @TaxAmount
   	FROM dbo.vSLClaimItem CI WITH (NOLOCK)
   	JOIN dbo.bSLIT SLIT WITH (NOLOCK) ON SLIT.SLCo=CI.SLCo and SLIT.SL=CI.SL AND SLIT.SLItem=CI.SLItem
	WHERE CI.SLCo = @SLCo
		AND CI.SL = @Subcontract
		AND CI.ClaimNo = @ClaimNo
		AND CI.SLItem = @SLItem
		AND @ApproveRetention <> @OldApproveRetention

	---- Keep running total of amount having been distributed amongst the items.  We will adjust for rounding error later
   	SET @RetentionLeft = @RetentionLeft - @ApproveRetention

	SET @Msg = @Msg + dbo.vfToString(@ApproveRetPct) + ',' + dbo.vfToString(@ApproveRetention) + ',' + dbo.vfToString(@RetentionLeft) + CHAR(13) + CHAR(10)

	---- next claim item
	GOTO cSLClaimItem_loop


	---- no more claim items to process
	cSLClaimItem_end:
		IF @OpenCursor = 1
			BEGIN
			CLOSE cSLClaimItem
			DEALLOCATE cSLClaimItem
			SET @OpenCursor = 0
			END


	/* If there is a difference between the Retainage Amount and the running total,
	   update the first item with the remaining amount not to exceed 100% of the Billed Amt
	   on the item.  Move on to the next item if necessary. 

	   Begin 2nd pass through items as required and distribute leftover amounts caused by
	   rounding issues beginning with the first item.  Typically, you will never get passed the
	   very first item on the 2nd pass. 

	   If there are some items on this bill whose amounts are opposite in polarity to the
	   overall bill amounts  (Negative items on a positive bill) then leftover amounts
	   caused by rounding issues will be distributed only to the normal positive items. (skip odd negative items)
	   Typically we are talking relatively small amounts leftover and the full leftover positive
	   amount will be distributed. */

	SET @Msg = @Msg + 'Left Over: ' + dbo.vfToString(@RetentionLeft)

	if @RetentionLeft <> 0 AND @AmtToDistribute <> 0 ----if @billedretg <> 0 and @wcretgleft <> 0 
		BEGIN
  
		---- declare cursor on vSLClaimItem for left over retention
		DECLARE cSLClaimItemLeft CURSOR LOCAL FAST_FORWARD FOR
				SELECT ci.SLItem, ISNULL(ci.ApproveAmount, 0), ISNULL(ci.ApproveRetention,0),
						ISNULL(ci.ApproveRetPct, 0), ISNULL(ci.TaxAmount, 0), ISNULL(i.TaxRate, 0)

		FROM dbo.vSLClaimItem ci
		INNER JOIN dbo.vSLClaimHeader ch ON ch.SLCo=ci.SLCo AND ch.SL=ci.SL AND ch.ClaimNo=ci.ClaimNo
		INNER JOIN dbo.bSLHD h ON h.SLCo=ci.SLCo AND h.SL=ci.SL
		INNER JOIN dbo.bSLIT i ON i.SLCo=ci.SLCo AND i.SL=ci.SL AND i.SLItem=ci.SLItem
		WHERE ci.SLCo = @SLCo
			AND ci.SL = @Subcontract
			AND ci.ClaimNo = @ClaimNo
			AND ci.ApproveAmount <> 0 ---- must have an approved amount
			AND ci.ApproveRetPct <> 0 ---- must have retention pct

		----open
		OPEN cSLClaimItemLeft
		SET @OpenCursorLeft = 1

		----loop through all claim items
		cSLClaimItemLeft_loop:
		FETCH NEXT FROM cSLClaimItemLeft INTO @SLItem, @ApproveAmount, @OldApproveRetention,
							@ApproveRetPct, @TaxAmount, @TaxRate

		IF @@fetch_status <> 0 GOTO cSLClaimItemLeft_end

		SET @ApproveRetention = 0

		SET @Msg = @Msg + dbo.vfToString(@SLItem)


		/* Do not attempt to apply minor rounding leftover amounts to Reverse polarity 
			items (Neg items on Positive Bill or visa versa).  This only further increases the leftover
			amount needing to be distributed.  Skip these items. */
		IF (@ApproveAmount < 0 AND @AmtToDistribute > 0) OR (@ApproveAmount > 0 AND @AmtToDistribute < 0)
			BEGIN
			GOTO cSLClaimItemLeft_loop
			END


		/* At this point we are applying leftover amounts to the correct polarity item (Normally positive) */
		IF @RetentionLeft <> 0 AND @ApproveRetPct <> 0
			BEGIN
   			IF (@RetentionLeft < 0 AND @ApproveRetention > 0) OR (@RetentionLeft > 0 AND @ApproveRetention < 0)
   				BEGIN
   				/* Due to rounding, too much has been applied overall (Amount Left has gone Negative).  
   					Take some back on the first item. */
   				SET @ApproveRetention = @RetentionLeft
   				END
   			ELSE
   				BEGIN
   				/* Due to rounding, not enough has yet been applied.  Place more on the first item, then 
   					second if necessary. */				
   				SELECT @ApproveRetention = 
						CASE WHEN ABS(@ApproveAmount) >= (ABS(@RetentionLeft) + ABS(@OldApproveRetention)) 
   							 THEN @RetentionLeft
							 ELSE @ApproveAmount - @OldApproveRetention
							 END
   				END

			---- update retention left
			select @RetentionLeft = @RetentionLeft - @ApproveRetention

			---- we need to set update vaLues here to calculate tax amounts if applicable
			---- @ApproveRetention is added to existing item retention
			SET @ApproveRetention = @ApproveRetention + @OldApproveRetention

			---- calculate approve retention pct - approve amount will never be zero
			SET @ApproveRetPct = @ApproveRetention / @ApproveAmount
			
			---- re-calculate tax if country not 'US' and APCo @TaxBasisNetRet = 'Y'
			IF @DefaultCountry <> 'US' AND @TaxBasisNetRet = 'Y'
				BEGIN
				SET @TaxAmount = (@ApproveAmount - @ApproveRetention) * @TaxRate
				END

			------ update claim item
			UPDATE CI
				SET CI.ApproveRetention = @ApproveRetention,
   					CI.ApproveRetPct = @ApproveRetPct,
					CI.TaxAmount = @TaxAmount
   			FROM dbo.vSLClaimItem CI WITH (NOLOCK)
   			JOIN dbo.bSLIT SLIT WITH (NOLOCK) ON SLIT.SLCo=CI.SLCo and SLIT.SL=CI.SL AND SLIT.SLItem=CI.SLItem
			WHERE CI.SLCo = @SLCo
				AND CI.SL = @Subcontract
				AND CI.ClaimNo = @ClaimNo
				AND CI.SLItem = @SLItem
   		
			END ---- @RetentionLeft <> 0 AND @ApproveRetPct <> 0

		---- Get next Item if an amount still remains
		IF @RetentionLeft <> 0 GOTO cSLClaimItemLeft_loop

		END  ----END @RetentionLeft <> 0

	---- no more claim items to process
	cSLClaimItemLeft_end:
		IF @OpenCursorLeft = 1
			BEGIN
			CLOSE cSLClaimItemLeft
			DEALLOCATE cSLClaimItemLeft
			SET @OpenCursorLeft = 0
			END

	---- update has completed. commit transaction
	COMMIT TRANSACTION


END TRY
BEGIN CATCH
    -- Test XACT_STATE:
        -- If 1, the transaction is committable.
        -- If -1, the transaction is uncommittable and should 
        --     be rolled back.
        -- XACT_STATE = 0 means that there is no transaction and
        --     a commit or rollback operation would generate an error.
	IF XACT_STATE() <> 0
		BEGIN
		ROLLBACK TRANSACTION
		SET @Msg = CAST(ERROR_MESSAGE() AS VARCHAR(200)) 
		SET @rcode = 1
		END
END CATCH


---- update claim header approved retention to sum of claim items
EXEC dbo.vspSLClaimApproveRetUpdate @SLCo, @Subcontract, @ClaimNo, @ErrMsg OUTPUT



vspexit:
	if @rcode <> 0 select @Msg = @Msg
	return @rcode




--/* Set the starting Distribution amount for countdown.  Even though distribution is based upon the 
--   Input PCT value we still do not want to allow distributing more than the user input 
--   dollar value.  This will counter the effect of a rounded UP or DOWN PCT value input. */
--select @wcretgleft = @billedretg

--/* Zero @billedretg input must be processed incase user is zeroing out a previous entry */
--declare bcItem cursor local fast_forward for
--select t.Item, isnull(t.WC,0), isnull(t.WCRetg,0), isnull(t.RetgRel,0),
--	t.WCRetPct
--from bJBIT t with (nolock)
--join JBITProgGrid tg on tg.JBCo = t.JBCo and tg.BillMonth = t.BillMonth and tg.BillNumber = t.BillNumber and tg.Item = t.Item
--where t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnumber
   
--open bcItem
--select @openitemcursor = 1

--fetch next from bcItem into @jbitem, @wcitemamt, @oldwcretg, @retgrel, 
--	@billitemwcpct
--while @@fetch_status = 0
--   	begin	/* Begin Item Loop. */

--	select @wcretg = @oldwcretg, @xwcretg = 0, @xsmretg = 0, @amtbilled = 0, 
--		@retgbilled = 0


--	if  @billitemwcpct <> 0
--   		begin
--		/******************* Update the JBIT work complete retainage. **********************/
--   		/* The WCPct input from the JBProgBillRetgTot form is now used to recalculated WCRetg for
--   		   each item.  (Basically we are taking the new override bill amount/Pct, as a whole, and
--   		   recalculating WCRetg values for each item) */
--   		if @source <> 'JBRetainTotals' and @diststyle = 'I'
--   			begin
--   			if (@wcretgleft < 0 and (case @roundopt when 'R' then round(@wcitemamt * @billitemwcpct, 0) else @wcitemamt * @billitemwcpct end) > 0) 
--   				or (@wcretgleft > 0 and (case @roundopt when 'R' then round(@wcitemamt * @billitemwcpct, 0) else @wcitemamt * @billitemwcpct end) < 0)
--   				begin
--   				/* Negative Item being processed. Will ultimately increase @wcretgleft. */
--   				select @wcpct = @billitemwcpct
--   				select @wcretg = (case @roundopt when 'R' then round(@wcitemamt * @billitemwcpct, 0) else @wcitemamt * @billitemwcpct end)
--   				end
--   			else
--   				begin
--   				/* Set Retainage % */
--   				if @wcretgleft = 0 or @wcitemamt = 0
--   					begin
--   					select @wcpct = 0
--   					end
--   				else
--   					begin
--   					select @wcpct = case when abs(@wcretgleft) <= abs(case @roundopt when 'R' then round(@wcitemamt * @billitemwcpct, 0) else @wcitemamt * @billitemwcpct end)
--   						then @wcretgleft / @wcitemamt else @billitemwcpct end
--   	   				end
   	   			
--   	   			/* Set WC Retainage */
--   				if abs(@wcretgleft) <= abs((case @roundopt when 'R' then round(@wcitemamt * @billitemwcpct, 0) else @wcitemamt * @billitemwcpct end))
--   					begin
--   					select @wcretg = @wcretgleft
--   					end
--   				else
--   					begin
--   					select @wcretg = case @roundopt when 'R' then round(@wcitemamt * @wcpct, 0) else @wcitemamt * @wcpct end
--   					end
--   				end
--   			end
--   		Else
--   			begin
--   			/* Retainage % will be a composite value and has already been passed into this procedure.  No need to recalculate.
--   			   Set WC Retainage only. */
--			select @wcretg = case @roundopt when 'R' then round(@wcitemamt * @wcpct, 0) else @wcitemamt * @wcpct end
--			end

--		/* Update the item with the new calculated WC retainage amount based upon WCPct input. */
--		/* Those bill items with a Retainage % value set to 0.00% have been SKIPPED entirely. */
--		update t
--		set t.WCRetg = @wcretg,
--   			t.WCRetPct = case when @enforcemaxretg = 'Y' 
--   				/* Max Retainage limit is about to be enforced here.  @wcpct & @wcretg are correct for each other as determined above */
--   				then case when t.WC = 0 then 0 else @wcpct end else 
--   				/* Normal Retainage Totals from Retainage Totals form.  @wcpct comes directly from the user input. */
--   				-- There is retainage to be distributed.  Those Bill Items w/out a billedamt will keep the Retainage % currently on bill item.
--   				case when @wcpct <> 0 and t.WC = 0 then @billitemwcpct
--   				-- Normal:  @wcretg is calculated from the @wcpct passed in therefore use the WC Percent value passed in.
--   				when (@wcpct <> 0 and t.WC <> 0 and @wcretgleft <> 0 and ((@wcretgleft - @wcretg) <> 0)) then @wcpct
--   				-- Normal:  @wcretg is calculated from the @wcpct passed in therefore use the WC Percent value passed in.
--   				when (@wcpct <> 0 and t.WC <> 0 and @wcretgleft <> 0 and ((@wcretgleft - @wcretg) = 0)) then @wcpct	
--   				-- Retainage is being Zero'd out.  Reset WC Percent to Contract Item default for startover.  There is no other logical reset value
--   				when (@wcpct = 0 and @wcretgleft = 0 and @wcretg = 0) then i.RetainPCT
--   				-- If @wcpct <> 0 and @wcretgleft = 0 then this might occur because of a Negative Item. Using @wcpct might be the best choice 
--   			else @wcpct end end,
--   			AuditYN = 'N'
--   		from bJBIT t with (nolock)
--   		join bJCCI i with (nolock) on i.JCCo = t.JBCo and i.Contract = t.Contract and i.Item = t.Item
--		where t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnumber and t.Item = @jbitem 
--   		--	and @wcretg <> @oldWCRetg

--   		/* Keep running total of amount having been distributed amongst the items.  We will adjust for 
--   		   rounding error later. */
--   		select @wcretgleft = @wcretgleft - @wcretg
--		end


--	update bJBIT
--	set AuditYN = 'Y'
--	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and Item = @jbitem
		
--	/* Get next item. We want to process ALL items at the WCPct rate. */
--	fetch next from bcItem into @jbitem, @wcitemamt, @oldwcretg, @retgrel, 
--		@billitemwcpct
--	end		/* End Item Loop. */
   
--if @openitemcursor = 1
--	begin
--	close bcItem
--	deallocate bcItem
--	select @openitemcursor = 0
--	end
   
--/* If there is a difference between the Retainage Amount and the running total,
--   update the first item with the remaining amount not to exceed 100% of the Billed Amt
--   on the item.  Move on to the next item if necessary. 

--   Begin 2nd pass through items as required and distribute leftover amounts caused by
--   rounding issues beginning with the first item.  Typically, you will never get passed the
--   very first item on the 2nd pass. 

--   If there are some items on this bill whose amounts are opposite in polarity to the
--   overall bill amounts  (Negative items on a positive bill) then leftover amounts
--   caused by rounding issues will be distributed only to the normal positive items. (skip odd negative items)
--   Typically we are talking relatively small amounts leftover and the full leftover positive
--   amount will be distributed. */
   
--if @billedretg <> 0 and (@wcretgleft <> 0 or @smretgleft <> 0)
--    begin	/* Begin excess amount remains */
--	declare bcItem cursor local fast_forward for
--	select t.Item, i.ContractAmt, isnull(t.WC,0), isnull(t.WCRetg,0), isnull(t.SM,0), isnull(t.SMRetg,0), isnull(t.RetgRel,0),
--		t.TaxGroup, t.TaxCode, t.WCRetPct, tg.SMRetgPct
--	from bJBIT t with (nolock)
--	join bJCCI i with (nolock) on i.JCCo = t.JBCo and i.Contract = t.Contract and i.Item = t.Item
--	join JBITProgGrid tg on tg.JBCo = t.JBCo and tg.BillMonth = t.BillMonth and tg.BillNumber = t.BillNumber and tg.Item = t.Item
--	where t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnumber
   
--	open bcItem
--	select @openitemcursor = 1
   
--	fetch next from bcItem into @jbitem, @contractitemamt, @wcitemamt, @oldwcretg, @retgrel, 
--		@billitemwcpct
--	while @@fetch_status = 0
--   		begin	/* Begin excess amount Item Loop */
--		select @wcretg = 0, @xwcretg = 0, @amtbilled = 0, 
--			@retgbilled = 0, @amountdue = 0

--		/* Do not attempt to apply minor rounding leftover amounts to Reverse polarity 
--		   items (Neg items on Positive Bill or visa versa).  This only further increases the leftover
--		   amount needing to be distributed.  Skip these items. */
--		if (@contractitemamt < 0 and @billedretg > 0) or (@contractitemamt > 0 and @billedretg < 0)		--Typically Pos, Pos
--			begin
--			goto NextItem
--			end
--		else
--   			/* At this point we are applying leftover amounts to the correct polarity item (Normally positive) */
--   			begin 
--			if @wcretgleft <> 0 and @billitemwcpct <> 0
--   				begin
--   				if (@wcretgleft < 0 and @billedretg > 0) or (@wcretgleft > 0 and @billedretg < 0)	--Typically Pos, Pos
--   					begin
--   					/* Due to rounding, too much has been applied overall (Amount Left has gone Negative).  
--   					   Take some back on the first item. */
--   					select @xwcretg = @wcretgleft
--   					end
--   				else
--   					begin
--   					/* Due to rounding, not enough has yet been applied.  Place more on the first item, then 
--   				       second if necessary. */				
--   					select @xwcretg = case when abs(@wcitemamt) >= (abs(@wcretgleft) + abs(@oldwcretg)) 
--   							then @wcretgleft else (@wcitemamt - @oldwcretg) end
--   					end
		
--   		    	update bJBIT
--   				set WCRetg = (WCRetg + @xwcretg), 
--   					WCRetPct = case when WC = 0 then 0 else (WCRetg + @xwcretg)/WC end,
--   					AuditYN = 'N'
--   		    	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and Item = @jbitem
   		
--   				/* If additional amount still remains, get next item. */
--   				select @wcretgleft = @wcretgleft - @xwcretg
--				end

--				end


--   			end
   
--		/* Get next Item if an amount still remains, else exit loop to save time.  */
--	NextItem:
--		if (@wcretgleft = 0) goto SecondLoopExit

--		update bJBIT
--		set AuditYN = 'Y'
--		where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and Item = @jbitem
	
--		fetch next from bcItem into @jbitem, @contractitemamt, @wcitemamt, @oldwcretg, @retgrel, 
--			@billitemwcpct
--		end		/* End excess amount Item Loop */
   
--SecondLoopExit:
--	if @openitemcursor = 1
--		begin
--		close bcItem
--		deallocate bcItem
--		select @openitemcursor = 0
--		end

--	/* If Excess amount is still not 0.00 then users must be warned and input value must be adjusted. 
--	   This is very unlikely to happen.  (I think it occurs as a result of the user inputting an overall
--	   Dollar Amount that does not calculate out to an even Percentage value (ie: 1750 retg / 3000 itemamt = .5833333)).  
	   
--	   The Pct value gets rounded down to 58.33% overall so the amount distributed comes up short initially.
--	   If the item values are just right (too few items, too small in value), I believe its possible to apply 
--	   the remaining amount to all items on the second pass and still have an amount left undistributed.  
--	   (It came up in testing or I would not have been aware of this) */
--	if @wcretgleft <> 0
--		begin
--		select @msg = 'The full WC Retainage was not distributed due to special circumstances and rounding.  '
--		select @msg = @msg + 'To correct, apply an additional ' + convert(varchar, @wcretgleft) + ' amount to WC Retainage on an item on the bill.'
--		select @msg = @msg + char(13) + char(10) + char(13) + char(10)
--		--select @msg = @msg + 'A lesser input value may be due to the effect of Negative item values on this process.'
--		select @rcode = 1
--		end

--	end		/* End excess amount remains */



















GO
GRANT EXECUTE ON  [dbo].[vspSLClaimsRetTotalUpdate] TO [public]
GO
