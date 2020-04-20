SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*==================================================================================          
    
Author:       
Scott Alvey    
    
Create date:       
07/11/2012     
    
Usage:
This view was created to serve the SM Service Agreement report sub-reports. 
It combines Service Agreement, Services, Service Site, Site Item (Serviceable Items), and 
task specific to the Service/Site combo or tasks specific to the Service/Site/Item combo.
    
Things to keep in mind:
Because a task can either be related to a specific serviceable item or to none, and therefore
related just to the service instance a union has to be made between the two scenarios to prevent
some very ugly duplication of data. Granted, not as ugly as the whole Storming of Bastille.
The first part of the union does not link to vrvSMServiceItemWithAgreement so it is 
just service specific tasks. The link to vrvSMServiceItemWithAgreement in the Item specific
tasks allows to ride the Agreement information over to SMAgreementServiceTask.
    
Related reports: 
SM Service Agreement (ID: 1206) 
   
Revision History          
Date  Author   Issue      Description
  
==================================================================================*/ 

CREATE view [dbo].[vrvSMAgreementQuoteServiceDetails] as

SELECT 
	'Service' as ServiceItemLevel
	, SMAgreement.SMCo
	, SMAgreement.Agreement
	, SMAgreement.Revision
	, SMServiceSite.ServiceSite
	, SMServiceSite.Description as ServiceSiteDescription
	, SMAgreementService.Service
	, SMAgreementService.Description as ServiceDescription
	, SMAgreementService.PricingMethod
	, SMAgreementService.BilledSeparately
	, SMAgreementService.PricingFrequency
	, SMAgreementService.ScheOptContactBeforeScheduling
	, SMAgreementService.DailyType
	, SMAgreementService.DailyEveryDays
	, SMAgreementService.WeeklyEveryWeeks
	, SMAgreementService.WeeklyEverySun
	, SMAgreementService.WeeklyEveryMon
	, SMAgreementService.WeeklyEveryTue
	, SMAgreementService.WeeklyEveryWed
	, SMAgreementService.WeeklyEveryThu
	, SMAgreementService.WeeklyEveryFri
	, SMAgreementService.WeeklyEverySat
	, SMAgreementService.MonthlyDay
	, SMAgreementService.MonthlyType
	, SMAgreementService.MonthlyDayEveryMonths
	, SMAgreementService.MonthlyApr
	, SMAgreementService.MonthlyAug
	, SMAgreementService.MonthlyDec
	, SMAgreementService.MonthlyFeb
	, SMAgreementService.MonthlyJan
	, SMAgreementService.MonthlyJul
	, SMAgreementService.MonthlyJun
	, SMAgreementService.MonthlyMar
	, SMAgreementService.MonthlyMay
	, SMAgreementService.MonthlyNov
	, SMAgreementService.MonthlyOct
	, SMAgreementService.MonthlySep
	, SMAgreementService.YearlyEveryYear
	, SMAgreementService.YearlyType
	, SMAgreementService.YearlyEveryDateMonthDay
	, SMAgreementService.YearlyEveryDayOrdinal
	, SMAgreementService.MonthlyEveryOrdinal
	, SMAgreementService.MonthlyEveryDay
	, SMAgreementService.RecurringPatternType
	, SMAgreementService.MonthlySelectOrdinal
	, SMAgreementService.MonthlySelectDay
	, SMAgreementService.YearlyEveryDateMonth
	, SMAgreementService.YearlyEveryDayDay
	, SMAgreementService.YearlyEveryDayMonth
	, SMAgreementService.MonthlyEveryMonths
	, SMAgreementServiceTask_ServiceLevel.Name as TaskName
	, SMAgreementServiceTask_ServiceLevel.Task as TaskSeq
	, null as ServiceItem --vrvSMServiceItemWithAgreement.ServiceItem
	, null as Description --vrvSMServiceItemWithAgreement.Description
FROM   
	SMAgreement 
LEFT OUTER JOIN 
	SMAgreementService ON 
		SMAgreement.SMCo=SMAgreementService.SMCo 
		AND SMAgreement.Agreement=SMAgreementService.Agreement 
		AND SMAgreement.Revision=SMAgreementService.Revision
LEFT OUTER JOIN 
	SMServiceSite ON 
		SMAgreementService.SMCo=SMServiceSite.SMCo 
		AND SMAgreementService.ServiceSite=SMServiceSite.ServiceSite 
LEFT OUTER JOIN 
	SMAgreementServiceTask SMAgreementServiceTask_ServiceLevel ON 
		SMAgreementService.SMCo=SMAgreementServiceTask_ServiceLevel.SMCo 
		AND SMAgreementService.Agreement=SMAgreementServiceTask_ServiceLevel.Agreement 
		AND SMAgreementService.Revision=SMAgreementServiceTask_ServiceLevel.Revision 
		AND SMAgreementService.Service=SMAgreementServiceTask_ServiceLevel.Service 
		and SMAgreementServiceTask_ServiceLevel.ServiceItem is null
 
 union all
 
