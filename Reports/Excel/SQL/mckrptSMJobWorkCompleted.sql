USE [Viewpoint]
GO

/****** Object:  StoredProcedure [dbo].[mckrptSMJobWorkCompleted]    Script Date: 4/14/2015 9:50:06 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =================================================================================================================================
-- Author:		Curt Salada
-- Create date: 2015-04-02
-- Description:	Reporting proc for Work Completed on SM Work Orders tied to non-company-1 jobs
-- Work Orders are opened in Astea for company 20 but since SM only operates in company 1, we can't tie the Work Orders to the jobs
-- directly in VP.  So we strip the job info from the work order in VP and encode it in the Requested By field.  This report
-- returns all Work Completed records for these work orders and extracts the Job info from the Requested By field.
-- Change History
-- Date       Author            Description
-- ---------- ----------------- ----------------------------------------------------------------------------------------------------
-- 2015-04-02 Curt Salada		Created
-- ==================================================================================================================================

CREATE PROCEDURE [dbo].[mckrptSMJobWorkCompleted] 
	@StartDate datetime = null
AS
BEGIN
	IF ((@StartDate IS NULL) OR (@StartDate > GETDATE()))
	BEGIN
		-- default to first day of current year  
		SET @StartDate = DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0)
	END  
	
    SELECT  w.WorkOrder ,
            c.WorkCompleted 'Line' ,
            SUBSTRING(w.RequestedBy, 5, 10) 'Job' ,
            SUBSTRING(w.RequestedBy, 21, 2) 'JCCo' ,
            CONVERT(VARCHAR(10), c.Date, 120) 'Date' ,
            CASE c.Type
              WHEN 1 THEN '1-Equip'
              WHEN 2 THEN '2-Labor'
              WHEN 4 THEN '4-Inventory'
              WHEN 5 THEN '5-Purchase'
              ELSE CAST(c.Type AS VARCHAR(10))
            END 'Type' ,
            c.Technician ,
            c.SMCostType ,
            c.ActualCost ,
            c.Description ,
            c.ServiceSite 'Service Site'
    FROM    SMWorkOrder w
            INNER JOIN SMWorkCompleted c ON w.SMCo = c.SMCo
                                            AND w.WorkOrder = c.WorkOrder
    WHERE   RequestedBy IS NOT NULL
			AND c.Date  >= @StartDate
    ORDER BY w.WorkOrder ,
            c.WorkCompleted

END


GO


