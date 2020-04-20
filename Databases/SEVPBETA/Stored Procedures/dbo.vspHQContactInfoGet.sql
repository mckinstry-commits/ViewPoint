SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 8/10/10
-- Description:	HQ Contact load proc
-- =============================================
CREATE PROCEDURE [dbo].[vspHQContactInfoGet]
(
	@HQCo bCompany,
	@ContactGroup bGroup OUTPUT,
	@msg varchar(255) OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT @ContactGroup = HQCO.ContactGroup 
	FROM dbo.HQCO
	WHERE HQCO.HQCo = @HQCo
	
	IF (@ContactGroup IS NULL)
	BEGIN
		SET @msg = 'The contact group for company ' + CONVERT(varchar, @HQCo) + ' must be assigned in HQ Company before HQ Contacts may be used.'
		RETURN 1
	END
END


GO
GRANT EXECUTE ON  [dbo].[vspHQContactInfoGet] TO [public]
GO
