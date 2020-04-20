SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMPS] as select a.* From bEMPS a

GO
GRANT SELECT ON  [dbo].[EMPS] TO [public]
GRANT INSERT ON  [dbo].[EMPS] TO [public]
GRANT DELETE ON  [dbo].[EMPS] TO [public]
GRANT UPDATE ON  [dbo].[EMPS] TO [public]
GRANT SELECT ON  [dbo].[EMPS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMPS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMPS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMPS] TO [Viewpoint]
GO
