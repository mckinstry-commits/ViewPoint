SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/******************************************/
CREATE proc [dbo].[vspPOINMTUpdateOnOrder]
/*************************************
* CREATED BY:	GF 08/10/2011 - TK-07438 TK-07439 TK-07440
* Modified By:	GF 11/22/2011 TK-10203 change um conversion to unit cost
 *				GF 01/05/2011 TK-11551 #145427 #145507 missed a change to bUnitCost
*
* USAGE:
* Updates IN Location Material (INMT) on order quantity for PO Item Distribution lines.
* Gets the HQ UM Conversion or the IN UM Conversion factor to use when calculating
* the On Order Units to update for a PO Item Distribution Line Type 2 - Inventory.
*
* Currently used in the POItemLine insert, update, and delete triggers.
*
* INPUT PARAMETERS:
* Material Group
* Material
* UM
* PostToCo
* Location
* Units
*
*
* Success returns:
*
*
* Error returns:
*	1 and error message
**************************************/
(@MatlGroup	INT	= NULL, @Material bMatl	= NULL, @UM	bUM	= NULL,
 @PostToCo	INT	= NULL, @Location bLoc	= NULL, @CurUnits bUnits = 0,
 @OldNew CHAR(3) = 'NEW', @ErrMsg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

----TK-11551
DECLARE @rcode INT, @StdUM bUM, @HQMatl CHAR(1), @UMConv bUnitCost, @INUMConv bUnitCost

---- initialize variables
SET @rcode = 0
SET @HQMatl = 'N'
SET @StdUM  = NULL
SET @UMConv = 0
SET @INUMConv = 0

---- check for Material in HQ
SELECT @StdUM = StdUM
FROM dbo.bHQMT
WHERE MatlGroup=@MatlGroup
	AND Material=@Material
IF @@ROWCOUNT = 1
	BEGIN
	---- setup in HQ Material
	SET @HQMatl = 'Y'
	---- if UM is Standard conversion = 1
	if @StdUM = @UM SET @UMConv = 1
	END

---- if HQ Material, validate UM and get unit of measure conversion
IF @HQMatl = 'Y' and @UM <> @StdUM
	BEGIN
	SELECT @UMConv = Conversion
	FROM dbo.bHQMU
	WHERE MatlGroup = @MatlGroup 
		AND Material = @Material
		AND UM = @UM
	---- if no material um conversion record found set to 1
	if @@rowcount = 0 SET @UMConv = 1
	END

---- get the UM Conversion from INMU if UM exists
select @INUMConv=Conversion 
from dbo.bINMU
WHERE INCo = @PostToCo
	AND Material	= @Material
	and MatlGroup	= @MatlGroup
	AND Loc			= @Location
	AND UM			= @UM
---- if none found use std UM conversion
IF @@rowcount = 0 SET @INUMConv = @UMConv

---- if no conversion rate set to 1
IF @INUMConv = 0 SET @INUMConv = 1

---- update OnOrder quantity in Location Material
UPDATE dbo.bINMT
		SET OnOrder = CASE @OldNew WHEN 'NEW'
						THEN OnOrder + (@CurUnits * @INUMConv)
						ELSE OnOrder + (-1 * (@CurUnits * @INUMConv))
						END,
						AuditYN = 'N'
WHERE INCo = @PostToCo
	AND Loc = @Location
	AND MatlGroup = @MatlGroup
	AND Material  = @Material
IF @@ROWCOUNT <> 0
	BEGIN
	---- reset audit flag
	UPDATE dbo.bINMT SET AuditYN = 'Y'
	WHERE INCo = @PostToCo
		AND Loc = @Location
		AND MatlGroup = @MatlGroup
		AND Material  = @Material
	END
ELSE
	BEGIN
    SET @ErrMsg = 'Error occurred updating On Order Quantity for the IN Location Material.'
    SET @rcode = 1
    END


vspexit:
	Return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspPOINMTUpdateOnOrder] TO [public]
GO
