SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE PROC [dbo].[vspPMSubcontractCOApproveSCOs]
CREATE  PROC [dbo].[vspPMSubcontractCOApproveSCOs]
/***********************************************************
* CREATED BY:	DAN SO	04/21/2011
* MODIFIED BY:	GF 05/13/2011 TK-05225 D-01958 no date approved being set
*               AW 10/11/2012 147206 / D-06043 don't allow them to unapprove if any items interfaced
*				
* USAGE:
* Used in PM Subcontract Change Order to Approve/Unapprove SCOs.
*	-- Copied from vspPMPOCOApprovePOCOs --
*
* INPUT PARAMETERS
*	@SCOKeyID	PM Subcontract Change Order KeyID
*	@ApproveCO	Approve the Change Order (Y,N)
*
* OUTPUT PARAMETERS
*	@SCOCount	Number SCO's SET TO 'Y'
*   @msg		Errors if found.
*
* RETURN VALUE
*   0			Success
*   1			Failure
*****************************************************/ 

(@SCOKeyID bigint, @ApproveCOYN char(1),
 @SCOCount smallint output, @msg varchar(255) output)


AS
SET NOCOUNT ON

	DECLARE	@rcode	INT
	---- TK-05225
	DECLARE @BeginStatus VARCHAR(6), @FinalStatus VARCHAR(6)
	

	---------------------
	-- PRIME VARIABLES --
	---------------------
	SET @rcode = 0
	SET @SCOCount = 0
	SET @BeginStatus = NULL
	SET @FinalStatus = NULL
	
	----------------------------
	-- CHECK INPUT PARAMETERS --
	----------------------------
	IF @SCOKeyID IS NULL
	BEGIN
		SET @msg = 'Missing Subcontract Change Order KeyID.'
		SET @rcode = 1
		GOTO vspexit
	END
	
	----------------------------
	-- CHECK IF ANY ITEMS HAVE BEEN INTERFACED
	----------------------------
	IF @ApproveCOYN='N' and exists(select 1  FROM	dbo.PMSubcontractCO co
	  JOIN	dbo.PMSL sl ON sl.PMCo = co.PMCo AND sl.Project = co.Project 
	   AND	sl.SLCo = co.SLCo AND sl.SL = co.SL  AND sl.SubCO = co.SubCO
	 WHERE	co.KeyID = @SCOKeyID AND sl.InterfaceDate IS NOT NULL)
	 BEGIN
	   	SET @msg = 'SL Change Order Items have been interfaced.  Unable to unapprove.'
		SET @rcode = 1
		GOTO vspexit
	 END
	

	---------------------------------
	-- GET DEFAULT STATUS TK-05225 --
	---------------------------------
	---- begin
	select Top 1 @BeginStatus = Status
	FROM dbo.PMSC WHERE DocCat = 'SUBCO' AND CodeType = 'B'
	IF @@ROWCOUNT = 0
		BEGIN
		SELECT @BeginStatus = c.BeginStatus
		FROM dbo.PMSubcontractCO s
		INNER JOIN dbo.PMCO c ON c.PMCo=s.PMCo
		WHERE s.KeyID = @SCOKeyID
		END
	
	---- final
	select Top 1 @FinalStatus = Status
	FROM dbo.PMSC WHERE DocCat = 'SUBCO' AND CodeType = 'F'
	IF @@ROWCOUNT = 0
		BEGIN
		SELECT @FinalStatus = c.FinalStatus
		FROM dbo.PMSubcontractCO s
		INNER JOIN dbo.PMCO c ON c.PMCo=s.PMCo
		WHERE s.KeyID = @SCOKeyID
		END

	---------------------------
	-- UPDATE DETAIL RECORDS --
	---------------------------
	UPDATE	sl
	   SET	SendFlag = @ApproveCOYN
	  FROM	dbo.PMSubcontractCO co
	  JOIN	dbo.PMSL sl ON sl.PMCo = co.PMCo AND sl.Project = co.Project 
	   AND	sl.SLCo = co.SLCo AND sl.SL = co.SL  AND sl.SubCO = co.SubCO
	 WHERE	co.KeyID = @SCOKeyID AND sl.InterfaceDate IS NULL
	   
	SET @SCOCount = @@ROWCOUNT

		
	--------------------------
	-- UPDATE HEADER RECORD --
	--------------------------	
	-- SET HEADER FLAG AND STATUS -- TK-05225
	UPDATE	dbo.PMSubcontractCO
	   SET	ReadyForAcctg = @ApproveCOYN,
			
			ApprovedBy = CASE WHEN @ApproveCOYN = 'Y'
						THEN SUSER_NAME()
						ELSE NULL
						END,
			Status	   = CASE WHEN @ApproveCOYN = 'Y'
						THEN @FinalStatus
						ELSE NULL ----@BeginStatus
						END,
			DateApproved = CASE WHEN @ApproveCOYN = 'Y'
								THEN dbo.vfDateOnly()
								ELSE NULL
								END
	 WHERE	KeyID = @SCOKeyID

	
	vspexit:
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMSubcontractCOApproveSCOs] TO [public]
GO
