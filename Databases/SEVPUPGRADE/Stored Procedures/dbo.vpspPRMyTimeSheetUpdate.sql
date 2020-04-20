SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* =============================================
-- Author:		Jacob Van Houten
-- Create date: 6/24/09
*	Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
-- Description:	Updates the header record from vPRMyTimesheet
-- =============================================*/
CREATE PROCEDURE [dbo].[vpspPRMyTimeSheetUpdate]
    (
      @PersonalTimeSheet bYN,
      @Original_Key_PRCo bCompany,
      @Original_Key_EntryEmployee bEmployee,
      @Original_Key_StartDate bDate,
      @Original_Key_Sheet VARCHAR(6),
      @Key_PRCo bCompany,
      @Key_EntryEmployee bEmployee,
      @Key_StartDate bDate,
      @Key_Sheet SMALLINT,
      @Status TINYINT,
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER
    )
AS 
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON ;

        UPDATE  [dbo].[PRMyTimesheet]
        SET     [PRCo] = @Key_PRCo,
                [EntryEmployee] = @Key_EntryEmployee,
                [StartDate] = @Key_StartDate,
                [Sheet] = @Key_Sheet,
                [Status] = @Status,
                [Notes] = @Notes,
                [UniqueAttchID] = @UniqueAttchID
        WHERE   [PRCo] = @Original_Key_PRCo
                AND [EntryEmployee] = @Original_Key_EntryEmployee
                AND [StartDate] = @Original_Key_StartDate
                AND [Sheet] = @Original_Key_Sheet

	--Return the updated row so that the datatable is updated	           
        EXEC vpspPRMyTimeSheetGet @PersonalTimeSheet, @Key_PRCo,
            @Key_EntryEmployee, @Key_StartDate, @Key_Sheet, @Status
    END

GO
GRANT EXECUTE ON  [dbo].[vpspPRMyTimeSheetUpdate] TO [VCSPortal]
GO
