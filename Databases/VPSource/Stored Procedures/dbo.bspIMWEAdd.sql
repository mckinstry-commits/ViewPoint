SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMWEAdd    Script Date: 1/25/2002 9:12:16 AM ******/
   CREATE    procedure [dbo].[bspIMWEAdd]
   /*******************************************************************************
   * Created By:   GR 11/25/99
   * Modified By:
   *
   * This SP will insert the recrod read from text file into IMW Workd Edit table
   *
   * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
   *
   * Pass In
   *   ImportId		ImportId to insert
   *   Template		Template for this import
   *   Form            Form
   *   Identifier      Identifier
   *   Seq             Seq
   *   RecordSeq       RecordSeq
   *   ImportedVal     Imported value
   *   UploadVal       Upload Value
   *   RecordType      RecordType
   *
   *
   * RETURN PARAMS
   *   msg           Error Message, or Success message
   *
   * Returns
   *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
   *
   ********************************************************************************/
   
    (@importid varchar(20), @template varchar(10), @form varchar(30), @identifier int,
    @seq int, @recordseq int, @importedval varchar(60), @uploadval varchar(60),
    @recordtype varchar(30), @msg varchar(60) output)
   
    as
    set nocount on
   
    declare @rcode int
   
    select @rcode=0
   
    If @importid is null
       begin
       select @msg='Missing ImportId', @rcode=1
       goto bspexit
       end
   
    if @template is null
       begin
       select @msg='Missing Template', @rcode=1
       goto bspexit
       end
   
    if @form is null
       begin
       select @msg='Missing Form', @rcode=1
       goto bspexit
       end
   
    --insert into Work Edit
    INSERT IMWE (ImportId, ImportTemplate, Form, Identifier, Seq, RecordSeq, ImportedVal,
                  UploadVal, RecordType)
          Values (@importid, @template, @form, @identifier, @seq , @recordseq, @importedval,
                   @uploadval, @recordtype)
   
   bspexit:
        if @rcode<>0 select @msg=isnull(@msg,'Work Add') + char(13) + char(10) + '[bspIMWEAdd]'
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMWEAdd] TO [public]
GO
