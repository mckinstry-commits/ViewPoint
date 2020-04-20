SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspIMGetTemplateInfo]
   /************************************************************************
   * CREATED:   RT 03/02/2006
   * MODIFIED:  CC Issue #128621 - Added RecordType to the order by clause to correct fixed length import issue.
   *
   * Purpose of Stored Procedure
   *
   *    Return the identifier information for given template.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successful 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   (@Template varchar(10), @msg varchar(60) output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 1
   
   	if @Template is null
   	begin
   		select @msg = 'Missing Template.', @rcode = 1
   		goto bspexit
   	end
   	
	select BegPos, EndPos, RecColumn, Identifier, RecordType from IMTA 
	where IMTA.ImportTemplate = @Template and 
	(BegPos is not null and EndPos is not null)
	Union 
	select BegPos, EndPos, RecColumn, Identifier, RecordType from IMTD 
	where IMTD.ImportTemplate = @Template 
	and (BegPos is not null and EndPos is not null) order by RecordType, RecColumn
   
    select @rcode = 0

   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMGetTemplateInfo] TO [public]
GO
