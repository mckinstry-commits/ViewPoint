SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspSMEMRevCodeRateGet]
   
/******************************************************
* Created By:  ScottAlvey  04/17/2013
* Modified By: 
*				
* Usage:
*	A standard validation for a revenue code from EMRC
*	and returns associated code rate
*
*
* Input Parameters
*	EMCo		Need company to retreive Allow posting override flag
* 	EMGroup		EM group for this company
*	EMCategory	EM Category to limit down code
*	RevCode		Revenue code to validate
*
* Output Parameters
*	@msg		The RevCode description.  Error message when appropriate.
*	Rate		Rate of the related cat/code combo
*
* Return Value
*  0	success
*  1	failure
***************************************************/
   
(
	@EMCo bCompany
	, @EMGroup bGroup
	, @EMCat bCat
	, @RevCode bRevCode
	, @Rate bDollar = null output
	, @msg varchar(60) = null output
)
   
AS
BEGIN
	SET NOCOUNT ON
   
	IF @EMCo is null
	BEGIN
		SELECT @msg= 'Missing Company.'
		RETURN 1
	END

	IF @EMGroup is null
	BEGIN
		SELECT @msg= 'Missing EM Group.'
		RETURN 1
	END

	IF @RevCode is null
	BEGIN
		SELECT @msg= 'Missing Revenue Code.'
		RETURN 1
	END

	IF @EMCat is null
	BEGIN
		SELECT @msg= 'Missing Category.'
		RETURN 1
	END
   
	SELECT 
		@Rate = r.Rate
		, @msg = c.Description
	from 
		EMRR r with (nolock)
	join
		EMRC c on
			r.EMGroup = c.EMGroup
			and r.RevCode = c.RevCode
	where 
		r.EMCo = @EMCo
		AND r.EMGroup = @EMGroup 
		AND r.Category = @EMCat
		AND r.RevCode = @RevCode

	IF @@rowcount = 0
	BEGIN
		select @msg = 'Revenue Code Rate not set up in EM Revenue Rates by Category.'
		RETURN 1
	END
   
	RETURN 0

END

GO
GRANT EXECUTE ON  [dbo].[vspSMEMRevCodeRateGet] TO [public]
GO
