SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspAPOnCostProcessWorkFile    Script Date: 8/28/99 9:34:02 AM ******/
CREATE                    proc [dbo].[vspAPOnCostProcessWorkFile]
/***********************************************************
* CREATED BY:   MV	03/27/12	TK-13202 AP On-Cost
* MODIFIED By :	MV	04/12/12	TK-14132 Fixed DiscRate,empty header, InvTotal
*				MV	04/16/12	TK-14132 Fixed problem with APLine increment when BatchSeq already exists
*				MV	04/17/12	TK-14132 Change to view APOnCostVendorTypesYN
*				MV	04/18/12	TK-14132 Delete any workfile headers that don't have lines
*				MV	04/19/12	TK-14132 OnCost line should be Exp not Job if OnCost Type JobExpOpt is JOIN 
*				MV	04/27/12	TK-14132 Delete workfile detail with OnCostAction = NULL 
*				MV	05/02/12	TK-14132 If inv amt is negative make oncost amt negative
*
* USAGE:
* Called from APEntry to create new On-Cost Invoice
* batch entries.  
*
*
*  INPUT PARAMETERS
*  @co                 AP Company
*  @BatchMth           Batch Month - payment month
*  @batchid            BatchId
*
* OUTPUT PARAMETERS
*  @msg                error message if error occurs
*
* RETURN VALUE
*  0                   success
*  1                   failure
*  5				   conditional success	
*************************************************************/
   
(@Co bCompany, 
 @BatchMth bMonth, 
 @BatchId bBatchID, 
 @Msg varchar(255) OUTPUT)

AS
SET NOCOUNT ON
   
DECLARE @rcode int				
   

DECLARE @VendorGroup bGroup,		@OnCostVendor bVendor, 
		@APRef bAPReference,		@Description bDesc, 
		@InvDate bDate,				@APLine INT,
		@PayMethod char(1),			@CMAcct bCMAcct, 
		@origMth bMonth,			@APTrans bTrans, 
		@openAPOnCost INT,			@UserId bVPUserName,
		@OnCostID TINYINT,			@CMCo bCompany,
		@CSCMCo	bCompany,			@CSCMAcct bCMAcct,
		@VCMAcct bCMAcct,			@APRefIncrementer INT,
		@BatchSeq INT,				@GLCo INT,
		@GLAcct bGLAcct,			@LineType INT,
		@Amount bDollar,			@CostType bJCCType,
		@OnCostTypesYN bYN,			@DiscAmt bDollar,
		@openAPHB INT,				@ErrorNbr INT

-- vendor master declares
DECLARE @PayTerms bPayTerms,		@DueDate bDate,
		@DiscDate bDate,			@DiscRate bPct

--On Cost Type declares
DECLARE	@ocDesc bItemDesc,			@ocCalcMethod CHAR(1),
		@ocRate bUnitCost,			@ocAmount bDollar,
		@ocPayType tinyint,			@ATOCategory VARCHAR(4),
		@SchemeID SMALLINT,			@MemberShipNbr VARCHAR(60)
		
-- Vendor On-Cost declares
DECLARE	@JobExpOpt CHAR(1),			@ocCostType bJCCType,
		@JobExpAcct bGLAcct,		@ExpOpt CHAR(1),
		@ExpAcct bGLAcct
		
-- APTL/TH declares
DECLARE	@JCCo bCompany,				@Job bJob,
		@PhaseGroup bGroup,			@Phase bPhase,
		@origCostType bJCCType,		@origGLCo bCompany,
		@origGLAcct bGLAcct,		@origAPLine INT,
		@origVendor bVendor



SELECT	@rcode = 0, 
		@UserId = SUSER_SNAME(), 
		@openAPOnCost = 0, @Msg = '',
		@APRefIncrementer = 0,
		@openAPHB = 0

-- validate input parameters
IF @Co IS NULL
BEGIN
	SELECT @Msg = 'Missing AP Company.'
	RETURN 1
END

IF @BatchMth IS NULL
BEGIN
	SELECT @Msg = 'Missing Batch Month.'
	RETURN 1
END

IF @BatchId IS NULL
BEGIN
	SELECT @Msg = 'Missing Batch ID.'
	RETURN 1
