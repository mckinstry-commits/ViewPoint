SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMRequiredMisc] AS 
SELECT m.*
FROM vSMRequiredMisc m
GO
GRANT SELECT ON  [dbo].[SMRequiredMisc] TO [public]
GRANT INSERT ON  [dbo].[SMRequiredMisc] TO [public]
GRANT DELETE ON  [dbo].[SMRequiredMisc] TO [public]
GRANT UPDATE ON  [dbo].[SMRequiredMisc] TO [public]
GO
