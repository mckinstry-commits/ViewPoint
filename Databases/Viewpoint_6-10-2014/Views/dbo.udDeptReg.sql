SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udDeptReg] as select a.* From budDeptReg a
GO
GRANT SELECT ON  [dbo].[udDeptReg] TO [public]
GRANT INSERT ON  [dbo].[udDeptReg] TO [public]
GRANT DELETE ON  [dbo].[udDeptReg] TO [public]
GRANT UPDATE ON  [dbo].[udDeptReg] TO [public]
GO
