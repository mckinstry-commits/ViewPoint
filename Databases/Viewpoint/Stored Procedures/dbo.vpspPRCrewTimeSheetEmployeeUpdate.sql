SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* =============================================
-- Author:		Chris Gall
-- Create date: 4/16/2012
-- Description:	Updates the record from PRRE
-- =============================================*/
CREATE PROCEDURE [dbo].[vpspPRCrewTimeSheetEmployeeUpdate]
	(@Original_Key_PRCo bCompany, @Original_Key_Crew varchar(10), @Original_Key_PostDate bDate, @Original_Key_SheetNum SMALLINT, @Original_Key_Employee bEmployee, @Original_Key_LineSeq SMALLINT, 
	@Craft bCraft, @Class bClass,
	@Phase1RegHrs bHrs, @Phase1OTHrs bHrs, @Phase1DblHrs bHrs,
	@Phase2RegHrs bHrs, @Phase2OTHrs bHrs, @Phase2DblHrs bHrs,
	@Phase3RegHrs bHrs, @Phase3OTHrs bHrs, @Phase3DblHrs bHrs,
	@Phase4RegHrs bHrs, @Phase4OTHrs bHrs, @Phase4DblHrs bHrs,
	@Phase5RegHrs bHrs, @Phase5OTHrs bHrs, @Phase5DblHrs bHrs,
	@Phase6RegHrs bHrs, @Phase6OTHrs bHrs, @Phase6DblHrs bHrs,
	@Phase7RegHrs bHrs, @Phase7OTHrs bHrs, @Phase7DblHrs bHrs,
	@Phase8RegHrs bHrs, @Phase8OTHrs bHrs, @Phase8DblHrs bHrs)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @isLocked AS BIT, @rcode INTEGER, @msg AS VARCHAR(255)
	
	SELECT 
		@isLocked = CASE WHEN PRRH.[Status] = 1 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
	FROM [dbo].[PRRH] WITH (NOLOCK)
	WHERE
		PRRH.PRCo = @Original_Key_PRCo 
		AND PRRH.Crew = @Original_Key_Crew
		AND PRRH.PostDate = @Original_Key_PostDate
		AND PRRH.SheetNum = @Original_Key_SheetNum

	IF @isLocked = 1
	BEGIN
		RAISERROR('This crew time sheet is locked down. To edit records change the time sheet''s status to "Not Completed".', 16, 1)
	END
	ELSE
	BEGIN
		--Craft Validation
		IF @Craft IS NOT NULL
		BEGIN
			EXEC @rcode = bspPRCraftVal @prco = @Original_Key_PRCo, @craft = @Craft, @msg = @msg OUTPUT
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
			EXEC @rcode = bspPRCraftClassVal @prco = @Original_Key_PRCo, @craft = @Craft, @class = @Class, @msg = @msg OUTPUT
			IF @rcode <> 0
			BEGIN
				SET @msg = 'Class validation failed - ' + @msg
				RAISERROR(@msg, 16, 1)
				GOTO vspExit
			END
		END
	
		UPDATE 
			PRRE
		SET
			 Craft = @Craft
			,Class = @Class
			,Phase1RegHrs = @Phase1RegHrs, Phase1OTHrs = @Phase1OTHrs, Phase1DblHrs = @Phase1DblHrs
			,Phase2RegHrs = @Phase2RegHrs, Phase2OTHrs = @Phase2OTHrs, Phase2DblHrs = @Phase2DblHrs
			,Phase3RegHrs = @Phase3RegHrs, Phase3OTHrs = @Phase3OTHrs, Phase3DblHrs = @Phase3DblHrs
			,Phase4RegHrs = @Phase4RegHrs, Phase4OTHrs = @Phase4OTHrs, Phase4DblHrs = @Phase4DblHrs
			,Phase5RegHrs = @Phase5RegHrs, Phase5OTHrs = @Phase5OTHrs, Phase5DblHrs = @Phase5DblHrs
			,Phase6RegHrs = @Phase6RegHrs, Phase6OTHrs = @Phase6OTHrs, Phase6DblHrs = @Phase6DblHrs
			,Phase7RegHrs = @Phase7RegHrs, Phase7OTHrs = @Phase7OTHrs, Phase7DblHrs = @Phase7DblHrs
			,Phase8RegHrs = @Phase8RegHrs, Phase8OTHrs = @Phase8OTHrs, Phase8DblHrs = @Phase8DblHrs	
			,TotalHrs = ISNULL(@Phase1RegHrs, 0) + ISNULL(@Phase1OTHrs, 0) + ISNULL(@Phase1DblHrs, 0) +
						ISNULL(@Phase2RegHrs, 0) + ISNULL(@Phase2OTHrs, 0) + ISNULL(@Phase2DblHrs, 0) +
						ISNULL(@Phase3RegHrs, 0) + ISNULL(@Phase3OTHrs, 0) + ISNULL(@Phase3DblHrs, 0) +
						ISNULL(@Phase4RegHrs, 0) + ISNULL(@Phase4OTHrs, 0) + ISNULL(@Phase4DblHrs, 0) +
						ISNULL(@Phase5RegHrs, 0) + ISNULL(@Phase5OTHrs, 0) + ISNULL(@Phase5DblHrs, 0) +
						ISNULL(@Phase6RegHrs, 0) + ISNULL(@Phase6OTHrs, 0) + ISNULL(@Phase6DblHrs, 0) +
						ISNULL(@Phase7RegHrs, 0) + ISNULL(@Phase7OTHrs, 0) + ISNULL(@Phase7DblHrs, 0) +
						ISNULL(@Phase8RegHrs, 0) + ISNULL(@Phase8OTHrs, 0) + ISNULL(@Phase8DblHrs, 0)		
		WHERE 
			PRRE.PRCo = @Original_Key_PRCo 
			AND PRRE.Crew = @Original_Key_Crew
			AND PRRE.PostDate = @Original_Key_PostDate
			AND PRRE.SheetNum = @Original_Key_SheetNum
			AND PRRE.Employee = @Original_Key_Employee
			AND PRRE.LineSeq = @Original_Key_LineSeq
    END
	 vspExit:
END
GO
GRANT EXECUTE ON  [dbo].[vpspPRCrewTimeSheetEmployeeUpdate] TO [VCSPortal]
GO
