SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[vspINRollupRecCountGet]
( @inco tinyint =0, @locgroup int = null,  @mth smalldatetime=null,  @allrecords int =0 output, @rolleduprecords int output, @msg varchar(255) output)
 as
 /***********************************************************************************
      * CREATED BY:  TRL 10/04/05
      *	MODIFIED BY:	GP 06/15/09 - 133981 Added INCo to the joins to fix incorrect counts
      *
      * USAGE:
      * Called from IN Rollup
      *
      * INPUT PARAMETERS:
      *   @inco         IN Company
      *   @locgroup  Location Group
      *   @mth          Month
      *  
      * OUTPUT PARAMETERS
      *  @allreocrds     
      *  @rolleduprecords
      *   @msg         error message if something went wrong
      *
      * RETURN VALUE:
      *   0               success
      *   1               fail
      **************************************************************************************/
set nocount on


declare @rcode int
select @rcode = 0

If IsNull(@inco,0) =0
	begin
	select @msg = 'Invalid IN Co#!', @rcode = 1
	goto vspexit
	end

 if @mth is null
          begin
          select @msg = 'Missing Month!', @rcode = 1
          goto vspexit
          end

select @allrecords = count(*)  from dbo.INDT with(nolock)
 join dbo.INLM with(nolock)on INDT.Loc = INLM.Loc and INDT.INCo = INLM.INCo
where  Source <> 'IN Rollup' and INDT.INCo = @inco and INLM.LocGroup =  IsNull(@locgroup,INLM.LocGroup)  and Mth <= @mth 

select @rolleduprecords = count(distinct convert(varchar(10),INDT.Loc) + convert(varchar(10),Mth) + convert(varchar(10),Material) + convert(varchar(10),TransType)) 
from dbo.INDT join INLM with(nolock) on INDT.Loc = INLM.Loc and INDT.INCo = INLM.INCo
where  Source <> 'IN Rollup' and INDT.INCo = @inco and INLM.LocGroup =  IsNull(@locgroup,INLM.LocGroup)  and Mth <= @mth 

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINRollupRecCountGet] TO [public]
GO
