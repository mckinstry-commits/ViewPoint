SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspHQGetNextResponseOrder ******/
CREATE  procedure [dbo].[vspHQGetNextResponseOrder]
/************************************************************************
 * Created By:	Gartht 03/22/2007 6.x  
 * Modified By:   
 *
 *
 * Purpose of Stored Procedure is to get the next response order value for 
 * a document template from HQDocTemplateResponseField. Used in PM Document 
 * Templates form.
 *
 *    
 * INPUT PARAMETERS:
 * TemplateName		- PM Document Template
 * 
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
(@TemplateName bReportTitle = null, @msg varchar(255) output)   	
as
set nocount on

declare @rcode int, @validcnt int

select @rcode = 0, @validcnt = 0, @msg = ''

---- get field count from HQDocTemplateResponseField
if not exists(select Seq from HQDocTemplateResponseField with (nolock) where TemplateName=@TemplateName)
	begin
	select @validcnt = 0
	end
else
	begin
	select @validcnt = count(*) from HQDocTemplateResponseField with (nolock) where TemplateName=@TemplateName
	if isnull(@validcnt,0) = 0 select @validcnt = 0
	end

select @msg = convert(varchar(5), isnull(@validcnt,0))

bspexit:
	 return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspHQGetNextResponseOrder] TO [public]
GO
