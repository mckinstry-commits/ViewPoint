SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[vspPOItemLineUnique]
/***********************************************************
* CREATED BY:	DAN SO 08/09/2011	TK-07411 PO Item Distribution Lines 
* MODIFIED BY:
*
* USED BY:
* Used in PO Item Distribution to make sure the newly entered line is unique.
*
*
* USAGE:
* 
*
* INPUT PARAMETERS
* @POITKeyID		Item Line KeyID
* @LineJCCo			Line JC Company
* @LineJob			Line Job
* @LinePhase		Line Phase
* @LineJCCT			Line JC Cost Type
* @LineINCo			Line IN Company
* @LineINLoc		Line IN Location
* @LineEMCo			Line EM Company
* @LineEquip		Line EM Equipment
* @LineCompType		Line EM Comp Type 
* @LineComponent	Line EM Component
* @LineEMCostCode	Line EM Cost Code
* @LineEMCT			Line EM Cost Type
* @LineEMWO			Line EM Work Order
* @LineEMWOItem		Line EM Work Order Item
* @LineSMCo			Line SM Company
* @LineSMWO			Line SM Work Order
* @LineSMScope		Line SM Scope
* 
* 
* OUTPUT PARAMETERS
* @LineUnique		'Return 'Y' if the Distribution Line is Unique, else 'N'
* @msg      
*	
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/ 
(@POITKeyID BIGINT,
@LineJCCo bCompany = NULL, @LineJob bJob = NULL, @LinePhase bPhase = NULL, @LineJCCT bJCCType = NULL,
@LineINCo bCompany = NULL, @LineINLoc bLoc = NULL,
@LineEMCo bCompany = NULL, @LineEquip bEquip = NULL, @LineCompType VARCHAR(10) = NULL, 
@LineComponent bEquip = NULL, @LineEMCostCode bCostCode = NULL, @LineEMCT bEMCType = NULL,
@LineEMWO bWO = NULL, @LineEMWOItem bItem = NULL,
@LineSMCo bCompany = NULL, @LineSMWO INT = NULL, @LineSMScope INT = NULL,
@LineUnique CHAR(1) = 'N' OUTPUT, @Msg VARCHAR(255) OUTPUT)

AS
SET NOCOUNT ON

	DECLARE @rcode INT
	  		
	--------------------------
	-- CHECK INPUT PARAMTER --
	--------------------------
	IF @POITKeyID IS NULL
		BEGIN
			SET @Msg = 'Missing Item KeyID'
			SET @rcode = 1
			GOTO vspexit
		END
		
	---------------------
	-- PRIME VARIABLES --
	---------------------
	SET @rcode = 0
	SET @LineUnique = 'N'

	----------------
	-- CHECK LINE --
	----------------
	IF NOT EXISTS
		(SELECT 1
		   FROM dbo.POItemLine
		  WHERE POITKeyID = @POITKeyID
		    AND (JCCo = @LineJCCo			OR JCCo IS NULL)
		    AND (Job = @LineJob				OR Job IS NULL)
		    AND (Phase = @LinePhase			OR Phase IS NULL)
		    AND (JCCType = @LineJCCT		OR JCCType IS NULL)
		    AND (INCo = @LineINCo			OR INCo IS NULL)
		    AND (Loc = @LineINLoc			OR Loc IS NULL)
		    AND (EMCo = @LineEMCo			OR EMCo IS NULL)
		    AND (Equip = @LineEquip			OR Equip IS NULL)
		    AND (CompType = @LineCompType	OR CompType IS NULL)
		    AND (Component = @LineComponent OR Component IS NULL)
		    AND (CostCode = @LineEMCostCode OR CostCode IS NULL)
		    AND (EMCType = @LineEMCT		OR EMCType IS NULL)
		    AND (WO = @LineEMWO				OR WO IS NULL)
		    AND (WOItem = @LineEMWOItem		OR WOItem IS NULL)
		    AND (SMCo = @LineSMCo			OR SMCo IS NULL)
		    AND (SMWorkOrder = @LineSMWO	OR SMWorkOrder IS NULL)
		    AND (SMScope = @LineSMScope		OR SMScope IS NULL))

		BEGIN
			SET @LineUnique = 'Y'
		END
		

vspexit:	
	return @rcode






GO
GRANT EXECUTE ON  [dbo].[vspPOItemLineUnique] TO [public]
GO
