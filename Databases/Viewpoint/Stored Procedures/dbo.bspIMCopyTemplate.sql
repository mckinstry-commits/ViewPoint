SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspIMCopyTemplate]
    /************************************************************************
    * CREATED:    MH 9/19/00
    * MODIFIED:	MH 02/12/02 - corrected inserts to IMXH and IMTD due to 
    *							table changes.
    *              DANF 02/15/05 - Added new column UserRoutine to IMTH
    *              DANF 03/12/02 - Change insert to use columns names
    *				MH 5/21/03 - Include RecordType in insert to cross reference tables.
    *				RBT 04/08/04 - #24182 Copy new fields added by issue #22267 (XML importing).
    *				DANF 03/28/07 - Issue 124145 correct for invalid OverrideYN value.
    *
    * Purpose of Stored Procedure
    *
    *    Copy an ImportTemplate
    *
    *
    * Notes about Stored Procedure
    *
    *
    * returns 0 if successful
    * returns 1 and error msg if failed
    *
    *************************************************************************/
    
        (@srctemplate varchar(10), @desttemplate varchar(10), @desc varchar(30) = '', @msg varchar(80) = '' output)
    
    as
    set nocount on
    
        declare @rcode int, @count int, @cnt int
   	declare @srcRecType varchar(10), @opencurs tinyint 
    
        select @rcode = 0, @count = 0, @cnt = 0
    
        if @srctemplate is null
            begin
                select @msg = 'Missing Source Import Template.', @rcode = 1
                goto bspexit
            end
        else
            begin
                select @count = count(*)
                from IMTH
                where ImportTemplate = @srctemplate
    
                if @count <> 1
                    begin
                        select @msg = 'Invalid Source Template.', @rcode = 1
                        goto bspexit
                    end
            end
    
        if @desttemplate is null
            begin
                select @msg = 'Missing Destination Import Template Name.', @rcode = 1
                goto bspexit
            end
    
        else
            begin
                select @count = count(*)
                from IMTH
                where ImportTemplate = @desttemplate
    
                if @count > 0
                    begin
                        select @msg = 'Destination Template Name already in use.', @rcode = 1
                        goto bspexit
                    end
            end
    
    --create template header
    
    --user to create template header.  sp will copy rest of info.
    
        insert bIMTH (ImportTemplate, Description, UploadRoutine, BidtekRoutine, Form,
            MultipleTable, FileType, Delimiter, OtherDelim, TextQualifier, LastImport, SampleFile,
            RecordTypeCol, BegPos, EndPos, ImportRoutine, UserRoutine, DirectType, XMLRowTag)
            select @desttemplate, @desc, UploadRoutine, BidtekRoutine, Form,
            MultipleTable, FileType, Delimiter, OtherDelim, TextQualifier, LastImport, SampleFile,
            RecordTypeCol, BegPos, EndPos, ImportRoutine, UserRoutine, DirectType, XMLRowTag 
   		 from IMTH where ImportTemplate = @srctemplate
    
    
    --copy template detail
    
       delete bIMTD where ImportTemplate = @desttemplate
    
       insert bIMTD (ImportTemplate, RecordType, Seq, Identifier, DefaultValue, ColDesc, FormatInfo, Required,
                    XRefName, RecColumn, BegPos, EndPos, BidtekDefault, Datatype, UserDefault, OverrideYN, 
   				 UpdateKeyYN, UpdateValueYN, ImportPromptYN, XMLTag)
           select ImportTemplate = @desttemplate, RecordType, Seq, Identifier, DefaultValue, ColDesc, FormatInfo, Required,
                    XRefName, RecColumn, BegPos, EndPos, BidtekDefault, Datatype, UserDefault, Case isnull(OverrideYN,'') when '' then 'N' else OverrideYN end, 
   				 UpdateKeyYN, UpdateValueYN, ImportPromptYN, XMLTag
   		from IMTD where ImportTemplate = @srctemplate
   
   
    --copy record type
   
   	declare IMTR_curs cursor for
   	select RecordType from bIMTR where ImportTemplate = @srctemplate
   	
   	open IMTR_curs 
   	select @opencurs = 1
   	fetch next from IMTR_curs into @srcRecType
   
   	while @@fetch_status = 0
   	begin
 
    
    		select @cnt = (select count(*) from bIMTR where ImportTemplate = @desttemplate and RecordType = @srcRecType)
    
    		if @cnt = 0
   	 	begin
    		    insert bIMTR (ImportTemplate, RecordType, Form, Description, Skip)
        		    select @desttemplate, RecordType, Form, Description, Skip
            		from bIMTR
   	 	        where ImportTemplate = @srctemplate and RecordType = @srcRecType
    		end
    
    --copy xref header
        insert bIMXH (ImportTemplate, RecordType, XRefName, Identifier, PMCrossReference, PMTemplate)
            select @desttemplate, RecordType, XRefName, Identifier, PMCrossReference, PMTemplate
            from bIMXH
            where ImportTemplate = @srctemplate and RecordType = @srcRecType
    
    --copy xref detail
        insert bIMXD (ImportTemplate, RecordType, XRefName, ImportValue, BidtekGroup, BidtekValue)
            select @desttemplate, RecordType, XRefName, ImportValue, BidtekGroup, BidtekValue
            from bIMXD
            where ImportTemplate = @srctemplate and RecordType = @srcRecType
    
    --copy xref fields
        insert into bIMXF(ImportTemplate, RecordType, XRefName, ImportField)
            select @desttemplate, RecordType, XRefName, ImportField
            from bIMXF
            where ImportTemplate = @srctemplate and RecordType = @srcRecType
   
   		fetch next from IMTR_curs into @srcRecType 
    	end
    
    bspexit:
   
   	if @opencurs = 1
   	begin
   		close IMTR_curs
   		deallocate IMTR_curs
   	end
   
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMCopyTemplate] TO [public]
GO
