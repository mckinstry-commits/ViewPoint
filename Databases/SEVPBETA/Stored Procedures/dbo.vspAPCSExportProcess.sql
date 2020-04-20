SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspAPCSExportProcess    Script Date: 8/28/99 9:33:58 AM ******/
CREATE         proc [dbo].[vspAPCSExportProcess]
/***********************************************************
* CREATED BY	: EN 04/02/2012 B-08617/TK-13167
* MODIFIED BY	: KK 05/01/12 - TK-14337 Changed ComData => Comdata
*
* USAGE:
* used to process Credit Service payments and assign CM Reference numbers to payments in APPB
* This will return 0 if OK, otherwise 1 if an error occurs
*
* Note that when Comdata credit service is being used payments will not be processed for vendors 
* without a Credit Service Email in APVM.  This validation is also performed prior to running this 
* processing procedure so this is merely a failsafe.
*
* INPUT PARAMETERS
*   @apco				AP Company of batch
*   @month				Batch Month
*   @batchid			BatchId of APPB credit service payments to include in export
*   @cscmco				Credit Service CM Company
*   @cscmacct			Credit Service CM Account
*   @overrideexisting   = Y if overriding CM Ref #'s previously assigned to batch
*   @begincmref			Beginning CM Reference # to use for payments to batch
*   @paiddate			PaidDate to be plugged into APPB
*
* OUTPUT PARAMETERS 
*   @msg     If error occurs, Error message goes here
*
* RETURN VALUE
*   0         success
*   1         Failure  '
*****************************************************/
   
(@apco bCompany, 
 @month bMonth, 
 @batchid bBatchID, 
 @cmco bCompany,
 @cmacct bCMAcct, 
 @overrideexisting bYN, 
 @cmref bCMRef, 
 @paiddate bDate,
 @msg varchar(255) OUTPUT)
 
AS
SET NOCOUNT ON

DECLARE	@rcode int,
		@paymentsprocessed int,
        @retpaytype tinyint,
        @creditservice tinyint,
		@batchseq int, 
		@vendorgroup bGroup,
        @vendor bVendor,
        @emailmissingmsg varchar(100),
        @expmth bMonth,
        @aptrans bTrans, 
        @retainage bDollar, 
        @prevpaid bDollar, 
        @batchprevpaid bDollar, 
        @prevdisc bDollar,
        @batchprevdisc bDollar, 
        @balance bDollar, 
        @batchbalance bDollar,
        @disctaken bDollar,
        @valmsg varchar(255)

SELECT	@paymentsprocessed = 0,
		@msg = ''

