SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   VIEW dbo.DDALErrors
/****************************************
 * Created: ??
 * Modified:
 *
 * Returns error messages from DD Application Log
 *
 ****************************************/
AS SELECT  DateTime, HostName, UserName, Company,
 UnhandledError, ErrorNumber, SQLRetCode, CrystalErrorID
 Description, FriendlyMessage,
 Assembly, Class, [Procedure], LineNumber,
 StackTrace, AssemblyVersion, ErrorProcedure
 FROM  dbo.vDDAL
WHERE Informational = 0










GO
GRANT SELECT ON  [dbo].[DDALErrors] TO [public]
GRANT INSERT ON  [dbo].[DDALErrors] TO [public]
GRANT DELETE ON  [dbo].[DDALErrors] TO [public]
GRANT UPDATE ON  [dbo].[DDALErrors] TO [public]
GRANT SELECT ON  [dbo].[DDALErrors] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDALErrors] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDALErrors] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDALErrors] TO [Viewpoint]
GO
