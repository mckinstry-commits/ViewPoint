SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMSMMaxReadingDateEndOdo] as
/* Created:  TRL Issue 130202 10/21/08

Usage:  Used to replace functions vfEMEquipLastOdo and vEMEquipLastReadDate
for EM Miles by State

Get the Max EndOdo for Equipment ReadingDate from EMSM
*/
Select r.Co, r.Equipment,r.LastReadingDate,EndOdo=IsNull(o.LastEndOdo,0)
From dbo.EMSMLastReadDate r with(nolock)
Inner Join dbo.EMSMLastReadDateEndOdo o with(nolock)on o.Co=r.Co and o.Equipment=r.Equipment 
														and o.ReadingDate=r.LastReadingDate

GO
GRANT SELECT ON  [dbo].[EMSMMaxReadingDateEndOdo] TO [public]
GRANT INSERT ON  [dbo].[EMSMMaxReadingDateEndOdo] TO [public]
GRANT DELETE ON  [dbo].[EMSMMaxReadingDateEndOdo] TO [public]
GRANT UPDATE ON  [dbo].[EMSMMaxReadingDateEndOdo] TO [public]
GO
