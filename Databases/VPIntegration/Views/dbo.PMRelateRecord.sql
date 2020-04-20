SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************
 * Created By:	GF 01/26/2011 - tfs #398
 * Modfied By:
 *
 * Provides a view of PM Related Records
 *
 *****************************************/
CREATE VIEW [dbo].[PMRelateRecord]
as
SELECT a.* FROM dbo.vPMRelateRecord a


GO
GRANT SELECT ON  [dbo].[PMRelateRecord] TO [public]
GRANT INSERT ON  [dbo].[PMRelateRecord] TO [public]
GRANT DELETE ON  [dbo].[PMRelateRecord] TO [public]
GRANT UPDATE ON  [dbo].[PMRelateRecord] TO [public]
GO
