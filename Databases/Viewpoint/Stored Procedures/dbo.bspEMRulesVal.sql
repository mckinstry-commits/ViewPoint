SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMRulesVal    Script Date: 8/28/99 9:34:31 AM ******/
   CREATE   proc [dbo].[bspEMRulesVal]
   /*************************************
   * Validates EM Rules Table
   *		
   * Created:  08/01/99 bc
   *			TV 02/11/04 - 23061 added isnulls
   * Pass:
   *	EM Rules Table
   *
   * Success returns:
   *	0 and Description, Job to Date or Period to Date option from bEMUR
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@emco bCompany, @rulestable varchar(10), @jp_flag char(1) = null output, @msg varchar(60) output)
   
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   select @jp_flag = JTDorPDFlag, @msg = Description
   from bEMUR
   where EMCo = @emco and RulesTable = @rulestable
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid Rules Table', @rcode = 1
   	end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMRulesVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMRulesVal] TO [public]
GO
