SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspEMMeterReadingAdjUpdate]
/***********************************************************
* CREATED BY:   TRL 02/22/2011 Issue 142619
* MODIFIED BY:
*
*
* PURPOSE:  This procedure is used in EM Meter Reading Adjustments
Deletes Meter Readings from EMMR
***********************************************************/
(@EMCo bCompany = NULL,
@Equipment bEquip = NULL,
@ReadingDate bDate = NULL,
@BatchMonth bMonth = NULL,
@BatchId int = NULL,
@EMTrans int = NULL,
@OldMeter bHrs = NULL,
@OldTotalMeter bHrs = NULL,
@OldDifference bHrs = NULL,
@NewMeter bHrs = NULL,
@NewTotalMeter bHrs = NULL,
@NewDifference bHrs = NULL,
@MeterReadingType varchar(1) = NULL,
@ErrMsg varchar(256) output)

AS

SET NOCOUNT ON

DECLARE @rcode int

SELECT @rcode = 0

IF @EMCo IS NULL
BEGIN
	SELECT @ErrMsg = 'Missing EM Company', @rcode = 1
	GOTO vspexit
END

IF IsNull(@Equipment,'') = ''
BEGIN
	SELECT @ErrMsg = 'Missing Equipment', @rcode = 1
	GOTO vspexit
END

IF IsNull(@BatchMonth,'') = ''  OR @BatchMonth IS NULL
BEGIN
	SELECT @ErrMsg = 'Missing Start Date', @rcode = 1
	GOTO vspexit
END

IF @BatchId IS NULL
BEGIN
	SELECT @ErrMsg = 'Missing BatchId', @rcode = 1
	GOTO vspexit
END

IF @EMTrans IS NULL
BEGIN
	SELECT @ErrMsg = 'Missing EM Trans', @rcode = 1
	GOTO vspexit
END

IF IsNull(@ReadingDate,'') = ''  OR @ReadingDate IS NULL
BEGIN
	SELECT @ErrMsg = 'Missing Reading Date', @rcode = 1
	GOTO vspexit
END

 IF EXISTS (SELECT TOP 1 1 FROM dbo.EMBF WHERE Co=@EMCo AND Equipment = @Equipment AND Source = 'EMMeter')
BEGIN
	SELECT @ErrMsg = 'Equipment cannot exist on open Meter Reading Batch', @rcode = 1
	GOTO vspexit	
END 

