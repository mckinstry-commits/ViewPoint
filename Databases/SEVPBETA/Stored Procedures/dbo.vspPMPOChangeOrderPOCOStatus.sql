SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE  PROC [dbo].[vspPMPOChangeOrderPOCOStatus]
CREATE  PROC [dbo].[vspPMPOChangeOrderPOCOStatus]
/***********************************************************
* CREATED BY:	DAN SO	04/19/2011
* MODIFIED BY:	
*				
* USAGE:
* Used in PM PO Change Order to return the overall status of POCOs.
*
* INPUT PARAMETERS
*	@POCOKeyID
*
* OUTPUT PARAMETERS
*	@Approved	All Items = 'Y'?
*   @msg		Status if no errors
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 

(@POCOKeyID BIGINT = NULL, 
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
	IF @POCOKeyID IS NULL
	BEGIN
		----SELECT @msg = 'Missing PO Change Order KeyID.', @rcode = 1
		GOTO vspexit
	END
	

	-----------------------------------
	-- DETERMINE CHANGE ORDER STATUS --
	-----------------------------------
	-- READY FOR ACCOUNTING? --
	SELECT	@ReadyFlag = ReadyForAcctg
	  FROM	dbo.PMPOCO WITH (NOLOCK)
	 WHERE	KeyID = @POCOKeyID

	-- GET RECORD COUNTS --
    SELECT	@TotalRecs = COUNT(*), @AppRecs = COUNT(CASE WHEN mf.SendFlag = 'Y' THEN 1 END)
	  FROM	dbo.PMPOCO co WITH (NOLOCK)
	  JOIN	dbo.PMMF mf WITH (NOLOCK) ON mf.PMCo = co.PMCo AND mf.Project = co.Project 
	   AND	mf.POCo = co.POCo AND mf.PO = co.PO  AND mf.POCONum = co.POCONum
     WHERE	co.KeyID = @POCOKeyID
	   
	-- CHANGE ORDER APPROVED? --
	IF (@TotalRecs = @AppRecs) AND (@ReadyFlag = 'Y')
		BEGIN
			SET @msg = 'Approved'
			SET @Approved = 'Y'
		END	


	
	vspexit:
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPOChangeOrderPOCOStatus] TO [public]
GO
