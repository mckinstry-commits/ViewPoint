SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vpspRQLines]
AS
SELECT * FROM RQRL

GO
GRANT EXECUTE ON  [dbo].[vpspRQLines] TO [VCSPortal]
GO
