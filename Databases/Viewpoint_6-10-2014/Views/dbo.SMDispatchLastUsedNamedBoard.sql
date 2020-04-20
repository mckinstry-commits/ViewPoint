SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMDispatchLastUsedNamedBoard]
AS
SELECT        dbo.vSMDispatchLastUsedNamedBoard.*
FROM            dbo.vSMDispatchLastUsedNamedBoard

GO
GRANT SELECT ON  [dbo].[SMDispatchLastUsedNamedBoard] TO [public]
GRANT INSERT ON  [dbo].[SMDispatchLastUsedNamedBoard] TO [public]
GRANT DELETE ON  [dbo].[SMDispatchLastUsedNamedBoard] TO [public]
GRANT UPDATE ON  [dbo].[SMDispatchLastUsedNamedBoard] TO [public]
GRANT SELECT ON  [dbo].[SMDispatchLastUsedNamedBoard] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMDispatchLastUsedNamedBoard] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMDispatchLastUsedNamedBoard] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMDispatchLastUsedNamedBoard] TO [Viewpoint]
GO
