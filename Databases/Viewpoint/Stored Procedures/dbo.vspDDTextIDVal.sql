SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		CC
-- Modified:	CC 7/17/2009 - Issue #129922 - Added culture
-- Create date: 4/10/08
-- Description:	Procedure to retrieve text for a given TextID
-- =============================================
CREATE PROCEDURE [dbo].[vspDDTextIDVal] 
	-- Add the parameters for the stored procedure here
	@TextID int = null,
	@culture INT = NULL,
	@Text VARCHAR(250) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int
	SET @rcode = 0

    -- Insert statements for procedure here
    SELECT @Text = CultureText  
    FROM dbo.DDCTShared
    WHERE dbo.DDCTShared.TextID = @TextID AND dbo.DDCTShared.CultureID = @culture
    
	IF @Text IS NULL AND NOT EXISTS (SELECT TOP 1 1 FROM dbo.DDTM WHERE dbo.DDTM.TextID = @TextID)
		SELECT @Text = 'Invalid TextID', @rcode = 1

	RETURN @rcode
END


GO
GRANT EXECUTE ON  [dbo].[vspDDTextIDVal] TO [public]
GO
