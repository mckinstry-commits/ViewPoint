SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMApplyUserInputs]  
      
    /**************************************************  
    *  
    * Created By:  RT 10/16/03 - #13558  
    * Modified By: RT 01/10/05 - #19580, change to accomodate > 1 prompted key field.  
	* DANF 10/29/07 - #125640 - Corrected prompt on imports.  
	* CC 03/14/2008 - #122980 - Add notes handling
	* Dave C 4/20/2010 - #138711 - Corrected sp to also update to IMWENotes at the FillKeys goto
    *  
    * USAGE:  
    *  
    * Used on direct imports (non-batch) to apply user inputs to single value fields  
    *    and to duplicate all records for multiple values of one key.  
    *  
    * INPUT PARAMETERS  
    *    ImportID  
    *  
    * RETURN PARAMETERS  
    *    Error Message and  
    *  0 for success, or  
    *    1 for failure  
    *  
    *************************************************/  
    (@importid varchar(20), @template varchar(10), @rectype varchar(30), @errmsg varchar(255) = null output)  
      
    AS  
    set nocount on  
      
    declare @rcode int,  
      @maxrecseq int,  
      @currentreqseq int,  
      @seqoffset int,  
      @Identifier int,  
      @Value varchar(20),  
     @MultipleKeys int  
      
    select @rcode = 0,  
      @currentreqseq = 0,  
      @seqoffset = 0,  
     @MultipleKeys = 0  
      
    if @importid is null  
    begin  
     select @rcode = 1, @errmsg = 'Missing Import Id!'  
     goto bspexit  
    end  
      
    if @template is null  
    begin  
     select @rcode = 1, @errmsg = 'Missing template!'  
     goto bspexit  
    end  
      
    if exists(select 1 from IMKV a join IMKV b on a.ImportId = b.ImportId and a.RecordType = b.RecordType   
     and a.Identifier <> b.Identifier where a.IsKeyYN = 'Y' and b.IsKeyYN = 'Y')  
    begin  
    select @MultipleKeys = 1 --if >1 key field, treat all as single input.  
     goto FillKeys  
    end  
      
    declare InputKeys cursor local fast_forward for  
    select Identifier, Value from IMKV  
    where ImportId = @importid and RecordType = @rectype and IsKeyYN = 'Y'  
    order by Identifier, Value  
      
    --record sequences [1 - max(RecordSeq)] represent all original entries.  
    select @maxrecseq = max(RecordSeq)  
    from IMWE  
    where ImportId = @importid and ImportTemplate = @template and RecordType = @rectype  
      
    --loop through all key values and make copies of all data for each key after the first.  
    open InputKeys  
      
    fetch next from InputKeys into @Identifier, @Value  
    if @@fetch_status = 0  
    begin  
     --take care of the first key value  
     update IMWE set ImportedVal = @Value  
      where Identifier = @Identifier and ImportId = @importid and RecordType = @rectype and   
       RecordSeq >= 0  
       
  update IMWENotes set ImportedVal = @Value  
      where Identifier = @Identifier and ImportId = @importid and RecordType = @rectype and   
       RecordSeq >= 0      
  
     fetch next from InputKeys into @Identifier, @Value  
     --if there are more key values, duplicate all original records and update the key on the new records.  
     while @@fetch_status = 0   
     begin  
      --set our offset value for record sequence (assumes first seq = 1)  
      select @seqoffset = max(RecordSeq) from IMWE where ImportId = @importid and ImportTemplate = @template  
       and RecordType = @rectype  
      
      --copy all the rows with new record sequences  
      insert into IMWE(ImportId,ImportTemplate,Form,Seq,Identifier,RecordSeq,ImportedVal,UploadVal,RecordType)  
       select ImportId,ImportTemplate,Form,Seq,Identifier,RecordSeq + @seqoffset,ImportedVal,UploadVal,RecordType   
       from IMWE where ImportId = @importid and RecordType = @rectype and RecordSeq <= @maxrecseq  
      
      --copy all the rows with new record sequences for notes  
      INSERT INTO IMWENotes(ImportId,ImportTemplate,Form,Seq,Identifier,RecordSeq,ImportedVal,UploadVal,RecordType)  
       SELECT ImportId,ImportTemplate,Form,Seq,Identifier,RecordSeq + @seqoffset,ImportedVal,UploadVal,RecordType   
       FROM IMWENotes WHERE ImportId = @importid and RecordType = @rectype and RecordSeq <= @maxrecseq  
  
      --update key value  
      update IMWE set ImportedVal = @Value  
       where Identifier = @Identifier and ImportId = @importid and RecordType = @rectype and RecordSeq > @seqoffset  
      
   --update key value for notes  
      UPDATE IMWENotes SET ImportedVal = @Value  
       WHERE Identifier = @Identifier and ImportId = @importid and RecordType = @rectype and RecordSeq > @seqoffset  
  
      fetch next from InputKeys into @Identifier, @Value  
     end  
    end  
    close InputKeys  
    deallocate InputKeys  
      
     
    --now set all user inputs for all record sequences  
     
   FillKeys:  
   if @MultipleKeys = 1  --if >1 key field, treat all as single input.  
   begin  
    declare UserInputs cursor local fast_forward for  
    select Identifier, Value from IMKV  
    where ImportId = @importid and RecordType = @rectype  
    order by Identifier, Value  
   end  
   else  
   begin  
    declare UserInputs cursor local fast_forward for  
    select Identifier, Value from IMKV  
    where ImportId = @importid and RecordType = @rectype and IsKeyYN = 'N'  
    order by Identifier, Value  
   end  
     
    
    open UserInputs  
      
    fetch next from UserInputs into @Identifier, @Value  
    while @@fetch_status = 0  
    begin  
     update IMWE set ImportedVal = @Value  
      where Identifier = @Identifier and ImportId = @importid and RecordType = @rectype  
      
     update IMWENotes set ImportedVal = @Value    
	  where Identifier = @Identifier and ImportId = @importid and RecordType = @rectype  
      
     fetch next from UserInputs into @Identifier, @Value  
    end  
    close UserInputs  
    deallocate UserInputs  
      
      
    bspexit:  
      
    delete IMKV where ImportId = @importid and RecordType = @rectype  
      
    return @rcode  
GO
GRANT EXECUTE ON  [dbo].[bspIMApplyUserInputs] TO [public]
GO
