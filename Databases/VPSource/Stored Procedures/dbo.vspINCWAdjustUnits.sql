SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspINCWAdjustUnits]

(@inco tinyint = 0, @matlgroup tinyint = 0, @location varchar(10) = null, @username varchar(128)=null, @msg varchar(256) = null output)
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
      *   
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
--1.  Update Adjust Units
 update dbo.INCW 
 set AdjUnits = PhyCnt - SysCnt
where INCo = @inco  and Loc = @location and  MatlGroup = @matlgroup and PhyCnt is not null and SysCnt is not null
and UserName = @username

--2 Update Ready where Adj Units is null or 0
 update dbo.INCW 
 set Ready = 'N'
where INCo = @inco  and Loc = @location and  MatlGroup = @matlgroup and AdjUnits is null
and UserName = @username

vspexit:
--		If @rcode <> 0 
--		select @msg = @msg + Char(13) + Char(10)+ ' [vspINCWAdjustUnits]'

		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINCWAdjustUnits] TO [public]
GO
