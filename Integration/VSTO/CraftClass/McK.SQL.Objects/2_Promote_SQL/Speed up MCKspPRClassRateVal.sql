USE [Viewpoint]
GO

/* IMPROVE MCKspPRClassRateVal

Missing Index Details from SQLQuery54.sql - VIEWPOINTAG\Viewpoint.Viewpoint (MCKINSTRY\ArunT (389))
The Query Processor estimates that implementing the following index could improve the query cost by 62.2564%.
*/


CREATE NONCLUSTERED INDEX IYY1_mck_bPRCC
ON [dbo].[bPRCC] ([WghtAvgOT])
INCLUDE ([PRCo],[Craft],[Class])
GO


/*
Missing Index Details from SQLQuery54.sql - VIEWPOINTAG\Viewpoint.Viewpoint (MCKINSTRY\ArunT (389))
The Query Processor estimates that implementing the following index could improve the query cost by 96.8687%.
*/

CREATE NONCLUSTERED INDEX IYY2_mck_MCKPRCPLoad
ON [dbo].[MCKPRCPLoad] ([Co],[Craft],[Class],[BatchNum])
INCLUDE ([Shift])
GO


/*
Missing Index Details from MCKspPRClassRateVal.sql - VIEWPOINTAG\VIEWPOINT.Viewpoint (MCKINSTRY\leog (376))
The Query Processor estimates that implementing the following index could improve the query cost by 96.5253%.
*/

CREATE NONCLUSTERED INDEX IYY3_mck_MCKPRCDSLoad
ON [dbo].[MCKPRCDSLoad] ([Co],[Craft],[Class],[BatchNum])
INCLUDE ([DLCode],[Factor],[Rate])
GO


/*
Missing Index Details from MCKspPRClassRateVal.sql - VIEWPOINTAG\VIEWPOINT.Viewpoint (MCKINSTRY\leog (376))
The Query Processor estimates that implementing the following index could improve the query cost by 73.6901%.
*/

CREATE NONCLUSTERED INDEX IYY4_mck_MCKPRCCLoad
ON [dbo].[MCKPRCCLoad] ([Co],[Craft],[Class],[BatchNum])
GO


