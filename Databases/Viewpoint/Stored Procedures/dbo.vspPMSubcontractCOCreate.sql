SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*********************************************/
CREATE PROC [dbo].[vspPMSubcontractCOCreate]
/**********************************************
* Created By:	GF 06/16/2011 TK-05799 TK-06039
* Modified By:  GF 10/05/2011 TK-08876 use company option for one subco per aco
*				TL 12/01/2011 TK-10436 add parameter @ReadyForAccounting
*				DAN SO 01/13/20120 - TK-11597 - get next SubCO - removed PMSubcontrctCO SELECT statement
*				GF 02/07/2012 TK-11854 use correct status based on ReadyForAccounting Flag
*				DAN SO 03/13/2013 - TK-13139 - Added @CreateSingleChangeOrder and check for adding to same CO
*											 - @CreateSingleChangeOrder takes precedence over @UseApprSubCo
*
*
* This SP will create a PMSubcontractCO record using the parameters
* passed in. This SP will be called from multiple places:
* PCO Approve, Create PCO SubCO, and the PMSL triggers.
* 
* Pass in the PMSL Key ID which will be used to find any information
* required to get a default status and descripiton for the PMSubcontractCO
* record.
*		
*				
* INPUT PARAMETERS
* @PMSLKeyID		PMSL KeyID
*
* OUTPUT PARAMETER
* @SubCO			Subcontract CO created
* @msg - error message if error occurs
*		
* RETURN VALUE
*   0 - Success
*   1 - Failure
*****************************************************/
(@PMSLKeyID BIGINT = NULL, @ReadyForAccounting bYN = null,
 -- TK-13139 --
 @CreateSingleChangeOrder bYN = NULL,
 @SubCO SMALLINT = NULL OUTPUT, @msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON
   
DECLARE @rcode INT, @retcode INT,
		@PMCo bCompany, @Project bJob, @PCOType bDocType, @PCO bACO,
		@PCOItem bACOItem, @ACO bACO, @ACOItem bACOItem, @slmsg VARCHAR(60),
		@APCo bCompany, @Phase bPhase, @SubCOStatus VARCHAR(6),
		@BeginStatus VARCHAR(6), @Description VARCHAR(60),
		@PMSLSeq INT, @PhaseGroup bGroup, @SL VARCHAR(30),
		----TK-08876
		@UseApprSubCo CHAR(1), @ACOSubCO SMALLINT, @Vendor bVendor,
		----TK-11854
		@FinalStatus VARCHAR(6)

SET @rcode = 0
SET @SubCO = NULL

---- must have PMSL key ID
IF @PMSLKeyID IS NULL
	BEGIN
	SELECT @msg = 'Invalid PM Subcontract Detail Record', @rcode = 1
	GOTO vspexit
	END
	
---- get PMSL information
SELECT  @PMCo = PMCo, @Project = Project, @PhaseGroup = PhaseGroup, @Phase = Phase,
		@PCOType = PCOType, @PCO = PCO, @PCOItem = PCOItem, @ACO = ACO, @ACOItem = ACOItem,
		@Description = SLItemDescription, @PMSLSeq = Seq,
		@APCo = SLCo, @SL = SL,
		----TK-08876
		@Vendor = Vendor	
FROM dbo.bPMSL
WHERE KeyID = @PMSLKeyID
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @msg = 'Invalid PM Subcontract Detail Record', @rcode = 1
	GOTO vspexit
	END
	
---- get PM company info
SELECT  @BeginStatus = BeginStatus,
		----TK-08876
		@UseApprSubCo = UseApprSubCo,
		----TK-11854
		@FinalStatus = FinalStatus
FROM dbo.bPMCO WHERE PMCo=@PMCo
IF @@rowcount = 0
	BEGIN
	SELECT @msg = 'Invalid PM Company.', @rcode = 1
	GOTO vspexit
	END


---- TK-08876 look for an existing subco for same SL and vendor
---- when the option to use only one subco for an ACO is in use
SET @ACOSubCO = NULL
-- TK-13139 --
IF @CreateSingleChangeOrder = 'Y' --@UseApprSubCo = 'Y'
	BEGIN
	SELECT @ACOSubCO = ISNULL(MIN(SubCO),0)
	FROM dbo.bPMSL
	WHERE PMCo=@PMCo
		AND Project=@Project
		AND SL=@SL
		AND Vendor=@Vendor
		AND ACO=@ACO
		AND Seq<>@PMSLSeq
	if ISNULL(@ACOSubCO,0) = 0 SET @ACOSubCO = NULL
	END

---- get SLItem description
IF ISNULL(@Description,'') = ''
	BEGIN
   	EXEC @retcode = dbo.bspPMSLItemDescDefault @PMCo, @Project, @PhaseGroup, @Phase, @PCOType, @PCO,
   					@PCOItem, @ACO, @ACOItem, @PMSLSeq, @slmsg OUTPUT
   	IF @retcode <> 0
   	    BEGIN
   	    SET @Description = NULL
   	    END
   	ELSE
   	    BEGIN
   	    SET @Description = @slmsg
   	    END
   	END


----TK-11854
---- get beginning or final status for SubCO from PMSC
SET @SubCOStatus = NULL
IF @ReadyForAccounting = 'N'
	BEGIN
	select Top 1 @SubCOStatus = Status
	FROM dbo.bPMSC WHERE DocCat = 'SUBCO' AND CodeType = 'B'
	---- if not begin status setup for 'SUBCO' category
	---- use PM Company begin status
	IF @@rowcount = 0 SET @SubCOStatus = @BeginStatus
	END
ELSE
	BEGIN
	select Top 1 @SubCOStatus = Status
	FROM dbo.bPMSC WHERE DocCat = 'SUBCO' AND CodeType = 'F'
	---- if not begin status setup for 'SUBCO' category
	---- use PM Company begin status
	IF @@rowcount = 0 SET @SubCOStatus = @FinalStatus
	END


-- GET NEXT SUBCO -- TK-11597
EXEC @retcode = dbo.vspPMSubCOGetNext @APCo, @SL, @SubCO OUTPUT, @msg OUTPUT
IF @retcode <> 0
    BEGIN
    	SET @rcode = 1
		GOTO vspexit
END
	
IF ISNULL(@SubCO,0) = 0 SET @SubCO = 1


---- TK-08876 check if we have are using one subco per aco option and we have a subco
---- TK-13139 --
IF @CreateSingleChangeOrder = 'Y' AND ISNULL(@ACOSubCO,0) <> 0 --@UseApprSubCo = 'Y'
	BEGIN
	SET @SubCO = @ACOSubCO
	END

---- if the SubCO does not exists in PMSubcontractCO then add
IF NOT EXISTS(SELECT 1 FROM dbo.vPMSubcontractCO WHERE SLCo=@APCo AND SL=@SL AND SubCO=@SubCO)
	BEGIN
	---- insert row for SubCO when not exists
	INSERT INTO dbo.vPMSubcontractCO (PMCo, Project, SLCo, SL, SubCO, Description, Status, Date,
				ReadyForAcctg, DateApproved)
	VALUES (@PMCo, @Project, @APCo, @SL, @SubCO, @Description, @SubCOStatus, dbo.vfDateOnly(),
			IsNull(@ReadyForAccounting,'N'),
			----TK-11854
			CASE WHEN @ReadyForAccounting = 'Y' THEN dbo.vfDateOnly() ELSE NULL END)
	--SELECT @msg = 'Error occurred creating Subcontract CO header record.', @rcode = 1
	--GOTO vspexit
	END


---- success
SET @rcode = 0
SET @msg = NULL



vspexit:
	IF @rcode <> 0 SELECT @msg = isnull(@msg,'') 
	RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPMSubcontractCOCreate] TO [public]
GO
