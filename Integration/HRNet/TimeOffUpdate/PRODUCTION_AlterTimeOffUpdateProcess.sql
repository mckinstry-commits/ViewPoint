USE McK_HRDB
go

SELECT * into EmployeeTimeOff_20141109 FROM dbo.EmployeeTimeOff 
SELECT * into TimeOffHistory_20141109 FROM dbo.TimeOffHistory
SELECT * into TimeOffHistoryLog_20141109 FROM dbo.TimeOffHistoryLog
SELECT * into TimeOffHistoryLogAutoInsert_20141109 FROM dbo.TimeOffHistoryLogAutoInsert
SELECT * into TimeOffHistoryLogHoursAdjust_20141109 FROM dbo.TimeOffHistoryLogHoursAdjust
go


USE HRNET
go

--Viewpoint to HRDB Update of PTO Actuals taken
--Run AS "Time Off Transfer From CGC" Scheduled job ON SESQL08
--Need to be implemented after Union Vacation changes.

--Task 1	
USE [McK_HRDB_TransferData]
GO

DECLARE @WeekEnding DATETIME
DECLARE @intWeekEnding INT
IF @WeekEnding IS NULL
BEGIN
	SET @WeekEnding		=	CAST(CONVERT(VARCHAR(10), DATEADD(d, -7, dbo.fnWeekEnding(GETDATE())), 111) AS DATETIME)
END
SET @intWeekEnding		=	CAST(CONVERT(VARCHAR(8),@WeekEnding,112) AS INT)

--print @intWeekEnding
--	CAST(DATEPART(yyyy,@WeekEnding) AS VARCHAR(4))
--+	CAST(RIGHT('0' + CONVERT(VARCHAR(2), DATEPART(mm,@WeekEnding)),2) AS CHAR(2))
--+	CAST(RIGHT('0' + CONVERT(VARCHAR(2), DATEPART(dd,@WeekEnding)),2) AS CHAR(2)) 


DELETE FROM McK_HRDB_TransferData.dbo.PRPTCH WHERE CHDTWE = @intWeekEnding

INSERT INTO McK_HRDB_TransferData.dbo.PRPTCH (CHEENO, CHOTHR, CHOTTY, CHDTWE) 
SELECT 
	t1.CHEENO
,	t1.CHOTHR
,	t1.CHOTTY
,	t1.CHDTWE
FROM
(
SELECT 
	CAST(prth.Employee AS int) AS CHEENO
,	cast(CASE 
		WHEN hqet.Description IN ('Other Earnings') THEN SUM(prth.Hours)
		ELSE 0
	END AS decimal(18,2)) AS CHOTHR
,	CAST(COALESCE(ecm.ShortCode,'') AS VARCHAR(10)) AS CHOTTY	
,	CAST(COALESCE(CONVERT(CHAR(8),prth.PREndDate, 112),0) AS int) AS CHDTWE
FROM 
	[VIEWPOINTAG\VIEWPOINT].Viewpoint.dbo.mvwPRTH prth JOIN
	[VIEWPOINTAG\VIEWPOINT].Viewpoint.dbo.bPREH preh ON
		prth.PRCo=preh.PRCo
	AND prth.PRGroup=preh.PRGroup
	AND prth.Employee=preh.Employee JOIN
	[VIEWPOINTAG\VIEWPOINT].Viewpoint.dbo.PREC prec ON
		prth.PRCo=prec.PRCo
	AND prth.EarnCode=prec.EarnCode JOIN
	[VIEWPOINTAG\VIEWPOINT].Viewpoint.dbo.HQET hqet ON
		prec.EarnType=hqet.EarnType LEFT OUTER JOIN
	 HRNET.mnepto.EarnCodeMap  ecm ON
		prth.PRCo=ecm.PRCo
	AND CAST(prth.EarnCode AS VARCHAR(10))=CAST(ecm.EarnCode AS VARCHAR(10)) COLLATE Latin1_General_CI_AS  JOIN	
	[VIEWPOINTAG\VIEWPOINT].Viewpoint.dbo.HQCO hqco ON
		prth.PRCo=hqco.HQCo
WHERE
	LTRIM(RTRIM(ecm.ShortCode)) <> '' 
and	prth.udArea IS NOT NULL
OR  ( 
		prec.Description IN (SELECT DISTINCT Description  FROM [VIEWPOINTAG\VIEWPOINT].Viewpoint.dbo.PREC WHERE EarnType IN (6,7)  )
	) 	
GROUP BY
	prth.Employee
,	hqet.Description
,	ecm.ShortCode 		
,	prth.PREndDate			
) t1 
WHERE 
	CHDTWE = @intWeekEnding  AND LEN(CHOTTY) > 0
 
 
 --Task 2
