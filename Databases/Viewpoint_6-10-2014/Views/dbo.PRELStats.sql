SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRELStats] as 
SELECT     TOP (100) PERCENT l.PRCo, l.Employee, l.LeaveCode, ISNULL(l.Cap1Freq, v.Cap1Freq) AS 'Cap1Freq', ISNULL(l.Cap1Max, v.Cap1Max) AS 'Cap1Max', 
                      ISNULL(l.Cap2Freq, v.Cap2Freq) AS 'Cap2Freq', ISNULL(l.Cap2Max, v.Cap2Max) AS 'Cap2Max', ISNULL(l.AvailBalFreq, v.AvailBalFreq) 
                      AS 'AvailBalFreq', ISNULL(l.AvailBalMax, v.AvailBalMax) AS 'AvailBalMax', l.Cap1Date, l.Cap2Date, l.AvailBalDate
FROM         dbo.PREL AS l WITH (nolock) INNER JOIN
                      dbo.PRLV AS v WITH (nolock) ON v.PRCo = l.PRCo AND v.LeaveCode = l.LeaveCode
GO
GRANT SELECT ON  [dbo].[PRELStats] TO [public]
GRANT INSERT ON  [dbo].[PRELStats] TO [public]
GRANT DELETE ON  [dbo].[PRELStats] TO [public]
GRANT UPDATE ON  [dbo].[PRELStats] TO [public]
GRANT SELECT ON  [dbo].[PRELStats] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRELStats] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRELStats] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRELStats] TO [Viewpoint]
GO
