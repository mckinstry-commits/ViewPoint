SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 4/10/08
-- Description:	returns the label description (culture) for a given CultureID
-- =============================================
CREATE PROCEDURE [dbo].[vspDDValCultureID] 
	-- Add the parameters for the stored procedure here
	@CultureID int = null,
	@Culture VARCHAR(15) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rcode int
	SET @rcode = 0

	SELECT @Culture = Culture FROM DDCL WHERE KeyID = @CultureID 

	IF @Culture IS NULL
		SELECT @Culture = 'Invalid Culture', @rcode = 1

	RETURN @rcode 
END

GO
GRANT EXECUTE ON  [dbo].[vspDDValCultureID] TO [public]
GO
