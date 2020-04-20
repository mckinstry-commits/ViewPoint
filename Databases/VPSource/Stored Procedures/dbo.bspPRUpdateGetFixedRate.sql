SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspPRUpdateGetFixedRate]
/***********************************************************
* Created: GG 11/13/06 - #123034
* Modified: CWW 07/23/08 - #126777 Added IMPORTANT comment
*
* IMPORTANT:  If a change is made to this stored procedure a corresponding change 
* MUST be made to the function vf_rptPRUpdateGetFixedRate.
*
* Called from bspPRUpdateValJC to determine JC fixed rate based
* on rate template assigned to job and posted values from timecard
*
* Inputs:
*   @jcco   			JC Company
*   @ratetemplate		JC Fixed Rate Template
*   @prco				PR Company
*   @craft				Craft
*   @class				Class
*   @shift				Shift
*   @factor				Earning code factor
*   @employee			Employee
*
* Output:
*   @oldjcrate			Old JC Fixed Rate
*	@newjcrate			New JC Fixed Rate
*
* Return Value:
*   0         success
*   1         failure
*****************************************************/

	(@jcco bCompany = null, @ratetemplate smallint = null, @prco bCompany = null,
	 @craft bCraft = null, @class bClass = null, @shift tinyint = null, @factor bRate = null,
	 @employee bEmployee = null, @oldjcrate bUnitCost = 0 output, @newjcrate bUnitCost = 0 output)

as
set nocount on
   
declare @rcode int
select @rcode = 0

-- Search for Old and New Fixed Rates based on hierarchy of factors

-- PRCo, Craft, Class, Shift, EarnFactor, Employee
select @oldjcrate = OldRate, @newjcrate = NewRate
from dbo.bJCRD (nolock)
where JCCo = @jcco and RateTemplate = @ratetemplate and PRCo = @prco and Craft = @craft
	and Class = @class and Shift = @shift and EarnFactor = @factor and Employee = @employee
if @@rowcount = 1 goto bspexit
-- PRCo, Craft, Class, EarnFactor, Employee
select @oldjcrate = OldRate, @newjcrate = NewRate
from dbo.bJCRD (nolock)
where JCCo = @jcco and RateTemplate = @ratetemplate and PRCo = @prco and Craft = @craft
	and Class = @class and Shift is null and EarnFactor = @factor and Employee = @employee
if @@rowcount = 1 goto bspexit
-- PRCo, Craft, Class, Shift, Employee
select @oldjcrate = OldRate, @newjcrate = NewRate
from dbo.bJCRD (nolock)
where JCCo = @jcco and RateTemplate = @ratetemplate and PRCo = @prco and Craft = @craft
	and Class = @class and Shift = @shift and EarnFactor is null and Employee = @employee
if @@rowcount = 1 goto bspexit
-- PRCo, Shift, EarnFactor, Employee
select @oldjcrate = OldRate, @newjcrate = NewRate
from dbo.bJCRD (nolock)
where JCCo = @jcco and RateTemplate = @ratetemplate and PRCo = @prco and Craft is null
	and Class is null and Shift = @shift and EarnFactor = @factor and Employee = @employee
if @@rowcount = 1 goto bspexit
-- PRCo, EarnFactor, Employee
select @oldjcrate = OldRate, @newjcrate = NewRate
from dbo.bJCRD (nolock)
where JCCo = @jcco and RateTemplate = @ratetemplate and PRCo = @prco and Craft is null
	and Class is null and Shift is null and EarnFactor = @factor and Employee = @employee
if @@rowcount = 1 goto bspexit
-- PRCo, Shift, Employee
select @oldjcrate = OldRate, @newjcrate = NewRate
from dbo.bJCRD (nolock)
where JCCo = @jcco and RateTemplate = @ratetemplate and PRCo = @prco and Craft is null
	and Class is null and Shift = @shift and EarnFactor is null and Employee = @employee
if @@rowcount = 1 goto bspexit
-- PRCo, Employee
select @oldjcrate = OldRate, @newjcrate = NewRate
from dbo.bJCRD (nolock)
where JCCo = @jcco and RateTemplate = @ratetemplate and PRCo = @prco and Craft is null
	and Class is null and Shift is null and EarnFactor is null and Employee = @employee
if @@rowcount = 1 goto bspexit
-- PRCo, Craft, Class, Shift, EarnFactor
select @oldjcrate = OldRate, @newjcrate = NewRate
from dbo.bJCRD (nolock)
where JCCo = @jcco and RateTemplate = @ratetemplate and PRCo = @prco and Craft = @craft
	and Class = @class and Shift = @shift and EarnFactor = @factor and Employee is null
if @@rowcount = 1 goto bspexit
-- PRCo, Craft, Class, EarnFactor
select @oldjcrate = OldRate, @newjcrate = NewRate
from dbo.bJCRD (nolock)
where JCCo = @jcco and RateTemplate = @ratetemplate and PRCo = @prco and Craft = @craft
	and Class = @class and Shift is null and EarnFactor = @factor and Employee is null
if @@rowcount = 1 goto bspexit
-- PRCo, Craft, Class, Shift
select @oldjcrate = OldRate, @newjcrate = NewRate
from dbo.bJCRD (nolock)
where JCCo = @jcco and RateTemplate = @ratetemplate and PRCo = @prco and Craft = @craft
	and Class = @class and Shift = @shift and EarnFactor is null and Employee is null
if @@rowcount = 1 goto bspexit
-- PRCo, Craft, Class
select @oldjcrate = OldRate, @newjcrate = NewRate
from dbo.bJCRD (nolock)
where JCCo = @jcco and RateTemplate = @ratetemplate and PRCo = @prco and Craft = @craft
	and Class = @class and Shift is null and EarnFactor is null and Employee is null
if @@rowcount = 1 goto bspexit
-- PRCo, Craft
select @oldjcrate = OldRate, @newjcrate = NewRate
from dbo.bJCRD (nolock)
where JCCo = @jcco and RateTemplate = @ratetemplate and PRCo = @prco and Craft = @craft
	and Class is null and Shift is null and EarnFactor is null and Employee is null
if @@rowcount = 1 goto bspexit

-- no matching entries found, set rates to 0.00
select @oldjcrate = 0, @newjcrate = 0

bspexit: 
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUpdateGetFixedRate] TO [public]
GO
