SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMSMLastReadDateEndOdo] as
/* Created:  TRL Issue 130202 10/21/08

Usage:  Used to replace functions vfEMEquipLastOdo and vEMEquipLastReadDate
for EM Miles by State

Get Max EndOdo for Equipment and Reading Date
*/
Select Co,Equipment,ReadingDate,LastEndOdo =Max(EndOdo)
from dbo.EMSM with(nolock)
Group by Co,Equipment,ReadingDate
GO
GRANT SELECT ON  [dbo].[EMSMLastReadDateEndOdo] TO [public]
GRANT INSERT ON  [dbo].[EMSMLastReadDateEndOdo] TO [public]
GRANT DELETE ON  [dbo].[EMSMLastReadDateEndOdo] TO [public]
GRANT UPDATE ON  [dbo].[EMSMLastReadDateEndOdo] TO [public]
GRANT SELECT ON  [dbo].[EMSMLastReadDateEndOdo] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMSMLastReadDateEndOdo] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMSMLastReadDateEndOdo] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMSMLastReadDateEndOdo] TO [Viewpoint]
GO
