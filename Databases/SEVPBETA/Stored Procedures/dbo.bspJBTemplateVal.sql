SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspJBTemplateVal]
/***********************************************************
* CREATED BY: bc   05/16/00
* MODIFIED By :
*
* USAGE:
*
* INPUT PARAMETERS
*   JBCo      JB Co to validate against
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of Contract
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
   
@jbco bCompany = 0, @template varchar(10), @laborrateopt char(1) output,
 	@laborrateoveryn bYN output, @equiprateopt char(1) output, @laborcatyn bYN output, 
	@equipcatyn bYN output, @matlcatyn bYN output, @miscdistYN bYN output, @msg varchar(255) output
   
as
set nocount on

declare @rcode int
select @rcode = 0
   
if @jbco is null
	begin
	select @msg = 'Missing JB Company!', @rcode = 1
	goto bspexit
	end

if @template is null
	begin
	select @msg = 'Missing template!', @rcode = 1
	goto bspexit
	end
   
select @msg = Description, @laborrateopt = LaborRateOpt,@laborrateoveryn = LaborOverrideYN,
	@equiprateopt = EquipRateOpt, @laborcatyn = LaborCatYN, @equipcatyn = EquipCatYN,
	@matlcatyn = MatlCatYN
from JBTM with (nolock)
where JBCo = @jbco and Template = @template
if @@rowcount = 0
	begin
	select @msg = 'Template not on file!', @rcode = 1
	goto bspexit
	end
   
if exists(select 1 from JBTS with (nolock) where JBCo = @jbco and Template = @template and
		Type = 'M')
	begin
	select @miscdistYN = 'Y'
	end
else
	begin
	select @miscdistYN = 'N'
	end
   
bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTemplateVal] TO [public]
GO
