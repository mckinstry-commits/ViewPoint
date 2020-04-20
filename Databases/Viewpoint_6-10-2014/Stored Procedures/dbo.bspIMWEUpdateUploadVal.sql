SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMWEUpdateUploadVal]
     /*******************************************************************************
     * Created By:   GR  10/07/99
     * Modified By:  CMW 08/05/02 issue #18185 - ImportId improperly dimensioned.
     *				  mh  12/17/02 issue #19180 - see comments below
     * 			  RBT 07/15/03 issue #21815 - update only records where old values matched.
     *				  RBT 09/05/03 issue #22375 - update where old value is null.
     *				  CC 03/31/08 issue #122980 - add support for notes/large fields
     *				  RM 10/12/09 issue #135927 - Add support for updating when @olduploadvalue is null
     * 
     * This SP will updates work table IMWE and XRefDetail if there is a change in
     * upload value
     *
     * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
     *
     * Pass In
     *
     *   ImportId
     *   Template		Template for this record type
     *   RecordType		Record Type
     *   Identifier		Identifier
     *   Seq             Seq
     *   XRefName        XRefName
     *   Imported Value
     *   Upload Value
     *
     * RETURN PARAMS
     *   msg           Error Message, or Success message
     *
     * Returns
     *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
     *
     ********************************************************************************/
     
      (@importid varchar(20), @template varchar(10), @recordtype varchar(30), @recseq int,
       @identifier int, @importedval varchar(max), @uploadval varchar(60), @olduploadval varchar(60),
       @msg varchar(255) output)
     
      as
      set nocount on
     
      declare @rcode int, @validcnt int, @xrefname varchar(30)
     
      select @rcode=0
     
       if @importid is null
         begin
         select @msg='Missing ImportId!', @rcode=1
         goto bspexit
         end
     
      if @template is null
         begin
         select @msg='Missing Template!', @rcode=1
         goto bspexit
         end
     
      if @recordtype is null
         begin
         select @msg='Missing Record Type!', @rcode=1
         goto bspexit
         end
     
      if @recseq is null
         begin
         select @msg='Missing Record Seq!', @rcode=1
         goto bspexit
         end
     
      if @identifier is null
         begin
         select @msg='Missing Identifier!', @rcode=1
         goto bspexit
         end
     
       --issue #22375
       if isnull(@olduploadval,'') = '' select @olduploadval = null
   
      -- check whether the work table is loaded
      select @validcnt=Count(*) from IMWE
      where ImportId=@importid and RecordType=@recordtype and ImportTemplate=@template
     
      if @validcnt = 0
         begin
             goto bspexit
         end
     
     --update IMWE with this upload value for the rest of the records with this
     --identifier and seq for this template/recordtype
     --...Having an upload value equal to the old upload value before updating (RT #21815).
     update IMWE set UploadVal=@uploadval
     where ImportId=@importid and RecordType=@recordtype
     and ImportTemplate=@template and Identifier=@identifier --and ImportedVal=@importedval (cmtd out - issue #19180)
     and (UploadVal=@olduploadval or (UploadVal is null and @olduploadval is null))
   
     update IMWENotes set UploadVal=@uploadval
     where ImportId=@importid and RecordType=@recordtype
     and ImportTemplate=@template and Identifier=@identifier --and ImportedVal=@importedval (cmtd out - issue #19180)
     and (UploadVal=@olduploadval or (UploadVal is null and @olduploadval is null))

     --get the Xrefname for this template/recordtype to update or insert XRef Detail
     select @xrefname=XRefName from IMTD
     where ImportTemplate=@template and RecordType=@recordtype and Identifier=@identifier
     
     if @xrefname is null or @xrefname = '' goto bspexit
     
     --check to see whether the record exisits in XRef Detail
     select @validcnt=Count(*) from IMXD
     where ImportTemplate=@template and XRefName=@xrefname and ImportValue=@importedval
     if @validcnt=0    --insert
         begin
             insert IMXD (ImportTemplate, XRefName, ImportValue, BidtekValue)
                    values (@template, @xrefname, @importedval, @uploadval)
         end
     else    --update
          begin
             update IMXD set BidtekValue=@uploadval
             where ImportTemplate=@template and XRefName=@xrefname and ImportValue=@importedval
         end
   
     bspexit:
     
          return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMWEUpdateUploadVal] TO [public]
GO
