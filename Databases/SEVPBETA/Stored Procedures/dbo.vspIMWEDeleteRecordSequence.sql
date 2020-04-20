SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspIMWEDeleteRecordSequence]
   /************************************************************************
   * CREATED:   DANF 01/02/2007
   * MODIFIED:  CC 05/30/2008 - Issue #128483 - Updated to delete note records. Corrected ImportID parameter length.
   *
   * Purpose of Stored Procedure
   *
   *    Delete detail from IMWE by record Sequence
   *    
   *           
   * Notes about Stored Procedure
   * 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   (@importid varchar(20), @template varchar(10), @recordtype varchar(30), @recordseq int, @msg varchar(255) output)
   
   as
   set nocount on
   
    declare @rcode int
   
    select @rcode=0
   
    If @importid is null
       begin
       select @msg='Missing ImportId.', @rcode=1
       goto bspexit
       end
   
    if @template is null
       begin
       select @msg='Missing Template.', @rcode=1
       goto bspexit
       end
   
    if @recordtype is null
       begin
       select @msg='Missing Record Type.', @rcode=1
       goto bspexit
       end

    if @recordseq is null
       begin
       select @msg='Missing Record Sequence.', @rcode=1
       goto bspexit
       end

	Delete IMWE 
	where ImportId = @importid and ImportTemplate = @template and RecordType = @recordtype and RecordSeq = @recordseq

	Delete IMWENotes 
	where ImportId = @importid and ImportTemplate = @template and RecordType = @recordtype and RecordSeq = @recordseq

   bspexit:
        if @rcode<>0 select @msg=isnull(@msg,'') + char(13) + char(10) + '[bspIMWEDeleteRecordSequence]'
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMWEDeleteRecordSequence] TO [public]
GO
