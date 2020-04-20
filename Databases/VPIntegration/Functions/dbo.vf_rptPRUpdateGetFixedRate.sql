SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[vf_rptPRUpdateGetFixedRate]
/***********************************************************
*
* IMPORTANT:  If a change is made to this function a corresponding change 
* MUST be made to the stored procedure bspPRUpdateGetFixedRate.
*
* Purpose:
* Invoke from view brvPREarnByDept for PR Department Reconcillation Report 
* to determine JC fixed rate based on rate template assigned to job 
* and posted values from the timecard.  The time card date is compared with
* the fixed rate template effective date to ensure the correct rate(OldRate verses NewRate) 
* is selected.
*
*
* Inputs:
*	@TimeCardDate		Time Card Date
*   @jcco   			JC Company
*   @ratetemplate		JC Fixed Rate Template
*   @prco				PR Company
*   @craft				Craft
*   @class				Class
*   @shift				Shift
*   @factor				Earning code factor
*   @employee			Employee
*
* Returns:
*   @Rate			JC Fixed Rate base on JCRT.EffectiveDate and time card date
*
  Maintenance Log:
	Coder	Date		Issue#	Description of Change
	CWirtz	07/21/2007  126777	New
*
*****************************************************/

	(@TimeCardDate bDate = null, @jcco bCompany = null, @ratetemplate smallint = null, @prco bCompany = null,
	 @craft bCraft = null, @class bClass = null, @shift tinyint = null, @factor bRate = null,
	 @employee bEmployee = null )

	RETURNS decimal(9,5)
as
BEGIN

Declare @Rate decimal(9,5)


-- Search for Fixed Rates based on hierarchy of factors

-- PRCo, Craft, Class, Shift, EarnFactor, Employee
select 
@Rate = 
	CASE 
		WHEN @TimeCardDate < JCRT.EffectiveDate THEN OldRate
		WHEN @TimeCardDate >= JCRT.EffectiveDate THEN NewRate
		ELSE 8888
	END
from JCRT JCRT (nolock) inner join JCRD JCRD (nolock)
  ON JCRT.JCCo = JCRD.JCCo and JCRT.RateTemplate = JCRD.RateTemplate
where JCRT.JCCo = @jcco and JCRT.RateTemplate = @ratetemplate and PRCo = @prco and Craft = @craft
	and Class = @class and Shift = @shift and EarnFactor = @factor and Employee = @employee
if @@rowcount = 1 goto bspexit
-- PRCo, Craft, Class, EarnFactor, Employee
select 
@Rate = 
	CASE 
		WHEN @TimeCardDate < JCRT.EffectiveDate THEN OldRate
		WHEN @TimeCardDate >= JCRT.EffectiveDate THEN NewRate
		ELSE 8888
	END
from JCRT JCRT (nolock) inner join JCRD JCRD (nolock)
  ON JCRT.JCCo = JCRD.JCCo and JCRT.RateTemplate = JCRD.RateTemplate
where JCRT.JCCo = @jcco and JCRT.RateTemplate = @ratetemplate and PRCo = @prco and Craft = @craft
	and Class = @class and Shift is null and EarnFactor = @factor and Employee = @employee
if @@rowcount = 1 goto bspexit
-- PRCo, Craft, Class, Shift, Employee
select 
@Rate = 
	CASE 
		WHEN @TimeCardDate < JCRT.EffectiveDate THEN OldRate
		WHEN @TimeCardDate >= JCRT.EffectiveDate THEN NewRate
		ELSE 8888
	END
from JCRT JCRT (nolock) inner join JCRD JCRD (nolock)
  ON JCRT.JCCo = JCRD.JCCo and JCRT.RateTemplate = JCRD.RateTemplate
where JCRT.JCCo = @jcco and JCRT.RateTemplate = @ratetemplate and PRCo = @prco and Craft = @craft
	and Class = @class and Shift = @shift and EarnFactor is null and Employee = @employee
if @@rowcount = 1 goto bspexit
-- PRCo, Shift, EarnFactor, Employee
select 
@Rate = 
	CASE 
		WHEN @TimeCardDate < JCRT.EffectiveDate THEN OldRate
		WHEN @TimeCardDate >= JCRT.EffectiveDate THEN NewRate
		ELSE 8888
	END
from JCRT JCRT (nolock) inner join JCRD JCRD (nolock)
  ON JCRT.JCCo = JCRD.JCCo and JCRT.RateTemplate = JCRD.RateTemplate
where JCRT.JCCo = @jcco and JCRT.RateTemplate = @ratetemplate and PRCo = @prco and Craft is null
	and Class is null and Shift = @shift and EarnFactor = @factor and Employee = @employee
if @@rowcount = 1 goto bspexit
-- PRCo, EarnFactor, Employee
select 
@Rate = 
	CASE 
		WHEN @TimeCardDate < JCRT.EffectiveDate THEN OldRate
		WHEN @TimeCardDate >= JCRT.EffectiveDate THEN NewRate
		ELSE 8888
	END
from JCRT JCRT (nolock) inner join JCRD JCRD (nolock)
  ON JCRT.JCCo = JCRD.JCCo and JCRT.RateTemplate = JCRD.RateTemplate
where JCRT.JCCo = @jcco and JCRT.RateTemplate = @ratetemplate and PRCo = @prco and Craft is null
	and Class is null and Shift is null and EarnFactor = @factor and Employee = @employee
