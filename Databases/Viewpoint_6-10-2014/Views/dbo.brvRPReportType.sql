SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   view [dbo].[brvRPReportType]
/***********************************
* Created: ??
* Modified: GG 01/23/06 - VP6.0 use vRP views
*
* Use: ??
*
*************************************/
 as
 
 select Title=Cast(t.Title as varchar(40)), ReportDescr=max(t.ReportDesc), Type=isnull(min(TType.TableType),'Detail'),
 Layout=(case when min(TType.TableType) is null then 'N' else 'Y' end)
 From RPRTShared t
 Left Join (Select distinct TTypeReportID=RPTP.ReportID, DDTH.TableType
        From RPTP
        Join DDTH on DDTH.TableName=RPTP.ViewName) as TType
 on TTypeReportID=t.ReportID
 Group By Cast(t.Title as varchar(40))
 
 
 
 



GO
GRANT SELECT ON  [dbo].[brvRPReportType] TO [public]
GRANT INSERT ON  [dbo].[brvRPReportType] TO [public]
GRANT DELETE ON  [dbo].[brvRPReportType] TO [public]
GRANT UPDATE ON  [dbo].[brvRPReportType] TO [public]
GRANT SELECT ON  [dbo].[brvRPReportType] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvRPReportType] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvRPReportType] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvRPReportType] TO [Viewpoint]
GO
