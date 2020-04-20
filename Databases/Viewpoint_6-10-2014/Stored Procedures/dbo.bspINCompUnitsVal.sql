SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspINCompUnitsVal]
   /*******************************************************************************************
    * CREATED BY	: GR 12/08/99
    * Modified: GG 10/16/02 - #16039 - changed warning message
    *
    * USAGE:
    * This routine is used to validate the component material units i.e checks the On Hand
    * qunatity in IN location materials falls below zero. The warning is displayed only if
    * the NegWarn option is checked
    *
    * INPUT PARAMETERS
    * @inco            IN Company
    * @compmatl        Component Material
    * @comploc         Location where material resides
    * @matlgroup       Material Group
    * @compunits       Component Material Units
    *
    * Return 0 success
    *        1 error
    *
    ********************************************************************************************/
       (@inco bCompany = null, @compmatl bMatl = null, @comploc bLoc = null , @matlgroup bGroup = null,
       @compunits bUnits = null, @msg varchar(255) output )
   as
   
   set nocount on
   
   declare @rcode int, @negwarn bYN, @units bUnits
   
   select @rcode = 0
   
   if @inco is null
       begin
       select @msg='Missing IN Company', @rcode=1
       goto bspexit
       end
   
   if @compmatl is null
       begin
       select @msg='Missing Component Material', @rcode=1
       goto bspexit
       end
   
   if @comploc is null
       begin
       select @msg='Missing Component Location', @rcode=1
       goto bspexit
       end
   
   if @matlgroup is null
       begin
       select @msg='Missing Material Group', @rcode=1
       goto bspexit
       end
   
   select @negwarn = NegWarn from bINCO where INCo=@inco
   
   if @negwarn='Y'
       begin
       select @units = OnHand from bINMT
       where INCo=@inco and Loc = @comploc and MatlGroup = @matlgroup and Material = @compmatl
       if @units < @compunits
           begin
           select @msg =  'Units exceed current On Hand quantity', @rcode=1
           goto bspexit
           end
       end
   
   bspexit:
   
     --if @rcode <> 0 select @msg
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINCompUnitsVal] TO [public]
GO