if @@rowcount = 1 goto bspexit
-- PRCo, Shift, Employee
select 
@Rate = 
	CASE 
		WHEN @TimeCardDate < JCRT.EffectiveDate THEN OldRate
		WHEN @TimeCardDate >= JCRT.EffectiveDate THEN NewRate
		ELSE 8888
	END
from JCRT JCRT (nolock) inner join JCRD JCRD (nolock)
  ON JCRT.JCCo = JCRD.JCCo and JCRT.RateTemplate = JCRD.RateTemplate
where JCRT.JCCo = @jcco and JCRT.RateTemplate = @ratetemplate and PRCo = @prco and Craft is null
	and Class is null and Shift = @shift and EarnFactor is null and Employee = @employee
if @@rowcount = 1 goto bspexit
-- PRCo, Employee
select 
@Rate = 
	CASE 
		WHEN @TimeCardDate < JCRT.EffectiveDate THEN OldRate
		WHEN @TimeCardDate >= JCRT.EffectiveDate THEN NewRate
		ELSE 8888
	END
from JCRT JCRT (nolock) inner join JCRD JCRD (nolock)
  ON JCRT.JCCo = JCRD.JCCo and JCRT.RateTemplate = JCRD.RateTemplate
where JCRT.JCCo = @jcco and JCRT.RateTemplate = @ratetemplate and PRCo = @prco and Craft is null
	and Class is null and Shift is null and EarnFactor is null and Employee = @employee
if @@rowcount = 1 goto bspexit
-- PRCo, Craft, Class, Shift, EarnFactor
select 
@Rate = 
	CASE 
		WHEN @TimeCardDate < JCRT.EffectiveDate THEN OldRate
		WHEN @TimeCardDate >= JCRT.EffectiveDate THEN NewRate
		ELSE 8888
	END
from JCRT JCRT (nolock) inner join JCRD JCRD (nolock)
  ON JCRT.JCCo = JCRD.JCCo and JCRT.RateTemplate = JCRD.RateTemplate
where JCRT.JCCo = @jcco and JCRT.RateTemplate = @ratetemplate and PRCo = @prco and Craft = @craft
	and Class = @class and Shift = @shift and EarnFactor = @factor and Employee is null
if @@rowcount = 1 goto bspexit
-- PRCo, Craft, Class, EarnFactor
select 
@Rate = 
	CASE 
		WHEN @TimeCardDate < JCRT.EffectiveDate THEN OldRate
		WHEN @TimeCardDate >= JCRT.EffectiveDate THEN NewRate
		ELSE 8888
	END
from JCRT JCRT (nolock) inner join JCRD JCRD (nolock)
  ON JCRT.JCCo = JCRD.JCCo and JCRT.RateTemplate = JCRD.RateTemplate
where JCRT.JCCo = @jcco and JCRT.RateTemplate = @ratetemplate and PRCo = @prco and Craft = @craft
	and Class = @class and Shift is null and EarnFactor = @factor and Employee is null
if @@rowcount = 1 goto bspexit
-- PRCo, Craft, Class, Shift
select 
@Rate = 
	CASE 
		WHEN @TimeCardDate < JCRT.EffectiveDate THEN OldRate
		WHEN @TimeCardDate >= JCRT.EffectiveDate THEN NewRate
		ELSE 8888
	END
from JCRT JCRT (nolock) inner join JCRD JCRD (nolock)
  ON JCRT.JCCo = JCRD.JCCo and JCRT.RateTemplate = JCRD.RateTemplate
where JCRT.JCCo = @jcco and JCRT.RateTemplate = @ratetemplate and PRCo = @prco and Craft = @craft
	and Class = @class and Shift = @shift and EarnFactor is null and Employee is null
if @@rowcount = 1 goto bspexit
-- PRCo, Craft, Class
select 
@Rate = 
	CASE 
		WHEN @TimeCardDate < JCRT.EffectiveDate THEN OldRate
		WHEN @TimeCardDate >= JCRT.EffectiveDate THEN NewRate
		ELSE 8888
	END
from JCRT JCRT (nolock) inner join JCRD JCRD (nolock)
  ON JCRT.JCCo = JCRD.JCCo and JCRT.RateTemplate = JCRD.RateTemplate
where JCRT.JCCo = @jcco and JCRT.RateTemplate = @ratetemplate and PRCo = @prco and Craft = @craft
	and Class = @class and Shift is null and EarnFactor is null and Employee is null
if @@rowcount = 1 goto bspexit
-- PRCo, Craft
select 
@Rate = 
	CASE 
		WHEN @TimeCardDate < JCRT.EffectiveDate THEN OldRate
		WHEN @TimeCardDate >= JCRT.EffectiveDate THEN NewRate
		ELSE 8888
	END
from JCRT JCRT (nolock) inner join JCRD JCRD (nolock)
  ON JCRT.JCCo = JCRD.JCCo and JCRT.RateTemplate = JCRD.RateTemplate
where JCRT.JCCo = @jcco and JCRT.RateTemplate = @ratetemplate and PRCo = @prco and Craft = @craft
	and Class is null and Shift is null and EarnFactor is null and Employee is null
if @@rowcount = 1 goto bspexit



-- no matching entries found, set rates to 0.00
select @Rate = 0

bspexit: 
	return @Rate
END

GO
GRANT EXECUTE ON  [dbo].[vf_rptPRUpdateGetFixedRate] TO [public]
GO