BEGIN TRY
	-- get retainage pay type from AP Company ... needed for determining total retainage to update bAPTB
	SELECT @retpaytype = RetPayType,
		   @creditservice = APCreditService
	FROM dbo.bAPCO
	WHERE APCo = @apco 
	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @msg = 'Invalid AP Co#'
		RETURN 1
	END

	-- if we are overriding pre-existing CM Reference #'s remove all CMRef# values for the Credit Service payments to be processed		   
	IF @overrideexisting = 'Y'
	BEGIN
		UPDATE dbo.bAPPB 
		SET	CMRef = NULL, 
			EFTSeq = NULL, 
			PaidDate = NULL 
		WHERE	Co = @apco AND 
				Mth = @month AND 
				BatchId = @batchid AND
				CMCo = @cmco AND 
				CMAcct = @cmacct AND 
				PayMethod = 'S'
	END

	-- create cursor of all Credit Service payment sequences in this batch
	DECLARE bcAPPBCSPaySeqs CURSOR LOCAL FAST_FORWARD FOR 
		SELECT	BatchSeq, 
				VendorGroup, 
				Vendor
		FROM dbo.bAPPB 
		WHERE	Co = @apco AND 
				Mth = @month AND 
				BatchId = @batchid AND 
				CMCo = @cmco AND 
				CMAcct = @cmacct AND 
				PayMethod = 'S' AND 
				CMRef IS NULL
		ORDER BY Vendor, BatchSeq

	-- open cursor
	OPEN bcAPPBCSPaySeqs

	-- get first row
	FETCH NEXT FROM bcAPPBCSPaySeqs INTO @batchseq, @vendorgroup, @vendor

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		-- only process payment sequences with transactions to be paid
		IF EXISTS (SELECT * FROM dbo.APTB WHERE Co = @apco AND Mth = @month AND BatchId = @batchid AND BatchSeq = @batchseq)
		BEGIN
			-- proceed with processing if not using credit service Comdata (APCO_APCreditService = 1) 
			-- or credit service is Comdata and vendor credit service email was specified
			IF @creditservice <> 1 OR
			   (@creditservice = 1 AND EXISTS (SELECT NULL 
											   FROM dbo.bAPVM 
											   WHERE VendorGroup = @vendorgroup AND 
													 Vendor = @vendor AND 
													 CSEmail IS NOT NULL
											  )
			   )
			BEGIN
				--update bAPTB fields Retainage, PrevPaid, PrevDisc, Balance, DiscTaken
				--update bAPPB fields CMRef, CMRefSeq, PaidDate
				SELECT	@expmth = MIN(ExpMth) 
				FROM dbo.bAPTB 
				WHERE Co = @apco AND Mth = @month AND BatchId = @batchid AND BatchSeq = @batchseq
				
				WHILE @expmth IS NOT NULL
				BEGIN
					SELECT	@aptrans = MIN(APTrans) 
					FROM dbo.bAPTB 
					WHERE Co = @apco AND Mth = @month AND BatchId = @batchid AND BatchSeq = @batchseq AND 
						  ExpMth = @expmth
							
					WHILE @aptrans IS NOT NULL
					BEGIN
						SELECT	@balance = ISNULL(
												 (SELECT SUM(Amount) 
												  FROM dbo.bAPTD WITH (NOLOCK)
												  WHERE	APCo = @apco AND 
														Mth = @expmth AND 
														APTrans = @aptrans AND 
														[Status] < 3
												  ), 0)

						SELECT	@batchbalance = ISNULL(
													  (SELECT SUM(Amount) 
													   FROM dbo.bAPDB 
													   WHERE Co = @apco AND 
															 Mth = @month AND 
															 BatchId = @batchid AND 
															 BatchSeq = @batchseq AND 
															 ExpMth = @expmth AND 
															 APTrans = @aptrans
													   ), 0)

						SELECT	@balance = @balance - @batchbalance

						SELECT	@retainage = SUM(d.Amount) 
						FROM dbo.bAPTD d WITH (NOLOCK) 
						WHERE d.APCo = @apco AND 
							  d.Mth = @expmth AND 
							  d.APTrans = @aptrans AND 
							  d.Status = 2 AND 
							  (
							   (d.PayCategory IS NULL AND 
								d.PayType = @retpaytype)
							   OR 
							   (d.PayCategory IS NOT NULL AND 
								d.PayType = (SELECT c.RetPayType 
											 FROM dbo.bAPPC c WITH (NOLOCK) 
											 WHERE c.APCo = @apco AND 
												   c.PayCategory = d.PayCategory
											)
							   )
							  )
						
						SELECT	@prevpaid = SUM(Amount) - SUM(DiscTaken),
								@prevdisc = SUM(DiscTaken)
						FROM dbo.bAPTD WITH (NOLOCK)
						WHERE APCo = @apco AND 
							  Mth = @expmth AND 
							  APTrans = @aptrans AND 
							  Status > 2
						
						SELECT	@batchprevdisc = SUM(DiscTaken),
								@batchprevpaid = SUM(Amount) - SUM(DiscTaken)
						FROM dbo.bAPDB 
						WHERE Co = @apco AND 
							  ExpMth = @expmth AND 
							  APTrans = @aptrans AND 
							  BatchId = @batchid AND 
							  Mth = @month AND 
							  BatchSeq < @batchseq

						SELECT	@disctaken = SUM(DiscTaken) 
						FROM dbo.bAPDB 
						WHERE Co = @apco AND 
							  ExpMth = @expmth AND 
							  APTrans = @aptrans AND 
							  Mth = @month AND 
							  BatchId = @batchid AND 
							  BatchSeq = @batchseq

						--clean up totals
						SELECT	@disctaken = ISNULL(@disctaken,0), 
								@retainage = ISNULL(@retainage,0),
								@prevpaid = ISNULL(@prevpaid,0) + ISNULL(@batchprevpaid,0),
								@prevdisc = ISNULL(@prevdisc,0) + ISNULL(@batchprevdisc,0)
								
						SELECT	@balance = @balance - ISNULL(@batchprevpaid,0) - ISNULL(@batchprevdisc,0)

						UPDATE dbo.bAPTB 
						SET Retainage = @retainage, 
							PrevPaid = @prevpaid,
							PrevDisc = @prevdisc,
							Balance = @balance - @retainage,
							DiscTaken = @disctaken
						FROM dbo.bAPTB
						WHERE Co = @apco AND 
							  Mth = @month AND 
							  BatchId = @batchid AND
							  BatchSeq = @batchseq AND 
							  ExpMth = @expmth AND 
							  APTrans = @aptrans
						IF @@ROWCOUNT = 0
						BEGIN
							IF CURSOR_STATUS('local','bcAPPBCSPaySeqs') >= 0
							BEGIN
								CLOSE bcAPPBCSPaySeqs
								DEALLOCATE bcAPPBCSPaySeqs
							END
							SELECT @msg = 'Failure to update Payment Transaction Batch '
							RETURN 1
						END

						SELECT	@aptrans = MIN(APTrans) 
						FROM dbo.bAPTB 
						WHERE Co = @apco AND Mth = @month AND BatchId = @batchid AND BatchSeq = @batchseq AND 
							  ExpMth = @expmth AND 
							  APTrans > @aptrans
					END
					SELECT	@expmth = MIN(ExpMth) 
					FROM dbo.bAPTB 
					WHERE Co = @apco AND Mth = @month AND BatchId = @batchid AND BatchSeq = @batchseq AND 
						  ExpMth > @expmth
				END

				-- get next available Credit Service CM Reference #
				-- first time this is called, it serves to validate the CMRef input parameter
				EXEC	@rcode = [dbo].[vspAPCSCMRefGenVal]
						@cmco = @cmco,
						@cmacct = @cmacct,
						@begincmref = @cmref,
						@overlookbatch = 'N',
						@mth = NULL,
						@batchid = NULL,
						@nextcmref = @cmref OUTPUT,
						@msg = @valmsg OUTPUT

				UPDATE dbo.bAPPB 
				SET CMRef = @cmref, 
					CMRefSeq = 0, 
					PaidDate = @paiddate
				WHERE Co = @apco AND 
					  Mth = @month AND 
					  BatchId = @batchid AND 
					  BatchSeq = @batchseq
				IF @@ROWCOUNT = 0
				BEGIN
					IF CURSOR_STATUS('local','bcAPPBCSPaySeqs') >= 0
					BEGIN
						CLOSE bcAPPBCSPaySeqs
						DEALLOCATE bcAPPBCSPaySeqs
					END
					SELECT @msg = 'Failure to update Payment Batch Header '
					RETURN 1
				END
				ELSE
				BEGIN
					SELECT @paymentsprocessed = @paymentsprocessed + 1
				END
			END
			ELSE
			BEGIN
				--payment sequence skipped due to missing credit service email ... add vendor to list to report to user
				IF @emailmissingmsg IS NULL
				BEGIN
					SELECT @emailmissingmsg = 'Payments to vendor(s) '
				END
				ELSE
				BEGIN
					SELECT @emailmissingmsg = @emailmissingmsg + ', '
				END
				
				SELECT @emailmissingmsg = @emailmissingmsg + CONVERT(varchar, @vendor)
			END

		END
		FETCH NEXT FROM bcAPPBCSPaySeqs INTO @batchseq, @vendorgroup, @vendor
	   
	END

	--close and deallocate the cursor
	IF CURSOR_STATUS('local','bcAPPBCSPaySeqs') >= 0
	BEGIN
		CLOSE bcAPPBCSPaySeqs
		DEALLOCATE bcAPPBCSPaySeqs
	END

	--provide feedback if vendors were not processed due to missing Credit Service Email
	IF @emailmissingmsg IS NOT NULL
	BEGIN
		--replace final ', ' in vendor list with ' and '
		SELECT @emailmissingmsg = STUFF(@emailmissingmsg, ( LEN(@emailmissingmsg) - CHARINDEX(' ,', REVERSE(@emailmissingmsg)) ), 2, ' and ')

		SELECT @msg = @emailmissingmsg + ' not processed: missing Credit Service Email' + Char(13) + Char(10)
	END
	
	IF @paymentsprocessed = 0
	BEGIN
		IF @overrideexisting = 'N'
		BEGIN
			IF EXISTS  (SELECT NULL FROM dbo.bAPPB 
						WHERE Co = @apco AND 
							  Mth = @month AND 
							  BatchId = @batchid AND 
							  CMCo = @cmco AND 
							  CMAcct = @cmacct AND 
							  PayMethod = 'S')
			BEGIN --this condition will occur if no CMRef#'s were assigned but Credit Service pay seq's do exist
				SELECT @msg = @msg + 'No additional CM Reference numbers assigned'
				RETURN 0
			END
			ELSE
			BEGIN --this condition will occur if no CMRef#'s were assigned but Credit Service pay seq's do not exist
				  --note that this condition should not cause this stored proc to be run because if everything is
				  --working correctly the Download button that triggers this proc should be disabled
				SELECT @msg = @msg + 'Batch contains no Credit Service payments - no CM Reference numbers assigned'
				RETURN 1
			END
		END
	END
	ELSE
	BEGIN
		SELECT @msg = @msg + ISNULL(CONVERT(varchar(15), @paymentsprocessed),'') + ' CM Reference number(s) assigned'
		RETURN 0
	END
END TRY
BEGIN CATCH   
	--close and deallocate the cursor
	IF CURSOR_STATUS('local','bcAPPBCSPaySeqs') >= 0
	BEGIN
		CLOSE bcAPPBCSPaySeqs
		DEALLOCATE bcAPPBCSPaySeqs
	END

	SELECT @msg = 'Export processing failed: ' + ERROR_MESSAGE()
	RETURN 1
END CATCH

GO
GRANT EXECUTE ON  [dbo].[vspAPCSExportProcess] TO [public]
GO
