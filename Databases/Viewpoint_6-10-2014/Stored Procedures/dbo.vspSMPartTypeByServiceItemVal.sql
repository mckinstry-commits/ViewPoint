SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Lane Gresham
-- Create date: 6/7/13
-- Description:	Validation for SM Part Types by ServiceItem
-- Modified:	6/11/13 LDG - If SMServiceItemPart.Material returs more than one record, returns null.
--				6/17/13 LDG - Added UM and Qty outputs.
-- =============================================

CREATE PROCEDURE [dbo].[vspSMPartTypeByServiceItemVal]
	@SMCo AS bCompany, 
	@SMPartType AS varchar(15), 
	@ServiceItem AS varchar(20),
	@Material AS bMatl = NULL OUTPUT, 
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	IF (@SMCo IS NULL)
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END
	
	IF (@SMPartType IS NULL)
	BEGIN
		SET @msg = 'Missing SM Part Type!'
		RETURN 1
	END

	IF (@ServiceItem IS NULL)
	BEGIN
		SET @msg = 'Missing Service Item!'
		RETURN 1
	END
	
	SELECT 1
	FROM SMServiceItemPart
		LEFT JOIN SMPartType on SMServiceItemPart.SMCo = SMPartType.SMCo 
		AND SMServiceItemPart.SMPartType = SMPartType.SMPartType
	WHERE SMServiceItemPart.SMCo = @SMCo 
		AND SMServiceItemPart.ServiceItem = @ServiceItem
		AND SMServiceItemPart.SMPartType = @SMPartType

	IF @@ROWCOUNT > 1
	BEGIN
		 SET @Material = NULL
	END 
	ELSE
	BEGIN
		SELECT 
			@Material = SMServiceItemPart.Material, 
			@msg = SMPartType.Description 
		FROM SMServiceItemPart
			LEFT JOIN SMPartType on SMServiceItemPart.SMCo = SMPartType.SMCo 
			AND SMServiceItemPart.SMPartType = SMPartType.SMPartType
		WHERE SMServiceItemPart.SMCo = @SMCo 
			AND SMServiceItemPart.ServiceItem = @ServiceItem
			AND SMServiceItemPart.SMPartType = @SMPartType
	END

    IF (@@ROWCOUNT = 0)
    BEGIN
		SET @msg = 'Part type has not been setup on Serviceable Item.'
		RETURN 1
    END
    
    RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMPartTypeByServiceItemVal] TO [public]
GO
