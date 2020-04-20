SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPCheckReversal    Script Date: 8/28/99 9:35:58 AM ******/
CREATE              proc [dbo].[bspAPCheckReversal]
/***********************************************************
* CREATED BY:	kf	10/01/1997
* MODIFIED By:	GG	04/26/1999
* MODIFIED BY:	kb	08/23/1999 - always added ECM as 'E' no matter what it was in the orig line.
*				GG	02/21/2000 - fixed to pull distinct AP Lines
*				EN	06/01/2000 - #9700 - use a single PrePaidDate value for all new transactions
*				GG	01/21/2001 - #14022 - update bAPHB.ChkRev flag
*				MV	07/03/2002 - #17243 - insert DiscDate into bAPHB from bAPTH
*				MV	09/17/2002 - #17243 - rej1 fix 
*				MV	10/18/2002 - 18878 quoted identifier cleanup
*				MV	11/01/2002 - 18037 insert AddressSeq into bAPHB
*				MV	12/03/2002 - 19543 insert SeparatePayYN in bAPHB
*				MV	02/19/2004 - #18769 Pay Category / #23061 isnull wrap / performance enhancements
*				ES	03/11/2004 - #23061 isnull wrap
*				MV	03/19/2004 - #22554 pre paid date is an input parameter now.
*				TJL 03/25/2008 - #127347 Intl addresses
*				MV	03/31/2008 - #124737 Use closed job GLAcct when reversing/posting to a closed job
*				MV	11/25/2008 - #131205 - commented out BEGIN/COMMIT TRANS - instead delete headers w/no lines 
*				MV	07/13/2010 - #133107 - Reverse taxes on check reversals
*				EN	07/19/2010 - #133107 Fix for rej#1 - Getting error in code that gets paid retainage because SQL anticipated
*									multiple values returned by subquery even though there could only ever be one
*									Mary Ann's note: this code is not new to issue #133107, it's been around since #23062 in 2004
*									I'm a bit concerned that it is just now throwing an error.
*				CHS	01/14/2011	- #142401
*				CHS 08/30/2011	- B-05545
*				MV	05/23/2012	- TK-15148 Calculate InvTot per country specific requirements from sum of lines  
*
* USAGE:
* Called from the AP Check Reversal program to add prepaid reversing entries
* for a check paid in a closed month.  Option to also generate new open
* transactions, so that payment may be made in an open month.
*
*  INPUT PARAMETERS
*   @apco             AP Company
*   @batchmth         Batch Month - open month for new entries
*   @batchid          BatchId
*   @cmco             CM Company
*   @cmacct           CM Account - payment was made on this account
*   @cmref            CM Reference - check number to be reversed
*   @createopen       Option to create open transactions = 'Y' or 'N'
*   @cmrefseq         CM Reference Seq # of payment to be reversed
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         Failure
************************************************************/
(@apco bCompany, @batchmth bMonth, @batchid bBatchID, @cmco bCompany, @cmacct bCMAcct,
@cmref bCMRef, @createopen bYN, @cmrefseq tinyint,@prepaiddate bDate = null, @msg varchar(255) output)
   
    AS
   
    DECLARE @rcode int, @openTrans int, @openLines int, @openTrans1 int, @openLines1 int, @locked int,
    @retpaytype tinyint, @expmth bMonth, @aptrans bTrans, @netamt float, @batchseq int, @apline smallint,
    @Gross bDollar, @Discount bDollar, @Retainage bDollar, @APPDGross bDollar, @APPDRetainage bDollar, @APPDPrevPaid bDollar,
	@APPDPrevDiscTaken bDollar,@APPDBalance bDollar, @prepaidmth varchar(12),@jcco int, @job bJob,@phasegroup bGroup,
	@phase bPhase, @jcct as int, @posttoclosedjob bYN, @status int, @glacct bGLAcct,@TaxType int, @TaxGroup int, @TaxCode bTaxCode,
	@TaxBasis bDollar, @TaxAmount bDollar, @HQDefaultCountry varchar(3),@TotGrossAmt bDollar, @TotMiscAmt bDollar, @TotTaxAmt bDollar,
	@TotRetgAmt bDollar
   
    SET NOCOUNT ON
   
    SELECT @rcode = 0, @openTrans = 0, @openLines = 0, @openTrans1 = 0, @openLines1 = 0, @locked = 0

   
    -- get Retainage Pay Type
    SELECT @retpaytype = RetPayType
    FROM bAPCO WHERE APCo = @apco
    if @@rowcount = 0
    BEGIN
        select @msg = 'Missing AP Company.', @rcode = 1
        GOTO bspexit
    END
    
   -- get HQ default country
   SELECT @HQDefaultCountry = DefaultCountry
   FROM dbo.HQCO
   WHERE HQCo=@apco
   
    -- #22554 check if prepaiddate was entered in form.
   IF @prepaiddate is null
   BEGIN
		SELECT @msg = 'Missing Pre Paid Date.', @rcode = 1
		GOTO bspexit
   END
   -- #22554 create prepaidmth from prepaiddate
   SELECT @prepaidmth = convert(varchar(2),datepart(mm,@prepaiddate)) 
   	+ '/1/' + convert(varchar(4),datepart(yy,@prepaiddate))
   
    -- validate existing AP check
    EXEC @rcode = bspAPCheckReversalVal @apco, @batchmth, @batchid, @cmco, @cmacct, @cmref, @cmrefseq, @msg output
    IF @rcode <> 0 GOTO bspexit
   
    -- passed validation, lock existing AP Payment Header until we're done
    UPDATE dbo.bAPPH set InUseMth = @batchmth, InUseBatchId = @batchid
    WHERE APCo = @apco AND CMCo = @cmco AND CMAcct = @cmacct AND PayMethod = 'C'
        AND CMRef = @cmref AND CMRefSeq = @cmrefseq
    if @@rowcount <> 1
        BEGIN
        SELECT @msg = 'Unable to lock AP Payment Header.', @rcode = 1
        GOTO bspexit
        END
   
    SELECT @locked = 1  -- payment header is locked
   
	-- CHECK REVERSAL TRANSACTIONS
    -- use a cursor to loop through paid transactions to create prepaid reversing entries
    DECLARE bcTrans CURSOR LOCAL FAST_FORWARD FOR
     	SELECT Mth, APTrans, Gross, Retainage, PrevPaid, PrevDiscTaken, Balance
        FROM bAPPD WITH (NOLOCK)
        WHERE APCo = @apco AND CMCo = @cmco
			AND	CMAcct = @cmacct AND PayMethod = 'C' 
			AND CMRef = @cmref AND CMRefSeq = @cmrefseq
   
    -- open cursor
    OPEN bcTrans
    SELECT @openTrans = 1
   
    next_Trans:
        FETCH NEXT FROM bcTrans INTO @expmth, @aptrans, @APPDGross, @APPDRetainage, @APPDPrevPaid, @APPDPrevDiscTaken, @APPDBalance
        IF @@fetch_status = -1 goto end_Trans
        IF @@fetch_status <> 0 goto next_Trans
   
        -- calculate net amount, but don't subtract discount taken
        SELECT @netamt = @APPDGross - @APPDRetainage - @APPDPrevPaid - @APPDPrevDiscTaken - @APPDBalance
   
        -- get next batch seq #
     	SELECT @batchseq = ISNULL(MAX(BatchSeq),0) + 1
        FROM	dbo.bAPHB WITH (NOLOCK) WHERE Co = @apco AND Mth = @batchmth AND BatchId = @batchid
		
