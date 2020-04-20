SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspINCWReadyFlagSet]
(@inco tinyint = 0, @matlgroup tinyint = 0, @location varchar(10) = null, @username varchar(128)=null, @ready varchar(1) = 'N',@msg varchar(256) = null output) 
as
 /***********************************************************************
      * CREATED BY:  TRL 04/28/06
      *
      * USAGE:
      * Called from INPhyCount
      *
      * INPUT PARAMETERS:
      *   @inco         IN Company
      *   @matlgroup
      *   @location
      *   @username
      *   @ready (y/n)
      *  
      *  Output
      *   @msg         error message if something went wrong
      *
      * RETURN VALUE:
      *   0               success
      *   1               fail
**********************************************************************/
declare @rcode int

select @rcode = 0

If IsNull(@inco,0) =0
	begin
	select @msg = 'Invalid IN Co#!', @rcode = 1
	goto vspexit
	end

 if IsNull(@matlgroup,0) = 0 
          begin
          select @msg = 'Missing Material Group!', @rcode = 1
          goto vspexit
          end

 if  @location is null
          begin
          select @msg = 'Missing IN Location!', @rcode = 1 
          goto vspexit
          end

if  @username is null
          begin
          select @msg = 'Missing User Name!', @rcode = 1 
          goto vspexit
          end
 
if  @ready is null
          begin
          select @msg = 'Ready Flag has not be set!', @rcode = 1 
          goto vspexit
          end
 

 update dbo.INCW 
 set Ready = @ready
where INCo = @inco  and Loc = @location and  MatlGroup = @matlgroup and CntDate is not null and AdjUnits is not null
and UserName = @username

vspexit:
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINCWReadyFlagSet] TO [public]
GO