END

-- Get bAPCO info
SELECT @CMCo = CMCo, @CMAcct = CMAcct, @CSCMCo = CSCMCo,@CSCMAcct = CSCMAcct 
FROM dbo.bAPCO
WHERE APCo=@Co

-- TAKE CARE OF ALL OnCostActions not 1 - Process
-- Update APTL OnCostAction = 2 'Never Process'
UPDATE dbo.APTL 
SET SubjToOnCostYN  = 'Y',
	OnCostStatus = 2
FROM dbo. APTL l 
JOIN dbo.vAPOnCostWorkFileDetail o ON l.APCo = o.APCo AND l.Mth = o.Mth AND l.Mth = o.Mth AND l.APTrans = o.APTrans	AND l.APLine = o.APLine
WHERE l.APCo=@Co AND o.OnCostAction = 2 AND o.UserID = @UserId
-- Delete from workfile
DELETE FROM vAPOnCostWorkFileDetail
WHERE APCo=@Co AND OnCostAction = 2 AND UserID = @UserId

---- Update APTL OnCostAction = 0 'Ready to process'
UPDATE dbo.APTL 
SET SubjToOnCostYN  = 'Y',
	OnCostStatus = 0
FROM dbo. APTL l 
JOIN dbo.vAPOnCostWorkFileDetail o ON l.APCo = o.APCo AND l.Mth = o.Mth AND l.Mth = o.Mth AND l.APTrans = o.APTrans	AND l.APLine = o.APLine
WHERE l.APCo=@Co AND o.OnCostAction = 0 AND o.UserID = @UserId
--Delete from workfile
DELETE FROM vAPOnCostWorkFileDetail
WHERE APCo=@Co AND OnCostAction = 0 AND UserID = @UserId

-- Delete workfile detail with OnCostAction = NULL
DELETE FROM vAPOnCostWorkFileDetail
WHERE APCo=@Co AND OnCostAction IS NULL AND UserID = @UserId

-- Cannot add a trans to On_cost batch with ExpMth > batch mth. Update Error for workfile detail where Mth > batchmth
UPDATE dbo.vAPOnCostWorkFileDetail
SET Error = 'Err: Trans mth is greater than On-Cost batch month.'
WHERE APCo=@Co AND UserID = @UserId AND Mth > @BatchMth

-- validate for workfile vendors that are not assigned any on cost types
UPDATE dbo.vAPOnCostWorkFileDetail 
SET Error = 'Err: No on-cost types setup for this vendor. '
FROM dbo.vAPOnCostWorkFileDetail w
JOIN dbo.bAPTH h ON h.APCo= w.APCo AND h.Mth = w.Mth AND h.APTrans= w.APTrans
JOIN dbo.APOnCostVendorTypesYN o ON h.APCo=o.APCo AND h.Mth=o.Mth AND h.APTrans=o.APTrans
WHERE w.APCo = @Co AND w.UserID = @UserId AND o.OnCostYN = 'Y'

-- BEGIN PROCESSING For OnCostAction = 1 'Process'
DECLARE vcAPOnCost CURSOR LOCAL FAST_FORWARD FOR SELECT DISTINCT
	'OnCostVendor' = ISNULL(v.OnCostVendor,p.OnCostVendor),v.OnCostID,o.Mth,o.APTrans,o.APLine,v.VendorGroup,'OrigVendor' = h.Vendor
FROM dbo.vAPOnCostWorkFileDetail o
JOIN dbo.bAPTH h ON h.APCo = o.APCo AND h.Mth = o.Mth AND h.APTrans = o.APTrans
JOIN dbo.vAPVendorMasterOnCost v ON h.APCo=v.APCo AND h.VendorGroup=v.VendorGroup AND h.Vendor=v.Vendor
JOIN dbo.vAPOnCostType p ON p.APCo=v.APCo AND p.OnCostID=v.OnCostID
WHERE o.APCo=@Co AND o.Mth <= @BatchMth AND o.UserID = @UserId AND o.OnCostAction = 1 
ORDER BY 'OnCostVendor',o.Mth,o.APTrans,o.APLine

