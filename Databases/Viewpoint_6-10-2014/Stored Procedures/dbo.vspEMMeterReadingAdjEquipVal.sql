SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[vspEMMeterReadingAdjEquipVal]
/***********************************************************
* CREATED BY:   TRL 02/17/2011 Issue 142619
* MODIFIED By :
*
* USAGE:
*	Validates EMEM.Equipment and returns meter reading info
*
* INPUT PARAMETERS
*	@EMCo		EM Company
*	@Equipment	Equipment to be validated
*
* OUTPUT PARAMETERS
* @LastHourReadingDate
* @LastHourReading
* @ReplacedHourMeterDate
* @ReplacedHourMeter
* @LastOdometerDate
* @LastOdometer
* @ReplacedOdometerDate
* @ReplacedOdometer
* @msg  -- error or Description
*
* RETURN VALUE
*	0 success
*	1 error
***********************************************************/
(@EMCo bCompany = null,
@Equipment bEquip = null,
@LastHourReadingDate  bDate output,
@LastHourReading  bHrs output,
@ReplacedHourMeterDate  bDate output,
@ReplacedHourMeter  bHrs output,
@LastOdometerDate  bDate output,
@LastOdometer  bHrs output,
@ReplacedOdometerDate  bDate output,
@ReplacedOdometer  bHrs output,
@msg varchar(255) output)

AS

SET NOCOUNT ON

DECLARE  @rcode int 

SELECT @rcode = 0
     
IF @EMCo is null
BEGIN
	SELECT @msg = 'Missing EM Company!', @rcode = 1
	GOTO vspexit
END

IF @Equipment is null
BEGIN
	SELECT @msg = 'Missing Equipment!', @rcode = 1
	GOTO vspexit	
END

--Return if Equipment Change in progress for New Equipment Code
EXEC @rcode = vspEMEquipChangeInProgressVal @EMCo, @Equipment, @msg output
IF @rcode = 1
BEGIN
	GOTO vspexit
END
  
 IF EXISTS (SELECT TOP 1 1 FROM dbo.EMBF WHERE Co=@EMCo AND Equipment = @Equipment AND Source = 'EMMeter')
BEGIN
	SELECT @msg = 'Equipment cannot exist on open Meter Reading Batch', @rcode = 1
	GOTO vspexit	
END 

SELECT  @LastHourReadingDate=HourDate,@LastHourReading=IsNull(HourReading,0),@ReplacedHourMeterDate=ReplacedHourDate,@ReplacedHourMeter=IsNull(ReplacedHourReading,0),
@LastOdometerDate=OdoDate,@LastOdometer=IsNull(OdoReading,0),@ReplacedOdometerDate=ReplacedOdoDate,@ReplacedOdometer=IsNull(ReplacedOdoReading,0),
@msg =[Description]
FROM dbo.EMEM 
WHERE EMCo = @EMCo and Equipment = @Equipment 
IF @@ROWCOUNT = 0 
BEGIN
	SELECT @msg = 'Invalid Equipment!', @rcode = 1
	GOTO vspexit	
END


vspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMMeterReadingAdjEquipVal] TO [public]
GO
