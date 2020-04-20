SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  view dbo.HRPCEmp
as

Select top 100 percent h.HRCo, h.PositionCode, h.HRRef, ActiveYN
from dbo.HRRM h
order by h.HRCo




GO
GRANT SELECT ON  [dbo].[HRPCEmp] TO [public]
GRANT INSERT ON  [dbo].[HRPCEmp] TO [public]
GRANT DELETE ON  [dbo].[HRPCEmp] TO [public]
GRANT UPDATE ON  [dbo].[HRPCEmp] TO [public]
GO
