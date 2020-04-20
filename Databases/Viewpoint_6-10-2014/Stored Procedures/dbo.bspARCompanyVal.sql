SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARCompanyVal    Script Date: 8/28/99 9:34:10 AM ******/
CREATE proc [dbo].[bspARCompanyVal]
/*************************************
* Modified: gr 4/15/99
*		TJL 03/07/07 - Issue #27815:  6x Rewrite, Added CustGroup output.  Modified all DDFI entries using this ValProc
*
* Validates AR Company number
*
* Pass:
*	AR Company number
*
* Success returns:
*	0 and Company name, CustGroup from bHQCO
*
* Error returns:
*	1 and error message
**************************************/
(@arco bCompany = 0, @custgroup bGroup output, @msg varchar(60) output)
as
set nocount on
declare @rcode int
select @rcode = 0

if @arco is null
	begin
	select @msg = 'Missing AR Company#.', @rcode = 1
	goto bspexit
	end

if exists(select 1 from ARCO with (nolock) where @arco = ARCo)
	begin
	select @msg = Name, @custgroup = CustGroup 
	from bHQCO with (nolock) 
	where HQCo = @arco
	goto bspexit
	end
else
	begin
	select @msg = 'Not a valid AR company ', @rcode = 1
	end

bspexit:
if @rcode <> 0 select @msg = @msg	--+ char(13) + char(10) + '[bspARCompanyVal]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARCompanyVal] TO [public]
GO
