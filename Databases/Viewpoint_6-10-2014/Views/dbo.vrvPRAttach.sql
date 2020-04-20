SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[vrvPRAttach] AS

select Src = 'SQ'
, PRSQ.PRCo
, PRSQ.PRGroup
, PRSQ.PREndDate
, PRSQ.Employee
, PRSQ.PaySeq
, PRSQ.CMCo
, PRSQ.CMAcct
, PRSQ.PayMethod
, PRSQ.CMRef
, PRSQ.UniqueAttchID as PRUniqueAttchID
--, HQAT.UniqueAttchID as HQUniqueAttchID
, HQAT.AttachmentID
, HQAT.Description
, Null as Void
from PRSQ 

left outer join HQAT HQAT with (nolock) on PRSQ.UniqueAttchID = HQAT.UniqueAttchID

where PRSQ.PRCo = 252 and PRSQ.Employee = 40

--Union ALL

--select distinct 'TH'
--, PRTH.PRCo
--, PRTH.PRGroup
--, PRTH.PREndDate
--, PRTH.Employee
--, PRTH.PaySeq
--, PRTH.PostSeq
--, Null as CMCo
--, Null as CMAcct
--, Null as PayMethod
--, Null as CMRef
--, PRTH.UniqueAttchID as PRUniqueAttchID
--, HQAT.UniqueAttchID as HQUniqueAttchID
--, HQAT.AttachmentID
--, HQAT.Description
--, Null as Void
--from PRTH

--join PRSQ with (nolock) on PRTH.PRCo = PRSQ.PRCo
--	and PRTH.PRGroup = PRSQ.PRGroup
--	and PRTH.PREndDate=PRSQ.PREndDate
--	and PRTH.Employee=PRSQ.Employee
--	and PRTH.PaySeq=PRSQ.PaySeq
--left outer join HQAT HQAT on HQAT.UniqueAttchID = PRTH.UniqueAttchID

--where HQAT.UniqueAttchID is not null 

--and PRTH.PRCo = 252 and PRTH.PRGroup = 1 and PRTH.Employee = 40 


GO
GRANT SELECT ON  [dbo].[vrvPRAttach] TO [public]
GRANT INSERT ON  [dbo].[vrvPRAttach] TO [public]
GRANT DELETE ON  [dbo].[vrvPRAttach] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRAttach] TO [public]
GRANT SELECT ON  [dbo].[vrvPRAttach] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPRAttach] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPRAttach] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPRAttach] TO [Viewpoint]
GO
