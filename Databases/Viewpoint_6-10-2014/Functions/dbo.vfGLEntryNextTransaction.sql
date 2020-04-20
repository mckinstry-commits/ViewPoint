SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 5/30/12
-- Description:	Returns the next GL Transaction for a given GLEntryID
-- =============================================
CREATE FUNCTION [dbo].[vfGLEntryNextTransaction]
(
	@GLEntryID bigint
)
RETURNS int
AS
BEGIN
	RETURN (SELECT ISNULL(MAX(GLTransaction), 0) + 1
			FROM dbo.vGLEntryTransaction
			WHERE GLEntryID = @GLEntryID)
END
GO
GRANT EXECUTE ON  [dbo].[vfGLEntryNextTransaction] TO [public]
GO