USE [McK_HRDB_TransferData]
GO

DECLARE	@return_value int

EXEC	@return_value = [dbo].[spCGCDATA_UpdateHoursUsedv3]
		@WeekEnding = NULL

SELECT	'Return Value' = @return_value

GO

-- embedded procedure
--sp_helptext [spCGCDATA_UpdateHoursUsedv3]
  
  
ALTER PROCEDURE [dbo].[spCGCDATA_UpdateHoursUsedv3]  
 @WeekEnding DATETIME = NULL  
AS  
  
SET NOCOUNT ON  
DECLARE @PrintOutput VARCHAR(4000)  
DECLARE @intWeekEnding INT  
DECLARE @DateStamp  DATETIME  
DECLARE @BatchId  VARCHAR(36)  
DECLARE @LocalError  INT  
DECLARE @ErrMsg   VARCHAR(100)   
DECLARE @intGroup  INT  
DECLARE @Counter  INT  
DECLARE @RowCount  VARCHAR(100)  
DECLARE @HRDB   TABLE(  
  EmployeeId  INT  
 , HoursRequested DECIMAL(18, 2)  
 , TimeOffTypeId VARCHAR(10)  
 , EmployeeName VARCHAR(50)  
 , StartDate  DATETIME  
 , EndDate   DATETIME  
 , WeekEnding  DATETIME  
 , CGCWeekStarting INT  
 , CGCWeekEnding INT  
 , Id    INT  
 , HRDBHoursUsed DECIMAL(18,2)  
)  
DECLARE @CGC   TABLE(  
 EmployeeID   INT  
, CGCHoursUsed  DECIMAL(18,2)  
, timeOffTypeId  VARCHAR(10)  
, WeekEnding   INT  
, ID     INT IDENTITY(1,1) NOT NULL  
)  
  
IF @WeekEnding IS NULL  
BEGIN  
 SET @WeekEnding  = CAST(CONVERT(VARCHAR(10), DATEADD(d, -7, dbo.fnWeekEnding(GETDATE())), 111) AS DATETIME)  
END  
  
SET @PrintOutput  = ''   
--SET @intWeekEnding  = CAST(DATEPART(yyyy,@WeekEnding) AS VARCHAR(4))+CAST(RIGHT('0' + CONVERT(VARCHAR(2), DATEPART(mm,@WeekEnding)),2) AS CHAR(2))+CAST(RIGHT('0' + CONVERT(VARCHAR(2), DATEPART(dd,@WeekEnding)),2) AS CHAR(2))   
SET @intWeekEnding		=	CAST(CONVERT(VARCHAR(8),@WeekEnding,112) AS INT)

SET @DateStamp   = GETDATE()  
SET @BatchId   = NEWID()  
SET @Counter   = 1  
  
IF DATEPART(dw,@WeekEnding) <> 1  
BEGIN  
 PRINT 'Please use a pay period date.'  
 SET @PrintOutput = @PrintOutput + 'Please use a pay period date.\n '  
