SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE     View [dbo].[brvReportInfo]
  
  as
  
  select RPRP.ReportID, RPRT.Title, ParameterName, FormatSeq=Null, FormatType='VPParam' from RPRP 
  	join RPRTShared as RPRT on RPRT.ReportID = RPRP.ReportID
  union all
  
  select RPRF.ReportID, RPRT.Title, Null, Seq, FormatType=FieldType From RPRF
        join RPRTShared as RPRT on RPRT.ReportID = RPRF.ReportID
  Where FieldType not in ('Proc Parameter','Parameters')
  
   
  





GO
GRANT SELECT ON  [dbo].[brvReportInfo] TO [public]
GRANT INSERT ON  [dbo].[brvReportInfo] TO [public]
GRANT DELETE ON  [dbo].[brvReportInfo] TO [public]
GRANT UPDATE ON  [dbo].[brvReportInfo] TO [public]
GRANT SELECT ON  [dbo].[brvReportInfo] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvReportInfo] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvReportInfo] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvReportInfo] TO [Viewpoint]
GO
