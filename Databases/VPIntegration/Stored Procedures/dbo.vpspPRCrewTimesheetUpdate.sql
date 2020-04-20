SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* =============================================
-- Author:		Chris Gall
-- Create date: 4/11/12
*	Modified:
-- Description:	Updates the Crew Timesheet detail record
-- =============================================*/
CREATE PROCEDURE [dbo].[vpspPRCrewTimesheetUpdate]
    (
      @Original_Key_PRCo bCompany,
      @Original_Key_Crew varchar(10),
      @Original_Key_PostDate bDate,
      @Original_Key_SheetNum int,      
      @Key_PRCo bCompany,
      @Key_Crew varchar(10),
      @Key_PostDate bDate,
      @Key_SheetNum SMALLINT,
      @Status TINYINT,
      @JCCo bCompany,
      @Job bJob,
      @Shift int,      
      @CreatedBy bVPUserName,
      @Notes varchar(max),
      @UniqueAttchID UNIQUEIDENTIFIER
    )
AS 
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON ;

        UPDATE  [dbo].[PRRH]
        SET     [PRCo] = @Key_PRCo,
				[JCCo] = @JCCo,
                [Job] = @Job,
                [PostDate] = @Key_PostDate,
                [SheetNum] = @Key_SheetNum,
                [Shift] = @Shift,
                [Status] = @Status,
                [UniqueAttchID] = @UniqueAttchID,
                [Notes] = @Notes
        WHERE   [PRCo] = @Original_Key_PRCo
                AND [Crew] = @Original_Key_Crew
                AND [PostDate] = @Original_Key_PostDate
                AND [SheetNum] = @Original_Key_SheetNum

	--Return the updated row so that the datatable is updated	           
        EXEC vpspPRCrewTimesheetGet @Key_PRCo,
            @CreatedBy, @Key_PostDate, @Key_SheetNum, @Status

END

GO
GRANT EXECUTE ON  [dbo].[vpspPRCrewTimesheetUpdate] TO [VCSPortal]
GO
