SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vrvARAgingTotalsByCompany]

/***
 Created: 8/11/11 DH
 Usage:  Selects 30, 60, 90 aging amounts by AR Company for use in SSRS reports
 
 ******/

AS

WITH cteMonthEndDates (MonthEndDate)
AS

(SELECT TheDate FROM vf_ARAgeEndMonthDates ('1/31/1976', '12/31/2100'))

SELECT ARCo,
	   a.MonthEndDate,
	   AmountCurrent,
	   AmountOver30,
	   AmountOver60,
	   AmountOver90,
	   TotalAged,
	   Retainage

 FROM cteMonthEndDates a
 CROSS APPLY vf_rptARAgingByCompany  (a.MonthEndDate)

	   
	   
GO
GRANT SELECT ON  [dbo].[vrvARAgingTotalsByCompany] TO [public]
GRANT INSERT ON  [dbo].[vrvARAgingTotalsByCompany] TO [public]
GRANT DELETE ON  [dbo].[vrvARAgingTotalsByCompany] TO [public]
GRANT UPDATE ON  [dbo].[vrvARAgingTotalsByCompany] TO [public]
GRANT SELECT ON  [dbo].[vrvARAgingTotalsByCompany] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvARAgingTotalsByCompany] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvARAgingTotalsByCompany] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvARAgingTotalsByCompany] TO [Viewpoint]
GO
