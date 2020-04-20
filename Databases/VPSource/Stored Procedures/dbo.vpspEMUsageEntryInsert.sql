SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Tom Jochums
-- Create date: 02/26/2010
-- Modified:    Eric V 04/15/11 #143539, Added Rev Rate and Rev Dollars to batch record.
-- Description:	Inserts a new EM Usage Entry Line for a batch
-- =============================================
CREATE PROCEDURE [dbo].[vpspEMUsageEntryInsert]
	@Key_EMCo As bCompany, 
	@JCCo AS bCompany, 
	@Key_Mth AS bMonth, 
	@VPUserName AS bVPUserName,
	@Key_BatchId As int, 
    @EquipmentId As varchar(10),
    @Phase As varchar(20),
    @Date As datetime,
    @JCCostType As tinyint,
    @CurrentOdometer As numeric,
    @CurrentHourMeter As numeric,
    @RevTimeUnits As numeric,
    @Notes As varchar,
    @Job As varchar(10),
    @PhaseGroup As tinyint
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Batch Locked Validation
	IF NOT EXISTS(SELECT TOP 1 1 FROM HQBC (NOLOCK) WHERE Co = @Key_EMCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId AND InUseBy = @VPUserName)
	BEGIN
		RAISERROR('You must first lock the batch before being able to add EM Usage', 16, 1)
		GOTO vspExit
	END
	
	DECLARE @RevCode As char(10), @BatchSeqID As int, @EMGroup AS tinyint, @GLCo As int, 
			@errmsg As varchar(255), @TimeUM As varchar(3), @Category As varchar(10),
			@HrsPerTimeUnit As numeric(10,2), @PreviousHourMeter As numeric(10,2), 
			@PreviousOdometer As numeric(10,2), @RevRate bDollar, @RevBasis char(1),
			@RevDollars bDollar, @WorkUM bUM, @OffsetAcct bGLAcct
	
	SELECT @GLCo = GLCo, @EMGroup = EMGroup From EMCO Where EMCo = @Key_EMCo
	
	DECLARE @batchSeqResult as Table (Seq int)
	Insert into @batchSeqResult Exec bspGetNextBatchSeq @Key_EMCo, @Key_Mth, @Key_BatchId
	
	SELECT @BatchSeqID = Seq From @batchSeqResult

	--Set the key month to the first day of the month
	SET @Key_Mth = CAST(DATEPART(yyyy, @Key_Mth) AS VARCHAR) + '-' + CAST(DATEPART(mm, @Key_Mth) AS VARCHAR) + '-01'

	Exec vspEMUsePostingEquipVal @Key_EMCo, @EquipmentId, 'Y', @Category output, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, @RevCode output, Null, Null, @errmsg

	EXEC vspEMUsePostingRevCodeVal @Key_EMCo, @EMGroup, @EquipmentId, @Category, @RevCode, @JCCo, @Job, Null, 
								   null, @RevBasis output, @HrsPerTimeUnit output, null, @RevRate output, @TimeUM output, @WorkUM output, @errmsg
	
	EXEC bspEMUsageGlacctDflt @emco=@Key_EMCo,@emgroup=@EMGroup,@transtype='J',@jcco=@JCCo,@job=@Job,
		@phase=@Phase,@jcct=@JCCostType,@cost_emco=NULL,@cost_equip=NULL,@costcode=NULL,@emct=NULL,
		@glacct=@OffsetAcct output,@msg=@errmsg output
	
	SELECT @PreviousHourMeter = HourReading, @PreviousOdometer = OdoReading FROM EMEM WHERE EMCo = @Key_EMCo AND Equipment = @EquipmentId

	-- Validate Rev Code: If we don't have one for the selected equipment, we can't run calcualtions
	If @RevCode Is Null 
	Begin
		Select @errmsg = 'No Revenue Code is set for your selected Equipment: ' + @EquipmentId
		RAISERROR(@errmsg , 16, 1)
		GOTO vspExit
	End
	
	--
	If @RevTimeUnits IS Not Null And @RevTimeUnits > 0
	Begin
		Set @CurrentHourMeter = Round(@PreviousHourMeter + (@RevTimeUnits * @HrsPerTimeUnit), 2)
	End
	Else
	Begin
		Set @RevTimeUnits = Round((@CurrentHourMeter - @PreviousHourMeter) / @HrsPerTimeUnit, 3)
	End
	
	if (@RevBasis='H')
	BEGIN
		/* Calculate RevAmount using Time basis */
		If @RevTimeUnits IS Not Null And @RevTimeUnits <> 0
		BEGIN
			IF (ISNULL(@HrsPerTimeUnit,0)>0)
				SET @RevDollars = (@RevTimeUnits/@HrsPerTimeUnit) * @RevRate
			ELSE
				SET @RevDollars = @RevTimeUnits * @RevRate
		END
	END
		
	-- Check to make sure the passed in user has the batch locked
	Declare @userCheck As varchar(128)
	Select @userCheck = InUseBy FROM HQBC WHERE Co = @Key_EMCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId
	IF @userCheck <> @VPUserName
	Begin
		Select @errmsg = 'This Batch is in use by another user - ' + @userCheck
		RAISERROR(@errmsg , 16, 1)
		GOTO vspExit
	End

	-- Set the User to VCSPortal so we can leverage V6's batch editing (The logged in user is VCSPortal)
	UPDATE HQBC SET InUseBy = 'VCSPortal'
	 WHERE Co = @Key_EMCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId	
	
	INSERT INTO EMBF ( 
			  Mth, BatchId, [Co], [EMGroup], [Source]  -- 1-5
            , [BatchSeq], [BatchTransType], [EMTransType], [Equipment], [RevCode]  -- 6-10
            , [PRCo], [JCCo], [Job], [JCPhase], [JCCostType]  -- 11-15
            , [Description], [ActualDate], [GLOffsetAcct], [CurrentOdometer], [CurrentHourMeter]  -- 16-20
			, [RevTimeUnits], [RevWorkUnits], [RevRate], [RevDollars], [GLCo]  -- 21-25
			, [OffsetGLCo], [PhaseGrp], [PreviousOdometer], [PreviousHourMeter], [TimeUM]  -- 26-30
			, [UM])  -- 31
		VALUES (
			  @Key_Mth, @Key_BatchId, @Key_EMCo, @EMGroup, 'EMRev'
			, @BatchSeqID, 'A', 'J', @EquipmentId, @RevCode
			, Null, @JCCo, @Job, @Phase, @JCCostType
			, @Notes, @Date, @OffsetAcct, @CurrentOdometer, @CurrentHourMeter
			, @RevTimeUnits, 0, @RevRate, @RevDollars, @GLCo
			, @GLCo, @PhaseGroup, @PreviousOdometer, @PreviousHourMeter, @TimeUM
			, @WorkUM
		)
			
		UPDATE HQBC
		SET 
			InUseBy = @VPUserName
		WHERE Co = @Key_EMCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId	
	vspExit:	
END
GO
GRANT EXECUTE ON  [dbo].[vpspEMUsageEntryInsert] TO [VCSPortal]
GO
