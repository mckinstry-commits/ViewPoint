SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************
   * Created By:
   * Modfied By:
   *
   * Provides a view of PM RFI Distribution
   * used in document tracking
   *
   *****************************************/
   /***** RFI view to get counts and minimum date from PMRD *****/
   /***** Issue #26340 change RespReqd to use DateReqd instead of DateSent *****/
   
   CREATE  view [dbo].[PMRIGrid] as
select a.PMCo, a.Project, a.RFIType, a.RFI,
   	'RespRecd'=(Select Count(DateRecd) from PMRD where PMRD.PMCo=a.PMCo 
   			and PMRD.Project=a.Project and PMRD.RFIType=a.RFIType and PMRD.RFI=a.RFI),
   	'RespReqd'=(Select Count(DateReqd) from PMRD where PMRD.PMCo=a.PMCo 
   			and PMRD.Project=a.Project and PMRD.RFIType=a.RFIType and PMRD.RFI=a.RFI),
   	'DateRespReqd'=(Select min(DateReqd) from PMRD where PMRD.PMCo=a.PMCo 
   			and PMRD.Project=a.Project and PMRD.RFIType=a.RFIType and PMRD.RFI=a.RFI)
   from dbo.PMRI a



GO
GRANT SELECT ON  [dbo].[PMRIGrid] TO [public]
GRANT INSERT ON  [dbo].[PMRIGrid] TO [public]
GRANT DELETE ON  [dbo].[PMRIGrid] TO [public]
GRANT UPDATE ON  [dbo].[PMRIGrid] TO [public]
GO
