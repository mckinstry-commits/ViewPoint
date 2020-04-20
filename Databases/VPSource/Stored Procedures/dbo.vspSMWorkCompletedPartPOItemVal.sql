SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* =============================================
-- Author:		Jeremiah Barkley
-- Create date: 11/23/10
-- Modified:  Mark H 12/14/10 - PO Item must be flagged for receiving.
--			  Mark H 04/05/11 - Returning Actual Cost Per Unit
--            Lane G 04/21/11 - Added scope validation to compare the PO item scope vs the work order scope.
--            Eric V 05/16/11 - Added @OtherPOPartLinesExist parameter.
--				GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
-- Description:	SM Part PO Item validation
=============================================*/
CREATE PROCEDURE [dbo].[vspSMWorkCompletedPartPOItemVal]
	@POCo AS bCompany,
	@PONumber AS varchar(30),
	@POItem AS bItem,
	@SMCo AS bCompany,
	@WorkOrder AS int,
	@Scope AS int,
	@DefaultPOItemLine int = NULL OUTPUT,
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @rowcount int

	SELECT 
		@msg = [Description]
	FROM dbo.POIT 
	WHERE POCo = @POCo AND PO = @PONumber AND POItem = @POItem
				
	IF (@@ROWCOUNT = 0)
	BEGIN
		SET @msg = 'Invalid PO Item.'
		RETURN 1
	END
	
	SELECT @DefaultPOItemLine = POItemLine
	FROM dbo.POItemLine 
	WHERE POCo = @POCo AND PO = @PONumber AND POItem = @POItem AND ItemType = 6 AND SMCo = @SMCo AND SMWorkOrder = @WorkOrder AND SMScope = @Scope 
	
	SET @rowcount = @@rowcount
	
	IF @rowcount = 0
	BEGIN
		SET @msg = 'No PO Item Lines are valid for the work order''s scope.'
		RETURN 1
	END
	ELSE IF @rowcount <> 1
	BEGIN
		SET @DefaultPOItemLine = NULL
	END
	
	RETURN 0
END





GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedPartPOItemVal] TO [public]
GO