SELECT 
	'Item' as ServiceItemLevel
	, SMAgreement.SMCo
	, SMAgreement.Agreement
	, SMAgreement.Revision
	, SMServiceSite.ServiceSite
	, SMServiceSite.Description
	, SMAgreementService.Service
	, SMAgreementService.Description
	, SMAgreementService.PricingMethod
	, SMAgreementService.BilledSeparately
	, SMAgreementService.PricingFrequency
	, SMAgreementService.ScheOptContactBeforeScheduling
	, SMAgreementService.DailyType
	, SMAgreementService.DailyEveryDays
	, SMAgreementService.WeeklyEveryWeeks
	, SMAgreementService.WeeklyEverySun
	, SMAgreementService.WeeklyEveryMon
	, SMAgreementService.WeeklyEveryTue
	, SMAgreementService.WeeklyEveryWed
	, SMAgreementService.WeeklyEveryThu
	, SMAgreementService.WeeklyEveryFri
	, SMAgreementService.WeeklyEverySat
	, SMAgreementService.MonthlyDay
	, SMAgreementService.MonthlyType
	, SMAgreementService.MonthlyDayEveryMonths
	, SMAgreementService.MonthlyApr
	, SMAgreementService.MonthlyAug
	, SMAgreementService.MonthlyDec
	, SMAgreementService.MonthlyFeb
	, SMAgreementService.MonthlyJan
	, SMAgreementService.MonthlyJul
	, SMAgreementService.MonthlyJun
	, SMAgreementService.MonthlyMar
	, SMAgreementService.MonthlyMay
	, SMAgreementService.MonthlyNov
	, SMAgreementService.MonthlyOct
	, SMAgreementService.MonthlySep
	, SMAgreementService.YearlyEveryYear
	, SMAgreementService.YearlyType
	, SMAgreementService.YearlyEveryDateMonthDay
	, SMAgreementService.YearlyEveryDayOrdinal
	, SMAgreementService.MonthlyEveryOrdinal
	, SMAgreementService.MonthlyEveryDay
	, SMAgreementService.RecurringPatternType
	, SMAgreementService.MonthlySelectOrdinal
	, SMAgreementService.MonthlySelectDay
	, SMAgreementService.YearlyEveryDateMonth
	, SMAgreementService.YearlyEveryDayDay
	, SMAgreementService.YearlyEveryDayMonth
	, SMAgreementService.MonthlyEveryMonths
	, SMAgreementServiceTask_ItemLevel.Name
	, SMAgreementServiceTask_ItemLevel.Task
	, vrvSMServiceItemWithAgreement.ServiceItem
	, vrvSMServiceItemWithAgreement.Description
FROM   
	SMAgreement 
LEFT OUTER JOIN 
	SMAgreementService ON 
		SMAgreement.SMCo=SMAgreementService.SMCo 
		AND SMAgreement.Agreement=SMAgreementService.Agreement 
		AND SMAgreement.Revision=SMAgreementService.Revision
LEFT OUTER JOIN 
	SMServiceSite ON 
		SMAgreementService.SMCo=SMServiceSite.SMCo 
		AND SMAgreementService.ServiceSite=SMServiceSite.ServiceSite 
LEFT OUTER JOIN 
	vrvSMServiceItemWithAgreement ON 
		SMAgreementService.SMCo=vrvSMServiceItemWithAgreement.SMCo 
		AND SMAgreementService.Agreement=vrvSMServiceItemWithAgreement.Agreement 
		AND SMAgreementService.Revision=vrvSMServiceItemWithAgreement.Revision 
		AND SMAgreementService.Service=vrvSMServiceItemWithAgreement.Service 
		AND SMAgreementService.ServiceSite=vrvSMServiceItemWithAgreement.ServiceSite 
LEFT OUTER JOIN 
	SMAgreementServiceTask SMAgreementServiceTask_ItemLevel ON 
		vrvSMServiceItemWithAgreement.SMCo=SMAgreementServiceTask_ItemLevel.SMCo 
		AND vrvSMServiceItemWithAgreement.Agreement=SMAgreementServiceTask_ItemLevel.Agreement 
		AND vrvSMServiceItemWithAgreement.Revision=SMAgreementServiceTask_ItemLevel.Revision 
		AND vrvSMServiceItemWithAgreement.Service=SMAgreementServiceTask_ItemLevel.Service 
		AND vrvSMServiceItemWithAgreement.ServiceItem=SMAgreementServiceTask_ItemLevel.ServiceItem
		and SMAgreementServiceTask_ItemLevel.ServiceItem is not null







GO
GRANT SELECT ON  [dbo].[vrvSMAgreementQuoteServiceDetails] TO [public]
GRANT INSERT ON  [dbo].[vrvSMAgreementQuoteServiceDetails] TO [public]
GRANT DELETE ON  [dbo].[vrvSMAgreementQuoteServiceDetails] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMAgreementQuoteServiceDetails] TO [public]
GO
