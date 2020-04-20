SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* =============================================
-- Author:		Joe AmRhein
-- Create date: 4/18/12
*	Modified:
-- Description:	Updates the Crew Progress Entry record
-- =============================================*/
CREATE PROCEDURE [dbo].[vpspPRCrewProgressEntryUpdate]
    (
      @Key_PRCo bCompany,
      @Key_Crew varchar(10),
      @Key_PostDate bDate,
      @Key_SheetNum SMALLINT,
      @Key_PhaseNum SMALLINT,
	  @CostType bJCCType,
	  @Units bUnits
    )
AS 
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON ;
	
		IF @Key_PhaseNum = 1
		BEGIN
			UPDATE  [dbo].[PRRH]
			SET     [Phase1CostType] = @CostType,
					[Phase1Units] = @Units
			WHERE   [PRCo] = @Key_PRCo
					AND [Crew] = @Key_Crew
					AND [PostDate] = @Key_PostDate
					AND [SheetNum] = @Key_SheetNum
		END
		
		IF @Key_PhaseNum = 2
		BEGIN
			UPDATE  [dbo].[PRRH]
			SET     [Phase2CostType] = @CostType,
					[Phase2Units] = @Units
			WHERE   [PRCo] = @Key_PRCo
					AND [Crew] = @Key_Crew
					AND [PostDate] = @Key_PostDate
					AND [SheetNum] = @Key_SheetNum
		END
		
		IF @Key_PhaseNum = 3
		BEGIN
			UPDATE  [dbo].[PRRH]
			SET     [Phase3CostType] = @CostType,
					[Phase3Units] = @Units
			WHERE   [PRCo] = @Key_PRCo
					AND [Crew] = @Key_Crew
					AND [PostDate] = @Key_PostDate
					AND [SheetNum] = @Key_SheetNum
		END
		
		IF @Key_PhaseNum = 4
		BEGIN
			UPDATE  [dbo].[PRRH]
			SET     [Phase4CostType] = @CostType,
					[Phase4Units] = @Units
			WHERE   [PRCo] = @Key_PRCo
					AND [Crew] = @Key_Crew
					AND [PostDate] = @Key_PostDate
					AND [SheetNum] = @Key_SheetNum
		END
		
		IF @Key_PhaseNum = 5
		BEGIN
			UPDATE  [dbo].[PRRH]
			SET     [Phase5CostType] = @CostType,
					[Phase5Units] = @Units
			WHERE   [PRCo] = @Key_PRCo
					AND [Crew] = @Key_Crew
					AND [PostDate] = @Key_PostDate
					AND [SheetNum] = @Key_SheetNum
		END
		
		IF @Key_PhaseNum = 6
		BEGIN
			UPDATE  [dbo].[PRRH]
			SET     [Phase6CostType] = @CostType,
					[Phase6Units] = @Units
			WHERE   [PRCo] = @Key_PRCo
					AND [Crew] = @Key_Crew
					AND [PostDate] = @Key_PostDate
					AND [SheetNum] = @Key_SheetNum
		END
		
		IF @Key_PhaseNum = 7
		BEGIN
			UPDATE  [dbo].[PRRH]
			SET     [Phase7CostType] = @CostType,
					[Phase7Units] = @Units
			WHERE   [PRCo] = @Key_PRCo
					AND [Crew] = @Key_Crew
					AND [PostDate] = @Key_PostDate
					AND [SheetNum] = @Key_SheetNum
		END
		
		IF @Key_PhaseNum = 8
		BEGIN
			UPDATE  [dbo].[PRRH]
			SET     [Phase8CostType] = @CostType,
					[Phase8Units] = @Units
			WHERE   [PRCo] = @Key_PRCo
					AND [Crew] = @Key_Crew
					AND [PostDate] = @Key_PostDate
					AND [SheetNum] = @Key_SheetNum
		END
	--Return the updated row so that the datatable is updated	           
        EXEC vpspPRCrewProgressEntryGet @Key_PRCo, @Key_Crew, @Key_PostDate, @Key_SheetNum, @Key_PhaseNum

END

GO
GRANT EXECUTE ON  [dbo].[vpspPRCrewProgressEntryUpdate] TO [VCSPortal]
GO
