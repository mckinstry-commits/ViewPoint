SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMGetNextMergeOrder ******/
CREATE  procedure [dbo].[bspPMGetNextMergeOrder]
/************************************************************************
 * Created By:	GF 04/12/2007 6.x  
 * Modified By:   
 *
 *
 * Purpose of Stored Procedure is to get the next merge order value for 
 * a document template from HQWF. Used in PM Document Templates form.
 *
 *    
 * INPUT PARAMETERS:
 * Template		- PM Document Template
 * WordTable	- PM Document Template Word Table Flag
 *
 * OUTPUT PARAMETERS:
 * Error Message = @msg or next merge order number   
 *           
 * 
 * 
 * returns 0 if successfull 
 * returns 1 and error msg if failed
 *
 *************************************************************************/
(@template bReportTitle = null, @wordtable bYN = 'N', @msg varchar(255) output)   	
as
set nocount on

declare @rcode int, @validcnt int

select @rcode = 0, @validcnt = 0, @msg = ''

---- get field count from HQWF
if not exists(select Seq from HQWF with (nolock) where TemplateName=@template and WordTableYN=@wordtable)
	begin
	select @validcnt = 0
	end
else
	begin
	select @validcnt = count(*) from HQWF with (nolock) where TemplateName=@template and WordTableYN=@wordtable
	if isnull(@validcnt,0) = 0 select @validcnt = 0
	end

select @msg = convert(varchar(5), isnull(@validcnt,0))



bspexit:
	 return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMGetNextMergeOrder] TO [public]
GO
