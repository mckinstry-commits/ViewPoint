SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 6/28/2012
-- Description:	Closes and Deallocates the cursor
-- =============================================
CREATE PROCEDURE [dbo].[vspCleanupCursor]
	@Cursor CURSOR VARYING OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    CLOSE @Cursor
    DEALLOCATE @Cursor
END
GO
GRANT EXECUTE ON  [dbo].[vspCleanupCursor] TO [public]
GO