OPEN vcAPOnCost
SELECT @openAPOnCost = 1
  
APOnCost_loop:      -- loop through each trans in workfile
FETCH NEXT FROM vcAPOnCost 
		   INTO	@OnCostVendor, @OnCostID, @origMth, @APTrans,@origAPLine, @VendorGroup, @origVendor	
	
	IF @@fetch_status <> 0 GOTO APOnCost_End

	-- start a new header seq
	SELECT @BatchSeq = NULL 
	SELECT @BatchSeq = BatchSeq
	FROM dbo.bAPHB
	WHERE Co=@Co AND Mth=@BatchMth AND BatchId=@BatchId AND VendorGroup=@VendorGroup AND Vendor=@OnCostVendor 
	IF @BatchSeq IS NULL			
	BEGIN
		-- get next batch seq
		SELECT @BatchSeq = ISNULL(MAX(BatchSeq),0)+1
		FROM dbo.bAPHB
		WHERE Co=@Co AND Mth=@BatchMth AND BatchId=@BatchId
		-- Reset some variables
		SELECT @PayMethod = NULL,@PayTerms = NULL, @DiscDate = NULL, @DueDate = NULL,@DiscRate=0
		-- get oc vendor info/defaults
		SELECT @PayMethod = PayMethod,@PayTerms = PayTerms, @CMAcct = ISNULL(CMAcct,@CMAcct)
		FROM dbo.bAPVM
		WHERE VendorGroup = @VendorGroup AND Vendor = @OnCostVendor
		-- set credit service cm defaults if paymethod is 'S' - credit service
		IF @PayMethod = 'S'
		BEGIN
			SELECT @CMCo = ISNULL(@CSCMCo, @CMCo), @CMAcct = ISNULL(@CSCMAcct,@CMAcct)
		END
		-- Get invoice date
		SELECT @InvDate = dbo.vfDateOnly()
		-- Get disc date,due date from pay terms
		IF @PayTerms IS NOT NULL
		BEGIN
			EXEC @rcode = bspHQPayTermsDateCalc @PayTerms, @InvDate,@DiscDate OUTPUT,
				@DueDate OUTPUT,@DiscRate OUTPUT,@Msg OUTPUT
			IF @rcode <> 0
			BEGIN
				UPDATE dbo.vAPOnCostWorkFileDetail
				SET Error = 'Err getting due date from on-cost vendor pay terms. ' 
				WHERE APCo=@Co AND UserID = @UserId AND Mth= @origMth AND APTrans = @APTrans
				GOTO APOnCost_loop
			END
		END
		ELSE
		BEGIN
			SELECT @DueDate = @InvDate
		END
		-- create unique APRef
APRef_Loop:
		SELECT	@APRefIncrementer = @BatchSeq
		SELECT	@APRef = CONVERT(VARCHAR(2),DATEPART(month,@BatchMth)) 
			+ RIGHT(CONVERT(VARCHAR(4),DATEPART(year,@BatchMth)),2) 
			+ CONVERT(VARCHAR(6), @BatchId)
			+ '-'
			+ CONVERT(VARCHAR(5),@APRefIncrementer)
		-- validate APRef
		EXEC @rcode = bspAPRefUniqueNoBatch @Co, @OnCostVendor,@APRef,
				NULL,NULL,@VendorGroup,@Msg OUTPUT
		IF @rcode <> 0
		BEGIN
			-- if the APRef is not unique increment the last digit and try again
			SELECT	@APRefIncrementer = @APRefIncrementer + 1
			GOTO APRef_Loop
		END
		-- insert new header rec
		BEGIN TRY
		INSERT INTO bAPHB
			(
				Co,					Mth,				BatchId,
				BatchSeq,			BatchTransType,		APTrans,
				VendorGroup,		Vendor,				APRef,
				Description,		InvDate,			DiscDate,
				DueDate,			InvTotal,			HoldCode,
				PayControl,			PayMethod,			CMCo,
				CMAcct,				V1099YN,			V1099Type,
				V1099Box,			PayOverrideYN,		PayName,
				PayAddress,			PayCity,			PayState,
				PayZip,				PayAddInfo,			AddendaTypeId,
				SeparatePayYN,		PaidYN,				PayCountry,
				PrePaidYN			
			)
		SELECT	@Co,				@BatchMth,			@BatchId,
				@BatchSeq,			'A',				NULL,
				@VendorGroup,		@OnCostVendor,		@APRef,
				NULL,				@InvDate,			@DiscDate,
				@DueDate,			0,					NULL,
				v.PayControl,		v.PayMethod,		@CMCo,
				@CMAcct,			v.V1099YN,			v.V1099Type,
				v.V1099Box,			'N',				v.Name,
				v.Address,			v.City,				v.State,
				v.Zip,				v.Address2,			v.AddendaTypeId,
				v.SeparatePayInvYN,	'N',				v.Country,
				'N'
		FROM dbo.APVM v
		WHERE VendorGroup=@VendorGroup AND Vendor=@OnCostVendor
		END TRY
		BEGIN CATCH
			UPDATE dbo.vAPOnCostWorkFileDetail
			SET Error = 'Err creating batch header for this on-cost invoice. '
			WHERE APCo=@Co AND UserID = @UserId AND Mth= @origMth AND APTrans = @APTrans
			GOTO APOnCost_loop
		END CATCH
		GOTO AddNewLine
	END
	ELSE
	BEGIN
