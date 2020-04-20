SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspEMMeterReadingAdjPreviousNextGet]
/***********************************************************
* CREATED BY:   TRL 02/17/2011 Issue 142619
* MODIFIED BY:  ECV 04/06/2011 Added check of different Month when comparing EMTrans
*                              Removed check for ReadingType and change in meter reading from the current
*                              because it was causing a record that had changed the total to be skipped.
*
*
* PURPOSE:  This procedure is used in EM Meter Reading Adjustments
*  It fills a grid of meter that will be changed or deleted
***********************************************************/
(@EMCo bCompany = NULL,
@Equipment bEquip = NULL,
@MeterReadingType varchar(1) = NULL,
@StartDate bDate = NULL,
@StartMeter decimal(16,2) = NULL,
@StartMonth bMonth = NULL,
@StartTrans int = NULL,
@EndDate bDate = NULL,
@EndMeter bHrs = NULL,
@EndMonth bMonth = NULL,
@EndTrans int = NULL,
@PreviousReadingDate bDate OUTPUT,
@PreviousMeter decimal(16,2) OUTPUT,
@PreviousReplacedMeter decimal(16,2) OUTPUT ,
@PreviousTotalMeter decimal(16,2) OUTPUT,
@NextReadingDate bDate OUTPUT, 
@NextMeter bHrs OUTPUT,
@NextReplacedMeter decimal(16,2) OUTPUT,
@NextTotalMeter decimal(16,2) OUTPUT,
@NextDifference decimal(16,2) OUTPUT, 
@ErrMsg varchar(256) output)

AS

SET NOCOUNT ON

DECLARE @rcode int, @GetMaxPreviousReadingDate bDate, @GetMaxPreviousBatchMth bMonth, @GetMaxPreviousEMTrans int,
@GetMinNextReadingDate bDate, @GetMinNextBatchMth bMonth, @GetMinNextEMTrans int

SELECT @rcode = 0

IF @EMCo IS NULL
BEGIN
	SELECT @ErrMsg = 'Missing EM Company', @rcode = 1
END

IF IsNull(@Equipment,'') = ''
BEGIN
	SELECT @ErrMsg = 'Missing Equipment', @rcode = 1
END

IF IsNull(@MeterReadingType,'') = '' OR (@MeterReadingType <> 'O' and @MeterReadingType <> 'H')
BEGIN
	SELECT @ErrMsg = 'Missing or Invalid Meter Reading Type', @rcode = 1
END

IF IsNull(@StartDate,'') = ''  OR @StartDate IS NULL
BEGIN
	SELECT @ErrMsg = 'Missing Start Date', @rcode = 1
END

IF IsNull(@EndDate,'') = ''  OR @EndDate IS NULL
BEGIN
	SELECT @ErrMsg = 'Missing End Date', @rcode = 1
END
/*
1.  Before retro meter readings were allowed
	 A.  multiple meter readings could be entered for the same day
	 B.  only meter readings dates greater than or equal to the Equipment' last meter reading date could be entered
	 C.  meter reading dates didn't have be within Meter Reading Batch Month 
	 D.  negative meter readings where allowed that would adjust Equipment's meter reading
	 E.  when entering multiple meter readings for the same equipment with in a batch, the difference (Hours/Miles) was
		 always calculated from Equipment's (EMEM) Last meter reading.  
	 F.  when changing meter reading info in the Equipment master, the change was not recored, unless no meter readings
		 existed for the equipment in EM Meter Reading History Table (EMMR)
		 
2.  With Retro meter readings
	A.  multiple meter readings on the same day are no longer allowed
	B.  when inserting meter readings the new meter reading must fall between the previous and next meter readings
	C.  meter reading date cannot be greater than the batch month
	D.  negative meter readings are no longer allowed
	E.  when entering multiple meter readings for the same equipment, readings are validated now validated between
	    meter readings in the batch and in the EM Location History Table
	F.  when changing meter reading info in the Equipment master, the change is recored EM Meter Reading History Table (EMMR)
		with a source of EMEMUpdate
*/

--Get Previous Meter Reading, meter reading before Start Date
--1 Get Max Reading Date
SELECT  @GetMaxPreviousReadingDate = Max(ReadingDate)
FROM dbo.EMMR 
WHERE EMCo=@EMCo AND Equipment = @Equipment AND Source = 'EMMeter' 
--AND CASE WHEN @MeterReadingType = 'O' THEN CurrentOdometer  ELSE CurrentHourMeter END <> @StartMeter
AND ReadingDate <= @StartDate 
AND (EMTrans <> @StartTrans OR Mth<>@StartMonth)

--2 Get Max Reading Date's Month
SELECT   @GetMaxPreviousBatchMth = Max(Mth)
FROM dbo.EMMR 
WHERE EMCo=@EMCo AND Equipment = @Equipment AND Source = 'EMMeter'
--AND  CASE WHEN @MeterReadingType = 'O' THEN CurrentOdometer  ELSE CurrentHourMeter END <> @StartMeter
AND ReadingDate = @GetMaxPreviousReadingDate
AND ReadingDate <= @StartDate 
AND (EMTrans <> @StartTrans OR Mth<>@StartMonth)

