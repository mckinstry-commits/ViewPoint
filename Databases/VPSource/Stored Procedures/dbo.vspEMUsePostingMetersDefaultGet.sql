SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [dbo].[vspEMUsePostingMetersDefaultGet]
/***********************************************************
* CREATED BY:	GF 01/17/2013 TK-20856
* MODIFIED By: 
*
*
*
* USAGE:
* This procedure is used by the EM Usage Posting program to get
* the default meters reading (odo, hours) for new transactions.
* Will be a validation procedure for the actual date input.
*
* The procedure will start with EMEM Meter Readings, then check
* the current batch for equipment entries with an earlier date.
* Will alos look for equipment entries for the same date and an earlier sequence.
*
*
* INPUT PARAMETERS
* Co         EM Co to pull from
* Mth        Month of batch
* BatchId    Batch ID to insert transaction into
* BatchSeq	 Batch Sequence
* Equipment	 Equipment code
* ActualDate Actual Date for the batch entry
*
*
* OUTPUT PARAMETERS
* @OdoReading	Odometer reading
* @HourReading	Hour reading
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@EMCo bCompany = NULL, @Mth bMonth = NULL, @BatchId bBatchID = NULL,
 @BatchSeq INT = NULL, @Equipment bEquip = NULL, @ActualDate bDate = NULL,
 @MeterMiles bHrs = 0 OUTPUT, @MeterHours bHrs = 0 OUTPUT,
 @ErrMsg varchar(255)OUTPUT)
AS
SET NOCOUNT ON
    
declare @rcode INT, @EMBF_MeterHours bHrs, @EMBF_MeterMiles bHrs

SET @rcode = 0
SET @MeterMiles = 0
SET @MeterHours = 0
SET @EMBF_MeterHours = 0
SET @EMBF_MeterMiles = 0


---- must have these key values to continue - batch sequence is not required.
IF @EMCo IS NULL OR @Mth IS NULL OR @BatchId IS NULL OR @Equipment IS NULL OR @ActualDate IS NULL GOTO vspexit

---- get meter readings from EMEM
SELECT  @MeterMiles = ISNULL(OdoReading, 0),
		@MeterHours = ISNULL(HourReading, 0)
FROM dbo.bEMEM
WHERE EMCo = @EMCo
	AND Equipment = @Equipment
IF @@ROWCOUNT = 0
	BEGIN
	SET @MeterMiles = 0
	SET @MeterHours = 0
   	GOTO vspexit
	END
  
---- check for existing batch records for equipment, same actual date, earlier sequence
SELECT TOP 1 @EMBF_MeterMiles = CurrentOdometer,
			 @EMBF_MeterHours = CurrentHourMeter
FROM dbo.bEMBF
WHERE Co = @EMCo
	AND Mth = @Mth
	AND BatchId = @BatchId
	AND Equipment = @Equipment
	AND ActualDate = @ActualDate
	AND BatchSeq <> ISNULL(@BatchSeq,-999)
	ORDER BY Co, Mth, BatchId, Equipment, ActualDate, BatchSeq DESC
	--AND (CASE WHEN @BatchTransType = 'A' AND BatchSeq <> ISNULL(@BatchSeq,-999) THEN 1
	--		  WHEN @BatchTransType <> 'A' AND BatchSeq = @BatchSeq THEN 1
	--		  ELSE 0
	--		  END) = 1

IF @@ROWCOUNT = 0
	BEGIN
	---- check for existing batch records for equipment, earlier actual date
	SELECT TOP 1 @EMBF_MeterMiles = CurrentOdometer,
				 @EMBF_MeterHours = CurrentHourMeter
	FROM dbo.bEMBF
	WHERE Co = @EMCo
		AND Mth = @Mth
		AND BatchId = @BatchId
		AND Equipment = @Equipment
		AND ActualDate < @ActualDate
		AND BatchSeq <> ISNULL(@BatchSeq,-999)
	ORDER BY Co, Mth, BatchId, Equipment, ActualDate DESC, BatchSeq DESC
	IF @@ROWCOUNT = 0 GOTO vspexit ---- no batch records, done
	END

---- use batch meter values
SET @MeterHours = ISNULL(@EMBF_MeterHours, 0)
SET @MeterMiles = ISNULL(@EMBF_MeterMiles, 0)

    




vspexit:
	RETURN	@rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMUsePostingMetersDefaultGet] TO [public]
GO
