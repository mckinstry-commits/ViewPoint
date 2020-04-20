SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMEqiupPartCodeHQMatlVal]
/*************************************
* Created By:	TRL 12/17/08 Issue 127133 added isnulls and @existsYN parameter
* Modified BY:	
*
* validates HQ Material vs HQMT.Material
*
* Pass:
*	HQ MatlGroup
*	HQ Material
*	Validation flag.  Yes or No
*
* Success returns:
*	0 and Description from bHQMT
*
* Error returns:
*	1 and error message
**************************************/
(@matlgroup bGroup = null, @material bMatl = null,
 @sum bUM output,@desc varchar(60) output, @errmsg varchar(60) output)

as 

set nocount on

declare @rcode int

select @rcode = 0

if @matlgroup is null
begin
	select @errmsg = 'Missing Material Group', @rcode = 1
	goto vspexit
end

-- validate material to HQMT
select @errmsg = IsNull(Description,''),@desc = IsNull(Description,''), @sum = SalesUM from dbo.HQMT with (nolock)
where MatlGroup = @matlgroup and Material = @material
if @@rowcount = 0 
begin
	select @errmsg = 'Not a valid Material', @rcode = 1
	goto vspexit
end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEqiupPartCodeHQMatlVal] TO [public]
GO
