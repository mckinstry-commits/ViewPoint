SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspIMWHAdd]
   /*******************************************************************************
   * Created By:   GR 9/20/99
   * Modified By: CMW 08/05/02 issue # 18185 - ImportId improperly dimensioned.
   *
   * This SP will insert the import work header record. The first part will delete
   * the old importid if any. Then insert the IMWH importid record.
   *
   * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
   *
   * Pass In
   *   ImportId		ImportId to insert
   *   Template		Template for this import
   *   ImportDate		Date this importid was inserted
   *   ImportBy		User who inserted this importid
   *
   * RETURN PARAMS
   *   msg           Error Message, or Success message
   *
   * Returns
   *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
   *
   ********************************************************************************/
   
    (@importid varchar(20) = null, @template varchar(10) = null, @importby varchar(10) = null, @textfile varchar(60) = null,
    @records int = 0, @importdate smalldatetime = null, @msg varchar(255) output)
   
    as
    set nocount on
   
    declare @rcode int
   
    select @rcode=0
   
    If @importid is null
       begin
       select @msg='Missing ImportId', @rcode=1
       goto bspexit
       end
   
    if @textfile is null
       begin
       select @msg='Missing File', @rcode=1
       goto bspexit
       end
   
    select * from IMTH where ImportTemplate=@template
    If @@rowcount = 0
       begin
       select @msg='Template is missing in Template Header', @rcode=1
       goto bspexit
       end
   
    /* delete old importid if needed */
    delete from IMWH where ImportId=@importid
   
    /* insert IMWH */
   
    insert IMWH (ImportId, ImportTemplate, TextFile, ImportBy, NumOfRecords, ImportDate)
                   VALUES(@importid, @template, @textfile, @importby, @records, @importdate)
   
   bspexit:
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMWHAdd] TO [public]
GO
