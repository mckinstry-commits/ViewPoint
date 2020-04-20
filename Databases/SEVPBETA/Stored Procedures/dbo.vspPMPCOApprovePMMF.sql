SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/*****************************************/
CREATE PROC [dbo].[vspPMPCOApprovePMMF]
/******************************************
* Created By:	GF 06/06/2011 TK-05799
* Modified By:	GF 06/15/2011 TK-06039
*				GF 07/15/2011 TK-06770
*				GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
*				GF 08/01/2011 TK-07189
*				TL 12/01/2011 TK-10436 add parameter @ReadyForAccounting
*				JG 12/02/2011 TK-10541 - Notes being concatenated from PMOL records to PMPOCO Detail.	
*				GF 02/07/2012 TK-11854 use the POCO approval procedure to set status and data also.	
*				DAN SO 03/12/2012 TK-13118 - Added @CreateChangeOrders and @CreateSingleChangeOrder
*				GF 03/30/2012 TK-13768 use the @CreateChangeorders flag
*			
*
* This SP updates any PMMF detail records when a pending
* change order is approved. Will be called from bspPMPCOApprove
* and when a pending change order is manually approved from the
* approved change order grid.
*
* First cursor is based on PMOL records with a vendor, no subcontract, not interfaced
* and the cost type is one of the subcontract cost types from PM Company Parameters.
* If a matching PMSL record is found, we use the PMSL Sequence and execute the SL
* inititalize procedure to create a new SL or add a new item to an existing SL. Same
* process as if running PM Subcontract Detail and selecting a row then click intialize.
* 
* Second Cursor is based on PMOL records with a PO, no POCO Number, and not interfaced.
* Must be detail existing in PMMF to create POCO Number.
* The next POCO Number will be from PMPOCO for the POCo and PO.
* Will update all matching PMMF records and assign to the new POCO Number.
* Then update the POCONum and Sequence in PMOL for the record.			
*				
* INPUT PARAMETERS
* PM Company, Project, PCOType, PCO, PCOItem, ACO, ACOItem, @CreateChangeOrders, @CreateSingleChangeOrder
*
* OUTPUT PARAMETER
* @msg - error message if error occurs
*		
* RETURN VALUE
*   0 - Success
*   1 - Failure
*****************************************************/
(@PMCo bCompany = null, @Project bJob = null, @PCOType bDocType = null,
 @PCO bPCO = null, @PCOItem bPCOItem = null, @ACO bPCO = null,
 @ACOItem bPCOItem = null, @Process CHAR(1) = 'A', @ReadyForAccounting bYN = null,
   -- TK-13118 --
 @CreateChangeOrders bYN = NULL, @CreateSingleChangeOrder bYN = NULL, 
 @msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT, @retcode INT, @retmsg VARCHAR(255),
		@opencursor tinyint, @opencursor2 TINYINT, @PO varchar(30), @POItem bItem,
		@APCo bCompany, @POCONum smallint, @Vendor bVendor,
		@Phase bPhase, @CostType bJCCType, @PMOLKeyID BIGINT, @PMOLNotes VARCHAR(MAX),
		@POCONumStatus VARCHAR(6), @BeginStatus VARCHAR(6),
		@Description VARCHAR(60), @PMMFSeq INT, @MatlPhaseDesc CHAR(1),
		@PhaseGroup bGroup, @LastPO varchar(30), @PMMFKeyID BIGINT,
		----TK-06770
		@MatlCostType bJCCType, @MatlCostType2 bJCCType, @pmmfseqlist VARCHAR(MAX),
		--TK-10436
		 @opencursor3 TINYINT,@PMPOCOKeyID BIGINT
		
SET @rcode = 0
SET @opencursor = 0
SET @opencursor2 = 0

IF @PMCo is null
	BEGIN
		SELECT @msg = 'Missing PM Company!', @rcode = 1
		GOTO bspexit
	END

IF @Project is null
	BEGIN
		SELECT @msg = 'Missing Project!', @rcode = 1
		GOTO bspexit
	END

if @PCOType is null
	BEGIN
		SELECT @msg = 'Missing PCO Type!', @rcode = 1
		GOTO bspexit
	END

if @PCO is null
	BEGIN
		SELECT @msg = 'Missing pending change order!', @rcode = 1
		GOTO bspexit
	END

if @PCOItem is null
	BEGIN
		SELECT @msg = 'Missing pending change order item!', @rcode = 1
		GOTO bspexit
	END

IF @ACO is null
	BEGIN
		SELECT @msg = 'Missing approved change order!', @rcode = 1
		GOTO bspexit
	END

IF @ACOItem is null
	BEGIN
		SELECT @msg = 'Missing approved change order item!', @rcode = 1
		GOTO bspexit
	END

---- get PM company info
SELECT  @APCo=APCo,
		@BeginStatus	= BeginStatus,
		@MatlPhaseDesc	= MatlPhaseDesc,
		@MatlCostType	= MtlCostType,
		@MatlCostType2	= MatlCostType2
FROM dbo.bPMCO WHERE PMCo=@PMCo
IF @@rowcount = 0
	BEGIN
	SELECT @msg = 'Invalid PM Company.', @rcode = 1
	GOTO bspexit
	END
	
	
	
----TK-06770
SET @pmmfseqlist = NULL
---- declare cursor on PMOL rows that have a vendor and no po and the cost type
---- is one of the 2 PM company defined material cost types
DECLARE bcPMOLCreate CURSOR LOCAL FAST_FORWARD
	FOR SELECT Phase, CostType, Vendor, KeyID
	FROM dbo.bPMOL
	WHERE PMCo = @PMCo
		AND Project = @Project
		AND PCOType = @PCOType
		AND PCO = @PCO
		AND PCOItem = @PCOItem
		AND ACO = @ACO
		AND ACOItem = @ACOItem
		AND Vendor IS NOT NULL
		AND PO IS NULL
		AND InterfacedDate IS NULL
		AND CostType IN (@MatlCostType, @MatlCostType2)
		
---- open cursor
OPEN bcPMOLCreate
SET @opencursor = 1

PMOL_Loop:
FETCH NEXT FROM bcPMOLCreate INTO @Phase, @CostType, @Vendor, @PMOLKeyID

IF @@FETCH_STATUS <> 0 GOTO PMOL_End

---- check for existence of a PMmf detail record associated to the PMOL record
SELECT TOP 1 @PMMFSeq = Seq, @PMMFKeyID = KeyID
FROM dbo.bPMMF
WHERE PMCo = @PMCo
	AND Project		= @Project
	AND PCOType		= @PCOType
	AND PCO			= @PCO
	AND PCOItem		= @PCOItem
	AND ACO			= @ACO
	AND ACOItem		= @ACOItem
	AND Phase		= @Phase
	AND CostType	= @CostType
	AND Vendor		= @Vendor
	---- TK-07189
	--AND RecordType	= 'C'
	AND MaterialOption = 'P'
	AND PO IS NULL
	AND InterfaceDate IS NULL
	
---- if no records found move to next
IF @@ROWCOUNT = 0 GOTO PMOL_Loop

---- process one sequence at a time to initialize subcontract detail
SELECT @pmmfseqlist =  ';' + CONVERT(VARCHAR(6),@PMMFSeq) + ';'

---- if we have any PMMF Sequences to create a PO for then use the bspPMMFInitialize procedure
---- TK-07189
EXEC @retcode = dbo.bspPMMFInitialize @PMCo, @Project, 'X', NULL, @ACO, @ACOItem, @pmmfseqlist, @retmsg OUTPUT
---- if error occurs trying to create a PO we will do nothing for now
---- users can manually assign a SL to the detail in PM Material Detail
if @retcode <> 0 GOTO PMOL_Loop
	--BEGIN
	--SET @rcode = @retcode
	--SET @msg = @retmsg
	--GOTO bspexit
	--END


---- set to 'C' so that no poco is created in next section
---- when the purchase order status = 3 pending then a new PO
---- TK-07189
UPDATE dbo.bPMMF SET IntFlag = CASE WHEN l.PO IS NULL THEN 'N' ELSE 'C' END
FROM dbo.bPMMF l
INNER JOIN dbo.bPOHD p ON p.POCo=l.POCo AND p.PO=l.PO
WHERE l.KeyID = @PMMFKeyID

---- get PO, POItem, POCONum, Seq from PMMF
SELECT  @PO = PO, @POItem = POItem, @POCONum = POCONum
FROM dbo.bPMMF
WHERE KeyID = @PMMFKeyID

---- now update PMOL and assign the PO, PO Item, POCONum, POCONumSeq
UPDATE dbo.bPMOL SET PO = @PO,
					 POSLItem	 = @POItem,
					 POCONum	 = CASE WHEN @POCONum IS NOT NULL THEN @POCONum ELSE NULL END,
					 POCONumSeq	 = CASE WHEN @POCONum IS NOT NULL THEN @PMMFSeq ELSE NULL END		 
WHERE KeyID = @PMOLKeyID AND PO IS NULL

--SELECT @msg = ISNULL(@PO,'') + '/' + ISNULL(CONVERT(VARCHAR(10),@POItem),0) + '/' + ISNULL(CONVERT(VARCHAR(10),@PMMFKeyID),'-1') + '/' + ISNULL(CONVERT(VARCHAR(10),@PMOLKeyID),'-1')

--SELECT @rcode = 1
--GOTO bspexit


GOTO PMOL_Loop


PMOL_End:
	CLOSE bcPMOLCreate
	DEALLOCATE bcPMOLCreate
	SET @opencursor = 0


----TK-13768 do not create POCO
IF @CreateChangeOrders <> 'Y' GOTO bspexit


SET @LastPO = NULL
---- declare cursor on PMOL rows that have a PO and no POCO Number assigned yet
DECLARE bcPMOLPOCO CURSOR LOCAL FAST_FORWARD
	FOR SELECT PhaseGroup, Phase, CostType, PO, POSLItem, KeyID, Notes
	FROM dbo.bPMOL
	WHERE PMCo = @PMCo
		AND Project = @Project
		AND PCOType = @PCOType
		AND PCO = @PCO
		AND PCOItem = @PCOItem
		AND ACO = @ACO
		AND ACOItem = @ACOItem
		AND PO IS NOT NULL
		AND POCONum IS NULL
		AND InterfacedDate IS NULL
		
---- open cursor
OPEN bcPMOLPOCO
SET @opencursor2 = 1

PMOL2_Loop:
FETCH NEXT FROM bcPMOLPOCO INTO @PhaseGroup, @Phase, @CostType, @PO, @POItem, @PMOLKeyID, @PMOLNotes

IF @@FETCH_STATUS <> 0 GOTO PMOL2_End

---- must have a PMMF record for the PMCo, Project, PCOType, PCO, PCOItem, PO, POItem
---- if not then no detail to assign to the created POCO, so why do?
---- we also need the description for the PMPOCO record we will create
SELECT TOP 1 @Description = MtlDescription, @PMMFSeq = Seq, @PMMFKeyID = KeyID
FROM dbo.bPMMF
WHERE PMCo = @PMCo
	AND Project = @Project
	AND PCOType = @PCOType
	AND PCO = @PCO
	AND PCOItem = @PCOItem
	AND ACO = @ACO
	AND ACOItem = @ACOItem
	AND Phase = @Phase
	AND CostType = @CostType
	AND PO = @PO
	AND POItem = @POItem
	AND POCONum IS NULL
	AND InterfaceDate IS NULL
	---- if 'C' created in first section
	AND ISNULL(IntFlag,'N') <> 'C'
	
---- if no detail do not create POCO Number
IF @@ROWCOUNT = 0 GOTO PMOL2_Loop


---- only get next POCO Number when PO changes
IF ISNULL(@LastPO,'') <> @PO
	BEGIN
	---- call the subcontract co create procedure to generate next SubCO
	SET @POCONum = NULL
	EXEC @retcode = dbo.vspPMPOCONumCreate @PMMFKeyID, @ReadyForAccounting ,@POCONum OUTPUT, @retmsg OUTPUT
	IF @retcode <> 0
		BEGIN
		SELECT @msg = @retmsg, @rcode = 1
		GOTO bspexit
		END

	IF @POCONum IS NULL
		BEGIN
		SELECT @msg = 'Error occurred generating next POCONum.', @rcode = 1
		GOTO bspexit
		END
	END

IF ISNUll(@POCONum,'')<>'' or @POCONum <> 0	
	BEGIN
	---- update PMPOCO with concatinated Notes for the Details. TK-10541	
	IF @PMOLNotes IS NOT NULL AND dbo.Trim(@PMOLNotes) <> ''
		BEGIN
			UPDATE dbo.PMPOCO
			---- Add two spaces between notes
			SET Details = CASE WHEN Details IS NOT NULL THEN Details + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) ELSE '' END + @PMOLNotes
			WHERE PMCo = @PMCo
				AND Project = @Project
				AND PO = @PO
				AND POCONum = @POCONum		

		END
	END