AddNewLine:	-- add new line
		-- clear these variables for each new line
		SELECT @GLCo = NULL, @GLAcct = NULL, @CostType = NULL, @ErrorNbr = 0
		-- get On Cost Type info
		SELECT	@ocCalcMethod = v.CalcMethod,
				@ocRate = ISNULL(v.Rate,o.Rate),@ocAmount = ISNULL(v.Amount,o.Amount),
				@ocPayType = ISNULL(v.PayType,o.PayType), @ATOCategory = ISNULL(v.ATOCategory,o.ATOCategory),
				@SchemeID = v.SchemeID, @MemberShipNbr = v.MemberShipNumber,@JobExpOpt = o.JobExpOpt,
				@ocCostType = o.CostType,@JobExpAcct = o.JobExpAcct, @ExpOpt = o.NonJobExpOpt,
				@ExpAcct = o.ExpAcct
		FROM dbo.vAPOnCostType o
		JOIN dbo.vAPVendorMasterOnCost v ON o.APCo=v.APCo AND o.OnCostID=v.OnCostID
		WHERE o.APCo=@Co AND v.VendorGroup=@VendorGroup AND v.Vendor=@origVendor AND o.OnCostID=@OnCostID
		-- get APTL info
		SELECT @JCCo = JCCo,@Job = Job,@PhaseGroup=PhaseGroup, @Phase=Phase,@origCostType=JCCType,@origGLCo=GLCo,
			@origGLAcct = GLAcct, @Amount = GrossAmt
		FROM dbo.APTL
		WHERE APCo=@Co AND Mth=@origMth AND APTrans=@APTrans AND APLine=@origAPLine
		-- determine GL Acct from defaults
		IF @JCCo IS NOT NULL AND @Job IS NOT NULL AND @JobExpOpt <> 'J'
		BEGIN
			 -- orig line is a job type and the on-cost JobExpOpt is not J 
			SELECT @LineType = 1
			-- get JC Company GLCo
			SELECT @GLCo = GLCo 
			FROM dbo.JCCO 
			WHERE JCCo=@JCCo
			-- set default JC Cost Type
			SELECT @CostType = ISNULL(@ocCostType,@origCostType)
			-- set Expense GL per Job Exp Option
			IF @JobExpOpt = 'I' SELECT @GLCo=@origGLCo, @GLAcct=@origGLAcct -- Use orig Invoice GLAcct
			IF @JobExpOpt = 'C'												-- Use GL Acct from on cost Cost Type
			BEGIN
				EXEC @rcode = bspJCCAGlacctDflt @JCCo, @Job, @PhaseGroup, @Phase, 
				  @ocCostType, 'N', @GLAcct OUTPUT, @Msg OUTPUT
				IF @GLAcct IS NULL
   				BEGIN
   					UPDATE dbo.vAPOnCostWorkFileDetail
					SET Error = 'On-Cost cost type does not have associated GL Acct.'
					WHERE APCo=@Co AND UserID = @UserId AND Mth= @origMth AND APTrans = @APTrans
					GOTO APOnCost_loop
   				END 
			END
		END
		ELSE
		BEGIN
			SELECT @LineType = 3
			SELECT @GLCo=@origGLCo
			-- If orig line is a job line with oncost type JobExpOpt J then
			-- on-cost line type should be an Exp line with job exp GL acct
			IF @JCCo IS NOT NULL AND @Job IS NOT NULL AND @JobExpOpt = 'J' 					
			BEGIN
				SELECT @GLAcct=@JobExpAcct -- use the Job Expense Acct setup in the on-cost type
				SELECT @JCCo = NULL,@Job = NULL,@PhaseGroup=NULL, @Phase=NULL -- clear job values
			END
			ELSE 
			BEGIN
				-- For all other line types, set Expense GL per Non Job Exp Option
				IF @ExpOpt = 'I' SELECT @GLAcct=@origGLAcct
				IF @ExpOpt = 'E' SELECT @GLAcct = @ExpAcct
			END
		END
		 --get next APLine #
		SELECT @APLine = ISNULL(MAX(APLine),0)+1
		FROM dbo.bAPLB
		WHERE Co=@Co AND Mth=@BatchMth AND BatchId=@BatchId AND BatchSeq=@BatchSeq
		-- calculate gross amt and discount amount
		IF @ocCalcMethod = 'R' SELECT @Amount =  @Amount * @ocRate
		IF @ocCalcMethod = 'A' SELECT @Amount =  CASE SIGN(@Amount) WHEN -1 THEN -(@ocAmount) ELSE @ocAmount END
		SELECT @DiscAmt = @Amount * ISNULL(@DiscRate,0)
		BEGIN TRY
		INSERT INTO dbo.bAPLB
			(
				Co,					Mth,				BatchId,
				BatchSeq,			APLine,				BatchTransType,
				LineType,			JCCo,				Job,
				PhaseGroup,			Phase,				JCCType,
				GLCo,				GLAcct,				UM,
				VendorGroup,		PayType,			GrossAmt,
				MiscAmt,			MiscYN,				PaidYN,
				SubjToOnCostYN,		Units,				UnitCost,
				TaxBasis,			TaxAmt,				Retainage,
				Discount,			BurUnitCost,		SMChange,
				POPayTypeYN,		ocApplyMth,			ocApplyTrans,
				ocApplyLine,		ATOCategory,		ocSchemeID,
				ocMembershipNbr	
			)
		VALUES
			(
				@Co,				@BatchMth,			@BatchId,
				@BatchSeq,			@APLine,			'A',
				@LineType,			@JCCo,				@Job,
				@PhaseGroup,		@Phase,				@CostType,
				@GLCo,				@GLAcct,			'LS',
				@VendorGroup,		@ocPayType,			@Amount,
				0,					'N',				'N',
				'N',				0,					0,
				0,					0,					0,
				@DiscAmt,			0,					0,
				'N',				@origMth,			@APTrans,
				@origAPLine,		@ATOCategory,		@SchemeID,
				@MemberShipNbr		
			)				
		END TRY
		BEGIN CATCH
			SELECT @ErrorNbr = @@ERROR
			SELECT ERROR_MESSAGE() AS ErrorMessage;
			UPDATE dbo.vAPOnCostWorkFileDetail
			SET Error = 'Err creating on-cost line for this invoice. '
			WHERE APCo=@Co AND UserID = @UserId AND Mth= @origMth AND APTrans = @APTrans AND APLine=@origAPLine
		END CATCH
		-- Insert for new line was successful
		IF @ErrorNbr = 0
		BEGIN
			-- update APTL
			UPDATE dbo.APTL 
			SET SubjToOnCostYN  = 'Y',
				OnCostStatus = 1
			WHERE APCo=@Co AND Mth=@origMth AND APTrans=@APTrans AND APLine=@origAPLine
			-- Delete line from workfile
			DELETE 
			FROM dbo.vAPOnCostWorkFileDetail
			WHERE APCo=@Co AND UserID = @UserId AND Mth= @origMth AND APTrans = @APTrans AND APLine=@origAPLine 
			-- no more lines?  delete header
			IF NOT EXISTS
				(
					SELECT * 
					FROM dbo.vAPOnCostWorkFileDetail
					WHERE APCo=@Co AND UserID = @UserId AND Mth= @origMth AND APTrans = @APTrans
				)
			BEGIN
				DELETE dbo.vAPOnCostWorkFileHeader
				WHERE APCo=@Co AND UserID = @UserId AND Mth= @origMth AND APTrans = @APTrans
			END
		END
	END
	GOTO APOnCost_loop

