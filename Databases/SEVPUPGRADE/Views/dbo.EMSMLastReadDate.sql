SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMSMLastReadDate] as
/* Created:  TRL Issue 130202 10/21/08

Usage:  Used to replace functions vfEMEquipLastOdo and vEMEquipLastReadDate
for EM Miles by State

Get Max Reading Date for Equipment
*/
Select Co,Equipment,LastReadingDate = Max(ReadingDate)
from dbo.EMSM with(nolock)
Group by Co,Equipment



GO
GRANT SELECT ON  [dbo].[EMSMLastReadDate] TO [public]
GRANT INSERT ON  [dbo].[EMSMLastReadDate] TO [public]
GRANT DELETE ON  [dbo].[EMSMLastReadDate] TO [public]
GRANT UPDATE ON  [dbo].[EMSMLastReadDate] TO [public]
GO
