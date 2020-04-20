SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE   view [dbo].[DDCBShared]
/****************************************
 * Created: 10/12/03 kb
 * Modified:
 *
 * Combines standard and custom ComboType's
 * from vDDCB and vDDCBc
 *
 ****************************************/
as

select isnull(c.ComboType,l.ComboType) as ComboType,
	isnull(c.Description,l.Description) as Description
from dbo.vDDCBc c
full outer join dbo.vDDCB l on  l.ComboType = c.ComboType 








GO
GRANT SELECT ON  [dbo].[DDCBShared] TO [public]
GRANT INSERT ON  [dbo].[DDCBShared] TO [public]
GRANT DELETE ON  [dbo].[DDCBShared] TO [public]
GRANT UPDATE ON  [dbo].[DDCBShared] TO [public]
GO
