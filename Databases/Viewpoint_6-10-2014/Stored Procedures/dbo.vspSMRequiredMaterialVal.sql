SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Lane Gresham
-- Create date: 6/18/13
-- Description:	SM Required Material Validation
-- Modified:	
-- =============================================
CREATE PROCEDURE [dbo].[vspSMRequiredMaterialVal]
	@smco bCompany,
	@matlgroup bGroup=0, 
	@material bMatl=NULL, 
	@serviceableitem varchar(20),
	@SMPartType varchar(15),
	@qty bUnits = NULL OUTPUT,
	@cost bUnitCost = 0 OUTPUT, 
	@costECM bECM OUTPUT,
	@stdum bUM OUTPUT,
	@msg varchar(60) OUTPUT
AS
BEGIN
	
	DECLARE @rcode int, @paydisc varchar(1)
			
	EXEC @rcode = vspHQMUMatlInfoGet @matlgroup = @matlgroup, @material = @material, @paydisc = @paydisc, @cost = @cost OUTPUT, @costECM = @costECM OUTPUT, @stdum = @stdum OUTPUT, @msg = @msg OUTPUT
	IF @rcode=1 GOTO vspexit

	IF @SMPartType IS NOT NULL
	BEGIN

		SELECT 
		
		@stdum = SMServiceItemPart.UM,
		@qty = SMServiceItemPart.Quantity,
		@msg = SMPartType.Description 
		FROM SMServiceItemPart
			LEFT JOIN SMPartType on SMServiceItemPart.SMCo = SMPartType.SMCo 
			AND SMServiceItemPart.SMPartType = SMPartType.SMPartType
		WHERE SMServiceItemPart.SMCo = @smco 
			AND SMServiceItemPart.ServiceItem = @serviceableitem
			AND SMServiceItemPart.SMPartType = @SMPartType
			AND SMServiceItemPart.Material = @material

	END

	vspexit:
		return @rcode

END

GO
GRANT EXECUTE ON  [dbo].[vspSMRequiredMaterialVal] TO [public]
GO
