SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* =============================================
* Author:		Jacob Van Houten
* Create date: 6/24/09
*	Modified date: 
* Description:	Inserts the header record from vPRMyTimeSheet
* Modification: EN 6/6/11 D-02028 when insert into PRMyTimesheetDetail, plug CreatedOn date with no timestamp by using dbo.vfDateOnly() rather than GETDATE()
				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
 =============================================*/
CREATE PROCEDURE [dbo].[vpspPRMyTimeSheetInsert]
    (
      @Key_PRCo bCompany,
      @Key_EntryEmployee bEmployee,
      @Key_StartDate bDate,
      @Key_Sheet VARCHAR(5),
      @CreatedBy bVPUserName,
      @PersonalTimeSheet bYN,
      @CopyFromStartDate bDate,
      @CopyFromSheet VARCHAR(5),
      @CopyHours BIT,
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER
    )
AS 
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON ;
	
	--Create and set defaults
        DECLARE @Status TINYINT,
            @CreatedOn SMALLDATETIME
	
        SELECT  @Status = 0,
                @CreatedOn = dbo.vfDateOnly()
	
        IF @Key_Sheet = '+' 
            BEGIN
                SELECT  @Key_Sheet = ISNULL(MAX(Sheet), 0) + 1
                FROM    PRMyTimesheet WITH ( NOLOCK )
                WHERE   PRCo = @Key_PRCo
                        AND EntryEmployee = @Key_EntryEmployee
                        AND StartDate = @Key_StartDate
            END
        ELSE 
            IF NOT ( 1 <= @Key_Sheet
                     AND @Key_Sheet <= 32767
                   ) 
                BEGIN
                    RAISERROR('You must enter a number between 1 and 32,767 for sheet', 1, 16)
                    GOTO vspExit
                END
	
        INSERT  INTO [dbo].[PRMyTimesheet]
                ( [PRCo],
                  [EntryEmployee],
                  [StartDate],
                  [Sheet],
                  [Status],
                  [CreatedOn],
                  [CreatedBy],
                  [Notes],
                  [UniqueAttchID],
                  [PersonalTimesheet]
                )
        VALUES  ( @Key_PRCo,
                  @Key_EntryEmployee,
                  @Key_StartDate,
                  @Key_Sheet,
                  @Status,
                  @CreatedOn,
                  @CreatedBy,
                  @Notes,
                  @UniqueAttchID,
                  @PersonalTimeSheet
                )
	
	--Copy a timesheet if necessary
        IF ( NOT @CopyFromStartDate IS NULL
             AND NOT @CopyFromSheet IS NULL
           ) 
            BEGIN
                EXEC vpspPRMyTimeSheetCopy @Key_PRCo, @Key_EntryEmployee,
                    @Key_StartDate, @Key_Sheet, @CopyFromStartDate,
                    @CopyFromSheet, @CreatedBy, @CreatedOn, @CopyHours
            END

	--Return the updated row so that the datatable is updated	           
        EXEC vpspPRMyTimeSheetGet @PersonalTimeSheet, @Key_PRCo,
            @Key_EntryEmployee, @Key_StartDate, @Key_Sheet, @Status
	
        vspExit:
    END

GO
GRANT EXECUTE ON  [dbo].[vpspPRMyTimeSheetInsert] TO [VCSPortal]
GO
