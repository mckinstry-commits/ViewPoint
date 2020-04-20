SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PRROEEmployeeWorkfile] as select a.* From vPRROEEmployeeWorkfile a

GO
GRANT SELECT ON  [dbo].[PRROEEmployeeWorkfile] TO [public]
GRANT INSERT ON  [dbo].[PRROEEmployeeWorkfile] TO [public]
GRANT DELETE ON  [dbo].[PRROEEmployeeWorkfile] TO [public]
GRANT UPDATE ON  [dbo].[PRROEEmployeeWorkfile] TO [public]
GRANT SELECT ON  [dbo].[PRROEEmployeeWorkfile] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRROEEmployeeWorkfile] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRROEEmployeeWorkfile] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRROEEmployeeWorkfile] TO [Viewpoint]
GO