--3 Get Max Reading Date's/Month's EM Trans
SELECT   @GetMaxPreviousEMTrans = Max(EMTrans)
FROM dbo.EMMR 
WHERE EMCo=@EMCo AND Equipment = @Equipment AND Source = 'EMMeter'
--AND  CASE WHEN @MeterReadingType = 'O' THEN CurrentOdometer  ELSE CurrentHourMeter END <> @StartMeter
AND ReadingDate = @GetMaxPreviousReadingDate 
AND Mth = @GetMaxPreviousBatchMth 
AND ReadingDate <= @StartDate 
AND (EMTrans <> @StartTrans OR Mth<>@StartMonth)

--4. Get Previous Meter Readings
SELECT @PreviousReadingDate = ReadingDate,
@PreviousMeter = CASE WHEN @MeterReadingType = 'O' THEN CurrentOdometer  ELSE CurrentHourMeter END,
@PreviousReplacedMeter = CASE WHEN @MeterReadingType = 'O' THEN CurrentTotalOdometer- CurrentOdometer  ELSE CurrentTotalHourMeter-CurrentHourMeter END,
@PreviousTotalMeter = CASE WHEN @MeterReadingType = 'O' THEN CurrentTotalOdometer ELSE CurrentTotalHourMeter END
FROM dbo.EMMR 
WHERE EMCo=@EMCo AND Equipment = @Equipment AND Source = 'EMMeter'
AND ReadingDate  = @GetMaxPreviousReadingDate 
AND Mth =  @GetMaxPreviousBatchMth 
AND EMTrans = @GetMaxPreviousEMTrans
AND ReadingDate <= @StartDate 

--Get Next Meter Reading, next reading before Start Date
--1 Get Max Reading Date
SELECT  @GetMinNextReadingDate = Min(ReadingDate)
FROM dbo.EMMR 
WHERE EMCo=@EMCo AND Equipment = @Equipment AND Source = 'EMMeter' 
AND  CASE WHEN @MeterReadingType = 'O' THEN CurrentOdometer  ELSE CurrentHourMeter END <> @EndMeter
AND ReadingDate >= @EndDate 
AND (EMTrans <> @EndTrans OR Mth<>@EndMonth)


--2 Get Max Reading Date's Month
SELECT  @GetMinNextBatchMth = Min(Mth)
FROM dbo.EMMR 
WHERE EMCo=@EMCo AND Equipment = @Equipment AND Source = 'EMMeter' 
AND  CASE WHEN @MeterReadingType = 'O' THEN CurrentOdometer  ELSE CurrentHourMeter END <> @EndMeter
AND ReadingDate = @GetMinNextReadingDate
AND ReadingDate >= @EndDate 
AND (EMTrans <> @EndTrans OR Mth<>@EndMonth)

--3 Get Max Reading Date's/Month's EM Trans
SELECT   @GetMinNextEMTrans = Min(EMTrans)
FROM dbo.EMMR 
WHERE EMCo=@EMCo AND Equipment = @Equipment AND Source = 'EMMeter' 
AND  CASE WHEN @MeterReadingType = 'O' THEN CurrentOdometer  ELSE CurrentHourMeter END <> @EndMeter
AND ReadingDate = @GetMinNextReadingDate 
AND Mth = @GetMinNextBatchMth 
AND ReadingDate >= @EndDate 
AND (EMTrans <> @EndTrans OR Mth<>@EndMonth)

--SELECT @GetMaxPreviousReadingDate, @GetMaxPreviousBatchMth,@GetMaxPreviousEMTrans 
--SELECT @GetMinNextReadingDate, @GetMinNextBatchMth,@GetMinNextEMTrans

--4. Get Previous Meter Readings
SELECT  @NextReadingDate = ReadingDate,
@NextMeter = CASE WHEN @MeterReadingType = 'O' THEN CurrentOdometer  ELSE CurrentHourMeter END,
@NextReplacedMeter = CASE WHEN @MeterReadingType = 'O' THEN CurrentTotalOdometer- CurrentOdometer  ELSE CurrentTotalHourMeter-CurrentHourMeter END,
@NextTotalMeter = CASE WHEN @MeterReadingType = 'O' THEN CurrentTotalOdometer ELSE CurrentTotalHourMeter END,
@NextDifference = CASE WHEN @MeterReadingType = 'O' THEN Miles  ELSE [Hours] END
FROM dbo.EMMR 
WHERE EMCo=@EMCo AND Equipment = @Equipment AND Source = 'EMMeter'
AND ReadingDate  = @GetMinNextReadingDate 
AND Mth =  @GetMinNextBatchMth 
AND EMTrans = @GetMinNextEMTrans
AND ReadingDate >= @EndDate 

vspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMMeterReadingAdjPreviousNextGet] TO [public]
GO
