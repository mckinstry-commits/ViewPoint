SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:	GF 12/05/2006
 * Modfied By:
 *
 * Provides a view of PM RFQ Distribution
 * used in document tracking
 *
 *****************************************/
/***** RFQ view to get counts and minimum date from PMQD *****/

CREATE  view [dbo].[PMRQGrid] as
select a.PMCo, a.Project, a.PCOType, a.PCO, a.RFQ,
   	'RespRecd'=(Select Count(DateRecd) from PMQD where PMQD.PMCo=a.PMCo 
   			and PMQD.Project=a.Project and PMQD.PCOType=a.PCOType and PMQD.PCO=a.PCO and PMQD.RFQ=a.RFQ),
   	'RespReqd'=(Select Count(DateReqd) from PMQD where PMQD.PMCo=a.PMCo 
   			and PMQD.Project=a.Project and PMQD.PCOType=a.PCOType and PMQD.PCO=a.PCO and PMQD.RFQ=a.RFQ),
   	'DateRespReqd'=(Select min(DateReqd) from PMQD where PMQD.PMCo=a.PMCo 
   			and PMQD.Project=a.Project and PMQD.PCOType=a.PCOType and PMQD.PCO=a.PCO and PMQD.RFQ=a.RFQ)
   from dbo.PMRQ a

GO
GRANT SELECT ON  [dbo].[PMRQGrid] TO [public]
GRANT INSERT ON  [dbo].[PMRQGrid] TO [public]
GRANT DELETE ON  [dbo].[PMRQGrid] TO [public]
GRANT UPDATE ON  [dbo].[PMRQGrid] TO [public]
GO
