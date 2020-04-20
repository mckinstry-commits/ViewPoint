/*
After environment refresh, apply these changes to Viewpoint's out-of-the-box objects
Optimizes SMWorkOrder queries
*/

USE [Viewpoint]
GO

CREATE NONCLUSTERED INDEX [IX_vSMWorkOrder_SMCo_CustGroup_Customer]
ON [dbo].[vSMWorkOrder] ([SMCo],[CustGroup],[Customer])
INCLUDE ([ServiceSite])
GO
