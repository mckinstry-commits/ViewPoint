SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/* =============================================
-- Author:		Jeremiah Barkley
-- Create date: 11/23/10
-- Modified:	Mark H 12/14/10 - Added check for Status.  Must be 0-Open 
--				JB 3/30/11 - Modified validation to validate against POs in 
--					SMPurchaseOrderList.
--				GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
--
-- Description:	SM Part PO Number validation
=============================================*/

CREATE PROCEDURE [dbo].[vspSMWorkCompletedPartPONumberVal]
	@SMCo AS bCompany,
	@WorkOrder AS int,
	@POCo AS bCompany,
	@PONumber AS varchar(30),
	@POCoOut AS bCompany OUTPUT,
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @Status int, @NumRows int
	
	IF (@POCo IS NULL)
	BEGIN
		-- Validate - however, POCo will not be provided so it may need to be determined
		SELECT @POCoOut = POCo, @msg = [Description], @Status = [Status] FROM dbo.SMPurchaseOrderList WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND PO = @PONumber
		
		SET @NumRows = @@ROWCOUNT
		
		IF (@NumRows = 0)
		BEGIN
			SELECT @POCoOut = NULL, @msg = 'Invalid PO Number.'
			RETURN 1
		END
		ELSE IF (@NumRows > 1)
		BEGIN
			SELECT @POCoOut = NULL, @msg = 'There are multiple purchase orders from different PO companies with PO Number ' + CONVERT(varchar, @PONumber) + '.  Please use the lookup to select one of the purchase orders.'
			RETURN 1
		END
	END
	ELSE
	BEGIN
		-- Validate normally
		SELECT @POCoOut = POCo, @msg = [Description], @Status = [Status] FROM dbo.SMPurchaseOrderList WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND POCo = @POCo AND PO = @PONumber

		IF (@@ROWCOUNT = 0)
		BEGIN
			SELECT @POCoOut = NULL, @msg = 'Invalid PO Number.'
			RETURN 1
		END
	END
	
	IF @Status <> 0
	BEGIN
		SET @msg = 'PO must be open.'
		RETURN 1
	END
	
	RETURN 0
END




GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedPartPONumberVal] TO [public]
GO
