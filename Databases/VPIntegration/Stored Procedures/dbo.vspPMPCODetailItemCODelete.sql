SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--CREATE PROC [dbo].[vspPMPCODetailItemCODelete]
CREATE proc [dbo].[vspPMPCODetailItemCODelete]
/***********************************************************
* CREATED BY:	DAN SO 04/26/2011
* MODIFIED BY:	
*
*
* USAGE:
*	Called from PMPCOS
*	Delete a change order related to a specific PCO Detail Item.
*
*
* INPUT PARAMETERS
*   @PCOKeyID		Key ID of PCO Detail record
*
* OUTPUT PARAMETERS
*   @msg			If error - error message
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
 (@PCOKeyID bigint, 
  @msg varchar(255) output)

	AS
	SET NOCOUNT ON

	DECLARE @COType		varchar(20),
			@CO			int,
			@CONum		int,
			@rcode		int


	---------------------
	-- PRIME VARIABLES --
	---------------------
	SET @COType = ''
	SET @CO = 0
	SET @CONum = 0
	SET @rcode = 0

	----------------------------------
	-- VALIDATE INCOMING PARAMETERS --
	----------------------------------
	IF @PCOKeyID IS NULL
		BEGIN
			SELECT @msg = 'Missing PCO KeyID!', @rcode = 1
			GOTO vspexit
		END


	------------------------------
	-- GET SPECIFIC INFORMATION --
	------------------------------
	SELECT	@COType = CASE WHEN SubCO IS NOT NULL THEN 'Subcontract' ELSE 'Purchase Order' END,
			@CO =     CASE WHEN SubCO IS NOT NULL THEN SubCO         ELSE POCONum          END,
			@CONum =  CASE WHEN SubCO IS NOT NULL THEN SubCOSeq      ELSE POCONumSeq       END
	  FROM	dbo.PMOL WITH (NOLOCK)
	 WHERE	KeyID = @PCOKeyID


	-------------------------------------
	-- DELETE THE RELATED CHANGE ORDER --
	-------------------------------------
	IF @COType = 'Subcontract' 
		BEGIN
			DELETE	sl
			  FROM	dbo.PMSL sl
			  JOIN	dbo.PMOL ol ON ol.PMCo=sl.PMCo AND ol.Project=sl.Project
						AND ol.Phase=sl.Phase AND ol.CostType=sl.CostType
						AND ol.Subcontract=sl.SL
						AND ol.SubCO=sl.SubCO AND ol.SubCOSeq=sl.Seq
			 WHERE	ol.KeyID = @PCOKeyID
						AND sl.SubCO = @CO
						AND sl.Seq = @CONum
		END
		
	IF @COType = 'Purchase Order'
		BEGIN
			DELETE	mf
			  FROM	dbo.PMMF mf WITH (NOLOCK)
			  JOIN	dbo.PMOL ol on ol.PMCo=mf.PMCo AND ol.Project=mf.Project
						AND ol.Phase=mf.Phase AND ol.CostType=mf.CostType
						AND ol.PO=mf.PO 
						AND ol.POCONum=mf.POCONum AND ol.POCONumSeq=mf.Seq
			 WHERE	ol.KeyID = @PCOKeyID
						AND mf.POCONum = @CO
						AND mf.Seq = @CONum
		END



	vspexit:
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPCODetailItemCODelete] TO [public]
GO
