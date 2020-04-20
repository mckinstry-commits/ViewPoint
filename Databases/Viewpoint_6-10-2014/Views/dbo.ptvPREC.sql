SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ptvPREC]
AS

-- PR Earnings Codes
SELECT EarnCode, Description, Factor, PRCo

FROM PREC with (nolock)

GO
GRANT SELECT ON  [dbo].[ptvPREC] TO [public]
GRANT INSERT ON  [dbo].[ptvPREC] TO [public]
GRANT DELETE ON  [dbo].[ptvPREC] TO [public]
GRANT UPDATE ON  [dbo].[ptvPREC] TO [public]
GRANT SELECT ON  [dbo].[ptvPREC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ptvPREC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ptvPREC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ptvPREC] TO [Viewpoint]
GO
