SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  view [dbo].[DDMFShared]
/****************************************
 * Created: GG 07/08/03
 * Modified: 
 *
 * Combines standard and custom Module Form information
 * from vDDMF and vDDMFc.  
 *
 ****************************************/
as

select isnull(c.Mod,f.Mod) as Mod,
	isnull(c.Form,f.Form) as Form,
	isnull(c.Active, 'Y') as Active
from dbo.vDDMFc c
full outer join dbo.vDDMF f on  f.Mod = c.Mod and f.Form = c.Form 







GO
GRANT SELECT ON  [dbo].[DDMFShared] TO [public]
GRANT INSERT ON  [dbo].[DDMFShared] TO [public]
GRANT DELETE ON  [dbo].[DDMFShared] TO [public]
GRANT UPDATE ON  [dbo].[DDMFShared] TO [public]
GRANT SELECT ON  [dbo].[DDMFShared] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDMFShared] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDMFShared] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDMFShared] TO [Viewpoint]
GO
