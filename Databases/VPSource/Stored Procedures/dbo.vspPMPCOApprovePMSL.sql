
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[vspPMPCOApprovePMSL]
/***********************************************************
* Created By:	GF 06/06/2011 TK-05799
* Modified By:  GF 06/15/2011 TK-06039
*				GF 07/12/2011 TK-06770
*				GF 08/01/2011 TK-07189
*				GP 08/30/2011 TK-07993 added table variable to keep track of which PMSL records don't need SubCOs
*				TL 12/01/2011 TK-10436 add parameter @ReadyForAccounting	
*				JG 12/02/2011 TK-10541 - Notes being concatenated from PMOL records to PMSubcontractCO Detail.
*				GF 02/07/2012 TK-11854 use the SCO approval procedure to set status and data also.
*				GF 02/10/2012 TK-12466 SLItemType should always be 2 - Change
*				GF 03/09/2012 TK-13116 #146042 duplicate of TK-12466 because did not get to 6.4.4
*				DAN SO 03/12/2012 - TK-13118 - Added @CreateChangeOrders and @CreateSingleChangeOrder
*				DAN SO 03/13/2012 - TK-13139 - Added @CreateSingleChangeOrder to SP calls
*				GF 03/30/2012 TK-13768 use the @CreateChangeorders flag
*				GF 05/22/2012 TK-13889 #145421 do not approve SCO if ready for accounting <> 'Y'
*				TRL 12/06/2012 TK-19418  Add Code to approve existing SLSubCO on Approval
*				AJW 03/15/2013 TFS 43659 support new check box for creating a new SL from PMSL
*
*				
* This SP updates any PMSL detail records when a pending
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
* If creating a new subcontract then we do not want to have an SCO created also. Will use the
* IntFlag to indicate when a new subcontract is created so that an SCO is not created also.
*
* Second cursor is based on PMOL records with a SL, no SubCO Number, and not interfaced.
* Must be detail existing in PMSL to create SubCO Number.
* The next SubCO Number will be from PMSubcontractCO for the SLCo and SL.
* Will update all matching PMSL records and assign to the new SubCO Number.
* Then update the SubCO and Sequence in PMOL for the record.			
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
		@slmsg VARCHAR(60), @opencursor TINYINT, @opencursor2 TINYINT,
		@SL VARCHAR(30), @SLItem bItem, @APCo bCompany, @SubCO SMALLINT, 
		@Vendor bVendor, @Seq INT, @Phase bPhase, @CostType bJCCType,
		@PMOLKeyID BIGINT, @PMOLNotes VARCHAR(MAX), @SubCOStatus VARCHAR(6), @BeginStatus VARCHAR(6),
		@Description VARCHAR(60), @PMSLSeq INT, @SLItemType TINYINT,
		@PhaseGroup bGroup, @PMSLKeyID BIGINT, @LastSL VARCHAR(30),
		----TK-06770
		@SLCostType bJCCType, @SLCostType2 bJCCType, @pmslseqlist VARCHAR(MAX),
		--TK-10436
		 @opencursor3 TINYINT,@PMSubcontractCOKeyID BIGINT,
		--TK-????
		@opencursor4 TINYINT

DECLARE @PMSLWithNewSL TABLE (PMSLKeyID bigint not null)

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
		----TK-06770
		@SLCostType		= SLCostType,
		@SLCostType2	= SLCostType2
FROM dbo.bPMCO WHERE PMCo=@PMCo
IF @@rowcount = 0
	BEGIN
	SELECT @msg = 'Invalid PM Company.', @rcode = 1
	GOTO bspexit
	END


----TK-06770
SET @pmslseqlist = NULL
---- declare cursor on PMOL rows that have a vendor and no SL and the cost type
---- is one of the 2 PM company defined subcontract cost types
--43659 Jeremy says if SL is null never create an SL or SubCO
--DECLARE bcPMOL CURSOR LOCAL FAST_FORWARD
--	FOR SELECT Phase, CostType, Vendor, KeyID
--	FROM dbo.bPMOL
--	WHERE PMCo = @PMCo
--		AND Project = @Project
--		AND PCOType = @PCOType
--		AND PCO = @PCO
--		AND PCOItem = @PCOItem
--		AND ACO = @ACO
--		AND ACOItem = @ACOItem
--		AND Vendor IS NOT NULL
--		AND Subcontract IS NULL
--		AND InterfacedDate IS NULL
--		AND CostType IN (@SLCostType, @SLCostType2)
		
------ open cursor
--OPEN bcPMOL
--SET @opencursor = 1

--PMOL_Loop:
--FETCH NEXT FROM bcPMOL INTO @Phase, @CostType, @Vendor, @PMOLKeyID

--IF @@FETCH_STATUS <> 0 GOTO PMOL_End

------ check for existence of a PMSL detail record associated to the PMOL record
--SELECT TOP 1 @PMSLSeq = Seq, @PMSLKeyID = KeyID
--FROM dbo.bPMSL
--WHERE PMCo = @PMCo
--	AND Project		= @Project
--	AND PCOType		= @PCOType
--	AND PCO			= @PCO
--	AND PCOItem		= @PCOItem
--	AND ACO			= @ACO
--	AND ACOItem		= @ACOItem
--	AND Phase		= @Phase
--	AND CostType	= @CostType
--	AND Vendor		= @Vendor
--	----TK-07189
--	--AND RecordType	= 'C'
--	AND SL IS NULL
--	AND InterfaceDate IS NULL
	
------ if no records found move to next
--IF @@ROWCOUNT = 0 GOTO PMOL_Loop

------ process one sequence at a time to initialize subcontract detail
--SELECT @pmslseqlist =  ';' + CONVERT(VARCHAR(6),@PMSLSeq) + ';'

------ if we have any PMSL Sequences to create a SL for then use the bspPMSLInitialize procedure
------ TK-07189
--EXEC @retcode = dbo.bspPMSLInitialize @PMCo, @Project, 'X', NULL, @ACO, @ACOItem, @pmslseqlist, 
--				-- TK-13139 --
--				@CreateSingleChangeOrder,
--				@retmsg OUTPUT
------ if error occurs trying to create a SL we will do nothing for now
------ users can manually assign a SL to the detail in PM Subcontract Detail
--if @retcode <> 0  GOTO PMOL_Loop

----keep track of which records have new subcontract
--INSERT @PMSLWithNewSL (PMSLKeyID)
--VALUES (@PMSLKeyID)

------ set to 'C' so that no subco is created in next section
------ when the subcontract status = 3 pending then a new subcontract
------ TK-07189
--UPDATE dbo.bPMSL SET IntFlag	= CASE WHEN l.SL IS NULL THEN 'N' ELSE 'C' END,
--					 ----TK-12466
--					 SLItemType = 2 ----SLItemType = CASE WHEN l.SubCO IS NULL THEN 1 ELSE l.SLItemType END
--FROM dbo.bPMSL l
--INNER JOIN dbo.bSLHD s ON s.SLCo=l.SLCo AND s.SL=l.SL
--WHERE l.KeyID = @PMSLKeyID

------ get SL, SLItem, SubCO, Seq from PMSL
--SELECT  @SL = SL, @SLItem = SLItem, @SubCO = SubCO
--FROM dbo.bPMSL
--WHERE KeyID = @PMSLKeyID


--GOTO PMOL_Loop


--PMOL_End:
--	CLOSE bcPMOL
--	DEALLOCATE bcPMOL
--	SET @opencursor = 0

----TK-13768 do not create SCO
IF @CreateChangeOrders = 'Y' 
BEGIN
---- reset last subcontract
SET @LastSL = NULL
---- declare cursor on PMOL rows that have a SL and no SubCO Number assigned yet
DECLARE bcPMOL2 CURSOR LOCAL FAST_FORWARD
	FOR SELECT PhaseGroup, Phase, CostType, Subcontract, POSLItem, KeyID, Notes
	FROM dbo.bPMOL
	WHERE PMCo = @PMCo
		AND Project = @Project
		AND PCOType = @PCOType
		AND PCO = @PCO
		AND PCOItem = @PCOItem
		AND ACO = @ACO
		AND ACOItem = @ACOItem
		AND Subcontract IS NOT NULL
		AND SubCO IS NULL
		AND InterfacedDate IS NULL
		-- 43659
		AND CreateSL='N'
		
---- open cursor
OPEN bcPMOL2
SET @opencursor2 = 1

PMOL2_Loop:
FETCH NEXT FROM bcPMOL2 INTO @PhaseGroup, @Phase, @CostType, @SL, @SLItem, @PMOLKeyID, @PMOLNotes

IF @@FETCH_STATUS <> 0 GOTO PMOL2_End

---- must have a PMSL record for the PMCo, Project, PCOType, PCO, PCOItem, SL, SLItem
---- if not then no detail to assign to the created SubCO, so why do?
---- we also need the description for the PMSubcontractCO record we will create
SELECT TOP 1 @Description = sl.SLItemDescription, @SLItemType = sl.SLItemType,
			 @PMSLSeq = sl.Seq, @PMSLKeyID = sl.KeyID
FROM dbo.bPMSL sl
----LEFT OUTER JOIN @PMSLWithNewSL new on new.PMSLKeyID = sl.KeyID
WHERE sl.PMCo = @PMCo
	AND sl.Project = @Project
	AND sl.PCOType = @PCOType
	AND sl.PCO = @PCO
	AND sl.PCOItem = @PCOItem
	AND sl.ACO = @ACO
	AND sl.ACOItem = @ACOItem
	AND sl.Phase = @Phase
	AND sl.CostType = @CostType
	AND sl.SL = @SL
	AND sl.SLItem = @SLItem
	AND sl.SLItemType IN (1,2,4)
	AND sl.SubCO IS NULL
	AND sl.InterfaceDate IS NULL
	----TK-13768
	---- if 'C' created in first section
	--AND ISNULL(IntFlag,'N') <> 'C'
	---- don't add SubCOs for new subcontracts found in previous loop
	----TK-13768
	----AND new.PMSLKeyID IS NULL
---- if no subcontract detail goto next
IF @@ROWCOUNT = 0
	BEGIN
	--SELECT 'No subcontract detail'
	GOTO PMOL2_Loop
	END

---- only get next subcontract change order when the last subcontract is different
IF ISNULL(@LastSL,'') <> @SL
	BEGIN
	---- call the subcontract co create procedure to generate next SubCO
	SET @SubCO = NULL
	EXEC @retcode = dbo.vspPMSubcontractCOCreate @PMSLKeyID, @ReadyForAccounting,
					-- TK-13139 --
					@CreateSingleChangeOrder,
					@SubCO OUTPUT, @retmsg OUTPUT
	IF @retcode <> 0
		BEGIN
		SELECT @msg = @retmsg, @rcode = 1
		GOTO bspexit
		END

	IF @SubCO IS NULL
		BEGIN
		SELECT @msg = 'Error occurred generating next SubCO.', @rcode = 1
		GOTO bspexit
		END

	----TK-13889 moved approve SCO to here
	IF @ReadyForAccounting = 'Y'
		BEGIN
		SELECT @PMSubcontractCOKeyID = KeyID
		FROM dbo.vPMSubcontractCO
		WHERE SLCo = @APCo
			AND SL = @SL
			AND SubCO = @SubCO
		IF @@ROWCOUNT = 1
			BEGIN
			EXEC @retcode = dbo.vspPMSubcontractCOApproveSCOs @PMSubcontractCOKeyID, 'Y', NULL, @retmsg OUTPUT
			END
		END
	END

IF ISNUll(@SubCO,'')<>'' or @SubCO <> 0	
	BEGIN
	---- update PMSubcontractCO with concatinated Notes for the Details. TK-10541	
	IF @PMOLNotes IS NOT NULL AND dbo.Trim(@PMOLNotes) <> ''
		BEGIN
			UPDATE dbo.vPMSubcontractCO
			---- Add two spaces between notes
			SET Details = CASE WHEN Details IS NOT NULL THEN Details + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) ELSE '' END + @PMOLNotes
			WHERE SLCo = @APCo
				AND SL = @SL
				AND SubCO = @SubCO		
		END
	END

---- set last subcontract to current
SET @LastSL = @SL

----TK-13889
---- update PMSL and assign the SubCO to all matching detail records
UPDATE dbo.bPMSL
SET	SubCO = @SubCO, IntFlag = 'C'
WHERE PMCo=@PMCo 
	AND Project=@Project
	AND PCOType=@PCOType 
	AND PCO=@PCO 
	AND PCOItem=@PCOItem
	AND ACO=@ACO 
	AND ACOItem=@ACOItem
	AND Phase = @Phase
	AND CostType = @CostType
	AND SL=@SL 
	AND SLItem=@SLItem
	AND InterfaceDate IS NULL
	

GOTO PMOL2_Loop


PMOL2_End:
	CLOSE bcPMOL2
	DEALLOCATE bcPMOL2
	SET @opencursor2 = 0
END


IF @ReadyForAccounting = 'Y'
	BEGIN
	--declare cursor on PMOL rows that have a SL with assigned SubCO Number 
     DECLARE bcPMOL3 CURSOR LOCAL FAST_FORWARD
	FOR SELECT PhaseGroup, Phase, CostType, Subcontract, SubCO
	FROM dbo.bPMOL
	WHERE PMCo = @PMCo
		AND Project = @Project
		AND PCOType = @PCOType
		AND PCO = @PCO
		AND PCOItem = @PCOItem
		AND ACO = @ACO
		AND ACOItem = @ACOItem
		AND Subcontract IS NOT NULL
		AND SubCO IS NOT NULL
		AND InterfacedDate IS NULL
	
	---- open cursor
	OPEN bcPMOL3
	SET @opencursor3 = 1

	PMOL3_Loop:
	FETCH NEXT FROM bcPMOL3 INTO @PhaseGroup, @Phase, @CostType, @SL, @SubCO

	IF @@FETCH_STATUS <> 0 GOTO PMOL3_End

	------ must have a PMSL record for the PMCo, Project, PCOType, PCO, PCOItem, SL, SubCO
	SELECT sl.SL, sl.SubCO FROM dbo.bPMSL sl
	WHERE sl.PMCo = @PMCo
		AND sl.Project = @Project
		AND sl.PCOType = @PCOType
		AND sl.PCO = @PCO
		AND sl.PCOItem = @PCOItem
		AND sl.ACO = @ACO
		AND sl.ACOItem = @ACOItem
		AND sl.Phase = @Phase
		AND sl.CostType = @CostType
		AND sl.SL = @SL
		AND sl.SLItemType IN (1,2,4)
		AND sl.SubCO = @SubCO
		AND sl.InterfaceDate IS NULL
		IF @@ROWCOUNT = 0
		BEGIN
			GOTO PMOL3_Loop
		END

		SELECT KeyID
		FROM dbo.vPMSubcontractCO
		WHERE SLCo = @APCo AND SL = @SL 	AND SubCO = @SubCO
		IF @@ROWCOUNT = 0
		BEGIN
			GOTO PMOL3_Loop
		END

		--Cycle through Subcontract SubCO's
		DECLARE bcPMOL4 CURSOR LOCAL FAST_FORWARD
		FOR SELECT KeyID
		FROM dbo.vPMSubcontractCO
		WHERE SLCo = @APCo AND SL = @SL 	AND SubCO = @SubCO

		---- open cursor
		OPEN bcPMOL4
		SET @opencursor4 = 1

		PMOL4_Loop:

		FETCH NEXT FROM bcPMOL4 INTO @PMSubcontractCOKeyID

		IF @@FETCH_STATUS <> 0 GOTO PMOL4_End

		EXEC @retcode = dbo.vspPMSubcontractCOApproveSCOs @PMSubcontractCOKeyID, 'Y', NULL, @retmsg OUTPUT
		
		GOTO PMOL4_Loop

		PMOL4_End:
			CLOSE bcPMOL4
			DEALLOCATE bcPMOL4
			SET @opencursor4 = 0
		
	GOTO PMOL3_Loop

	PMOL3_End:
		CLOSE bcPMOL3
		DEALLOCATE bcPMOL3
		SET @opencursor3 = 0
	END


bspexit:
	---- update PMSL and set IntFlag = 'N' if 'C' cleanup
	UPDATE dbo.bPMSL SET IntFlag = NULL
	WHERE PMCo=@PMCo AND Project=@Project AND IntFlag = 'C'
	
	
	IF @opencursor = 1
		BEGIN
		CLOSE bcPMOL
		DEALLOCATE bcPMOL
		SET @opencursor = 0
		END
		
	IF @opencursor2 = 1
		BEGIN
		CLOSE bcPMOL2
		DEALLOCATE bcPMOL2
		SET @opencursor2 = 0
		END

	IF @opencursor3 = 1
		BEGIN
		CLOSE bcPMSL3
		DEALLOCATE bcPMSL3
		SET @opencursor3 = 0
		END
	
	IF @opencursor4 = 1
		BEGIN
		CLOSE bcPMSL4
		DEALLOCATE bcPMSL4
		SET @opencursor4 = 0
		END

	IF @rcode <> 0 SELECT @msg = isnull(@msg,'') 
	RETURN @rcode












GO

GRANT EXECUTE ON  [dbo].[vspPMPCOApprovePMSL] TO [public]
GO