---- set last PO to current
SET @LastPO = @PO

---- update PMOL record and assign POCONum and POCONumSeq
UPDATE	dbo.bPMOL
SET		POCONum=@POCONum, POCONumSeq=@PMMFSeq
WHERE	KeyID = @PMOLKeyID

---- update PMMF and assign the POCONum to all matching detail records
UPDATE	dbo.bPMMF 
SET		POCONum=@POCONum
WHERE	PMCo=@PMCo 
	AND Project=@Project
	AND PCOType=@PCOType 
	AND PCO=@PCO 
	AND PCOItem=@PCOItem
	AND ACO=@ACO 
	AND ACOItem=@ACOItem
	AND Phase = @Phase
	AND CostType = @CostType
	AND PO=@PO 
	AND POItem=@POItem


GOTO PMOL2_Loop


PMOL2_End:
	CLOSE bcPMOLPOCO
	DEALLOCATE bcPMOLPOCO
	SET @opencursor2 = 0
	
IF @ReadyForAccounting = 'Y'
BEGIN
	---- declare cursor on PMMF rows that have a PO and POCO Number assigned but no matching PMOL record
	DECLARE bcPMPOCO3 CURSOR LOCAL FAST_FORWARD
		FOR SELECT DISTINCT  b.KeyID
		FROM dbo.vPMPOCO b
		INNER JOIN dbo.bPMMF a on a.PMCo=b.PMCo and a.Project=b.Project and a.POCo=b.POCo and a.PO=b.PO and a.POCONum=b.POCONum
		WHERE  b.ReadyForAcctg = 'N' 
			AND b.PMCo = @PMCo
			AND b.Project = @Project
			AND a.PCOType =@PCOType
			AND a.PCO = @PCO
			AND a.PCOItem = @PCOItem
			AND a.ACO = @ACO
			AND a.ACOItem = @ACOItem
			AND a.PO IS NOT NULL
			AND a.POCONum IS NOT NULL
			AND a.InterfaceDate  is null 
			AND  a.SendFlag = 'Y'		
	---- open cursor
	OPEN bcPMPOCO3
	SET @opencursor3 = 1

	PMPOCO3_Loop:
	FETCH NEXT FROM bcPMPOCO3 INTO   @PMPOCOKeyID

	IF @@FETCH_STATUS <> 0 GOTO PMPOCO3_End

	---- update PMPOCO
	---- TK-11854 execute SP to approve POCO
	DECLARE @POCOCount SMALLINT
	SET @POCOCount = 0
	EXEC @rcode = dbo.vspPMPOCOApprovePOCOs @PMPOCOKeyID, 'Y', @POCOCount OUTPUT, @msg OUTPUT
	--UPDATE	dbo.vPMPOCO
	--SET		ReadyForAcctg = @ReadyForAccounting
	--WHERE	KeyID = @PMPOCOKeyID AND ReadyForAcctg='N'

	GOTO PMPOCO3_Loop

	PMPOCO3_End:
		CLOSE bcPMPOCO3
		DEALLOCATE bcPMPOCO3
		SET @opencursor3 = 0
END

bspexit:
	---- update PMMF and set IntFlag = 'N' if 'C' cleanup
	UPDATE dbo.bPMMF SET IntFlag = 'N'
	WHERE PMCo=@PMCo AND Project=@Project AND IntFlag = 'C'

	IF @opencursor = 1
		BEGIN
		CLOSE bcPMOLCreate
		DEALLOCATE bcPMOLCreate
		SET @opencursor = 0
		END
		
	IF @opencursor2 = 1
		BEGIN
		CLOSE bcPMOLPOCO
		DEALLOCATE bcPMOLPOCO
		SET @opencursor2 = 0
		END

	IF @opencursor3 = 1
		BEGIN
		CLOSE bcPMPOCO3
		DEALLOCATE bcPMPOCO3
		SET @opencursor3 = 0
		END
	
	IF @rcode <> 0 SELECT @msg = isnull(@msg,'') 
	RETURN @rcode





GO
GRANT EXECUTE ON  [dbo].[vspPMPCOApprovePMMF] TO [public]
GO
