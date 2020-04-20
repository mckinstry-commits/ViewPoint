SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspHRPRDefaultsVal]
   /************************************************************************
   * CREATED:  MH 7/9/03    
   * MODIFIED: MH 7/23/03   
   *			MH 9/29/04 - added dbo. prefix to tables and nolock hint
   *
   * Purpose of Stored Procedure
   *
   *    Centralize validation of PR Defaults.  Called from:
   *		bspHRValidateBeforeUpdate
   *		bspHRAddPREmployee
   *		bspHRInitPRGrid
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@prco bCompany, @race char(2), @prgroup bGroup, @dept bDept, @inscode bInsCode,
   	@craft bCraft, @class bClass, @localcode bLocalCode, @earncode bEDLCode, 
   	@occupcat varchar(10), @catstatus char(1), @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @race is not null and not exists(select 1 from dbo.bPRRC with (nolock) where PRCo = @prco and Race = @race)
   	begin
   		select @msg = 'Race code is invalid', @rcode =1
   		goto bspexit
   	end
   
   	if @prgroup is not null and not exists(select 1 from dbo.bPRGR (nolock) where PRCo = @prco and PRGroup =@prgroup)
   	begin
   		select @msg = 'PRGroup is invalid', @rcode = 1
   		goto bspexit
   	end
   
   	if @dept is not null and not exists(select 1 from dbo.bPRDP (nolock) where PRCo = @prco and PRDept = @dept)
   	begin
   		select @msg = 'PRDepartment is invalid', @rcode = 1
   		goto bspexit
   	end
   
   	if @inscode is not null and not exists(select 1 from dbo.bHQIC (nolock) where InsCode = @inscode)
   	begin
   		select @msg = 'Insurance Code is invalid', @rcode = 1
   		goto bspexit
   	end
   
   	if @craft is not null and not exists(select 1 from dbo.bPRCM (nolock) where PRCo = @prco and Craft = @craft)
   	begin
   		select @msg = 'Craft is invalid', @rcode = 1
   		goto bspexit
   	end
   
   	if @class is not null and not exists(select 1 from dbo.bPRCC (nolock) where PRCo = @prco and Craft = @craft
   		and Class = @class)
   	begin
   		select @msg = 'Class is invalid for craft', @rcode = 1
   		goto bspexit
   	end
   
   	if @localcode is not null and not exists(select 1 from dbo.bPRLI (nolock) where PRCo = @prco and
   		LocalCode = @localcode)
   	begin
   		select @msg = 'Local code is invalid', @rcode = 1
   		goto bspexit
   	end
   
   	if @earncode is not null and not exists(select 1 from dbo.bPREC (nolock) where PRCo = @prco and EarnCode = @earncode)
   	begin
   		select @msg = 'Earning code is invalid', @rcode = 1
   		goto bspexit
   	end
   
   	if @occupcat is not null and not exists(select 1 from dbo.bPROP (nolock) where PRCo = @prco and OccupCat=@occupcat)
   	begin
   		select @msg = 'Occupational Category is invalid', @rcode = 1
   		goto bspexit
   	end
   
   	if @catstatus is not null
   	begin
   		exec @rcode = bspPROccupCatStatusVal @catstatus, @msg output
   		if @rcode = 1 goto bspexit
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRPRDefaultsVal] TO [public]
GO
