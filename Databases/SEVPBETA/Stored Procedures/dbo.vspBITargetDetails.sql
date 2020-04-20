SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* =============================================
-- Author:		HH TK-20362
-- Create date: 12/19/2012
-- Modified by: 
--
-- Description:	Inserts date range for BI Operational Targets Budget BITargetBudget
--
=============================================*/
CREATE PROCEDURE [dbo].[vspBITargetDetails]
	@BICo bCompany,						
	@TargetName varchar(50),						
	@Revision int = null,
	@BeginDate bDate,					
	@EndDate bDate,
	@Period int,
	@PRGroup bGroup,
	@msg varchar(255) OUTPUT			
AS
BEGIN

SET NOCOUNT ON 

IF (SELECT Period FROM BITargetHeader WHERE BICo = @BICo AND TargetName = @TargetName) <> @Period
	OR (SELECT PRGroup FROM BITargetHeader WHERE BICo = @BICo AND TargetName = @TargetName) <> @PRGroup
BEGIN
	-- Period/PRGroup changed: reset data
	DELETE 
	FROM BITargetBudget 
	WHERE BICo = @BICo
		AND TargetName = @TargetName
END
ELSE
BEGIN
	-- Trim date range
	DELETE 
	FROM BITargetBudget
	WHERE BICo = @BICo
		AND TargetName = @TargetName
		AND (TargetDate < @BeginDate OR TargetDate > @EndDate)
END

DECLARE @LastDayOfMonth bYN
DECLARE @DateCounter DATETIME

IF @Period = 5
BEGIN
	-- All revisions
	IF @Revision IS NULL
	BEGIN
	
		DECLARE allrevision_cursor CURSOR FAST_FORWARD FOR 
		SELECT DISTINCT Revision 
		FROM BITargetDetail
		WHERE BICo = @BICo
			AND TargetName = @TargetName
		ORDER BY Revision 
		
		OPEN allrevision_cursor
		FETCH NEXT FROM allrevision_cursor INTO @Revision
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			DECLARE payperiod_cursor CURSOR FAST_FORWARD FOR 
			SELECT PREndDate 
			FROM PRPC
			WHERE PRCo = @BICo
				AND PRGroup = @PRGroup
				AND PREndDate BETWEEN @BeginDate AND @EndDate
			ORDER BY PREndDate

			OPEN payperiod_cursor
			FETCH NEXT FROM payperiod_cursor INTO @DateCounter

			WHILE @@FETCH_STATUS = 0
			BEGIN

				IF NOT EXISTS(SELECT * FROM BITargetBudget WHERE BICo = @BICo 
											AND TargetName = @TargetName 
											AND Revision = @Revision
											AND TargetDate = @DateCounter)
				BEGIN
					INSERT  INTO [BITargetBudget]
							(
								[BICo]
								,[TargetName]
								,[Revision]
								,[TargetDate]
							)
					VALUES  (
								@BICo
								,@TargetName
								,@Revision
								,@DateCounter
							)
				END
				
				FETCH NEXT FROM payperiod_cursor INTO @DateCounter
				
			END
			CLOSE payperiod_cursor
			DEALLOCATE payperiod_cursor	
				
			FETCH NEXT FROM allrevision_cursor INTO @Revision
			
		END
		CLOSE allrevision_cursor
		DEALLOCATE allrevision_cursor		
		
	END -- End All revisions
	-- Specific revision
	ELSE
	BEGIN
		DECLARE payperiod_cursor CURSOR FAST_FORWARD FOR 
		SELECT PREndDate 
		FROM PRPC
		WHERE PRCo = @BICo
			AND PRGroup = @PRGroup
			AND PREndDate BETWEEN @BeginDate AND @EndDate
		ORDER BY PREndDate

		OPEN payperiod_cursor
		FETCH NEXT FROM payperiod_cursor INTO @DateCounter

		WHILE @@FETCH_STATUS = 0
		BEGIN

			IF NOT EXISTS(SELECT * FROM BITargetBudget WHERE BICo = @BICo 
										AND TargetName = @TargetName 
										AND Revision = @Revision
										AND TargetDate = @DateCounter)
			BEGIN
				INSERT  INTO [BITargetBudget]
						(
							[BICo]
							,[TargetName]
							,[Revision]
							,[TargetDate]
						)
				VALUES  (
							@BICo
							,@TargetName
							,@Revision
							,@DateCounter
						)
			END
			
			FETCH NEXT FROM payperiod_cursor INTO @DateCounter
			
		END
		CLOSE payperiod_cursor
		DEALLOCATE payperiod_cursor		
	END -- End Specific revision