--		BEGIN TRAN
        -- add header batch entry for prepaid reversing transaction
     	INSERT dbo.bAPHB(Co, Mth, BatchId, BatchSeq, BatchTransType, VendorGroup, Vendor, APRef,
     		Description, InvDate,DiscDate, DueDate, InvTotal, PayControl, PayMethod,	CMCo, CMAcct,	--#17243 DiscDate
            PrePaidYN, PrePaidMth, PrePaidDate, PrePaidChk, PrePaidSeq, PrePaidProcYN,V1099YN,V1099Type,
   		 V1099Box, PayOverrideYN, PayName, PayAddress, PayCity, PayState, PayZip, PayCountry, ChkRev,AddressSeq, SeparatePayYN)
    	select @apco, @batchmth, @batchid, @batchseq, 'A', VendorGroup, Vendor, APRef, Description, InvDate,
   		ISNULL(DiscDate,DueDate), DueDate,/*-(@netamt)*/ 0, PayControl, 'C', @cmco, @cmacct, 'Y', @batchmth,	--#17243 DiscDate
   		 @prepaiddate, @cmref, (@cmrefseq +1), 'N',V1099YN, V1099Type, V1099Box, PayOverrideYN, PayName,
   		 PayAddress, PayCity, PayState, PayZip, PayCountry, 'Y', AddressSeq, SeparatePayYN
        FROM dbo.bAPTH
        WHERE APCo = @apco AND Mth = @expmth AND APTrans = @aptrans
        if @@rowcount <> 1
            BEGIN
            SELECT @msg = 'Unable to add a reversing transaction - Mth: ' +
                isnull(convert(varchar(2),datepart(month, @expmth)),'') + '/' +
     		      isnull(substring(convert(varchar(4),datepart(year, @expmth)),3,4),'') +
     			' Trans # ' + isnull(convert(varchar(6),@aptrans),''), @rcode = 1
            GOTO bspexit
            END
   
        -- use a cursor to loop through paid transaction lines to create reversals
        DECLARE bcLines cursor LOCAL FAST_FORWARD FOR
     	SELECT DISTINCT(l.APLine)
        FROM dbo.bAPTL l WITH (NOLOCK)
        JOIN dbo.bAPTD d WITH (NOLOCK) ON l.APCo = d.APCo and l.Mth = d.Mth and l.APTrans = d.APTrans and l.APLine = d.APLine
        WHERE l.APCo = @apco 
			AND l.Mth = @expmth		AND l.APTrans = @aptrans
            AND d.CMCo = @cmco		AND d.CMAcct = @cmacct 
			AND d.PayMethod = 'C'	AND d.CMRef = @cmref 
			AND d.CMRefSeq = @cmrefseq
   
        -- open cursor
        OPEN bcLines
        SELECT @openLines = 1
   
        next_Line:
            FETCH NEXT FROM bcLines into @apline
            if @@fetch_status = -1 goto end_Line
            if @@fetch_status <> 0 goto next_Line

			-- get tax information
			SELECT @TaxType=TaxType, @TaxGroup=TaxGroup, @TaxCode=TaxCode
			FROM dbo.bAPTL
			WHERE APCo = @apco AND Mth = @expmth
				AND APTrans = @aptrans
				AND APLine = @apline
   
            -- get line amounts based on paid amounts - all pay types
            SELECT	@Gross = isnull(sum(Amount - CASE @TaxType WHEN 2 THEN 0 ELSE isnull(TotTaxAmount, 0) END),0), -- CHS	01/14/2011	- #142401 
					@Discount = isnull(sum(DiscTaken),0),
					@TaxAmount = isnull(sum(TotTaxAmount),0)
            FROM dbo.bAPTD WITH (NOLOCK)
            WHERE APCo = @apco AND Mth = @expmth
				AND APTrans = @aptrans	AND APLine = @apline
                AND CMCo = @cmco		AND CMAcct = @cmacct 
				AND PayMethod = 'C'		AND CMRef = @cmref
                AND CMRefSeq = @cmrefseq
   
            -- get paid retainage
            SELECT @Retainage = isnull(sum(Amount - TotTaxAmount),0)
            FROM dbo.bAPTD d WITH (NOLOCK)
            WHERE d.APCo = @apco AND d.Mth = @expmth AND d.APTrans = @aptrans 
				AND d.APLine = @apline	AND d.CMCo = @cmco 
				AND d.CMAcct = @cmacct	AND d.PayMethod = 'C' 
				AND d.CMRef = @cmref	AND d.CMRefSeq = @cmrefseq 
				AND (
					(PayCategory IS NULL AND PayType = @retpaytype)
   					OR (PayCategory IS NOT NULL 
						AND EXISTS (SELECT 1 FROM dbo.bAPPC c 
							WHERE c.APCo=@apco 
							AND c.PayCategory=PayCategory 
							AND c.RetPayType=PayType)
						)
					)
   
			--Get closed job GL Acct  
			SELECT @jcco=l.JCCo, @job=l.Job, @phasegroup=l.PhaseGroup,@phase=l.Phase,@jcct=l.JCCType,@status=jm.JobStatus,
				@posttoclosedjob=PostClosedJobs
			FROM dbo.bAPTL l 
			JOIN dbo.bJCCO jc ON l.JCCo=jc.JCCo
			JOIN dbo.bJCJM jm ON l.JCCo=jm.JCCo AND l.Job=jm.Job 
            WHERE APCo = @apco AND Mth = @expmth
				AND APTrans = @aptrans AND APLine = @apline
				AND l.JCCo IS NOT NULL 
				AND	l.Job IS NOT NULL 
				AND l.Phase IS NOT NULL
				AND l.JCCType IS NOT NULL
			IF @@rowcount=1
				BEGIN
					IF @status = 3 --closed
						BEGIN
						--get closed job glacct
							EXEC @rcode =  bspJCCAGlacctDflt @jcco, @job,@phasegroup, @phase, @jcct,'N', @glacct = @glacct output,
								@msg = @msg output
							IF @glacct IS NULL
								BEGIN
									SELECT @msg = 'Unable to create reversing transaction, closed job Gl Account is missing for Job/Phase/CT: ' 
									+ convert(varchar(10),@job) + '/'
									+ convert(varchar(20),@phase) + '/'
									+ convert(varchar(3),@jcct), @rcode = 1
									goto bspexit
								END
							END
					ELSE --status is open use bAPTL GLAcct
						BEGIN
							SELECT @glacct=GLAcct
							FROM bAPTL 
							WHERE APCo = @apco AND Mth = @expmth AND APTrans = @aptrans AND APLine = @apline
						END
				END
			ELSE
				BEGIN
					SELECT @glacct=GLAcct 
					FROM bAPTL 
					WHERE APCo = @apco AND Mth = @expmth AND APTrans = @aptrans AND APLine = @apline
				END

            -- add line batch entry for reversing lines - B-05545
     	    INSERT dbo.bAPLB(Co, Mth, BatchId, BatchSeq, APLine, BatchTransType, LineType, PO, POItem, POItemLine, ItemType,
                SL, SLItem, JCCo, Job, PhaseGroup, Phase, JCCType, EMCo, WO, WOItem, Equip, EMGroup, CostCode,
                EMCType, CompType, Component, INCo, Loc, MatlGroup, Material, GLCo, GLAcct, Description, UM,
                Units, UnitCost, ECM, VendorGroup, Supplier, PayType,
				GrossAmt, MiscAmt, MiscYN, TaxGroup,TaxCode,
				TaxType, TaxBasis,TaxAmt, Retainage, Discount, BurUnitCost, BECM, PayCategory, SMCo, SMWorkOrder, Scope, SMCostType, SMJCCostType, SMPhaseGroup, SMPhase)
            SELECT @apco, @batchmth, @batchid, @batchseq, @apline, 'A', LineType, PO, POItem, POItemLine, ItemType,
                SL, SLItem, JCCo, Job, PhaseGroup, Phase, JCCType, EMCo, WO, WOItem, Equip, EMGroup, CostCode,
                EMCType, CompType, Component, INCo, Loc, MatlGroup, Material, GLCo, @glacct, Description, UM,
                0, 0, ECM, VendorGroup, Supplier, PayType,
				-(@Gross), 0, 'N', @TaxGroup, @TaxCode,
                @TaxType,0,-(@TaxAmount), -(@Retainage), -(@Discount), 0, BECM, PayCategory, SMCo, SMWorkOrder, Scope, SMCostType, SMJCCostType, SMPhaseGroup, SMPhase
            FROM bAPTL
            WHERE APCo = @apco AND Mth = @expmth AND APTrans = @aptrans AND APLine = @apline
            IF @@rowcount <> 1
                BEGIN
					SELECT @msg = 'Unable to add Line # ' + isnull(convert(varchar(6),@apline),'') +
						' for reversing transaction - Mth: ' + isnull(convert(varchar(2),datepart(month, @expmth)),'')
   					 + '/' + isnull(substring(convert(varchar(4),datepart(year, @expmth)),3,4),'') +
     					' Trans # ' + isnull(convert(varchar(6),@aptrans),''), @rcode = 1
					GOTO bspexit
                END
   
            GOTO next_Line
   
        end_Line:
            CLOSE bcLines
            DEALLOCATE bcLines
            SELECT @openLines = 0
            
            -- Update Invoice Total - TK-15148
            SELECT @TotGrossAmt = 0,@TotMiscAmt = 0,@TotTaxAmt = 0, @TotRetgAmt = 0
            SELECT		@TotGrossAmt =	SUM(ISNULL(GrossAmt,0)),
						@TotMiscAmt	=	SUM(CASE MiscYN WHEN 'Y' THEN ISNULL(MiscAmt,0) ELSE 0 END),
						@TotTaxAmt =	SUM(CASE TaxType WHEN 2 THEN 0 ELSE ISNULL(TaxAmt,0) END),
						@TotRetgAmt=	SUM(ISNULL(Retainage, 0))
			FROM dbo.bAPLB 
			WHERE Co=@apco AND Mth=@batchmth AND BatchId=@batchid AND BatchSeq=@batchseq
            
			UPDATE dbo.bAPHB
			SET InvTotal = @TotGrossAmt + @TotMiscAmt + @TotTaxAmt - CASE @HQDefaultCountry WHEN 'US' THEN 0 ELSE @TotRetgAmt END
			FROM dbo.bAPHB 
			WHERE Co=@apco AND Mth=@batchmth AND BatchId=@batchid AND BatchSeq=@batchseq
				 
            -- get next transaction
            GOTO next_Trans     
   
    end_Trans:
        CLOSE bcTrans
        DEALLOCATE bcTrans
        SELECT @openTrans = 0
   
    -- check to see if new 'open' transactions should be created
    IF @createopen <> 'Y' GOTO bspexit
   
	--NEW OPEN TRANSACTIONS 
    -- use a cursor to loop through paid transactions to create new entries
    DECLARE bcTrans1 CURSOR FOR
     	SELECT Mth, APTrans, Gross, Retainage, PrevPaid, PrevDiscTaken, Balance
        FROM dbo.bAPPD
        WHERE APCo = @apco AND CMCo = @cmco AND CMAcct = @cmacct 
			AND PayMethod = 'C' AND CMRef = @cmref
            AND CMRefSeq = @cmrefseq
   
    -- open cursor
    OPEN bcTrans1
    SELECT @openTrans1 = 1
   
    next_Trans1:
        FETCH NEXT FROM bcTrans1 INTO @expmth, @aptrans, @APPDGross, @APPDRetainage, @APPDPrevPaid, @APPDPrevDiscTaken, @APPDBalance
        IF @@fetch_status = -1 goto end_Trans1
        IF @@fetch_status <> 0 goto next_Trans1
   
        -- calculate net amount, but don't subtract discount taken
        SELECT @netamt = @APPDGross - @APPDRetainage - @APPDPrevPaid - @APPDPrevDiscTaken - @APPDBalance
   
        -- get next batch seq #
     	SELECT @batchseq = isnull(max(BatchSeq),0) + 1
        FROM dbo.bAPHB WHERE Co = @apco AND Mth = @batchmth AND BatchId = @batchid
   
        -- add header batch entry for new open transaction
     	INSERT bAPHB(Co, Mth, BatchId, BatchSeq, BatchTransType, VendorGroup, Vendor, APRef,
     		Description, InvDate,DiscDate,DueDate, InvTotal, PayControl, PayMethod,CMCo, CMAcct,  
            PrePaidYN, V1099YN, V1099Type, V1099Box, PayOverrideYN, PayName, PayAddress,
            PayCity, PayState, PayZip, PayCountry, ChkRev, AddressSeq, SeparatePayYN)
        SELECT @apco, @batchmth, @batchid, @batchseq, 'A', VendorGroup, Vendor, APRef, Description, InvDate,
   		ISNULL(DiscDate,DueDate), DueDate,/*@netamt*/ 0, PayControl, 'C', @cmco, @cmacct, 'N', V1099YN,
   		V1099Type, V1099Box, PayOverrideYN, PayName,PayAddress, PayCity, PayState, PayZip, PayCountry, 'Y',
   		AddressSeq,SeparatePayYN
 
        FROM dbo.bAPTH
        WHERE APCo = @apco AND Mth = @expmth AND APTrans = @aptrans
        IF @@rowcount <> 1
            BEGIN
				SELECT @msg = 'Unable to add a new open transaction - Mth: ' +
					isnull(convert(varchar(2),datepart(month, @expmth)), '') + '/' +	--#23061
     				  isnull(substring(convert(varchar(4),datepart(year, @expmth)),3,4), '') +
     				' Trans # ' + isnull(convert(varchar(6),@aptrans), ''), @rcode = 1
				GOTO bspexit
            eND
   
        -- use a cursor to loop through paid transaction lines to create new lines
        DECLARE bcLines1 CURSOR FOR
     	SELECT DISTINCT(l.APLine)
        FROM bAPTL l
        JOIN bAPTD d ON l.APCo = d.APCo AND l.Mth = d.Mth AND l.APTrans = d.APTrans AND l.APLine = d.APLine
        WHERE l.APCo = @apco AND l.Mth = @expmth AND l.APTrans = @aptrans
            AND d.CMCo = @cmco AND d.CMAcct = @cmacct AND d.PayMethod = 'C'
            AND d.CMRef = @cmref AND d.CMRefSeq = @cmrefseq
   
   
        -- open cursor
        OPEN bcLines1
        SELECT @openLines1 = 1
   
        next_Line1:
            FETCH NEXT FROM bcLines1 INTO @apline
            IF @@fetch_status = -1 goto end_Line1
            IF @@fetch_status <> 0 goto next_Line1
   

			-- get tax information
			SELECT @TaxType=TaxType, @TaxGroup=TaxGroup, @TaxCode=TaxCode
			FROM dbo.bAPTL
			WHERE APCo = @apco AND Mth = @expmth
				AND APTrans = @aptrans
				AND APLine = @apline

            -- get line amounts based on paid amounts - all pay types 
            SELECT	@Gross = isnull(sum(Amount - CASE @TaxType WHEN 2 THEN 0 ELSE  isnull(TotTaxAmount, 0) END),0), -- CHS	01/14/2011	- #142401 
				@Discount = isnull(sum(DiscTaken),0),
				@TaxAmount = isnull(sum(TotTaxAmount),0)
            FROM dbo.bAPTD
            WHERE APCo = @apco AND Mth = @expmth AND APTrans = @aptrans AND APLine = @apline
                AND CMCo = @cmco AND CMAcct = @cmacct AND PayMethod = 'C' AND CMRef = @cmref
                AND CMRefSeq = @cmrefseq
   
            -- get paid retainage
            SELECT @Retainage = ISNULL(SUM(Amount - TotTaxAmount),0)
            FROM dbo.bAPTD
            WHERE APCo = @apco AND Mth = @expmth AND APTrans = @aptrans AND APLine = @apline
                AND CMCo = @cmco AND CMAcct = @cmacct AND PayMethod = 'C' AND CMRef = @cmref
                AND CMRefSeq = @cmrefseq 
				AND (
					(PayCategory IS NULL AND PayType = @retpaytype)
   					OR (PayCategory IS NOT NULL 
						AND EXISTS (SELECT 1 FROM dbo.bAPPC c 
							WHERE c.APCo=@apco 
							AND c.PayCategory=PayCategory 
							AND c.RetPayType=PayType)
						)
					)

			--Get closed job GL Acct  
			SELECT @jcco=l.JCCo, @job=l.Job, @phasegroup=l.PhaseGroup,@phase=l.Phase,@jcct=l.JCCType,@status=jm.JobStatus,
				@posttoclosedjob=PostClosedJobs
			FROM dbo.bAPTL l 
			JOIN dbo.bJCCO jc ON l.JCCo=jc.JCCo
			JOIN dbo.bJCJM jm ON l.JCCo=jm.JCCo AND l.Job=jm.Job 
            WHERE APCo = @apco AND Mth = @expmth
				AND APTrans = @aptrans AND APLine = @apline
				AND l.JCCo IS NOT NULL 
				AND	l.Job IS NOT NULL 
				AND l.Phase IS NOT NULL
				AND l.JCCType IS NOT NULL
			IF @@rowcount=1
				BEGIN
					IF @status = 3 --closed
						BEGIN
						--get closed job glacct
							EXEC @rcode =  bspJCCAGlacctDflt @jcco, @job,@phasegroup, @phase, @jcct,'N', @glacct = @glacct output,
								@msg = @msg output
							IF @glacct IS NULL
								BEGIN
									SELECT @msg = 'Unable to create new transaction, closed job Gl Account is missing for Job/Phase/CT: ' 
									+ convert(varchar(10),@job) + '/'
									+ convert(varchar(20),@phase) + '/'
									+ convert(varchar(3),@jcct), @rcode = 1
									goto bspexit
								END
						END
					ELSE --status is open use bAPTL GLAcct
						BEGIN
							SELECT @glacct=GLAcct
							FROM bAPTL 
							WHERE APCo = @apco AND Mth = @expmth AND APTrans = @aptrans AND APLine = @apline
						END
				END
			ELSE
				BEGIN
					SELECT @glacct=GLAcct 
					FROM bAPTL 
					WHERE APCo = @apco AND Mth = @expmth AND APTrans = @aptrans AND APLine = @apline
				END

            -- add line batch entry for new lines - B-05545
     	    INSERT bAPLB(Co, Mth, BatchId, BatchSeq, APLine, BatchTransType, LineType, PO, POItem, POItemLine, ItemType,
                SL, SLItem, JCCo, Job, PhaseGroup, Phase, JCCType, EMCo, WO, WOItem, Equip, EMGroup, CostCode,
                EMCType, CompType, Component, INCo, Loc, MatlGroup, Material, GLCo, GLAcct, Description, UM,
				Units, UnitCost, ECM, VendorGroup, Supplier, PayType,
				GrossAmt, MiscAmt, MiscYN, TaxGroup,TaxCode,
				TaxType, TaxBasis,TaxAmt, Retainage, Discount, BurUnitCost, BECM, PayCategory, SMCo, SMWorkOrder, Scope, SMCostType, SMJCCostType, SMPhaseGroup, SMPhase)
            SELECT @apco, @batchmth, @batchid, @batchseq, @apline, 'A', LineType, PO, POItem, POItemLine, ItemType,
                SL, SLItem, JCCo, Job, PhaseGroup, Phase, JCCType, EMCo, WO, WOItem, Equip, EMGroup, CostCode,
                EMCType, CompType, Component, INCo, Loc, MatlGroup, Material, GLCo, @glacct, Description, UM,
                0, 0, ECM, VendorGroup, Supplier, PayType,
				@Gross, 0, 'N', @TaxGroup, @TaxCode,
                @TaxType,0 ,@TaxAmount, @Retainage, @Discount, 0, BECM, PayCategory, SMCo, SMWorkOrder, Scope, SMCostType, SMJCCostType, SMPhaseGroup, SMPhase
            FROM dbo.bAPTL
            WHERE APCo = @apco AND Mth = @expmth AND APTrans = @aptrans AND APLine = @apline
            IF @@rowcount <> 1
                BEGIN
                SELECT @msg = 'Unable to add Line # ' + isnull(convert(varchar(6),@apline), '') +	--#23061
                    ' for reversing transaction - Mth: ' + isnull(convert(varchar(2),datepart(month, @expmth)), '') + '/' +
     		        isnull(substring(convert(varchar(4),datepart(year, @expmth)),3,4), '') +
     			    ' Trans # ' + isnull(convert(varchar(6),@aptrans), ''), @rcode = 1
                GOTO bspexit
                END
   
            GOTO next_Line1
   
        end_Line1:
            CLOSE bcLines1
            DEALLOCATE bcLines1
            SELECT @openLines1 = 0
            
            -- Update Invoice Total - TK15148
            SELECT @TotGrossAmt = 0,@TotMiscAmt = 0,@TotTaxAmt = 0, @TotRetgAmt = 0
            SELECT		@TotGrossAmt =	SUM(ISNULL(GrossAmt,0)),
						@TotMiscAmt	=	SUM(CASE MiscYN WHEN 'Y' THEN ISNULL(MiscAmt,0) ELSE 0 END),
						@TotTaxAmt =	SUM(CASE TaxType WHEN 2 THEN 0 ELSE ISNULL(TaxAmt,0) END),
						@TotRetgAmt=	SUM(ISNULL(Retainage, 0))
			FROM dbo.bAPLB 
			WHERE Co=@apco AND Mth=@batchmth AND BatchId=@batchid AND BatchSeq=@batchseq
            
			UPDATE dbo.bAPHB
			SET InvTotal = @TotGrossAmt + @TotMiscAmt + @TotTaxAmt - CASE @HQDefaultCountry WHEN 'US' THEN 0 ELSE @TotRetgAmt END
			FROM dbo.bAPHB 
			WHERE Co=@apco AND Mth=@batchmth AND BatchId=@batchid AND BatchSeq=@batchseq
            			
             -- get next transaction
            GOTO next_Trans1    
   
    end_Trans1:
        CLOSE bcTrans1
        DEALLOCATE bcTrans1
        SELECT @openTrans1 = 0
   
    bspexit:
		IF @rcode=1
			BEGIN
			DELETE bAPHB FROM dbo.bAPHB h 
			WHERE h.Co=@apco AND h.Mth=@batchmth AND h.BatchId=@batchid 
				AND NOT EXISTS(SELECT * FROM dbo.bAPLB l WHERE l.Co=h.Co AND l.Mth=h.Mth AND l.BatchId=h.BatchId AND l.BatchSeq=h.BatchSeq) 
			END
		
        IF @openLines = 1
            BEGIN
            CLOSE bcLines
            DEALLOCATE bcLines
            END
        IF @openTrans = 1
            BEGIN
            close bcTrans
            DEALLOCATE bcTrans
            END
        if @openLines1 = 1
            BEGIN
            close bcLines1
            DEALLOCATE bcLines1
            END
        if @openTrans1 = 1
            BEGIN
            close bcTrans1
            DEALLOCATE bcTrans1
            END
   
        -- unlock AP Payment Header
        IF @locked = 1
            BEGIN
            update bAPPH set InUseMth = null, InUseBatchId = null
            WHERE APCo = @apco and CMCo = @cmco AND CMAcct = @cmacct and PayMethod = 'C'
                AND CMRef = @cmref AND CMRefSeq = @cmrefseq
   
            if @@rowcount <> 1
                BEGIN
                select @msg = 'Unable to unlock AP Payment Header.', @rcode = 1
                END
            END

     	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPCheckReversal] TO [public]
GO
