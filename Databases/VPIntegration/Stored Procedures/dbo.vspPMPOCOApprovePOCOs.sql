SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE PROC [dbo].[vspPMPOCOApprovePOCOs]
CREATE  PROC [dbo].[vspPMPOCOApprovePOCOs]
/***********************************************************
* CREATED BY:	DAN SO	04/18/2011
* MODIFIED BY:	GF 05/13/2011 TK-05225	TK-06536
*               AW 10/11/2012 147206 / D-06043 don't allow them to unapprove if any items interfaced
*				
* USAGE:
* Used in PM PO Change Order to Approve/Unapprove POCOs.
*
* INPUT PARAMETERS
*	@POCOKeyID	PM PO Change Order KeyID
*	@ApproveCO	Approve the Change Order (Y,N)
*
* OUTPUT PARAMETERS
*	@POCOCount	Number PO's SET TO 'Y'
*   @msg		Errors if found.
*
* RETURN VALUE
*   0			Success
*   1			Failure
*****************************************************/ 

(@POCOKeyID bigint, @ApproveCOYN char(1),
 @POCOCount smallint output, @msg varchar(255) output)


AS
SET NOCOUNT ON

	DECLARE @rcode	INT
	---- TK-05225
	DECLARE @BeginStatus VARCHAR(6), @FinalStatus VARCHAR(6)

	---------------------
	-- PRIME VARIABLES --
	---------------------
	SET @rcode = 0
	SET @POCOCount = 0
	SET @BeginStatus = NULL
	SET @FinalStatus = NULL

	----------------------------
	-- CHECK INPUT PARAMETERS --
	----------------------------
	IF @POCOKeyID IS NULL
	BEGIN
		SET @msg = 'Missing PO Change Order KeyID.'
		SET @rcode = 1
		GOTO vspexit
	END
	
		----------------------------
	-- CHECK IF ANY ITEMS HAVE BEEN INTERFACED
	----------------------------
	IF @ApproveCOYN='N' and exists(select 1 FROM dbo.PMPOCO co
	  JOIN	dbo.PMMF mf ON mf.PMCo = co.PMCo AND mf.Project = co.Project 
	   AND	mf.POCo = co.POCo AND mf.PO = co.PO  AND mf.POCONum = co.POCONum
	 WHERE	co.KeyID = @POCOKeyID AND mf.InterfaceDate IS NOT NULL)
	 BEGIN
	   	SET @msg = 'PO Change Order Items have been interfaced.  Unable to unapprove.'
		SET @rcode = 1
		GOTO vspexit
	 END
	
	---------------------------------
	-- GET DEFAULT STATUS TK-05225 --
	---------------------------------
	---- begin
	select Top 1 @BeginStatus = Status
	FROM dbo.PMSC WHERE DocCat = 'PURCHASECO' AND CodeType = 'B'
	IF @@ROWCOUNT = 0
		BEGIN
		SELECT @BeginStatus = c.BeginStatus
		FROM dbo.PMPOCO s
		INNER JOIN dbo.PMCO c ON c.PMCo=s.PMCo
		WHERE s.KeyID = @POCOKeyID
		END
	
	---- final
	select Top 1 @FinalStatus = Status
	FROM dbo.PMSC WHERE DocCat = 'PURCHASECO' AND CodeType = 'F'
	IF @@ROWCOUNT = 0
		BEGIN
		SELECT @FinalStatus = c.FinalStatus
		FROM dbo.PMPOCO s
		INNER JOIN dbo.PMCO c ON c.PMCo=s.PMCo
		WHERE s.KeyID = @POCOKeyID
		END

	---------------------------
	-- UPDATE DETAIL RECORDS --
	---------------------------
	UPDATE	mf
	   SET	SendFlag = @ApproveCOYN
	  FROM	dbo.PMPOCO co
	  JOIN	dbo.PMMF mf ON mf.PMCo = co.PMCo AND mf.Project = co.Project 
	   AND	mf.POCo = co.POCo AND mf.PO = co.PO  AND mf.POCONum = co.POCONum
	 WHERE	co.KeyID = @POCOKeyID AND mf.InterfaceDate IS NULL
	   
	SET @POCOCount = @@ROWCOUNT


	--------------------------
	-- UPDATE HEADER RECORD --
	--------------------------	
	-- SET HEADER FLAG and status TK-05225 --
	UPDATE	dbo.PMPOCO
	   SET	ReadyForAcctg = @ApproveCOYN, 
			ReadyBy	= CASE WHEN @ApproveCOYN = 'Y' 
						THEN SUSER_NAME()
						ELSE NULL
						END,
			Status	= CASE WHEN @ApproveCOYN = 'Y'
						THEN @FinalStatus
						ELSE NULL ----@BeginStatus
						END,
			DateApproved = CASE WHEN @ApproveCOYN = 'Y'
								THEN dbo.vfDateOnly()
								ELSE NULL
								END
	 WHERE	KeyID = @POCOKeyID


	
	vspexit:
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPOCOApprovePOCOs] TO [public]
GO
