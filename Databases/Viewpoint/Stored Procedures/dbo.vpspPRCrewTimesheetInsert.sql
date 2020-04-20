SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* =============================================
* Author:		Chris Gall
* Create date: 4/11/12
* Description:	Inserts a Crew Timesheet Detail
 =============================================*/
CREATE PROCEDURE [dbo].[vpspPRCrewTimesheetInsert]
    (
      @Key_PRCo bCompany,
      @Key_Crew varchar(10),
      @Key_PostDate bDate,
      @Key_SheetNum VARCHAR(5),
      @JCCo bCompany,
      @Job bJob,
      @Shift int,
      @CreatedBy bVPUserName,
      @CopyFromPostDate bDate,
      @CopyFromSheet VARCHAR(5),
      @CopyHours BIT,
      @Notes varchar(max),
      @UniqueAttchID UNIQUEIDENTIFIER
    )
AS 
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @Status TINYINT,
		    @CreatedOn SMALLDATETIME,
		    @rcode AS INTEGER,
			@msg AS VARCHAR(255),
			@PhaseGroup bGroup,
			@PRGroup bGroup,
			@phase1 bPhase, @phase2 bPhase, @phase3 bPhase, @phase4 bPhase, @phase5 bPhase, @phase6 bPhase, @phase7 bPhase, @phase8 bPhase
			
    SELECT  @Status = 0,
            @CreatedOn = dbo.vfDateOnly()

    IF @Key_SheetNum = '+' 
        BEGIN
            SELECT  @Key_SheetNum = ISNULL(MAX(SheetNum), 0) + 1
            FROM    PRRH WITH ( NOLOCK )
            WHERE   PRCo = @Key_PRCo
                    AND Crew = @Key_Crew
                    AND PostDate = @Key_PostDate
        END
    ELSE 
        IF NOT ( 1 <= @Key_SheetNum
                 AND @Key_SheetNum <= 32767
               ) 
            BEGIN
                RAISERROR('You must enter a number between 1 and 32,767 for sheet', 1, 16)
                GOTO vspExit
            END
		
	--JCCo validation
	IF @JCCo IS NULL
	BEGIN
		SET @msg = 'JCCo validation failed. JCCo required for Phase.'
		RAISERROR(@msg, 16, 1)
		GOTO vspExit
	END
	ELSE
	BEGIN
		EXEC @rcode = bspPRJCCompanyVal @jcco = @JCCo, @phasegrp = @PhaseGroup OUTPUT, @msg = @msg OUTPUT
		IF @rcode <> 0
		BEGIN
			SET @msg = 'JCCo validation failed - ' + @msg
			RAISERROR(@msg, 16, 1)
			GOTO vspExit
		END
	END
	
	--Crew validation
	IF @Key_Crew IS NULL
	BEGIN
		SET @msg = 'Crew validation failed. Crew required.'
		RAISERROR(@msg, 16, 1)
		GOTO vspExit
	END
	ELSE
	BEGIN
		EXEC @rcode = bspPRTSCrewVal @Key_PRCo, @Key_Crew, null, null, null, null, 
						@phase1 OUTPUT, @phase2 OUTPUT, @phase3 OUTPUT, @phase4 OUTPUT, @phase5 OUTPUT, @phase6 OUTPUT, @phase7 OUTPUT, @phase8 OUTPUT,
						@PRGroup OUTPUT, null, null, @msg OUTPUT
		IF @rcode <> 0
		BEGIN
			SET @msg = 'Crew validation failed - ' + @msg
			RAISERROR(@msg, 16, 1)
			GOTO vspExit
		END
	END
	
	-- Put the insert into a transaction in the event the copy timesheet or
	-- initialize crew fails.
	BEGIN TRAN	

	INSERT  INTO [dbo].[PRRH]
				( [PRCo],
				  [Crew],
				  [PostDate],
				  [SheetNum],
				  [PRGroup],
				  [Status],
				  [JCCo],
				  [Job],
				  [Shift],
				  [PhaseGroup],
				  [CreatedOn],
				  [CreatedBy],
				  [Notes],
				  [UniqueAttchID]
				)
		VALUES  ( @Key_PRCo,
				  @Key_Crew,
				  @Key_PostDate,
				  @Key_SheetNum,
				  @PRGroup,
				  @Status,
				  @JCCo,
				  @Job,
				  @Shift,
				  @PhaseGroup,
				  @CreatedOn,
				  @CreatedBy,
				  @Notes,
				  @UniqueAttchID
				)
                
	--Copy a timesheet if necessary
	IF ( NOT @CopyFromPostDate IS NULL
		 AND NOT @CopyFromSheet IS NULL
	   ) 
		BEGIN
			EXEC @rcode = vpspPRCrewTimesheetCopy @Key_PRCo, @Key_Crew,
				@Key_PostDate, @Key_SheetNum, @CopyFromPostDate,
				@CopyFromSheet, @CopyHours, @msg OUTPUT
				
			IF @rcode <> 0
			BEGIN
				SET @msg = 'Copy Crew Timesheet failed - ' + @msg
				ROLLBACK TRAN
				RAISERROR(@msg, 16, 1)
				GOTO vspExit
			END
		END
	ELSE
		BEGIN
			-- If not copying, default the phases to the crew
			UPDATE [dbo].[PRRH] SET
				Phase1 = @phase1,
				Phase2 = @phase2,
				Phase3 = @phase3,
				Phase4 = @phase4,
				Phase5 = @phase5,
				Phase6 = @phase6,
				Phase7 = @phase7,
				Phase8 = @phase8
			WHERE
				PRCo = @Key_PRCo
				AND Crew = @Key_Crew
				AND PostDate = @Key_PostDate
				AND SheetNum = @Key_SheetNum
				
			-- Add employees from crew (PRCW) into PRRE, this is the same stored proc V6 uses
			EXEC @rcode = bspPRTSEmplInit @Key_PRCo, @Key_Crew, @Key_PostDate, @Key_SheetNum, @JCCo, @Job, 
						@phase1, @phase2, @phase3, @phase4, @phase5, @phase6, @phase7, @phase8, 
						null/*Shift*/, @msg OUTPUT
						
			IF @rcode <> 0
			BEGIN
				SET @msg = 'Crew initialization failed - ' + @msg
				ROLLBACK TRAN
				RAISERROR(@msg, 16, 1)
				GOTO vspExit
			END
			
			-- Add equipment from crew (PRCW) into PRRQ, this is the same stored proc V6 uses
			EXEC @rcode = bspPRTSEquipInit @Key_PRCo, @Key_Crew, @Key_PostDate, @Key_SheetNum, @JCCo, @Job, 
						@phase1, @phase2, @phase3, @phase4, @phase5, @phase6, @phase7, @phase8, @msg OUTPUT
						
			IF @rcode <> 0
			BEGIN
				SET @msg = 'Equipment initialization failed - ' + @msg
				ROLLBACK TRAN
				RAISERROR(@msg, 16, 1)
				GOTO vspExit
			END
		END
		
	COMMIT TRAN	
	
	--Return the updated row so that the datatable is updated	           
    EXEC vpspPRCrewTimesheetGet @Key_PRCo,
            @CreatedBy, @Key_PostDate, @Key_SheetNum, @Status            
                
	vspExit:
END

GO
GRANT EXECUTE ON  [dbo].[vpspPRCrewTimesheetInsert] TO [VCSPortal]
GO
