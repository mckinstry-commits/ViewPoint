SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[vspIMGetRecordCountIMWE]
   /************************************************************************
   * CREATED:    DANF
   * MODIFIED:
   *
   * Purpose of Stored Procedure
   *
   *    Return record count of IMWE
   *
   *
   * Notes about Stored Procedure
   *
   *
   * returns 0 if successfull
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@importid varchar(20), @importtemplate varchar(10), @reccount int = 0 output, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare  @rcode int
   
   if @importid is null
       begin
           select @msg = 'Missing ImportId', @rcode = 1
           goto bspexit
       end
   
   if @importtemplate is null
       begin
           select @msg = 'Missing Import Template', @rcode = 1
           goto bspexit
       end
   
	select @reccount = max(RecordSeq) 
	from IMWE with (nolock) 
	where ImportId = @importid and ImportTemplate = @importtemplate
   
   select @rcode = 0
   
   bspexit:
   
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMGetRecordCountIMWE] TO [public]
GO
