SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/* =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/21/11
-- Description:	SM Part PO Item Line validation
-- Modification:   TL 03/30/2012 TK-13604 Added Code to Return JC Cost Type
--				   NH 07/05/2012 TK-16162 SM phase and PO Item Line phase must match
=============================================*/
CREATE PROCEDURE [dbo].[vspSMWorkCompletedPOItemLineVal]
	(@POCo bCompany, @PONumber varchar(30), @POItem bItem, @POItemLine int,
		@SMCo bCompany, @WorkOrder int, @Scope int,
		@MaterialGroup bGroup = NULL OUTPUT, @Material bMatl = NULL OUTPUT, @UM bUM = NULL OUTPUT,
		@Quantity bUnits = NULL OUTPUT, @ActualCostPerUnit bUnitCost = NULL OUTPUT,
		@JCCostType bJCCType=NULL OUTPUT, @msg varchar(255) = NULL OUTPUT)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @POItemLineScope int, @SMPhase bPhase, @POItemLinePhase bPhase

	SELECT @MaterialGroup = MatlGroup, @Material = Material, @UM = UM
	FROM dbo.POIT
	WHERE POCo = @POCo AND PO = @PONumber AND POItem = @POItem
	
	SELECT 
		@ActualCostPerUnit = ((InvCost + ISNULL(InvMiscAmt,0) + InvTax) / CASE InvUnits WHEN 0 THEN 1 ELSE InvUnits END),
		@Quantity = CASE WHEN BOUnits < 0 THEN 0 ELSE BOUnits END, @POItemLineScope = SMScope,
		@JCCostType=SMJCCostType, @POItemLinePhase=SMPhase
	FROM dbo.POItemLine
	WHERE POCo = @POCo AND PO = @PONumber AND POItem = @POItem AND POItemLine = @POItemLine AND ItemType = 6 AND SMCo = @SMCo AND SMWorkOrder = @WorkOrder
	
	-- TK-16162 query for SMPhase
	select @SMPhase = Phase
	from dbo.SMWorkOrderScope
	where SMCo = @SMCo and WorkOrder = @WorkOrder and Scope = @Scope
	
	IF (@@rowcount = 0)
	BEGIN
		SET @msg = 'Invalid PO Item Line for this work order.'
		RETURN 1
	END
	
	IF dbo.vfIsEqual(@Scope, @POItemLineScope) = 0
	BEGIN
		SET @msg = 'PO Item Line scope must match work order scope.'
		RETURN 1
	END
	
	-- TK-16162 phases must match
	IF dbo.vfIsEqual(@SMPhase, @POItemLinePhase) = 0
	BEGIN
		SET @msg = 'PO Item Line phase must match work order scope phase.'
		RETURN 1
	END

	RETURN 0
END






GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedPOItemLineVal] TO [public]
GO
