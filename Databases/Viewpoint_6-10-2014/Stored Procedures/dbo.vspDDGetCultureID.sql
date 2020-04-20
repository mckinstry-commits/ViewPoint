SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 4/10/08
-- Description:	Returns a culture ID for a given culture text, will return default if not found
-- =============================================
CREATE PROCEDURE [dbo].[vspDDGetCultureID]
	-- Add the parameters for the stored procedure here
	@Culture VARCHAR(15) = null, 
	@CultureID int = null OUTPUT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int
	SET @rcode = 0

    -- Insert statements for procedure here
	SELECT @CultureID = KeyID FROM DDCL WHERE Culture = @Culture
	IF @CultureID IS NULL
		SELECT @CultureID = KeyID, @rcode = 1 FROM DDCL WHERE Culture = 'en-US'

	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vspDDGetCultureID] TO [public]
GO
