SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[SMNamedDispatchBoard] as select a.* From vSMNamedDispatchBoard a







GO
GRANT SELECT ON  [dbo].[SMNamedDispatchBoard] TO [public]
GRANT INSERT ON  [dbo].[SMNamedDispatchBoard] TO [public]
GRANT DELETE ON  [dbo].[SMNamedDispatchBoard] TO [public]
GRANT UPDATE ON  [dbo].[SMNamedDispatchBoard] TO [public]
GRANT SELECT ON  [dbo].[SMNamedDispatchBoard] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMNamedDispatchBoard] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMNamedDispatchBoard] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMNamedDispatchBoard] TO [Viewpoint]
GO
