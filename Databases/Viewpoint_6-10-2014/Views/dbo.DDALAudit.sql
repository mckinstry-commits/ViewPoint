SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










CREATE  VIEW dbo.DDALAudit
/****************************************
 * Created: ??
 * Modified:
 *
 * Returns informational messages from DD Application Log
 *
 ****************************************/
AS SELECT  DateTime, HostName, UserName,
 Company, Event, Object, Description
FROM  dbo.vDDAL
WHERE Event is not null AND Object is not null











GO
GRANT SELECT ON  [dbo].[DDALAudit] TO [public]
GRANT INSERT ON  [dbo].[DDALAudit] TO [public]
GRANT DELETE ON  [dbo].[DDALAudit] TO [public]
GRANT UPDATE ON  [dbo].[DDALAudit] TO [public]
GRANT SELECT ON  [dbo].[DDALAudit] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDALAudit] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDALAudit] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDALAudit] TO [Viewpoint]
GO
