SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************
 * Created By:	GF 11/10/2006
 * Modfied By:
 *
 * Provides a view of PM Document History for test logs
 *
 *****************************************/
 
CREATE  view [dbo].[PMDHTest] as
select a.DocType as [TestType], a.Document as [TestCode], a.*
From dbo.PMDH a where a.DocCategory = 'TEST'

GO
GRANT SELECT ON  [dbo].[PMDHTest] TO [public]
GRANT INSERT ON  [dbo].[PMDHTest] TO [public]
GRANT DELETE ON  [dbo].[PMDHTest] TO [public]
GRANT UPDATE ON  [dbo].[PMDHTest] TO [public]
GRANT SELECT ON  [dbo].[PMDHTest] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMDHTest] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMDHTest] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMDHTest] TO [Viewpoint]
GO
