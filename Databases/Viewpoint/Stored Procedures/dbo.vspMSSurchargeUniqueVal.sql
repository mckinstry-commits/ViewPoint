SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************/
CREATE proc [dbo].[vspMSSurchargeUniqueVal]
/*************************************
* Created By:   GF 03/26/2010 - #129350 surcharges
* Modified By:
*
*
*
* validates MSCo,SurchargeCode,LocGroup,FromLoc,MatlGroup,Material,TruckType,UM,Zone,EffectiveDate
* to MSSurchargeCodeRates for uniqueness.
*
* Pass:
*   MSCo,HaulCode,LocGroup,FromLoc,MatlGroup,Category,Material,TruckType,UM,Zone,Seq
*
* Success returns:
*	0
*
* Error returns:
*	1 and error message
**************************************/
(@msco bCompany, @surchargecode smallint, @locgroup bGroup = null, @fromloc bLoc = null,
 @matlgroup bGroup, @category varchar(10) = null, @material bMatl = null, @trucktype varchar(10) = null,
 @um bUM = null, @zone varchar(10) = null, @seq int = null,  @msg varchar(255) output)
as
set nocount on
   
declare @rcode int, @validcnt int

select @rcode = 0, @msg=''
   
-- validate required columns
if @msco is null
   begin
   select @msg = 'Missing MS Company!', @rcode=1
   goto bspexit
   end

if @surchargecode is null
   begin
   select @msg = 'Missing Haul Code!', @rcode=1
   goto bspexit
   end

if @locgroup is null
   begin
   select @msg = 'Missing Location Group!', @rcode=1
   goto bspexit
   end

if @matlgroup is null
	begin
	select @msg = 'Missing Material Group!', @rcode=1
	goto bspexit
	end
 
 
---- check if record exists already
if @seq is null
	begin
	select @validcnt = Count(*) from bMSSurchargeCodeRates
	where MSCo=@msco and SurchargeCode=@surchargecode and LocGroup=@locgroup
	and isnull(FromLoc,'')=isnull(@fromloc,'') and MatlGroup=@matlgroup
	and isnull(Category,'')=isnull(@category,'') and isnull(Material,'')=isnull(@material,'')
	and isnull(TruckType,'')=isnull(@trucktype,'') and isnull(UM,'')=isnull(@um,'') 
	and isnull(Zone,'')=isnull(@zone,'') 
	if @validcnt > 0
		begin
		select @msg = 'Duplicate record, cannot insert!', @rcode=1
		goto bspexit
		end
	end
else
	begin
	select @validcnt = Count(*) from bMSSurchargeCodeRates
	where MSCo=@msco and SurchargeCode=@surchargecode and LocGroup=@locgroup
	and isnull(FromLoc,'')=isnull(@fromloc,'') and MatlGroup=@matlgroup
	and isnull(Category,'')=isnull(@category,'') and isnull(Material,'')=isnull(@material,'')
	and isnull(TruckType,'')=isnull(@trucktype,'') and isnull(UM,'')=isnull(@um,'') 
	and isnull(Zone,'')=isnull(@zone,'') and Seq <> @seq
	if @validcnt >0
		begin
		select @msg = 'Duplicate record, cannot update!', @rcode=1
		goto bspexit
		end
	end



bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode


		


GO
GRANT EXECUTE ON  [dbo].[vspMSSurchargeUniqueVal] TO [public]
GO
