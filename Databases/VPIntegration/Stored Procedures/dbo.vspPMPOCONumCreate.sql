SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*********************************************/
CREATE proc [dbo].[vspPMPOCONumCreate]
/**********************************************
* Created By:	GF 06/21/2011 TK-06039
* Modified By:  GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
*					TL 12/01/2011 TK-10436 add parameter @ReadyForAccounting	
*				GF 02/07/2012 TK-11854 use correct status based on ReadyForAccounting Flag
*
*
* This SP will create a PMPOCO record using the parameters
* passed in. This SP will be called from multiple places:
* PCO Approve, Create PCO POCONum, and the PMMF triggers.
* 
* Pass in the PMMF Key ID which will be used to find any information
* required to get a default status and descripiton for the PMPOCONum
* record.
*		
*				
* INPUT PARAMETERS
* @PMMFKeyID		PMMF KeyID
*
* OUTPUT PARAMETER
* @POCONum			POCO Number created
* @msg - error message if error occurs
*		
* RETURN VALUE
*   0 - Success
*   1 - Failure
*****************************************************/
(@PMMFKeyID BIGINT = NULL, @ReadyForAccounting bYN = null,@POCONum SMALLINT = NULL OUTPUT, @msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON
   
DECLARE @rcode INT, @retcode INT,
		@PMCo bCompany, @Project bJob, @PCOType bDocType, @PCO bACO,
		@PCOItem bACOItem, @ACO bACO, @ACOItem bACOItem, @pomsg VARCHAR(60),
		@APCo bCompany, @Phase bPhase, @POCONumStatus VARCHAR(6),
		@BeginStatus VARCHAR(6), @Description VARCHAR(60),
		@PMMFSeq INT, @PhaseGroup bGroup, @PO varchar(30), @MatlPhaseDesc CHAR(1),
		----TK-11854
		@FinalStatus VARCHAR(6)

SET @rcode = 0
SET @POCONum = NULL

---- must have PMSL key ID
IF @PMMFKeyID IS NULL
	BEGIN
	SELECT @msg = 'Invalid PM Material Detail Record', @rcode = 1
	GOTO vspexit
	END
	
---- get PMMF information
SELECT  @PMCo = PMCo, @Project = Project, @PhaseGroup = PhaseGroup, @Phase = Phase,
		@PCOType = PCOType, @PCO = PCO, @PCOItem = PCOItem, @ACO = ACO, @ACOItem = ACOItem,
		@Description = MtlDescription, @PMMFSeq = Seq,
		@APCo = POCo, @PO = PO
FROM dbo.bPMMF
WHERE KeyID = @PMMFKeyID
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @msg = 'Invalid PM Material Detail Record', @rcode = 1
	GOTO vspexit
	END
	

---- get PM company info
SELECT @BeginStatus = BeginStatus, @MatlPhaseDesc = MatlPhaseDesc,
		----TK-11854
		@FinalStatus = FinalStatus
FROM dbo.bPMCO WHERE PMCo=@PMCo
IF @@rowcount = 0
	BEGIN
	SELECT @msg = 'Invalid PM Company.', @rcode = 1
	GOTO vspexit
	END


---- if missing description use the phase description if flag in PMCO is checked
IF ISNULL(@Description,'') = '' AND @MatlPhaseDesc = 'Y'
	BEGIN
	SELECT @Description = [Description]
	FROM dbo.bJCJP
	WHERE JCCo = @PMCo 
		AND	Job = @Project
		AND PhaseGroup = @PhaseGroup
		AND Phase = @Phase
	END


----TK-11854
---- get beginning status for POCONum from PMSC
SET @POCONumStatus = NULL
IF @ReadyForAccounting = 'N'
	BEGIN
	select Top 1 @POCONumStatus = Status
	FROM dbo.bPMSC WHERE DocCat = 'PURCHASECO' AND CodeType = 'B'
	---- if not begin status setup for 'PURCHASEPO' category
	---- use PM Company begin status
	IF @@rowcount = 0 SET @POCONumStatus = @BeginStatus
	END
ELSE
	BEGIN
	select Top 1 @POCONumStatus = Status
	FROM dbo.bPMSC WHERE DocCat = 'PURCHASECO' AND CodeType = 'F'
	---- if not begin status setup for 'PURCHASEPO' category
	---- use PM Company begin status
	IF @@rowcount = 0 SET @POCONumStatus = @FinalStatus
	END
	

---- get next POCO Number
SELECT @POCONum = isnull(max(POCONum) + 1, 1)
FROM dbo.vPMPOCO
WHERE POCo = @APCo
	AND PO=@PO 
IF ISNULL(@POCONum,0) = 0 SET @POCONum = 1


---- if SubCO exists in PMSubcontractCO something is wrong throw error
IF EXISTS(SELECT 1 FROM dbo.vPMPOCO WHERE POCo=@APCo AND PO=@PO AND POCONum=@POCONum)
	BEGIN
	SELECT @msg = 'Error occurred creating Purhcase Order CO header record.', @rcode = 1
	GOTO vspexit
	END


INSERT INTO dbo.vPMPOCO (PMCo, Project, POCo, PO, POCONum, Description, Status, Date,
			ReadyForAcctg, DateApproved)
VALUES (@PMCo, @Project, @APCo, @PO, @POCONum, @Description, @POCONumStatus, dbo.vfDateOnly(),
			IsNull(@ReadyForAccounting,'N'),
			----TK-11854
			CASE WHEN @ReadyForAccounting = 'Y' THEN dbo.vfDateOnly() ELSE NULL END)

---- success
SET @rcode = 0
SET @msg = NULL



vspexit:
	IF @rcode <> 0 SELECT @msg = isnull(@msg,'') 
	RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPMPOCONumCreate] TO [public]
GO
