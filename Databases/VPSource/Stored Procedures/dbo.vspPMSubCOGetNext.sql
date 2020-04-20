SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************
* Created By:	DAN SO 01/13/2012 - TK-11597
* Modified By:  
*
* This sp will get the next highest Subcontract Change Order.  It will
* look at SLCB, SLCD, and the PMSubcontractCO tables for the next SubCO.
*		
*				
* INPUT PARAMETERS
*	@SLCO	Subcontract Company
*	@SL		Subcontract		
*
* OUTPUT PARAMETER
*	@SubCO	Next Subcontract Change Order
*	@msg		Some sessage
*		
* RETURN VALUE
*   0 - Success
*   1 - Failure
*****************************************************/
CREATE  PROC [dbo].[vspPMSubCOGetNext]

(@SLCo bCompany = NULL, @SL VARCHAR(30) = NULL, 
 @SubCO SMALLINT = NULL OUTPUT, @msg VARCHAR(255) OUTPUT)

	AS
	SET NOCOUNT ON
   
	DECLARE @SLCB	SMALLINT, 
			@SLCD	SMALLINT, 
			@PM		SMALLINT,
			@rcode	TINYINT

	-------------------------------
	-- CHECK INCOMING PARAMETERS --
	-------------------------------
	IF @SLCo IS NULL
		BEGIN
			SET @msg = 'Missing SL Company'
			SET @rcode = 1
			GOTO vspexit
		END

	IF @SL IS NULL
		BEGIN
			SET @msg = 'Missing Subcontract'
			SET @rcode = 1
			GOTO vspexit
		END


	---------------------
	-- PRIME VARIABLES --
	---------------------	
	SET @SubCO = NULL
	SET @SLCB = NULL
	SET @SLCD = NULL
	SET @PM	= NULL
	SET @rcode = 0
	
	
	---------------------
	-- GET SUBCO VALUE --
	---------------------
	SELECT	@SLCB = ISNULL(MAX(cb.SLChangeOrder) + 1, 1),
			@SLCD = ISNULL(MAX(cd.SLChangeOrder) + 1, 1), 
			@PM = ISNULL(MAX(pm.SubCO) + 1, 1)
	  FROM	SLHDPM hd
 LEFT JOIN	SLCB cb ON cb.Co=hd.SLCo AND cb.SL=hd.SL
 LEFT JOIN	SLCD cd ON cd.SLCo=hd.SLCo AND cd.SL=hd.SL
 LEFT JOIN	PMSubcontractCO pm ON pm.SLCo=hd.SLCo AND pm.SL=hd.SL
     WHERE	hd.SLCo = @SLCo
	   AND	hd.SL = @SL 

	-- DEFAULT VALUE --
	SET @SubCO = @SLCB

	-- DETERMINE WHICH VALUE IS LARGER --
	If @SLCD > @PM
		BEGIN
			IF @SLCD > @SLCB SET @SubCO = @SLCD
		END
	ELSE
		BEGIN
			IF @PM > @SLCB SET @SubCO = @PM
		END


------------------
-- END PROCDURE --
------------------
vspexit:
	IF @rcode <> 0 SELECT @msg = ISNULL(@msg,'') 
	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMSubCOGetNext] TO [public]
GO