END  
ELSE  
BEGIN  
 PRINT CAST(@intWeekEnding AS VARCHAR(100))  
 /********************************************************************************  
  * Get Time Off History for Approved (NOT WR) for a Weekending Period   
  ********************************************************************************/  
 INSERT INTO @HRDB  
 SELECT  
  vw.EmployeeId  
 , vw.HoursRequested  
 , vw.TimeOffTypeId  
 , vw.FirstName + SPACE(1) + vw.LastName AS EmployeeName  
 , vw.StartDate  
 , vw.EndDate  
 , dbo.fnWeekEnding(vw.EndDate) WeekEnding  
 , CAST(DATEPART(yyyy,vw.StartDate) AS VARCHAR(4))+CAST(RIGHT('0' + CONVERT(VARCHAR(2), DATEPART(mm,vw.StartDate)),2) AS CHAR(2))+CAST(RIGHT('0' + CONVERT(VARCHAR(2), DATEPART(dd,vw.StartDate)),2) AS CHAR(2)) AS CGCWeekStarting  
 , CAST(DATEPART(yyyy,dbo.fnWeekEnding(vw.EndDate)) AS VARCHAR(4))+CAST(RIGHT('0' + CONVERT(VARCHAR(2), DATEPART(mm,dbo.fnWeekEnding(vw.EndDate))),2) AS CHAR(2))+CAST(RIGHT('0' + CONVERT(VARCHAR(2), DATEPART(dd,dbo.fnWeekEnding(vw.EndDate))),2) AS CHAR(2)
) AS CGCWeekEnding  
 , vw.Id  
 , vw.HoursUsed  
 FROM  
   McK_HRDB.dbo.vwTimeOffHistoryAudit vw  
 WHERE  
  [Status] = 'Approved'  
  AND TimeOffTypeId <> 'WR'  
  AND @WeekEnding BETWEEN dbo.fnWeekEnding(vw.Startdate) AND dbo.fnWeekEnding(vw.EndDate)  
    
 /********************************************************************************  
  * Get Payroll Time Off data from CGC for a Weekending Period   
  ********************************************************************************/  
  PRINT 'start @CGC'  
  INSERT INTO @CGC  
  SELECT  
  CHEENO   
 , SUM(CHOTHR)  
 , CHOTTY   
 , CHDTWE   
 FROM  
  PRPTCH   
 WHERE  
  CHDTWE = @intWeekEnding  
  AND LEN(CHOTTY) > 0  
 GROUP BY  
  CHEENO  
 , CHOTTY  
 , CHDTWE  
  PRINT 'end @CGC'  
    /********************************************************************************  
 * Get All Time Off Requests in a week ending period  
 ********************************************************************************/  
  PRINT 'start TimeOffHistoryLogAutoInsert'  
 INSERT INTO McK_HRDB.dbo.TimeOffHistoryLogAutoInsert  
 SELECT  
  CHEENO --AS EmployeeId  
 , CHOTHR --AS HoursUsed  
 , CHOTTY --AS TimeOffType  
 , CHDTWE --AS WeekEnding  
 , @BatchId  
 , GETDATE()  
 FROM  
  PRPTCH   
 WHERE  
  LEN(CHOTTY) > 0  
  AND CHDTWE = @intWeekEnding  
  PRINT 'end TimeOffHistoryLogAutoInsert'  
 SET @RowCount = CAST(@@ROWCOUNT AS VARCHAR(100))  
 PRINT 'TimeOffHistoryLogAutoInsert Insert ' + @RowCount  
 SET @PrintOutput = @PrintOutput + '\n TimeOffHistoryLogAutoInsert Insert ' + @RowCount  
 /********************************************************************************  
 * Begin Transaction  
 * NOTE TRANSACTIONS MAY FAIL IS SOME CASES  
 ********************************************************************************/  
   
 PRINT 'Begining Transaction for pay period: ' + CAST(@WeekEnding AS VARCHAR(20))  
 SET @PrintOutput = @PrintOutput + 'Begining Transaction for pay period: ' + CAST(@WeekEnding AS VARCHAR(20)) + '\n '  
 --BEGIN TRANSACTION  
   /********************************************************************************  
 *  Merge @CGC and @HRDB and insert into log to show what   
 *  records are being updated  
 ********************************************************************************/  
 INSERT INTO McK_HRDB.dbo.TimeOffHistoryLog  
 (  
  HRDB_Group_Row_Num  
 , HRDB_EmpId  
 , HRDB_ID  
 , HRDB_HoursRequested  
 , HRDB_TimeOffType  
 , HRDB_EmployeeName  
 , HRDB_StartDate  
 , HRDB_EndDate  
 , HRDB_WeekEnding  
 , HRDB_intWeekStarting  
 , HRDB_intWeekEnding  
 , CGC_Group_Row_Num  
 , CGC_TimeOffType  
 , CGC_WeekEnding  
 , HRDB_HoursUsed  
 , CGC_HoursUsed  
 , BatchId  
 , DateStamp  
 )  
 SELECT   
  hrdb.Group_Row_Number  
 , hrdb.EmployeeId  
 , hrdb.Id  
 , hrdb.HoursRequested  
 , hrdb.TimeOffTypeId  
 , hrdb.EmployeeName  
 , hrdb.StartDate  
 , hrdb.EndDate  
 , hrdb.WeekEnding  
 , hrdb.CGCWeekStarting  
 , hrdb.CGCWeekEnding  
 , cgc.Group_Row_Number  
 , cgc.timeOffTypeId  
 , cgc.WeekEnding  
 , hrdb.HRDBHoursUsed  
 , cgc.CGCHoursUsed  
 , @BatchId  
 , @DateStamp  
 FROM (  
   SELECT   
    ROW_NUMBER() OVER (PARTITION BY employeeName, TimeOffTypeId, WeekEnding ORDER BY ID) AS Group_Row_Number  
   , *  
   FROM   
    @HRDB  
  ) hrdb  
  INNER JOIN (  
   SELECT   
    ROW_NUMBER() OVER(PARTITION BY EmployeeID, TimeOffTypeId,WeekEnding ORDER BY [EmployeeID]) AS Group_Row_Number  
   , *  
   FROM  
    @CGC  
    ) cgc ON   
     cgc.EmployeeId = hrdb.EmployeeId   
     AND cgc.WeekEnding BETWEEN  hrdb.CGCWeekStarting AND hrdb.CGCWeekEnding  
     AND cgc.TimeOffTypeId = hrdb.TimeOffTypeId  
     AND hrdb.[Group_Row_Number] = cgc.[Group_Row_Number]  
       
   
 SET @RowCount = CAST(@@ROWCOUNT AS VARCHAR(100))  
 PRINT 'TimeOffHistoryLog Insert: ' + @RowCount  
 SET @PrintOutput = @PrintOutput +'TimeOffHistoryLog Insert: ' + @RowCount + '\n '  
 SET @LocalError = @@error  
    IF @LocalError <> 0   
    BEGIN  
  SET @ErrMsg = 'Failure at "Merge @CGC and @HRDB and insert into log to show what..."'  
  SET @PrintOutput = @PrintOutput +'Failure at "Merge @CGC and @HRDB and insert into log to show what..."\n '  
  GOTO ERR_HANDLER  
    END  
      
      
   /********************************************************************************  
    * Update TimeOffHistory from TimeOffHistoryLog  
 ********************************************************************************/  
 --SELECT @intGroup = MAX(HRDB_Group_Row_Num) FROM TimeOffHistoryLog WHERE BatchId = @BatchId  
  
 --WHILE @Counter <= @intGroup  
 --BEGIN  
   
 UPDATE  
  McK_HRDB.dbo.TimeOffHistory  
 SET  
  HoursUsed = t.HoursUsed + tl.[CGC_HoursUsed]  
 FROM  
  McK_HRDB.dbo.TimeOffHistory t  
  INNER JOIN McK_HRDB.dbo.TimeOffHistoryLog tl ON t.ID = tl.HRDB_ID  
 WHERE   
  BatchId = @BatchId  
  AND tl.HRDB_Group_Row_Num = 1--@Counter  
  AND t.HoursUsed <> t.HoursRequested  
   
 SET @RowCount = CAST(@@ROWCOUNT AS VARCHAR(100))  
 PRINT 'Update TimeOffHistory from TimeOffHistoryLog: ' + @RowCount  
 SET @PrintOutput = @PrintOutput +'Update TimeOffHistory from TimeOffHistoryLog: ' + @RowCount + '\n '  
   
 SET @LocalError = @@error  
    IF @LocalError <> 0   
    BEGIN  
  SET @ErrMsg = 'Failure at "Update TimeOffHistory from TimeOffHistoryLog"'  
  SET @PrintOutput = @PrintOutput + 'Failure at "Update TimeOffHistory from TimeOffHistoryLog"' + '\n '  
  GOTO ERR_HANDLER  
    END  
     
 -- PRINT 'Executed ' + @BatchId + ' ' + CAST(@Counter AS VARCHAR(10)) + 'Loop 1'  
 -- SET @Counter = @Counter+ 1  
 --END  
   
   
  
   /********************************************************************************  
 * Merge/insert dataset where multiple time-off taken in a week were one was updated  
 * and the other wasn't  
 ********************************************************************************/  
 INSERT INTO McK_HRDB.dbo.TimeOffHistoryLogHoursAdjust  
 SELECT   
  OverHours.ID  
 , UNDERHOURS.ID AS UnderID  
 , OverHours.HoursRequested  
 , OverHours.HoursUsed  
 , UnderHours.HoursRequested AS UnderHoursRequested  
 , OverHours.HoursUsed-OverHours.HoursRequested AS UnderHoursCalc  
 , @BatchId  
 , GETDATE()  
 FROM(  
   SELECT  
    *  
   FROM  
    McK_HRDB.dbo.TimeOffHistory  
   WHERE  
    @WeekEnding BETWEEN dbo.fnWeekEnding(Startdate) AND dbo.fnWeekEnding(EndDate)  
    AND [HoursUsed] > [HoursRequested]  
    AND Status = 'Approved'  
    ) OverHours  
    INNER JOIN (  
   SELECT  
    *  
   FROM  
    McK_HRDB.dbo.TimeOffHistory  
   WHERE  
    @WeekEnding BETWEEN dbo.fnWeekEnding(Startdate) AND dbo.fnWeekEnding(EndDate)  
    AND [HoursUsed] =0  
    AND Status = 'Approved'  
   ) UNDERHOURS ON OverHours.[EmployeeID] = UNDERHOURS.[EmployeeID]  
    AND OverHours.[TimeOffTypeID] = UNDERHOURS.[TimeOffTypeID]  
    AND DATEPART(week,OverHours.StartDate)=DATEPART(week,UnderHours.StartDate)  
  
 SET @RowCount = CAST(@@ROWCOUNT AS VARCHAR(100))      
 PRINT 'TimeOffHistoryLogHoursAdjust Insert: ' + @RowCount  
 SET @PrintOutput = @PrintOutput + 'TimeOffHistoryLogHoursAdjust Insert: ' + @RowCount + '\n '  
   
 SET @LocalError = @@error  
    IF @LocalError <> 0   
    BEGIN  
  SET @ErrMsg = 'Failure at "Merge/insert dataset where multiple time-off taken in a week were one was updated..."'  
  SET @PrintOutput = @PrintOutput + 'Failure at "Merge/insert dataset where multiple time-off taken in a week were one was updated..."\n '  
  GOTO ERR_HANDLER  
    END  
      
      
          
   /********************************************************************************  
 * Update Time Off History where in multiple Time Off Request updated one's hours used (1)  
 * exceeded hours requested.   
 ********************************************************************************/  
 --UPDATE  
 -- McK_HRDB.dbo.[TimeOffHistory]  
 --SET  
 -- HoursUsed = v.OverHoursRequested  
 --FROM  
 -- McK_HRDB.dbo.[TimeOffHistory] t  
 -- INNER JOIN McK_HRDB.dbo.TimeOffHistoryLogHoursAdjust v ON t.ID = v.OverHoursID  
 --WHERE  
 -- v.BatchId = @BatchId  
   
 --SET @RowCount = CAST(@@ROWCOUNT AS VARCHAR(100))  
 --PRINT 'Update Time Off History where in multiple Time Off 01: ' + @RowCount  
 --SET @PrintOutput = @PrintOutput + 'Update Time Off History where in multiple Time Off 01: ' + @RowCount + '\n '  
   
 --SET @LocalError = @@error  
 --   IF @LocalError <> 0   
 --   BEGIN  
 -- SET @ErrMsg = 'Failure at "Update Time Off History where in multiple Time Off Request updated one''s hours used (1)..."'  
 -- SET @PrintOutput = @PrintOutput + 'Failure at "Update Time Off History where in multiple Time Off Request updated one''s hours used (1)..."\n '  
 -- GOTO ERR_HANDLER  
 --   END  
    
   
   
   /********************************************************************************  
 * Update Time Off History where in multiple Time Off Request updated one's hours used (2)  
 * from another request exceeded hours.  
 ********************************************************************************/  
 --UPDATE  
 -- McK_HRDB.dbo.[TimeOffHistory]  
 --SET  
 -- HoursUsed = v.UnderHoursCalc  
 --FROM  
 -- McK_HRDB.dbo.[TimeOffHistory] t  
 -- INNER JOIN McK_HRDB.dbo.TimeOffHistoryLogHoursAdjust v ON t.ID = v.UnderHoursID  
 --WHERE  
 -- v.BatchId = @BatchId  
   
 --SET @RowCount = CAST(@@ROWCOUNT AS VARCHAR(100))  
 --PRINT 'Update Time Off History where in multiple Time Off 02: ' + @RowCount  
 --SET @PrintOutput = @PrintOutput + 'Update Time Off History where in multiple Time Off 02: ' + @RowCount + '\n '  
   
 --SET @LocalError = @@error  
 --   IF @LocalError <> 0   
 --   BEGIN  
 -- SET @ErrMsg = 'Failure at "Update Time Off History where in multiple Time Off Request updated one''s hours used (2)..."'  
 -- SET @PrintOutput = @PrintOutput + 'Failure at "Update Time Off History where in multiple Time Off Request updated one''s hours used (2)..."\n '  
 -- GOTO ERR_HANDLER  
 --   END  
   
   
   
   /********************************************************************************  
 * Complete Time Off where Hours Requested equals Hours Used  
 ********************************************************************************/  
 UPDATE  
  McK_HRDB.dbo.TimeOffHistory  
 SET  
  Status = 'Complete'  
 WHERE  
  HoursUsed = HoursRequested  
  AND Status <> 'Complete'  
  AND dbo.fnWeekEnding(EndDate)= @WeekEnding  
   
 SET @RowCount = CAST(@@ROWCOUNT AS VARCHAR(100))  
 PRINT 'Complete Time Off: ' + @RowCount  
 SET @PrintOutput = @PrintOutput + 'Complete Time Off: ' + @RowCount + '\n '  
   
 SET @LocalError = @@error  
    IF @LocalError <> 0   
    BEGIN  
  SET @ErrMsg = 'Failure at "Complete Time Off where Hours Requested equals Hours Used"'  
  SET @PrintOutput = @PrintOutput + 'Failure at "Complete Time Off where Hours Requested equals Hours Used"\n '  
  GOTO ERR_HANDLER  
    END  
      
     
       
   /********************************************************************************  
 * Insert reports from CGC that does not exists in HRDB  
 ********************************************************************************/  
 INSERT INTO McK_HRDB.dbo.[TimeOffHistory] (  
  [EmployeeID]  
 , [TimeOffTypeID]  
 , [Year]  
 , [StartDate]  
 , [EndDate]  
 , [HoursRequested]  
 , [HoursUsed]  
 , [Status]  
 , [Comments]  
 , [DateApproved]  
 , [DateCreated]  
 , [DateModified]  
  )   
 SELECT  
  CHEENO AS EmployeeId  
 , CHOTTY AS TimeOffType  
 , YEAR(dbo.fn_McK_convert_cgc_date(tch.CHDTWE))  
 , dbo.fn_McK_convert_cgc_date(tch.CHDTWE)   
 , dbo.fn_McK_convert_cgc_date(tch.CHDTWE)   
 , CHOTHR AS HoursUsed  
 , CHOTHR AS HoursUsed  
 , 'Complete'  
 , 'Auto loaded from CGC'  
 , @DateStamp  
 , @DateStamp  
 , @DateStamp  
 FROM  
  McK_HRDB.dbo.TimeOffHistoryLogAutoInsert tch  
  INNER JOIN McK_HRDB.dbo.PersonnelInformation p ON tch.CHEENO = p.EmpID  
 WHERE  
  NOT EXISTS (  
   SELECT   
    *  
   FROM McK_HRDB.dbo.[TimeOffHistory] t   
   WHERE  
    tch.CHEENO = t.EmployeeId  
    AND tch.CHOTTY = t.TimeOffTypeId  
    AND dbo.fn_McK_convert_cgc_date(tch.chdtwe)   
     BETWEEN dbo.fnWeekEnding(StartDate) AND dbo.fnWeekEnding(EndDate)  
  )  
  AND CHOTTY IN ('PT','VA')  
  AND BatchId = @BatchId  
   
 SET @RowCount = CAST(@@ROWCOUNT AS VARCHAR(100))  
 PRINT 'Auto Load from CGC: ' + @RowCount  
 SET @PrintOutput = @PrintOutput + 'Auto Load from CGC: ' + @RowCount + '\n '  
   
 SET @LocalError = @@error  
    IF @LocalError <> 0   
    BEGIN  
  SET @ErrMsg = 'Failure at "Insert reports from CGC that does not exists in HRDB"'  
  SET @PrintOutput = @PrintOutput + 'Failure at "Insert reports from CGC that does not exists in HRDB"\n '  
  GOTO ERR_HANDLER  
    END  
      
  /********************************************************************************  
  * Clear Table Variables  
  *********************************************************************************/  
 DELETE FROM @HRDB  
 DELETE FROM @CGC  
   
 --COMMIT TRANSACTION  
 PRINT 'Transaction Committed for pay period: ' + CAST(@WeekEnding AS VARCHAR(20))  
 SET @PrintOutput = @PrintOutput + 'Transaction Committed for pay period: ' + CAST(@WeekEnding AS VARCHAR(20)) + '\n '  
 PRINT 'TRANSACTION WAS DISABLED'  
 SET @PrintOutput = @PrintOutput + 'TRANSACTION WAS DISABLED' + '\n '  
 INSERT INTO TransferLog (MESSAGE) VALUES (@PrintOutput)  
 /********************************************************************************  
  * Roll back everything  
  *********************************************************************************/  
 ERR_HANDLER:  
    IF @LocalError <> 0   
        BEGIN  
            SELECT @ErrMsg AS ErrMsg  
            --ROLLBACK  
        END  
   
 SET NOCOUNT OFF  
RETURN( @LocalError )  
   
END  
GO
  
  
  