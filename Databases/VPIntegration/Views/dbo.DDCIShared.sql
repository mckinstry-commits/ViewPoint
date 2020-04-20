SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE    view [dbo].[DDCIShared]
/****************************************
 * Created: 10/12/03 kb
 * Modified:
 *
 * Combines standard and custom ComboType Items
 * from vDDCI and vDDCIc
 *
 ****************************************/
as

select isnull(c.ComboType,l.ComboType) as ComboType,
	isnull(c.Seq,l.Seq) as Seq,
	isnull(c.DisplayValue,l.DisplayValue) as DisplayValue,
	isnull(c.DatabaseValue,l.DatabaseValue) as DatabaseValue
from dbo.vDDCIc c
full outer join dbo.vDDCI l on  l.ComboType = c.ComboType 







GO
GRANT SELECT ON  [dbo].[DDCIShared] TO [public]
GRANT INSERT ON  [dbo].[DDCIShared] TO [public]
GRANT DELETE ON  [dbo].[DDCIShared] TO [public]
GRANT UPDATE ON  [dbo].[DDCIShared] TO [public]
GO
