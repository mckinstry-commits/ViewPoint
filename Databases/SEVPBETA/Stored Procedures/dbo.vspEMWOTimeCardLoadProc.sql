SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMGroupGet    Script Date: 8/28/99 9:34:28 AM ******/
CREATE proc [dbo].[vspEMWOTimeCardLoadProc]
/********************************************************
* CREATED BY: 	TRL 03/13/08 Issue 127305
* MODIFIED BY:	GP	05/02/2008 #128110 Added output parameter @LaborCostCodeChg to return
*								corresponding value from EMCO.
*	
*				
* USAGE: EMWOTimceCards
* 	Retrieves EMGroup, GL Company, Labor CT, CostCode and PRCo
*
* INPUT PARAMETERS:
*	EM Company
*
* OUTPUT PARAMETERS:
*	EMGroup from bHQCO
*	GLCo 
*	Labort CT
*	WOCostCode
*	PRCo
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/

(@emco bCompany = 0, @EMGroup tinyint output, @GLCo bCompany output,
 @LaborCT bEMCType output, @WOCostCodeChg bYN output, @PRCo bCompany output, 
 @LaborCostCodeChg bYN output, @msg varchar(60) output) 
as    
set nocount on

declare @rcode int

select @rcode = 0

if @emco is null
	begin
  		select @msg = 'Missing EM Company.', @rcode = 1
		goto vspexit
	end
else
	begin
		select top 1 1 
		from dbo.EMCO with (nolock)
		where EMCo = @emco
		if @@rowcount = 0
		begin
			select @msg = 'Company# ' + convert(varchar,@emco) + ' not setup in EM.', @rcode = 1
			goto vspexit
		end
	end

--get HQ group info
select @EMGroup = EMGroup from dbo.HQCO with (nolock)where HQCo = @emco

--get EM Company info
select @GLCo = GLCo, @LaborCT = LaborCT,@WOCostCodeChg = WOCostCodeChg, 
		@LaborCostCodeChg = LaborCostCodeChg, @PRCo = PRCo
	from dbo.EMCO with (nolock)
where EMCo = @emco

if @@rowcount = 0 
   begin
	select @msg = 'EM Company does not exist.', @rcode=1, @EMGroup=0
	goto vspexit
	end

if @EMGroup is Null 
begin
    select @msg = 'EM Group not setup for EM Co ' + isnull(convert(varchar(3),@emco),'') + ' in HQ!' , @rcode=1, @EMGroup=0
	goto vspexit
end 

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWOTimeCardLoadProc] TO [public]
GO
