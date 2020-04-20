SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPBVoid    Script Date: 8/28/99 9:32:32 AM ******/
CREATE   proc [dbo].[bspAPPBVoid]
/******************************************************************************
* Created: ??
* MODIFIED By : kb 02/24/99 - fixed problem where when voiding a check it was
*	                    inserting the APPB record with the amount then when adding the detail batch
* 	                    records the trigger was also updating the APPB record's amount so the amount
* 	                    was coming out doubled.
*               EN 01/22/00 - expand dimension of @name to varchar(60) and include AddnlInfo when insert bAPPB
*               GG 11/27/00 - changed datatype from bAPRef to bAPReference
*               GG 07/20/01 - rewritten to fix logic when voiding all seqs on an EFT (#12789)
*			 	MV 10/09/02 - #18842 for manual voids recalc amounts in bAPTB after recs are inserted 
*				MV 02/19/04 - #18769 PayCategory / #23061 isnull wrap / performance enhancements
*				MV 03/01/05 - #27220 - include paidmth in select for APTD validcount
*				MV 07/31/07 - #27763 - ltrim CMRef and @cmref
*				TJL 03/25/08 - #127347 Intl addresses 
*				KK 04/25/12 - B-08618 - Modified to include pay method Credit Service
*
* USAGE:
* Called by AP Void program to pull payments from AP Payment History into an AP Payment Batch
* to be cleared or voided.
*
* INPUT PARAMETERS
*   @co            AP Company #
*   @mth           Batch month of payments
*   @batchid       Batch ID#
*   @cmco          CM Company #
*   @cmacct        CM Account
*   @paymethod     'C' = check, 'E' = EFT, 'S' = Credit Service
*   @cmref         CM Reference to void
*   @cmrefseq      CM Reference Sequence (checks only, null if EFT or Credit Service)
*   @sendeftseq    EFT Seq # to void (null if all seqs)
*   @reuseYN       'Y' = CM Ref# can be reused, 'N' = CM Ref# recorded as void
*   @voidmemo      Memo to record with void
*
* OUTPUT PARAMETERS
*   @count         # of payments processed
*   @msg           error message
*
* RETURN VALUE
*   0         success
*   1         Failure
******************************************************************************/
(@co bCompany = NULL, 
 @mth bMonth = NULL, 
 @batchid bBatchID = NULL, 
 @cmco bCompany = NULL,
 @cmacct bCMAcct = NULL, 
 @paymethod char(1) = NULL, 
 @cmref bCMRef = NULL, 
 @cmrefseq tinyint = NULL,
 @sendeftseq smallint = NULL, 
 @reuseYN bYN = NULL, 
 @voidmemo varchar(255) = NULL, 
 @count int OUTPUT,
 @msg varchar(255) OUTPUT)

AS
SET NOCOUNT ON
   
DECLARE @rcode int, 
		@seq int, 
		@voidyn bYN, 
		@eftseq smallint, 
		@inusemth bMonth, 
		@inusebatchid bBatchID,
        @openPayment tinyint, 
        @paidmth bMonth, 
        @validcnt int, 
        @chktype char(1)
   
SELECT @rcode = 0, @count = 0, @openPayment = 0
   
-- B-08618 Credit service paymennts need EFTSeq and CMRefSeq set to 0
IF @paymethod IN ('C','S') SELECT @sendeftseq = 0 -- flag NOT EFT for Check/Credit Service payements
IF @paymethod IN ('E','S') SELECT @cmrefseq = 0  -- will always be 0 for EFT/Credit Service payments
IF @sendeftseq IS NOT NULL SELECT @eftseq = @sendeftseq -- EFT seq # to null
   
-- process all sequences included in EFT (If null, process all EFT seq)
IF @sendeftseq IS NULL
BEGIN
	DECLARE Payment CURSOR FOR
	SELECT EFTSeq
	FROM bAPPH
	WHERE APCo = @co 
		  and CMCo = @cmco 
		  and CMAcct = @cmacct 
		  and PayMethod = 'E'
		  and CMRef = @cmref 
		  and CMRefSeq = 0  -- all EFT Seq#s
	OPEN Payment
	SELECT @openPayment = 1

	FETCH NEXT FROM Payment INTO @eftseq

	IF @@fetch_status <> 0
	BEGIN
		SELECT @msg = 'No payment sequences found for this EFT.', @rcode = 1
		GOTO bspexit
	END
END
   
