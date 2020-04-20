SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspHQPMFinMatlCompMatlVal] 
/*****************************************
* Created by:	TRL 03/17/2009	-	Issue	- #129409
* Modified by:	CHS 10/15/2009	-	Issue	- #136100
*
*	Usage:  HQ Escalation Materials, validate Fin Matl and Comp Matl
*
*	Input parameters
*	Country, State, Price Index, MatlGroup, FinishMatl and Component Matl
*
*	Output parameters
*	@errmsg
*
**********************************************/
(@country varchar(2) = null, @state varchar(4) = null, @priceindex varchar(20)=null,
 @matlgroup bGroup = null, @finishedmatl bMatl=null, @componentmatl bMatl=null,
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
If not exists (Select top 1 1 From dbo.HQPO with(nolock) Where Country = IsNull(@country,'')and State=IsNull(@state,'')
				and PriceIndex = IsNull(@priceindex,''))
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
If not exists (Select top 1 1 from dbo.HQMT with(nolock) Where MatlGroup=@matlgroup and Material=@finishedmatl
				and Active = 'Y')
begin
	select @errmsg = 'Missing or In-active Finished Material',@rcode = 1
	goto vspexit
end


--Check to see if Finished Material exists in IN Bill Materials for Matl Group
If not exists (Select top 1 1 From dbo.INBH with(nolock)Where MatlGroup=@matlgroup and FinMatl=@finishedmatl)
begin
		-- issue #136100 Check to see if Finished Material exists in IN Bill Materials Overrides
		if not exists (Select top 1 1 From dbo.INBO with(nolock)Where MatlGroup=@matlgroup and FinMatl=@finishedmatl)
		Begin
			select @errmsg = 'Invalid Finished Material in IN Bill of Materials',@rcode = 1
			goto vspexit
		End
end

--Check to see if Finished Material is being used in another index 
If exists (select top 1 1 from dbo.HQPM Where Country=@country and State=@state and PriceIndex <> @priceindex
			and MatlGroup=@matlgroup and FinishedMatl=@finishedmatl)
begin
	select @errmsg = 'Finished Material already used on another index',@rcode = 1
	goto vspexit
end

--Check to see if Component Material is missing/invalid or Inactive in HQ Materials
If not exists (Select top 1 1 from dbo.HQMT with(nolock) Where MatlGroup=@matlgroup and Material=@componentmatl
				and Active = 'Y')
begin
	select @errmsg = 'Missing or In-active Component Material',@rcode = 1
	goto vspexit
end

---- get description for component material
select @errmsg = Description
from dbo.HQMT with(nolock) where MatlGroup=@matlgroup and Material=@componentmatl

--Check to see if Component Material exists in IN Bill Materials for Matl Group and Finished Material
IF  exists (Select top 1 1 From dbo.INBM with(nolock)Where MatlGroup=@matlgroup and FinMatl=@finishedmatl 
				and CompMatl = @componentmatl)
	BEGIN
		goto vspexit
	END
ELSE
	BEGIN
		--Check to see if Component Material exists in IN Bill Materials Override for Matl Group and Finished Material
		If  not exists (Select top 1 1 From dbo.INBO with(nolock)Where MatlGroup=@matlgroup and FinMatl=@finishedmatl 
				and CompMatl = @componentmatl)
		Begin
			select @errmsg = 'Invalid Component Material for Finished Material in IN Bill of Materials',@rcode = 1
			goto vspexit
		End
	END




vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspHQPMFinMatlCompMatlVal] TO [public]
GO
