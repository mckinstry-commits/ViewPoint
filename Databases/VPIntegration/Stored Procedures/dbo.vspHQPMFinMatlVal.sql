SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************/
CREATE proc [dbo].[vspHQPMFinMatlVal] 
/*****************************************
* Created by: TRL 03/17/09  Issue 129409
* Modified by:
*
*	Usage:  HQ Escalation Materials, validate Fin Matl and Comp Matl
*
*	Input parameters
*	Country, State, Price Index, MatlGroup, FinishMatl and Component Matl
*
*	Output parameters
*	@errmsg
*
*********************************************/
(@country varchar(2) = null,@state varchar(4) = null,@priceindex varchar(20)=null,
 @matlgroup bGroup = null ,@finishedmatl bMatl=null,
 @errmsg varchar(255) output)
as 
set nocount on

declare @rcode int

select @rcode = 0

--Validate Country
If not exists (Select top 1 1 From dbo.HQCountry with(nolock) Where Country = IsNull(@country,''))
	begin
	select @errmsg = 'Missing or invalid Country',@rcode = 1
	goto vspexit
	end

--Validate Country/State
If not exists (Select top 1 1 From dbo.HQST with(nolock) Where Country = IsNull(@country,'')and State=IsNull(@state,''))
	begin
	select @errmsg = 'Missing or invalid State',@rcode = 1
	goto vspexit
	end

--Validate Coutry/State/PriceIndex
If not exists (Select top 1 1 From dbo.HQPO with(nolock) Where Country = IsNull(@country,'')
				and State=IsNull(@state,'') and PriceIndex = IsNull(@priceindex,''))
	begin
	select @errmsg = 'Missing or invalid Price Index',@rcode = 1
	goto vspexit
	end

--Check for missing Matl Group
If @matlgroup is null
	begin
	select @errmsg = 'Missing MatlGroup',@rcode = 1
	goto vspexit
	end

--Validate Matl Group
If not exists (Select top 1 1 From dbo.HQGP with(nolock) Where Grp = @matlgroup)
	begin
	select @errmsg = 'Invalid Group',@rcode = 1
	goto vspexit
	end

--Check to see if Finished Material is missing/invalid or Inactive in HQ Materials
If not exists (Select top 1 1 from dbo.HQMT with(nolock) Where MatlGroup=@matlgroup
			and Material=@finishedmatl and Active = 'Y')
	begin
	select @errmsg = 'Missing or In-active Finished Material',@rcode = 1
	goto vspexit
	end

--Check to see if Finished Material exists in IN Bill Materials for Matl Group
If not exists(Select 1 From dbo.INBH with(nolock)Where MatlGroup=@matlgroup and FinMatl=@finishedmatl)
	begin
	--check to see if finished materail exist in IN Bill Materials override for material group
	if not exists(select 1 from dbo.INBO with (nolock) where MatlGroup=@matlgroup and FinMatl=@finishedmatl)
		begin
		select @errmsg = 'Invalid Finished Material in IN Bill of Materials',@rcode = 1
		goto vspexit
		end
	end

--Check to see if Finished Material is being used in another index for the country and state
If exists (select top 1 1 from dbo.HQPM Where Country=@country and State=@state and PriceIndex <> @priceindex
			and MatlGroup=@matlgroup and FinishedMatl=@finishedmatl)
	begin
	select @errmsg = 'Finished Material already used in another country/state price index.',@rcode = 1
	goto vspexit
	end

---- get description
select @errmsg = Description
from dbo.HQMT with(nolock) where MatlGroup=@matlgroup and Material=@finishedmatl


vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspHQPMFinMatlVal] TO [public]
GO
