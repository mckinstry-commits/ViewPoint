SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* CREATED:	    
* MODIFIED:	AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-  
*           EricV 04/15/11 #143539, Added Rev Rate and Rev Dollars to batch record.
*
* Purpose:

* returns 1 and error msg if failed
*
*************************************************************************/
CREATE PROCEDURE [dbo].[vpspEMUsageEntryUpdate]
	@Key_EMCo As bCompany, 
	@Key_Mth AS bMonth, 
	@VPUserName AS bVPUserName,
	@Key_BatchId As int, 
	@Key_BatchSequence As int,
    @EquipmentId As varchar(10),
    @Phase As varchar(20),
    @Date As datetime,
    @JCCostType As tinyint,
    @CurrentOdometer As numeric,
    @CurrentHourMeter As numeric,
    @RevTimeUnits As numeric,
    @Notes As varchar,
    @JCCo AS bCompany,
    @Job As varchar(10)
As
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Batch is Open Validation
	IF NOT EXISTS(SELECT TOP 1 1 FROM HQBC (NOLOCK) WHERE Co = @Key_EMCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId AND [Status] = 0)
	BEGIN
		RAISERROR('Cannot update. Batch is not in the Open status.', 16, 1)
		GOTO vspExit
	END
	
	-- Batch Locked Validation
	IF NOT EXISTS(SELECT TOP 1 1 FROM HQBC (NOLOCK) WHERE Co = @Key_EMCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId AND InUseBy = @VPUserName)
	BEGIN
		RAISERROR('You must first lock the batch before being able to add EM Usage', 16, 1)
		GOTO vspExit
	END
	
	--#142350 - removing @errMsg AS VARCHAR(255),
	DECLARE @EMGroup AS tinyint,
			@Category AS varchar(10),
			@HrsPerTimeUnit AS numeric(10, 2),
			@PreviousHourMeter AS numeric(10, 2),
			@PreviousOdometer AS numeric(10, 2),
			@TimeUM AS varchar(3),
			@SavedHourMeter AS numeric(10, 2),
			@SavedTimeUnits AS numeric(10, 2), 
			@RevRate bDollar, 
			@RevBasis char(1),
			@RevDollars bDollar, 
			@WorkUM bUM,
			@OffsetAcct bGLAcct,
			@GLCo bCompany
	
	--Set the key month to the first day of the month
	SET @Key_Mth = CAST(DATEPART(yyyy, @Key_Mth) AS VARCHAR) + '-' + CAST(DATEPART(mm, @Key_Mth) AS VARCHAR) + '-01'

	Declare @userCheck As varchar(128), @RevCode As varchar(10), @errmsg As varchar(255)
	Select @userCheck = InUseBy FROM HQBC WHERE Co = @Key_EMCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId
	IF @userCheck <> @VPUserName
	Begin
		Declare @errorMessage as varchar(255)
		Select @errorMessage = 'This Batch is in use by another user - ' + @userCheck
		RAISERROR(@errorMessage , 16, 1)
		GOTO vspExit
	End

	SELECT @SavedHourMeter = CurrentHourMeter
         , @SavedTimeUnits = RevTimeUnits
	  FROM EMBF
	 WHERE Co = @Key_EMCo 
	   AND Mth = @Key_Mth 
	   AND BatchId = @Key_BatchId 
	   AND BatchSeq = @Key_BatchSequence


	UPDATE HQBC SET  InUseBy = 'VCSPortal'
	WHERE Co = @Key_EMCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId
	
	SELECT @GLCo = GLCo, @EMGroup = EMGroup From EMCO Where EMCo = @Key_EMCo

	Exec vspEMUsePostingEquipVal @Key_EMCo, @EquipmentId, 'Y', @Category output, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, @RevCode output, Null, Null, @errmsg

	EXEC vspEMUsePostingRevCodeVal @Key_EMCo, @EMGroup, @EquipmentId, @Category, @RevCode, @JCCo, @Job, Null, 
								   null, @RevBasis output, @HrsPerTimeUnit output, null,@RevRate output, @TimeUM output, @WorkUM output, @errmsg
	
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
	
	If @RevTimeUnits IS Not Null And @RevTimeUnits > 0 AND @RevTimeUnits <> @SavedTimeUnits
	Begin
		Set @CurrentHourMeter = Round(@PreviousHourMeter + (@RevTimeUnits * @HrsPerTimeUnit), 2)
	End
	Else If @CurrentHourMeter <> @SavedHourMeter
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

	UPDATE EMBF SET 
	       Equipment = @EquipmentId
	     , JCPhase = @Phase
	     , ActualDate = @Date 
	     , JCCostType = @JCCostType
	     , CurrentOdometer = @CurrentOdometer
         , CurrentHourMeter = @CurrentHourMeter
         , RevTimeUnits = @RevTimeUnits
         , [Description] = @Notes
         , RevCode = @RevCode
         , [TimeUM] = @TimeUM
         , [PreviousOdometer] = @PreviousOdometer
         , [PreviousHourMeter] = @PreviousHourMeter
         , [RevRate] = @RevRate
         , [RevDollars] = @RevDollars
         , [GLOffsetAcct] = @OffsetAcct
         , [OffsetGLCo] = @GLCo
         , [UM] = @WorkUM
	 WHERE Co = @Key_EMCo 
	   AND Mth = @Key_Mth 
	   AND BatchId = @Key_BatchId 
	   AND BatchSeq = @Key_BatchSequence


	UPDATE HQBC
	   SET InUseBy = @VPUserName
	 WHERE Co = @Key_EMCo 
	   AND Mth = @Key_Mth 
	   AND BatchId = @Key_BatchId	
	
	vspExit:	
END

GO
GRANT EXECUTE ON  [dbo].[vpspEMUsageEntryUpdate] TO [VCSPortal]
GO