END
ELSE
BEGIN
	-- All revisions
	IF @Revision IS NULL
	BEGIN
		
		DECLARE allrevision_cursor CURSOR FAST_FORWARD FOR 
		SELECT DISTINCT Revision 
		FROM BITargetDetail
		WHERE BICo = @BICo
			AND TargetName = @TargetName
		ORDER BY Revision 
		
		OPEN allrevision_cursor
		FETCH NEXT FROM allrevision_cursor INTO @Revision
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- Start the counter at the begin date
			SET @DateCounter = @BeginDate
			WHILE @DateCounter <= @EndDate
			BEGIN
				-- Set value for IsLastDayOfMonth
				IF MONTH(@DateCounter) = MONTH(DATEADD(d, 1, @DateCounter))
				   SET @LastDayOfMonth = 'N'
				ELSE
				   SET @LastDayOfMonth = 'Y'  

				-- add a record into the date dimension table for this date if not exists
				IF NOT EXISTS(SELECT * FROM BITargetBudget WHERE BICo = @BICo 
													AND TargetName = @TargetName 
													AND Revision = @Revision
													AND TargetDate = @DateCounter)
				BEGIN
					INSERT  INTO [BITargetBudget]
							(
								[BICo]
								,[TargetName]
								,[Revision]
								,[TargetDate]
							)
					VALUES  (
								@BICo
								,@TargetName
								,@Revision
								,@DateCounter
							)
				END

				-- Increment the date counter for next pass thru the loop
				SELECT @DateCounter =
					CASE @Period
						WHEN 0 THEN DATEADD(yy, 1, @DateCounter)
						WHEN 1 THEN DATEADD(qq, 1, @DateCounter)
						WHEN 2 THEN DATEADD(mm, 1, @DateCounter)
						WHEN 3 THEN DATEADD(ww, 1, @DateCounter)
						WHEN 4 THEN DATEADD(dd, 1, @DateCounter)
						ELSE DATEADD(dd, 1, @DateCounter)
					END
			END
		
			FETCH NEXT FROM allrevision_cursor INTO @Revision
		END

		CLOSE allrevision_cursor
		DEALLOCATE allrevision_cursor		
		
	END -- End All revisions
	-- Specific revision
	ELSE
	BEGIN
		-- Start the counter at the begin date
		SET @DateCounter = @BeginDate
		WHILE @DateCounter <= @EndDate
		BEGIN
			-- Set value for IsLastDayOfMonth
			IF MONTH(@DateCounter) = MONTH(DATEADD(d, 1, @DateCounter))
			   SET @LastDayOfMonth = 'N'
			ELSE
			   SET @LastDayOfMonth = 'Y'  

			-- add a record into the date dimension table for this date if not exists
			IF NOT EXISTS(SELECT * FROM BITargetBudget WHERE BICo = @BICo 
												AND TargetName = @TargetName 
												AND Revision = @Revision
												AND TargetDate = @DateCounter)
			BEGIN
				INSERT  INTO [BITargetBudget]
						(
							[BICo]
							,[TargetName]
							,[Revision]
							,[TargetDate]
						)
				VALUES  (
							@BICo
							,@TargetName
							,@Revision
							,@DateCounter
						)
			END

			-- Increment the date counter for next pass thru the loop
			SELECT @DateCounter =
				CASE @Period
					WHEN 0 THEN DATEADD(yy, 1, @DateCounter)
					WHEN 1 THEN DATEADD(qq, 1, @DateCounter)
					WHEN 2 THEN DATEADD(mm, 1, @DateCounter)
					WHEN 3 THEN DATEADD(ww, 1, @DateCounter)
					WHEN 4 THEN DATEADD(dd, 1, @DateCounter)
					ELSE DATEADD(dd, 1, @DateCounter)
				END
		  END
	END -- End Specific revision
END

END


GO
GRANT EXECUTE ON  [dbo].[vspBITargetDetails] TO [public]
GO
