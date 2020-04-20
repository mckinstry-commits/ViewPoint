SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspVAGroupSecuityVal    Script Date: 8/28/99 9:35:02 AM ******/
   /****** Object:  Stored Procedure dbo.bspVAGroupSecuityVal    Script Date: 2/12/97 3:25:04 PM ******/
   CREATE     proc [dbo].[bspVAGroupSecuityVal]
   /*************************************
   * validates Group Security
   * modified by : DanF 03/19/04 - Issue 20980 Add Data Type Security Group to Job and Contract Expand Security Group to smallint
   *
   * Pass:
   *	Security Group to be validated
   *
   * Success returns:
   *	0 and Group Name from vDDSG
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@SecurityGroup int = null, @msg varchar(60) output)
   as
   set nocount on
   	declare @rcode int
   	select @rcode = 0
   
   if @SecurityGroup is null
   	begin
   	select @msg = 'Missing Security Group', @rcode = 1
   	goto bspexit
   	end
   
   
   select @msg = Name from dbo.DDSG with (nolock)
     where SecurityGroup=@SecurityGroup and GroupType = 0
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid Security Group', @rcode = 1
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspVAGroupSecuityVal] TO [public]
GO
