SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  view [dbo].[vrvHRFMLA] as
select PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, PostDate, Hours, Rate, Amt, Earnings=0, 
Dedns=0, LeaveCode=null, LVCdDescription=null, LVCdType=null, LVCdMth='1/1/1950',LVCdTrans=0

from PRTH

Union all

select PRCo, PRGroup, PREndDate, Employee, PaySeq, 0, '1/1/1950', Hours, 0, 0, Earnings, 
Dedns,null, null, null, '1/1/1950',0

from PRSQ

union all

select PRCo, PRGroup, PREndDate, Employee, PaySeq, 0, ActDate, Amt, 0, 0, 0,
0, LeaveCode, Description, Type, Mth, Trans

from PRLH

GO
GRANT SELECT ON  [dbo].[vrvHRFMLA] TO [public]
GRANT INSERT ON  [dbo].[vrvHRFMLA] TO [public]
GRANT DELETE ON  [dbo].[vrvHRFMLA] TO [public]
GRANT UPDATE ON  [dbo].[vrvHRFMLA] TO [public]
GRANT SELECT ON  [dbo].[vrvHRFMLA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvHRFMLA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvHRFMLA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvHRFMLA] TO [Viewpoint]
GO
