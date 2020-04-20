SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vpspIsPortalActive]
AS

declare @rcode int
select @rcode = 0

SELECT @rcode = 
  CASE Count(*)
    WHEN 0 THEN 0
    ELSE 1
  END
FROM pPasswordRules

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vpspIsPortalActive] TO [VCSPortal]
GO
