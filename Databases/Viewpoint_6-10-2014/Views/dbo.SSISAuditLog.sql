SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.SSISAuditLog
AS
SELECT     DateTime, HostName, UserName, ErrorNumber, Description, SQLRetCode, UnhandledError, Informational, [Assembly], Class, [Procedure], AssemblyVersion, 
                      StackTrace, FriendlyMessage, LineNumber, Event, Company, Object, CrystalErrorID, ErrorProcedure
FROM         dbo.DDAL
WHERE     ([Assembly] = 'SSISDatabaseLogProvider')

GO
GRANT SELECT ON  [dbo].[SSISAuditLog] TO [public]
GRANT INSERT ON  [dbo].[SSISAuditLog] TO [public]
GRANT DELETE ON  [dbo].[SSISAuditLog] TO [public]
GRANT UPDATE ON  [dbo].[SSISAuditLog] TO [public]
GRANT SELECT ON  [dbo].[SSISAuditLog] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SSISAuditLog] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SSISAuditLog] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SSISAuditLog] TO [Viewpoint]
GO
