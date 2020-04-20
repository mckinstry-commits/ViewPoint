SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
SELECT     t.HRCo, i.HRRef, t.Accident, t.AccidentDate, t.AccidentTime, t.EmployerPremYN, t.JobSiteYN, t.JCCo, t.Job, t.PhaseGroup, t.Phase, t.ReportedBy, 
                      t.DateReported, t.TimeReported, t.Location, t.ClosedDate, t.CorrectiveAction, t.Notes, t.UniqueAttchID, t.MSHAID, t.MineName
FROM         dbo.HRAT AS t INNER JOIN
                      dbo.HRAI AS i ON t.HRCo = i.HRCo AND t.Accident = i.Accident AND i.AccidentType = 'R' AND i.HRRef IS NOT NULL
*/
CREATE VIEW dbo.HRATbyHRRef
AS
SELECT     dbo.HRAT.HRCo, dbo.HRAI.HRRef, dbo.HRAI.AccidentType, dbo.HRAT.Accident, dbo.HRAI.Seq, dbo.HRAT.AccidentDate, dbo.HRAI.AccidentCode, 
                      dbo.HRAI.PreventableYN, dbo.HRAI.Type, dbo.HRAI.IllnessInjuryDesc, dbo.HRAI.Cause, dbo.HRAT.EmployerPremYN, dbo.HRAT.JobSiteYN
FROM         dbo.HRAT INNER JOIN
                      dbo.HRAI ON dbo.HRAT.HRCo = dbo.HRAI.HRCo AND dbo.HRAT.Accident = dbo.HRAI.Accident AND dbo.HRAI.AccidentType = 'R' AND 
                      dbo.HRAI.HRRef IS NOT NULL

GO
GRANT SELECT ON  [dbo].[HRATbyHRRef] TO [public]
GRANT INSERT ON  [dbo].[HRATbyHRRef] TO [public]
GRANT DELETE ON  [dbo].[HRATbyHRRef] TO [public]
GRANT UPDATE ON  [dbo].[HRATbyHRRef] TO [public]
GRANT SELECT ON  [dbo].[HRATbyHRRef] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRATbyHRRef] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRATbyHRRef] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRATbyHRRef] TO [Viewpoint]
GO
