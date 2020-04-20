SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************
* CREATED:	 DAN SO 04/01/2010 - ISSUE: #129350
* MODIFIED:	
*
* USAGE:
*	Copies old Surcharge Rate(s) value(s) for selected Surcharge Code
*		- copy and modification of: bspMSPriceTemplateUpdate
*
* INPUT PARAMETERS
*   @MSCo      		MS Company #
*   @SurchargeCode  Surcharge Code related to rates to be processed
*
* OUTPUT PARAMETERS
*   @errmsg			Error message
*
* RETURN VALUE
*   @rcode			0 = success
*					1 = error
* 
************************************************************/
--CREATE PROCEDURE [dbo].[vspMSSurchargeRatesUpdate]
CREATE PROCEDURE [dbo].[vspMSSurchargeRatesUpdate]

	@MSCo bCompany = NULL, @SurchargeCode smallint = NULL,
	@errmsg varchar(255) output

	AS
	SET NOCOUNT ON
   
	DECLARE @rcode int
   
	-------------------------------
	-- VALIDATE INPUT PARAMETERS --
	-------------------------------
	-- MSCo --
	IF NOT EXISTS(SELECT 1 FROM bMSCO WITH (NOLOCK) WHERE MSCo = @MSCo)
		BEGIN
			SET @errmsg = 'Invalid MS Company!'
			SET @rcode = 1
   			GOTO vspexit
		END
		
	-- SurchargeCode --
	IF NOT EXISTS(SELECT 1 FROM bMSSurchargeCodes WITH (NOLOCK) WHERE MSCo = @MSCo AND SurchargeCode = @SurchargeCode)
		BEGIN
			SET @errmsg = 'Invalid Surcharge Code!'
			SET @rcode = 1
   			GOTO vspexit
		END
   
   
	----------------------------------------------------------------
	-- UPDATE 'NEW' MSSurchargeCodeRates VALUES WITH 'OLD' VALUES --
	----------------------------------------------------------------
	UPDATE bMSSurchargeCodeRates
	   SET OldSurchargeRate = SurchargeRate, OldMinAmt = MinAmt
	 WHERE MSCo = @MSCo 
	   AND SurchargeCode = @SurchargeCode
   

	-----------------
	-- END ROUTINE --
	-----------------   
	vspexit:
   		IF @rcode <> 0 
   			SET @errmsg = isnull(@errmsg,'')
   			
   		RETURN @rcode

		


GO
GRANT EXECUTE ON  [dbo].[vspMSSurchargeRatesUpdate] TO [public]
GO
