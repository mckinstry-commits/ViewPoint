SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMDeptVal    Script Date: 8/28/99 9:34:27 AM ******/
   CREATE    procedure [dbo].[bspEMDeptVal]
   /*************************************
   *
   *	TV 02/11/04 - 23061 added isnulls	
   *	TV 07/12/2005 - issue 29254 - Allow Deptartment and Category to be Null.
   * validates Department
   *
   * Pass:
   *	EMCO, Department
   *
   * Success returns:
   *	0 
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@emco bCompany = null, @dept bDept = null, @msg varchar(60) output)
   as 
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if isnull(@dept,'') = ''
   	begin
   	select @msg = 'Missing department', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bEMDM where EMCo = @emco and isnull(Department,'') = isnull(@dept,'')
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid Department', @rcode = 1
   		end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMDeptVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMDeptVal] TO [public]
GO