process_payment:   -- process a single Check, EFT or Credit Service sequence
	-- get payment info from AP Payment History and validate
	SELECT @paidmth = PaidMth, 
		   @voidyn = VoidYN, 
		   @inusebatchid = InUseBatchId,
		   @inusemth = InUseMth, 
		   @chktype = ChkType
	  FROM bAPPH WITH (NOLOCK)
	 WHERE APCo = @co 
		   and CMCo = @cmco 
		   and CMAcct = @cmacct 
		   and PayMethod = @paymethod
		   and LTRIM(CMRef) = LTRIM(@cmref) 
		   and CMRefSeq = @cmrefseq  -- 0 if EFT/Credit Service
		   and EFTSeq = @eftseq -- 0 if Check/Credit Service
	  
	IF @@rowcount = 0 -- no records were found in APPH with this reference/sequence information
	BEGIN
		IF @sendeftseq IS NULL
			GOTO next_payment    -- if not found when processing all seq#s, skip
		
		SELECT @msg = 'CM Ref #:' + ISNULL(@cmref,'') -- CM Ref is the only criteria needed for CredServ error msg
	   
		IF @paymethod = 'C' SELECT @msg = ISNULL(@msg,'') + ' CM Ref Seq #: ' + ISNULL(CONVERT(varchar(3),@cmrefseq),'')
		IF @paymethod = 'E' SELECT @msg = ISNULL(@msg,'') + ' EFT Seq #: ' + ISNULL(CONVERT(varchar(6),@eftseq),'')
		
		SELECT @msg = ISNULL(@msg,'') + ' not found in AP Payment History.', @rcode = 1	
			GOTO bspexit
	END
	
	IF @mth <> @paidmth
	BEGIN
		IF @sendeftseq IS NULL 
			GOTO next_payment    -- if not found when processing all seq#s, skip
			
		SELECT @msg = 'Paid month must match Batch month', @rcode = 1
		GOTO bspexit
	END
	
	IF @voidyn = 'Y'
	BEGIN
		IF @sendeftseq IS NULL 
			GOTO next_payment    -- if not found when processing all seq#s, skip
			
		SELECT @msg = 'Payment has already been voided.', @rcode = 1
		GOTO bspexit
	END
	
	IF @inusebatchid IS NOT NULL OR @inusemth IS NOT NULL
	BEGIN
		IF @sendeftseq IS NULL 
			GOTO next_payment    -- if not found when processing all seq#s, skip
			
		SELECT @msg = 'Payment already in use by Batch #:' + ISNULL(CONVERT(varchar(10),@inusebatchid),''),
			   @rcode = 1
		GOTO bspexit
	END
   
	-- OK to void, get next available Seq# for Payment Batch
	SELECT @seq = ISNULL(MAX(BatchSeq),0) + 1
	FROM bAPPB WITH (NOLOCK)
	WHERE Co = @co and Mth = @mth and BatchId = @batchid

	BEGIN TRANSACTION
   
	-- add Payment Batch Header (bAPPB insert trigger will lock bAPPH entry)
	INSERT bAPPB (Co,			Mth,		BatchId,		BatchSeq, 
				  CMCo,			CMAcct,		PayMethod,		CMRef, 
				  CMRefSeq,		EFTSeq,		ChkType,		VendorGroup, 
				  Vendor,		Name,		AddnlInfo,		Address, 
				  City,			State,		Zip,			Country, 
				  PaidDate,		Amount,		Supplier,		VoidYN, 
				  VoidMemo,		ReuseYN)
		   SELECT @co,			@mth,		@batchid,		@seq, 
				  CMCo,			CMAcct,		PayMethod,		CMRef, 
				  CMRefSeq,		EFTSeq,		ChkType,		VendorGroup, 
				  Vendor,		Name,		AddnlInfo,		Address, 
				  City,			State,		Zip,			Country, 
				  PaidDate,		0,			Supplier,		'Y', 
				  @voidmemo,	@reuseYN
			 FROM bAPPH 
			WHERE CMCo = @cmco 
				  and CMAcct = @cmacct 
				  and PayMethod = @paymethod
				  and LTRIM(CMRef) = LTRIM(@cmref) 
				  and CMRefSeq = @cmrefseq 
				  and EFTSeq = @eftseq       
	IF @@rowcount <> 1
	BEGIN
		SELECT @msg = 'Unable to add entry to AP Payment Batch Header.', @rcode = 1
		GOTO error
	END
   
	SELECT @count = @count + 1  -- # of payment batch entries added
 	-- count # of transactions on payment
	SELECT @validcnt = count(*)
	FROM bAPPD WITH (NOLOCK)
	WHERE CMCo = @cmco 
		  and CMAcct = @cmacct 
		  and PayMethod = @paymethod
		  and LTRIM(CMRef) = LTRIM(@cmref) 
		  and CMRefSeq = @cmrefseq -- 0 for EFT/Credit Service
		  and EFTSeq = @eftseq -- 0 for Check/Credit Service
   
	-- add Payment Batch Trans using Payment Detail (bAPTB insert trigger will lock bAPTH and update amounts in bAPPB)
	INSERT bAPTB(Co,			Mth,		BatchId,		BatchSeq, 
				 ExpMth,		APTrans,	APRef,			Description, 
				 InvDate,		Gross,		Retainage,		PrevPaid, 
				 PrevDisc,		Balance,	DiscTaken)
		  SELECT @co,			@mth,		@batchid,		@seq, 
				 Mth,			APTrans,	APRef,			Description, 
				 InvDate,		Gross,		Retainage,		PrevPaid, 
				 PrevDiscTaken, Balance,	DiscTaken
			FROM bAPPD
		   WHERE CMCo = @cmco 
				 and CMAcct = @cmacct 
				 and PayMethod = @paymethod
				 and LTRIM(CMRef) = LTRIM(@cmref) 
				 and CMRefSeq = @cmrefseq 
				 and EFTSeq = @eftseq			 
	IF @@rowcount <> @validcnt
	BEGIN
		SELECT @msg = 'Unable to add all transactions included with payment into Payment Batch Transaction table.', 
			   @rcode = 1
		GOTO error
	END
   
	-- count # of transaction detail entries on payment
	SELECT @validcnt = count(*)
	FROM bAPTD WITH (NOLOCK)
	WHERE CMCo = @cmco 
		  and CMAcct = @cmacct 
		  and PaidMth = @paidmth --#27220 select by paidmth
		  and PayMethod = @paymethod  
		  and LTRIM(CMRef) = LTRIM(@cmref) 
		  and CMRefSeq = @cmrefseq 
		  and ISNULL(EFTSeq,0) = @eftseq

	-- add Payment Batch Detail using AP Trans Detail
	INSERT bAPDB(Co,		Mth,		BatchId,	BatchSeq, 
				 ExpMth,	APTrans,	APLine,		APSeq, 
				 PayType,	Amount,		DiscTaken,	PayCategory)
		  SELECT @co,		@mth,		@batchid,	@seq, 
				 Mth,		APTrans,	APLine,		APSeq, 
				 PayType,	Amount,		DiscTaken,  PayCategory
			FROM bAPTD
		   WHERE CMCo = @cmco 
				 and CMAcct = @cmacct 
				 and PayMethod = @paymethod
				 and LTRIM(CMRef) = LTRIM(@cmref) 
				 and CMRefSeq = @cmrefseq 
				 and ISNULL(EFTSeq,0) = @eftseq
				 and Status = 3 
				 and PaidMth = @mth 
				 and APCo = @co    -- additional restrictions for safety
	IF @@rowcount <> @validcnt
	BEGIN
		SELECT @msg = 'Unable to add all transaction detail included with payment into Payment Batch Detail table.',
			   @rcode = 1
		GOTO error
	END
   	
   	COMMIT TRANSACTION 
       
	/* 18842 for manual checks, execute ManualCheckProcess after bAPTB and bAPTD are inserted
	 to update bAPTB with recalculated amounts so bAPTB and bAPDB are in sync for APPB validation  */
	IF @chktype = 'M' 	
	BEGIN
		EXEC @rcode = bspAPManualCheckProcess @co, @mth, @batchid, @seq, @msg OUTPUT
		IF @rcode <> 0 
			GOTO error
	END
   
next_payment:
	IF @sendeftseq IS NULL
	BEGIN
		FETCH NEXT FROM Payment INTO @eftseq
		IF @@fetch_status <> 0 
			GOTO bspexit
		GOTO process_payment
	END
   
GOTO bspexit
   
error:  -- error within processing transaction
	ROLLBACK TRANSACTION
	GOTO bspexit
   
bspexit:
	IF @openPayment = 1
	BEGIN
		CLOSE Payment
		DEALLOCATE Payment
	END
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPPBVoid] TO [public]
GO
