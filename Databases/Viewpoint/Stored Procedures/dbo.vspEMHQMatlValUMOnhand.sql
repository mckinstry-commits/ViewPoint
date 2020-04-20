SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE              proc [dbo].[vspEMHQMatlValUMOnhand]
/********************************************************
* CREATED BY: 	TV 06/26/03
* MODIFIED BY:	TV 02/11/04 - 23061 added isnulls	
* 				TV 02/08/05 - 27037 Invalid use of null calling  vspEMHQMatlValUMOnhand
*	            TV 07/18/07 - VP 6 conversion, set Matl Group to EMCo HQ Matl group or IN Co HQ Matl Group
*				TRL 04/24/08 Issue 127683 re-wrote stored procedure
*				TRL 02/23/08	Issue 127133 add output @hqmatl 
* INPUT PARAMETERS:
*   	EM Company
*   	Equipment
*   	HQ Material Group
*	Material (either HQ or EM equip no)
*	Default UM
*
* OUTPUT PARAMETERS:
*	Valid UM  (bEMEP.UM or bHQMT.StdUM)
*	Stocking Status = 'P' or 'S' where bHQMT.Stocked = 'Y' -> 'S' and 'N' -> 'P'
*   On Hand amount for part number
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
**********************************************************/
@emco bCompany = null, @equipment bEquip, @matlgroup bGroup=0, @partno varchar(30),
@defum bUM, @inco bCompany=null, @inloc bLoc=null,@stdum bUM output, @stockingstatus char(1) output,
@price bUnitCost output, @taxcode bTaxCode output, @onhand int output,@onorder int output, 
@matldesc varchar(30)=null output, @hqmatl bMatl output, @msg varchar(255) output
   
as
   
set nocount on
   
declare @rcode int, @category varchar(10), @matlvalid bYN,  @numrows int,  @stocked bYN
	
   
-- Default @stockingstatus to 'P' and change it later to 'S' if bHQMT.Stocked = 'Y' 
select @rcode=0, @stockingstatus = 'P'

if @emco is null
begin
   	select @msg='Missing EM Company', @rcode=1
   	goto vspexit
end
if IsNull(@equipment,'')=''
begin
   	select @msg='Missing Equipment', @rcode=1
   	goto vspexit
end
if @matlgroup= 0
begin
   	select @msg='Missing HQ Material Group', @rcode=1
   	goto vspexit
end

if IsNull(@partno,'')=''
begin
   	select @msg='Missing Part No', @rcode=1
   	goto vspexit
end
--Needs to allow a null UM tv 03/27/03
if IsNull(@defum,'')=''
begin
   	select @msg='Missing Default UM', @rcode=1
   	goto vspexit
end

--Validate Material against EMEP and/or HQMT 
exec @rcode = bspEMEquipPartVal @emco, @equipment, @matlgroup, @inco, @inloc, 
@partno, null, @hqmatl output, @stdum output, @price output, @stocked output, 
@category output,@taxcode output, @msg output

--Translate bHQMT.Stocked to EM stocking status 
select @stockingstatus = case when @stocked = 'Y' then 'S' else 'P' end
	
If @inco is not null and IsNull(@inloc,'') <> ''
	Begin
			--get on hand amount from INMT
		select @onhand = isnull(OnHand,0),@onorder = isnull(OnOrder,0)
		from dbo.INMT with(nolock)
		left join dbo.HQMT with(nolock) on INMT.MatlGroup=HQMT.MatlGroup and INMT.Material=HQMT.Material
		where INMT.INCo = @inco and INMT.Loc = @inloc and INMT.Material = @partno and INMT.MatlGroup=@matlgroup
		If @@rowcount = 0
		begin
			select @msg = 'Material: '+ @partno + ' doesnot exist in Inv Loc: ' + @inloc + '!',@rcode = 1 
			goto vspexit
		end
	End

vspexit:  
if @stdum is null 
begin
	select @stdum=@defum
end

/*   if @msg is null 
		begin
			select @msg = @partno
		end*/

If IsNull(@matldesc,'')= ''
begin
	select @matldesc= @msg 
end

    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMHQMatlValUMOnhand] TO [public]
GO
