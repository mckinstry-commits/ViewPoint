SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:
 * Modfied By:
 *
 * Provides a view of PM Document History for punch lists
 *
 *****************************************/
 
CREATE  view [dbo].[PMDHPunch] as
select a.Document as [PunchList], a.*
From dbo.PMDH a where a.DocCategory = 'PUNCH'

GO
GRANT SELECT ON  [dbo].[PMDHPunch] TO [public]
GRANT INSERT ON  [dbo].[PMDHPunch] TO [public]
GRANT DELETE ON  [dbo].[PMDHPunch] TO [public]
GRANT UPDATE ON  [dbo].[PMDHPunch] TO [public]
GO
