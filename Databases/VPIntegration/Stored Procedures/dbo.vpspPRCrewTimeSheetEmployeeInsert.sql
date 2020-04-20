SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Chris Gall
-- Create date: 4/16/2012
-- Description:	Inserts the record into PRRE
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRCrewTimeSheetEmployeeInsert]
	(@Key_PRCo bCompany, @Key_Crew varchar(10), @Key_PostDate bDate, @Key_SheetNum SMALLINT, 
	 @Key_Employee bEmployee, @Key_LineSeq AS VARCHAR(10), @Craft bCraft, @Class bClass,
	 @Phase1RegHrs bHrs = NULL, @Phase1OTHrs bHrs = NULL, @Phase1DblHrs bHrs = NULL,
	 @Phase2RegHrs bHrs = NULL, @Phase2OTHrs bHrs = NULL, @Phase2DblHrs bHrs = NULL,
	 @Phase3RegHrs bHrs = NULL, @Phase3OTHrs bHrs = NULL, @Phase3DblHrs bHrs = NULL,
	 @Phase4RegHrs bHrs = NULL, @Phase4OTHrs bHrs = NULL, @Phase4DblHrs bHrs = NULL,
	 @Phase5RegHrs bHrs = NULL, @Phase5OTHrs bHrs = NULL, @Phase5DblHrs bHrs = NULL,
	 @Phase6RegHrs bHrs = NULL, @Phase6OTHrs bHrs = NULL, @Phase6DblHrs bHrs = NULL,
	 @Phase7RegHrs bHrs = NULL, @Phase7OTHrs bHrs = NULL, @Phase7DblHrs bHrs = NULL,
	 @Phase8RegHrs bHrs = NULL, @Phase8OTHrs bHrs = NULL, @Phase8DblHrs bHrs = NULL)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @isLocked AS BIT, @lineSeq AS SMALLINT, @rcode INTEGER, @msg AS VARCHAR(255)
	
	SELECT 
		@isLocked = CASE WHEN PRRH.[Status] = 1 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
	FROM [dbo].[PRRH] WITH (NOLOCK)
	WHERE
		PRRH.PRCo = @Key_PRCo 
		AND PRRH.Crew = @Key_Crew
		AND PRRH.PostDate = @Key_PostDate
		AND PRRH.SheetNum = @Key_SheetNum

	IF @isLocked = 1
	BEGIN
		RAISERROR('This crew time sheet is locked down. To add records change the time sheet''s status to "Not Completed".', 16, 1)
	END
	ELSE
	BEGIN
		--If the Craft AND Class are both empty then assign the defaults from PREH for the given employee	
 		IF dbo.vpfIsNullOrEmpty(@Craft) = 1 AND dbo.vpfIsNullOrEmpty(@Class) = 1 
		BEGIN
		  SELECT @Craft = PREH.Craft, 
				 @Class = PREH.Class
		  FROM PREH
			WHERE PREH.PRCo = @Key_PRCo AND PREH.Employee = @Key_Employee	
		END
	
		--Craft Validation
		IF @Craft IS NOT NULL
		BEGIN
			EXEC @rcode = bspPRCraftVal @prco = @Key_PRCo, @craft = @Craft, @msg = @msg OUTPUT
			IF @rcode <> 0
			BEGIN
				SET @msg = 'Craft validation failed - ' + @msg
				RAISERROR(@msg, 16, 1)
				GOTO vspExit
			END
		END
		
		--Class Validation
		IF @Class IS NOT NULL
		BEGIN
			EXEC @rcode = bspPRCraftClassVal @prco = @Key_PRCo, @craft = @Craft, @class = @Class, @msg = @msg OUTPUT
			IF @rcode <> 0
			BEGIN
				SET @msg = 'Class validation failed - ' + @msg
				RAISERROR(@msg, 16, 1)
				GOTO vspExit
			END
		END
	
		-- Find the next available line seq if + or '' passed in
		IF @Key_LineSeq = '+' OR @Key_LineSeq = '' OR @Key_LineSeq IS NULL
			BEGIN
				SELECT @lineSeq = MAX(LineSeq) + 1
				FROM PRRE
				WHERE PRCo = @Key_PRCo 
					AND Crew = @Key_Crew
					AND PostDate = @Key_PostDate
					AND SheetNum = @Key_SheetNum
					AND Employee = @Key_Employee									
			END
		ELSE
			BEGIN
				-- Otherwise, convert varchar to int (FUTURE: if we allow users to enter this)
				SET @lineSeq = CAST(@Key_LineSeq AS SMALLINT)
			END
	
		IF @lineSeq IS NULL
			BEGIN
				SET @lineSeq = 1
			END
	
		INSERT INTO PRRE (
			 PRCo
			,Crew
			,PostDate
			,SheetNum
			,Employee
			,LineSeq
			,Craft
			,Class
			,Phase1RegHrs,Phase1OTHrs,Phase1DblHrs
			,Phase2RegHrs,Phase2OTHrs,Phase2DblHrs
			,Phase3RegHrs,Phase3OTHrs,Phase3DblHrs
			,Phase4RegHrs,Phase4OTHrs,Phase4DblHrs
			,Phase5RegHrs,Phase5OTHrs,Phase5DblHrs
			,Phase6RegHrs,Phase6OTHrs,Phase6DblHrs
			,Phase7RegHrs,Phase7OTHrs,Phase7DblHrs
			,Phase8RegHrs,Phase8OTHrs,Phase8DblHrs
			,TotalHrs
		)
		VALUES
		(
			 @Key_PRCo
			,@Key_Crew	
			,@Key_PostDate
			,@Key_SheetNum
			,@Key_Employee
			,@lineSeq
			,@Craft
			,@Class
			,@Phase1RegHrs,@Phase1OTHrs,@Phase1DblHrs
			,@Phase2RegHrs,@Phase2OTHrs,@Phase2DblHrs
			,@Phase3RegHrs,@Phase3OTHrs,@Phase3DblHrs
			,@Phase4RegHrs,@Phase4OTHrs,@Phase4DblHrs
			,@Phase5RegHrs,@Phase5OTHrs,@Phase5DblHrs
			,@Phase6RegHrs,@Phase6OTHrs,@Phase6DblHrs
			,@Phase7RegHrs,@Phase7OTHrs,@Phase7DblHrs
			,@Phase8RegHrs,@Phase8OTHrs,@Phase8DblHrs
			,ISNULL(@Phase1RegHrs, 0) + ISNULL(@Phase1OTHrs, 0) + ISNULL(@Phase1DblHrs, 0) +
			 ISNULL(@Phase2RegHrs, 0) + ISNULL(@Phase2OTHrs, 0) + ISNULL(@Phase2DblHrs, 0) +
			 ISNULL(@Phase3RegHrs, 0) + ISNULL(@Phase3OTHrs, 0) + ISNULL(@Phase3DblHrs, 0) +
			 ISNULL(@Phase4RegHrs, 0) + ISNULL(@Phase4OTHrs, 0) + ISNULL(@Phase4DblHrs, 0) +
			 ISNULL(@Phase5RegHrs, 0) + ISNULL(@Phase5OTHrs, 0) + ISNULL(@Phase5DblHrs, 0) +
			 ISNULL(@Phase6RegHrs, 0) + ISNULL(@Phase6OTHrs, 0) + ISNULL(@Phase6DblHrs, 0) +
			 ISNULL(@Phase7RegHrs, 0) + ISNULL(@Phase7OTHrs, 0) + ISNULL(@Phase7DblHrs, 0) +
			 ISNULL(@Phase8RegHrs, 0) + ISNULL(@Phase8OTHrs, 0) + ISNULL(@Phase8DblHrs, 0)
			
		)
    END
	 vspExit:
END


GO
GRANT EXECUTE ON  [dbo].[vpspPRCrewTimeSheetEmployeeInsert] TO [VCSPortal]
GO
