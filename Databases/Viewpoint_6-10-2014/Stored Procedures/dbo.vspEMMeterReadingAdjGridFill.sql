SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspEMMeterReadingAdjGridFill]
/***********************************************************
* CREATED BY:   TRL 02/17/2011 Issue 142619
* MODIFIED BY:
*
*
* PURPOSE:  This procedure is used in EM Meter Reading Adjustments
*  It fills a grid of meter that will be changed or deleted
***********************************************************/
(@EMCo bCompany = NULL,
@Equipment bEquip = NULL,
@MeterReadingType varchar(1) = NULL,
@StartDate bDate = NULL,
@EndDate bDate = NULL,
@FilterMonth bMonth = NULL,
@FilterTrans int = NULL,
@ErrMsg varchar(256) output)

AS

SET NOCOUNT ON

DECLARE @rcode int

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

 IF EXISTS (SELECT TOP 1 1 FROM dbo.EMBF WHERE Co=@EMCo AND Equipment = @Equipment AND Source = 'EMMeter')
BEGIN
	SELECT @ErrMsg = 'Equipment cannot exist on open Meter Reading Batch', @rcode = 1
	GOTO vspexit	
END 

SELECT  [Reading Date] = ReadingDate,
[Current Meter] = CASE WHEN @MeterReadingType = 'O' THEN CurrentOdometer  ELSE CurrentHourMeter END,
[Replaced Meter] = CASE WHEN @MeterReadingType = 'O' THEN CurrentTotalOdometer- CurrentOdometer  ELSE CurrentTotalHourMeter-CurrentHourMeter END,
[Total Meter] = CASE WHEN @MeterReadingType = 'O' THEN CurrentTotalOdometer ELSE CurrentTotalHourMeter END,
[Difference] = CASE WHEN @MeterReadingType = 'O' THEN Miles  ELSE [Hours] END,
[New Meter] = '',
[New Replaced Meter] = '',
[New Total Meter] = '',
[New Difference] = '',
 Mth,[Batch ID] = BatchId,[Trans]= EMTrans 
FROM dbo.EMMR 
WHERE EMCo=@EMCo AND Equipment = @Equipment AND ReadingDate >= @StartDate AND ReadingDate <=@EndDate
AND Mth = IsNull(@FilterMonth,Mth) AND EMTrans = IsNull(@FilterTrans,EMTrans) AND Source = 'EMMeter'
ORDER BY ReadingDate,
	(CASE WHEN @MeterReadingType = 'O' THEN CurrentTotalOdometer ELSE CurrentTotalHourMeter END) ASC,
	(CASE WHEN @MeterReadingType = 'O' THEN Miles ELSE [Hours] END) DESC
	

vspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMMeterReadingAdjGridFill] TO [public]
GO
