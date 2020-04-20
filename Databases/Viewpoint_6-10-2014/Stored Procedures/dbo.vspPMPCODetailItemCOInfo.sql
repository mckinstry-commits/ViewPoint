SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[vspPMPCODetailItemCOInfo]
/***********************************************************
* CREATED BY:	DAN SO 04/26/2011
* MODIFIED BY:	GF 02/21/2012 TK-12789 ISSUE #145905 more detail checking for PCO item delete
*
*
* USAGE:
* Called from PMPCOSItem or PMPCOSItemDetail to validate if the PCO Item
* or the PCO Item Detail Line is ok to delete.
*
*
* INPUT PARAMETERS
* @PMOIKeyId		PMOI Key ID of PCO Item to validate for delete
* @PMOLKeyId		PMOL Key ID of PCO Item Line to validate for delete
*
* OUTPUT PARAMETERS
* @ValidToDelete	Used to let form know if item or line is valid to delete - 0=False, 1=True
* @TypeOfDetail		Flag to indicate if subcontract or material detail exists (N,M,S)
* @msg			Error Message
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@PMOIKeyId BIGINT = NULL, @PMOLKeyId BIGINT = NULL, 
 @ValidToDelete BIT OUTPUT, @TypeOfDetail CHAR(1) = 'N' OUTPUT,
 @Msg varchar(500) output)

AS
SET NOCOUNT ON

----TK-12789 
DECLARE @rcode INT, @SendFlag CHAR(1), @Ready CHAR(1),
		@PMCo bCompany, @Project bJob, @PCOType bDocType, @PCO bPCO, @PCOItem bPCOItem,
		@PhaseGroup bGroup, @Phase bPhase, @CostType bJCCType, @validcnt INT,
		@KeyPart VARCHAR(100), @DetailKeyId BIGINT, @DetailPhase bPhase,
		@DetailCostType bJCCType, @DetailCheck CHAR(1),
		@DetailPOCONum SMALLINT, @DetailSubCO SMALLINT


SET @ValidToDelete = 0	-- DEFAULTED FALSE
SET @rcode = 0
SET @DetailCheck = 'N'
SET @TypeOfDetail = 'N'

IF ISNULL(@PMOIKeyId,0) > 0 SET @PMOLKeyId = NULL
IF ISNULL(@PMOLKeyId,0) > 0 SET @PMOIKeyId = NULL

---- check for valid key id
IF @PMOIKeyId IS NULL AND @PMOLKeyId IS NULL
	BEGIN
	SELECT @Msg = 'Missing PCO Item or Detail Key ID!', @rcode = 1
	GOTO vspexit
	END

IF @PMOLKeyId IS NOT NULL SET @DetailCheck = 'Y'

-----------------------------------------------------------------------
-- we need to check all detail for a PCO Item or just one detail record
-- this will depend on the whether we have a PMOI Key Id or PMOL Key Id
-- It is possible that we have detail in PMSL or PMMF for the PCO Item
-- but there is no matching detail record in PMOL.
-----------------------------------------------------------------------

SET @PhaseGroup = NULL
SET @Phase = NULL
SET @CostType = NULL

---- if PCO Item check all PMSL or PMMF detail for the PCO Item Key parts
IF @PMOIKeyId IS NOT NULL
	BEGIN
	SELECT  @PMCo = i.PMCo, @Project = i.Project, @PCOType = i.PCOType,
			@PCO  = i.PCO, @PCOItem  = i.PCOItem, @DetailKeyId = i.KeyID
	FROM dbo.PMOI i
	WHERE KeyID = @PMOIKeyId
	IF @@ROWCOUNT = 0
		BEGIN
		SELECT @Msg = 'Missing PCO Item Key ID!', @rcode = 1
		GOTO vspexit
		END
	END
ELSE
	BEGIN
	---- if checking a detail line then just get that detail phase cost type for checks
	IF @PMOLKeyId IS NOT NULL
		BEGIN
		---- get PMOL information
		SELECT  @PMCo = l.PMCo, @Project = l.Project, @PCOType = l.PCOType, @PCO = l.PCO,
				@PCOItem = l.PCOItem, @PhaseGroup = l.PhaseGroup, @Phase = l.Phase,
				@CostType = l.CostType, @DetailKeyId = l.KeyID
		FROM dbo.PMOL l
		WHERE KeyID = @PMOLKeyId
		IF @@ROWCOUNT = 0
			BEGIN
			SELECT @Msg = 'Missing PCO Item Key ID!', @rcode = 1
			GOTO vspexit
			END
		END
	END

---- build key part of message
SELECT @KeyPart = 'PCO Item: ' + dbo.vfToString(@PCOItem) + ', ' 

---- we need to check PMSL and PMMF first and not rely on PMOL data which may not be accurate
---- check for subcontract detail in bPMSL assigned to SL and has been interfaced.
SELECT @DetailPhase = s.Phase, @DetailCostType = s.CostType
FROM dbo.PMSL s
WHERE s.PMCo=@PMCo
	AND s.Project=@Project
	AND s.PCOType=@PCOType
	AND s.PCO=@PCO
	AND s.PCOItem=@PCOItem
	AND s.Phase = ISNULL(@Phase, s.Phase)
	AND s.CostType = ISNULL(@CostType, s.CostType)
	AND s.SL IS NOT NULL
	AND s.InterfaceDate IS NOT NULL
IF @@ROWCOUNT <> 0
	begin
  	select @Msg = ISNULL(@KeyPart,'') + 'Phase: ' + dbo.vfToString(@DetailPhase) + ', CostType: ' + dbo.vfToString(@DetailCostType) + ' : ' + 'Subcontract detail exists and has been interfaced. Cannot delete.'
  	SET @rcode = 1
  	Goto vspexit
  	end

---- check for material detail in bPMMF assigned to PO and has been interfaced.
SELECT @DetailPhase = m.Phase, @DetailCostType = m.CostType
FROM dbo.PMMF m
WHERE m.PMCo=@PMCo
	AND m.Project=@Project
	AND m.PCOType=@PCOType
	AND m.PCO=@PCO
	AND m.PCOItem=@PCOItem
	AND m.Phase = ISNULL(@Phase, m.Phase)
	AND m.CostType = ISNULL(@CostType, m.CostType)
	AND m.PO IS NOT NULL
	AND m.InterfaceDate IS NOT NULL
IF @@ROWCOUNT <> 0
	begin
  	select @Msg = ISNULL(@KeyPart,'') + 'Phase: ' + dbo.vfToString(@DetailPhase) + ', CostType: ' + dbo.vfToString(@DetailCostType) + ' : ' + ' Purchase Order detail exists and has been interfaced. Cannot delete.'
    SET @rcode = 1
  	Goto vspexit
  	END
 
---- check for material detail in bPMMF assigned to MO and has been interfaced.
SELECT @DetailPhase = m.Phase, @DetailCostType = m.CostType
FROM dbo.PMMF m
WHERE m.PMCo=@PMCo
	AND m.Project=@Project
	AND m.PCOType=@PCOType
	AND m.PCO=@PCO
	AND m.PCOItem=@PCOItem
	AND m.Phase = ISNULL(@Phase, m.Phase)
	AND m.CostType = ISNULL(@CostType, m.CostType)
	AND m.MO IS NOT NULL
	AND m.InterfaceDate IS NOT NULL
IF @@ROWCOUNT <> 0 
	BEGIN
  	SELECT @Msg = ISNULL(@KeyPart,'') + 'Phase: ' + dbo.vfToString(@DetailPhase) + ', CostType: ' + dbo.vfToString(@DetailCostType) + ' : ' + ' Material Order detail exists and has been interfaced. Cannot delete.'
  	SET @rcode = 1
  	GOTO vspexit
  	END 	
  	

---- now we need to check for PMSL detail assigned to a SubCO that is 
SELECT  @SendFlag = s.SendFlag, @Ready = co.ReadyForAcctg,
		@DetailPhase = s.Phase, @DetailCostType = s.CostType,
		@DetailSubCO = s.SubCO
FROM dbo.PMSL s WITH (NOLOCK)
JOIN dbo.PMSubcontractCO co ON s.SLCo=co.SLCo AND s.SL=co.SL AND s.SubCO=co.SubCO 
WHERE s.PMCo=@PMCo
	AND s.Project=@Project
	AND s.PCOType=@PCOType
	AND s.PCO=@PCO
	AND s.PCOItem=@PCOItem
	AND s.Phase = ISNULL(@Phase, s.Phase)
	AND s.CostType = ISNULL(@CostType, s.CostType)
	AND s.SL IS NOT NULL
	AND s.SubCO IS NOT NULL
	AND s.InterfaceDate IS NULL
IF @@ROWCOUNT <> 0
	BEGIN
	IF @SendFlag = 'Y' OR @Ready = 'Y'
		BEGIN
		SELECT @Msg = ISNULL(@KeyPart,'') + 'Phase: ' + dbo.vfToString(@DetailPhase) + ', CostType: ' + dbo.vfToString(@DetailCostType) + ', SCO: ' + dbo.vfToString(@DetailSubCO) + ' : ' + ' Subcontract detail exists.'
  		--SET @rcode = 1
  		SET @TypeOfDetail = 'S'
  		GOTO vspexit
  		END
  	END
	

---- now we need to check for PMMF detail assigned to a POCONum that is approved
SELECT  @SendFlag = m.SendFlag, @Ready = co.ReadyForAcctg,
		@DetailPhase = m.Phase, @DetailCostType = m.CostType,
		@DetailPOCONum = m.POCONum
FROM dbo.PMMF m WITH (NOLOCK)
JOIN dbo.PMPOCO co WITH (NOLOCK) ON m.POCo=co.POCo AND m.PO=co.PO AND m.POCONum=co.POCONum
WHERE m.PMCo=@PMCo
	AND m.Project=@Project
	AND m.PCOType=@PCOType
	AND m.PCO=@PCO
	AND m.PCOItem=@PCOItem
	AND m.Phase = ISNULL(@Phase, m.Phase)
	AND m.CostType = ISNULL(@CostType, m.CostType)
	AND m.PO IS NOT NULL
	AND m.POCONum IS NOT NULL
	AND m.InterfaceDate IS NULL
IF @@ROWCOUNT <> 0
	BEGIN
	IF @SendFlag = 'Y' OR @Ready = 'Y'
		BEGIN
  		SELECT @Msg = ISNULL(@KeyPart,'') + 'Phase: ' + dbo.vfToString(@DetailPhase) + ', CostType: ' + dbo.vfToString(@DetailCostType) + ', POCO: ' + dbo.vfToString(@DetailPOCONum) + ' : ' + ' Purchase Order detail exists.'
  		--SET @rcode = 1
  		SET @TypeOfDetail = 'M'
  		GOTO vspexit
  		END
  	END

	
---- set to true
SET @ValidToDelete = 1 ----TRUE



	------------------------------------
	---- GET CHANGE ORDER INFORMATION --
	------------------------------------

--DECLARE @SendFlag	bYN,
--		@Ready		bYN,
--		@COType		varchar(20),
--		@CO			int,
--		@CONum		int,
	
	--SET @COType = ''
	--SET @CO = 0
	--SET @CONum = 0
	--SELECT	@COType = CASE WHEN SubCO IS NOT NULL THEN 'Subcontract' ELSE 'Purchase Order' END,
	--		@CO =     CASE WHEN SubCO IS NOT NULL THEN SubCO         ELSE POCONum          END,
	--		@CONum =  CASE WHEN SubCO IS NOT NULL THEN SubCOSeq      ELSE POCONumSeq       END
	--  FROM	dbo.PMOL WITH (NOLOCK)
	-- WHERE	KeyID = @PMOLKeyId


	---- GET FLAGS TO DETERMINE IF CO HAS BEEN APPROVED --
	--IF @COType = 'Subcontract' 
	--	BEGIN
	--		SELECT	@SendFlag = sl.SendFlag, @Ready = co.ReadyForAcctg
	--		  FROM	dbo.PMOL ol WITH (NOLOCK)
	--		  JOIN	dbo.PMSL sl WITH (NOLOCK) ON ol.PMCo=sl.PMCo AND ol.Project=sl.Project
	--					AND ol.Phase=sl.Phase AND ol.CostType=sl.CostType
	--					AND ol.Subcontract=sl.SL
	--					AND ol.SubCO=sl.SubCO AND ol.SubCOSeq=sl.Seq
	--		  JOIN	dbo.PMSubcontractCO co WITH (NOLOCK) ON ol.PMCo=co.PMCo AND ol.Project=co.Project
	--					AND ol.Subcontract=co.SL AND ol.SubCO=co.SubCO 
	--		 WHERE	ol.KeyID = @PMOLKeyId
	--		 			AND sl.SubCO = @CO
	--					AND sl.Seq = @CONum
	--	END
		
	--IF @COType = 'Purchase Order'
	--	BEGIN
	--		SELECT	@SendFlag = mf.SendFlag, @Ready = co.ReadyForAcctg
	--		  FROM	dbo.PMOL ol WITH (NOLOCK)
	--		  JOIN	dbo.PMMF mf WITH (NOLOCK) ON ol.PMCo=mf.PMCo AND ol.Project=mf.Project
	--					AND ol.Phase=mf.Phase AND ol.CostType=mf.CostType
	--					AND ol.PO=mf.PO 
	--					AND ol.POCONum=mf.POCONum AND ol.POCONumSeq=mf.Seq
	--		  JOIN	dbo.PMPOCO co WITH (NOLOCK) on mf.PMCo=co.PMCo AND mf.Project=co.Project
	--					AND mf.PO=co.PO AND mf.POCONum=co.POCONum
	--		 WHERE	ol.KeyID = @PMOLKeyId
	--		 			AND mf.POCONum = @CO
	--					AND mf.Seq = @CONum
	--	END


	---------------------------------
	---- CHANGE ORDER NOT APROVED? --
	---------------------------------
	--IF @SendFlag = 'N' OR @Ready = 'N' SET @ValidToDelete = 0




vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMPCODetailItemCOInfo] TO [public]
GO
