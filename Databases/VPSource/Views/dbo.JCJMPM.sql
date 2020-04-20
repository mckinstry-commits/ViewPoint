SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************
   * Created By:	GF 05/30/2008
   * Modfied By:    HH JG GP 11/22/2010 - added where-clause to filter out PCPotentialProjects
   *				GF 01/30/2012 TK-00000 do not need where clause. already in base view (JCJM)
   *
   *
   * Provides a view of JC Jobs for PM
   * used in PM forms returns alias columns
   * form PMCo, Project
   *
   *****************************************/
CREATE VIEW [dbo].[JCJMPM]
AS


select a.*, a.JCCo as [PMCo], a.Job as [Project]
from dbo.JCJM a
----where PCVisibleInJC = 'Y' 

GO
GRANT SELECT ON  [dbo].[JCJMPM] TO [public]
GRANT INSERT ON  [dbo].[JCJMPM] TO [public]
GRANT DELETE ON  [dbo].[JCJMPM] TO [public]
GRANT UPDATE ON  [dbo].[JCJMPM] TO [public]
GO
