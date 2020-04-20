SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 11/17/10
-- Description:	Deletes the given SM session
-- =============================================
CREATE PROCEDURE [dbo].[vspSMSessionDelete]
	@SMSessionID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DELETE dbo.SMSession
    WHERE SMSessionID = @SMSessionID
    
    RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMSessionDelete] TO [public]
GO
