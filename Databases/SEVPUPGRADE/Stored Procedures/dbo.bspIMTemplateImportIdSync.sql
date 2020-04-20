SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  Procedure [dbo].[bspIMTemplateImportIdSync]
   /***********************************************************
   * CREATED BY: GR 09/30/99
   * MODIFIED: GG 09/20/02 - #18522 ANSI nulls
   *
   * USAGE:
   * validates ImportID/Template
   *
   * INPUT PARAMETERS
   *   ImportID
   *
   * OUTPUT PARAMETERS
   *  Template
   *   @msg If Error, error message
   * RETURN VALUE
   *   0   success
   *   1   failure
   *****************************************************/
   	(@importid varchar(20) = null, @template varchar(10) output, @msg varchar(60) output)
   as
   
   set nocount on
   
   
   declare @rcode int
   select @rcode = 0
   
   if @importid is null	-- #18522
   	begin
   	select @msg = 'Missing ImportId!', @rcode = 1
   	goto bspexit
   	end
   
   if exists(select distinct(ImportTemplate) from IMWE where ImportId = @importid)
   	begin
           select @template = ImportTemplate from IMWE where ImportId = @importid
       end
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMTemplateImportIdSync] TO [public]
GO
