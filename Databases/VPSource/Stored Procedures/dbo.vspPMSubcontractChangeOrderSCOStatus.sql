SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE  PROC [dbo].[vspPMSubcontractChangeOrderSCOStatus]
CREATE  PROC [dbo].[vspPMSubcontractChangeOrderSCOStatus]
/***********************************************************
* CREATED BY:	DAN SO	04/21/2011
* MODIFIED BY:	
*				
* USAGE:
* Used in PM Subcontract Change Order to return the overall status of SCOs.
*	-- Copied from vspPMPOChangeOrderPOCOStatus --
*
* INPUT PARAMETERS
*	@SCOKeyID
*
* OUTPUT PARAMETERS
*	@Approved	All Items = 'Y'?
*   @msg		Status if no errors
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 

(@SCOKeyID bigint, 
 @Approved char(1) output, @msg varchar(255) output)


AS
SET NOCOUNT ON

	DECLARE @ReadyFlag	bYN,
			@TotalRecs	int,
			@AppRecs	int,
			@rcode		int

	---------------------
	-- PRIME VARIABLES --
	---------------------
	SET @rcode = 0
	SET @TotalRecs = 0
	SET @AppRecs = 0
	SET @Approved = 'N'
	SET @msg = 'Unapproved'


	----------------------------
	-- CHECK INPUT PARAMETERS --
	----------------------------
	IF @SCOKeyID IS NULL
	BEGIN
		SELECT @msg = 'Missing Subcontract Change Order KeyID.', @rcode = 1
		GOTO vspexit
	END
		
	
	-----------------------------------
	-- DETERMINE CHANGE ORDER STATUS --
	-----------------------------------
	-- READY FOR ACCOUNTING? --
	SELECT	@ReadyFlag = ReadyForAcctg
	  FROM	dbo.PMSubcontractCO WITH (NOLOCK)
	 WHERE	KeyID = @SCOKeyID
	
	-- GET RECORD COUNTS --
    SELECT	@TotalRecs = COUNT(*), @AppRecs = COUNT(CASE WHEN SendFlag = 'Y' THEN 1 END)
	  FROM	dbo.PMSubcontractCO co WITH (NOLOCK)
	  JOIN	dbo.PMSL sl WITH (NOLOCK) ON sl.PMCo = co.PMCo AND sl.Project = co.Project 
	   AND	sl.SLCo = co.SLCo AND sl.SL = co.SL  AND sl.SubCO = co.SubCO
     WHERE	co.KeyID = @SCOKeyID
       AND	sl.InterfaceDate IS NULL
	   
	-- CHANGE ORDER APPROVED? --
	IF (@TotalRecs = @AppRecs) AND (@ReadyFlag = 'Y')
		BEGIN
			SET @msg = 'Approved'
			SET @Approved = 'Y'
		END	


	
	vspexit:
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMSubcontractChangeOrderSCOStatus] TO [public]
GO
