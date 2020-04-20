SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBCompanyVal    Script Date: ******/
CREATE proc [dbo].[vspJBCompanyVal]
/*************************************
* Created: TJL - Issue #28237, 6x recode
* Modified:
*
* Validates JB Company number and returns Name from HQCo
*	
* Pass:
*	JB Company number
*
* Success returns:
*	0 and Company name from bHQCO
*
* Error returns:
*	1 and error message
**************************************/
(@jbco bCompany, @msg varchar(60) output)
as 
set nocount on
declare @rcode int
select @rcode = 0

if @jbco is null
	begin
	select @msg = 'Missing JB Company#', @rcode = 1
	goto vspexit
	end

if exists(select 1 from bJBCO with (nolock) where bJBCO.JBCo = @jbco)
	begin
	select @msg = bHQCO.Name from bHQCO where bHQCO.HQCo = @jbco
	goto vspexit
	end
else
	begin
	select @msg = 'Not a valid JB Company', @rcode = 1
	end

vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBCompanyVal] TO [public]
GO
