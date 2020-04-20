SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PRROEEmployeeHistory] as select a.* From vPRROEEmployeeHistory a

GO
GRANT SELECT ON  [dbo].[PRROEEmployeeHistory] TO [public]
GRANT INSERT ON  [dbo].[PRROEEmployeeHistory] TO [public]
GRANT DELETE ON  [dbo].[PRROEEmployeeHistory] TO [public]
GRANT UPDATE ON  [dbo].[PRROEEmployeeHistory] TO [public]
GRANT SELECT ON  [dbo].[PRROEEmployeeHistory] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRROEEmployeeHistory] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRROEEmployeeHistory] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRROEEmployeeHistory] TO [Viewpoint]
GO