IF @MeterReadingType = 'H'
	--Hour Meter
	BEGIN
		IF EXISTS (SELECT TOP 1 1 FROM dbo.EMMR WHERE EMCo=@EMCo AND Equipment = @Equipment AND Source = 'EMMeter' 
		AND ReadingDate = @ReadingDate AND Mth = @BatchMonth AND BatchId = @BatchId  AND EMTrans = @EMTrans)
		BEGIN
			UPDATE dbo.EMMR
			SET CurrentHourMeter = @NewMeter, CurrentTotalHourMeter = @NewTotalMeter, [Hours]=@NewDifference 
			WHERE EMCo=@EMCo AND Equipment = @Equipment AND Source = 'EMMeter' 
			AND ReadingDate =@ReadingDate AND Mth = @BatchMonth AND BatchId = @BatchId  AND EMTrans = @EMTrans
			
			-- Audit Deletes
			INSERT bHQMA (TableName, KeyString, 	Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
			select 'bEMMR','EM Company: ' + convert(char(3), @EMCo) + ' Equipment: ' + @Equipment 
			+ ' Batch Month:  '  + CONVERT(varchar,@BatchMonth) + ' BatchId: '  +CONVERT(varchar,@BatchId) + ' EMTrans: ' + CONVERT(varchar,@EMTrans), 
			@EMCo, 'C', 'CurrentHourMeter', CONVERT(varchar,@OldMeter),CONVERT(varchar,@NewMeter), getdate(), SUSER_SNAME()
			
			-- Audit Deletes
			INSERT bHQMA (TableName, KeyString, 	Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
			select 'bEMMR','EM Company: ' + convert(char(3), @EMCo) + ' Equipment: ' + @Equipment 
			+ ' Batch Month:  '  + CONVERT(varchar,@BatchMonth) + ' BatchId: '  +CONVERT(varchar,@BatchId) + ' EMTrans: ' + CONVERT(varchar,@EMTrans), 
			@EMCo, 'C', 'CurrentTotalHourMeter', CONVERT(varchar,@OldTotalMeter),CONVERT(varchar,@NewTotalMeter), getdate(), SUSER_SNAME()
			
			-- Audit Deletes
			INSERT bHQMA (TableName, KeyString, 	Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
			select 'bEMMR','EM Company: ' + convert(char(3), @EMCo) + ' Equipment: ' + @Equipment 
			+ ' Batch Month:  '  + CONVERT(varchar,@BatchMonth) + ' BatchId: '  +CONVERT(varchar,@BatchId) + ' EMTrans: ' + CONVERT(varchar,@EMTrans), 
			@EMCo, 'C', 'Hours', CONVERT(varchar,@OldDifference),CONVERT(varchar,@NewDifference), getdate(), SUSER_SNAME()

		END
	END
ELSE
	--'Odometer'
	BEGIN
		IF EXISTS (SELECT TOP 1 1 FROM dbo.EMMR WHERE EMCo=@EMCo AND Equipment = @Equipment AND Source = 'EMMeter' 
		AND ReadingDate = @ReadingDate AND Mth = @BatchMonth AND BatchId = @BatchId  AND EMTrans = @EMTrans)
		BEGIN
			UPDATE dbo.EMMR
			SET CurrentOdometer = @NewMeter, CurrentTotalOdometer = @NewTotalMeter, Miles =@NewDifference 
			WHERE EMCo=@EMCo AND Equipment = @Equipment AND Source = 'EMMeter' 
			AND ReadingDate = @ReadingDate AND Mth = @BatchMonth AND BatchId = @BatchId  AND EMTrans = @EMTrans
			
			-- Audit Deletes
			INSERT bHQMA (TableName, KeyString, 	Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
			select 'bEMMR','EM Company: ' + convert(char(3), @EMCo) + ' Equipment: ' + @Equipment 
			+ ' Batch Month:  '  + CONVERT(varchar,@BatchMonth) + ' BatchId: '  +CONVERT(varchar,@BatchId) + ' EMTrans: ' + CONVERT(varchar,@EMTrans), 
			@EMCo, 'C', 'CurrentOdometer', CONVERT(varchar,@OldMeter),CONVERT(varchar,@NewMeter), getdate(), SUSER_SNAME()
			
			-- Audit Deletes
			INSERT bHQMA (TableName, KeyString, 	Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
			select 'bEMMR','EM Company: ' + convert(char(3), @EMCo) + ' Equipment: ' + @Equipment 
			+ ' Batch Month:  '  + CONVERT(varchar,@BatchMonth) + ' BatchId: '  +CONVERT(varchar,@BatchId) + ' EMTrans: ' + CONVERT(varchar,@EMTrans), 
			@EMCo, 'C', 'CurrentTotalOdometer', CONVERT(varchar,@OldTotalMeter),CONVERT(varchar,@NewTotalMeter), getdate(), SUSER_SNAME()
			
			-- Audit Deletes
			INSERT bHQMA (TableName, KeyString, 	Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
			select 'bEMMR','EM Company: ' + convert(char(3), @EMCo) + ' Equipment: ' + @Equipment 
			+ ' Batch Month:  '  + CONVERT(varchar,@BatchMonth) + ' BatchId: '  +CONVERT(varchar,@BatchId) + ' EMTrans: ' + CONVERT(varchar,@EMTrans), 
			@EMCo, 'C', 'Miles', CONVERT(varchar,@OldDifference),CONVERT(varchar,@NewDifference), getdate(), SUSER_SNAME()
		END
	END
		
vspexit:
	RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspEMMeterReadingAdjUpdate] TO [public]
GO