APOnCost_End:
IF @openAPOnCost = 1
BEGIN
	CLOSE vcAPOnCost
	DEALLOCATE vcAPOnCost
	SELECT @openAPOnCost = 0
END

-- PROCESSING FINISHED - DO CLEANUP
-- delete headers from the workfile that no longer have any lines
DELETE FROM dbo.APOnCostWorkFileHeader
WHERE APCo=@Co AND UserID=@UserId
	AND NOT EXISTS
				(
					SELECT * 
					FROM dbo.APOnCostWorkFileDetail d
					WHERE d.APCo=APOnCostWorkFileHeader.APCo
					AND d.Mth=APOnCostWorkFileHeader.Mth
					AND d.APTrans=APOnCostWorkFileHeader.APTrans
					AND d.UserID=APOnCostWorkFileHeader.UserID
				)

-- delete headers from On-Cost batch that do not have lines/update InvTotal with sum of lines 
DECLARE vcAPHB CURSOR LOCAL FAST_FORWARD FOR SELECT 
	BatchSeq
FROM dbo.bAPHB
WHERE Co=@Co AND Mth=@BatchMth AND BatchId=@BatchId
ORDER BY BatchSeq

OPEN vcAPHB
SELECT @openAPHB = 1
  
APHB_loop:      -- loop through each on cost header
	FETCH NEXT FROM vcAPHB 
			   INTO	@BatchSeq
		
	IF @@fetch_status <> 0 
	BEGIN
		GOTO APHB_End
	END
	ELSE
	BEGIN
		-- Clear any batch headers that do not have lines
		IF NOT EXISTS 
				(
					SELECT * 
					FROM dbo.APLB 
					WHERE Co=@Co AND Mth=@BatchMth AND BatchId=@BatchId AND BatchSeq=@BatchSeq
				)
		BEGIN
			DELETE 
			FROM dbo.APHB
			WHERE Co=@Co AND Mth=@BatchMth AND BatchId=@BatchId AND BatchSeq=@BatchSeq 
			GOTO APHB_loop
		END 
			
		-- Update each batch seq Invoice Total with sum of the lines
		UPDATE dbo.bAPHB
		SET InvTotal = ISNULL(s.TotalFromLines,0)
		FROM dbo.bAPHB 
			CROSS APPLY (
							SELECT SUM(ISNULL(l.GrossAmt,0)) AS TotalFromLines
							FROM dbo.bAPLB l
							WHERE l.Co=@Co AND l.Mth=@BatchMth AND l.BatchId=@BatchId AND l.BatchSeq=@BatchSeq 
						) AS s
		WHERE Co=@Co AND Mth=@BatchMth AND BatchId=@BatchId AND BatchSeq=@BatchSeq 
		GOTO APHB_loop
	END

APHB_End:
IF @openAPHB = 1
BEGIN
	CLOSE vcAPHB
	DEALLOCATE vcAPHB
	SELECT @openAPHB = 0
END

-- Error messages in workfile detail?  Alert the user.
IF EXISTS
	(
		SELECT * 
		FROM dbo.vAPOnCostWorkFileDetail
		WHERE APCo=@Co AND UserID = @UserId AND Error IS NOT NULL
	)
BEGIN
	SELECT @Msg = 'Warning: there were one or more failures. Return to the workfile and inspect the Error text in workfile detail.'
	RETURN 7
END


RETURN 

GO
GRANT EXECUTE ON  [dbo].[vspAPOnCostProcessWorkFile] TO [public]
GO
