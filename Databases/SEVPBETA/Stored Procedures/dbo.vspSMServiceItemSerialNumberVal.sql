SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lane Gresham
-- Create date: 08/02/11
-- Description:	Validation for SM Service Item Serial Number.
-- Modified:	
-- =============================================
CREATE PROCEDURE [dbo].[vspSMServiceItemSerialNumberVal]
	@SMCo AS bCompany, @ServiceableItem varchar(20),  @SerialNumber varchar(60), @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END
	
	IF @SerialNumber IS NULL
	BEGIN
		SET @msg = 'Missing Serial Number!'
		RETURN 1
	END

	IF EXISTS(SELECT 1
		FROM dbo.SMServiceItems
		WHERE SMCo = @SMCo AND SerialNumber = @SerialNumber AND ServiceItem <> @ServiceableItem )
	BEGIN
		SET @msg = 'Warning, SM Service Item Serial Number already exists within the Company'
		RETURN 1
	END
	
	RETURN 0

END
GO
GRANT EXECUTE ON  [dbo].[vspSMServiceItemSerialNumberVal] TO [public]
GO
