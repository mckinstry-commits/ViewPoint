SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[PRSQMaint]
AS
SELECT  s.*, c.UniqueAttchID as cUniqueAttchID  --TODO:  remove the "As" clause.
FROM    dbo.PRSQ AS s (nolock)
INNER JOIN dbo.PRPC AS c (nolock) ON c.PRCo = s.PRCo AND c.PRGroup = s.PRGroup AND s.PREndDate = c.PREndDate
WHERE (c.Status = 0)

GO
GRANT SELECT ON  [dbo].[PRSQMaint] TO [public]
GRANT INSERT ON  [dbo].[PRSQMaint] TO [public]
GRANT DELETE ON  [dbo].[PRSQMaint] TO [public]
GRANT UPDATE ON  [dbo].[PRSQMaint] TO [public]
GO
