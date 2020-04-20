SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************************************/
CREATE proc [dbo].[bspMSTruckTypeValForOther]
/*************************************
 * Created By:   GF 07/27/2000
 * Modified By:
 *
 * Validates MS Truck Type for other modules.
 * First validates for the current company, if not found
 * then checks all other companies.
 *
 * Pass:
 * MS Company
 * Module
 * MS Truck Type to be validated
 *
 * Success returns:
 *	0 and Description from bMSTT
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@co bCompany = null, @module varchar(2) = null, @trucktype varchar(10) = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @co is null
   	begin
   	select @msg = 'Missing Company', @rcode = 1
   	goto bspexit
   	end

if @trucktype is null
   	begin
   	select @msg = 'Missing MS Truck Type', @rcode = 1
   	goto bspexit
   	end

---- validate truck type for EM
if @module = 'EM'
	BEGIN
	---- validate for current EM company
	select @msg=Description from MSTT with (nolock) where MSCo=@co and TruckType=@trucktype
	if @@rowcount <> 0 goto bspexit
	---- validate for all other EM companies
	select @msg=min(a.Description) from MSTT a with (nolock) 
	where a.TruckType=@trucktype and a.MSCo<>@co
	and exists(select * from EMCO b with (nolock) where b.EMCo=a.MSCo)
	if @@rowcount = 0
		begin
		select @msg = 'Not a valid MS Truck Type', @rcode = 1
		end
	goto bspexit
	END



bspexit:
	if @rcode <> 0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTruckTypeValForOther] TO [public]
GO
