SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 8/16/10
-- Description:	HQ Contact Seq validation
-- =============================================
CREATE PROCEDURE [dbo].[vspHQContactValidation]
(
	@ContactGroup bGroup,
	@ContactSeq int,
	@msg varchar(255) OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;

	IF (@ContactGroup IS NULL)
	BEGIN
		SET @msg = 'Invalid Contact Group.'
		RETURN 1
	END
	
	SELECT @msg = HQContact.FirstName + ' ' + HQContact.LastName 
	FROM HQContact 
	WHERE ContactGroup = @ContactGroup AND ContactSeq = @ContactSeq
	
	IF (@@rowcount = 0)
	BEGIN
		SET @msg = 'Contact not on file.'
		RETURN 1
	END
END




GO
GRANT EXECUTE ON  [dbo].[vspHQContactValidation] TO [public]
GO
