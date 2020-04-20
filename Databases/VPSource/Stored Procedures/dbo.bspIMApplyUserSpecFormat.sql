SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMApplyUserSpecFormat]
    /************************************************************************
    * CREATED:   MH 7/27/00
    * MODIFIED:  RBT 6/9/03 - Issue #21014, pass back error messages from bspIMFormatingOptions.
    *						Changed @msg size from 80 to 100.
    *			  danf 11/03/03 - Issue #22911 Only include template detail records with a User format other than null or empty.
    *			  RBT 12/29/03 - Issue #23334, allow multiple formats separated with " & "
    *			  RBT 02/20/06 - Issue #120275, fix multiple formats
    *			  CC 03/19/2008 - Issue #122980, added handling for notes
    *			  CC 12/01/2009 - Issue #136438, corrected formatting issue by changing union to union all
	*			 
    * Purpose of Stored Procedure
    *
    *    Apply Formats listed in IMTD to an ImportId.
    *
    * Notes about Stored Procedure
    *
    *
    * returns 0 if successfull
    * returns 1 and error msg if failed
    *
    *************************************************************************/
    
        (@importid varchar(20), @template varchar(10), @rectype varchar(30), @msg varchar(100) = '' output)
    
    as
    set nocount on
    
        declare @rcode int, @formatedval varchar(max), @fs varchar(3), @fslen integer
    
        select @rcode = 0
   	 select @fs = ' & '		--format separator
    	 select @fslen = 3
   
        --cursor variables
    
        declare @ident int, @format varchar(30), @recseq int, @uploadval varchar(max), @formatlist varchar(30)
    
        if @importid is null
            begin
                select @msg = 'Missing ImportID!', @rcode = 1
                goto bspexit
            end
    
        if @template is null
            begin
                select @msg = 'Missing Import Template!', @rcode = 1
                goto bspexit
            end
		DECLARE @IsNote bYN

        declare bcFormat_Cur cursor local fast_forward for
            select Identifier, FormatInfo from IMTD where ImportTemplate = @template and isnull(FormatInfo,'')<>''
    		and RecordType = @rectype
    
        open bcFormat_Cur
    
        fetch next from bcFormat_Cur into @ident, @format
    
        --outer loop....
        while @@fetch_status = 0
        begin
            DECLARE bcImportVal_Cur CURSOR LOCAL FAST_FORWARD FOR
			(	SELECT RecordSeq, CAST(UploadVal AS VARCHAR(MAX)), 'N'
				FROM IMWE
				WHERE ImportId = @importid and ImportTemplate = @template and Identifier = @ident
   				and RecordType = @rectype
			UNION 
				SELECT RecordSeq, UploadVal, 'Y'
				FROM IMWENotes
				WHERE ImportId = @importid and ImportTemplate = @template and Identifier = @ident
   				and RecordType = @rectype
			)
            open bcImportVal_Cur
   
            fetch next from bcImportVal_Cur into @recseq, @uploadval, @IsNote
   
            --inner loop....
            while @@fetch_status = 0
            BEGIN
   			if @uploadval is not null 
   				begin
	   				--#23334, check for multiple formats and call sequentially.
   					declare @endpos integer
   					declare @currformat varchar(30)
   				
   					select @endpos = 1
 					select @formatlist = @format	--issue #120275
  				
   					while @endpos > 0
   						begin
   							select @endpos = charindex(@fs, @formatlist)
	   						if isnull(@endpos, 0) > 0 
   								begin
   									--grab the next format
   									select @currformat = ltrim(substring(@formatlist, 1, @endpos-1))
   									--remove from the original string
	   								select @formatlist = substring(@formatlist, @endpos+@fslen, len(@formatlist)-(@endpos+@fslen-1))
   								end
   							else
   								begin
   									--only one format existed, or we are down to the last one.
   									select @currformat = ltrim(@formatlist)
   								end
   
   							select @msg = '', @formatedval = null
	   						exec @rcode = bspIMFormatingOptions @currformat, @uploadval, @formatedval output, @msg output
   							if @rcode = 0
   								begin
   									select @uploadval = @formatedval
  								end
   							else
   								begin
   									close bcImportVal_Cur
   									deallocate bcImportVal_Cur
   									close bcFormat_Cur
   									deallocate bcFormat_Cur
	   								goto bspexit
   								end
	   					end	-- while @endpos > 0
					IF @IsNote = 'N'
   	 		            update IMWE set UploadVal = @formatedval
   	         		    where ImportId = @importid and ImportTemplate = @template and Identifier = @ident
   	                 	and RecordSeq = @recseq and RecordType = @rectype
					ELSE
						update IMWENotes set UploadVal = @formatedval
   	         		    where ImportId = @importid and ImportTemplate = @template and Identifier = @ident
   	                 	and RecordSeq = @recseq and RecordType = @rectype
   				end --if @uploadval is not null 
   
               fetch next from bcImportVal_Cur into @recseq, @uploadval, @IsNote
   				select @rcode = 0, @msg = ''
            end
   
            close bcImportVal_Cur
            deallocate bcImportVal_Cur
   
            fetch next from bcFormat_Cur into @ident, @format
        end
   
        close bcFormat_Cur
        deallocate bcFormat_Cur
    
    bspexit:
    
         return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspIMApplyUserSpecFormat] TO [public]
GO
