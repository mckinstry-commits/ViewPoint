SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspIMIMWEDataTypeFormat]
/************************************************************************
* CREATED:    MH 12/17/99
* MODIFIED:   DANF 01/15/00 expand format to 30 characters
*             DANF 10/30/02 12607 changed UploadVal is not null to isnull(UploadVal,'')<>''
* 		DANF 10/26/2004 - Issue 25901 Added with ( nolock )  and local fast_forward cursor
*		RBT 12/10/04 - issue #26468, do not format bPct datatype. Cleanup.
*		RBT 12/28/04 - issue #26662, expand datatype field length to 30.
*		RBT 01/12/05 - issue #26782, fix to close cursor before skipping records.
*		RBT 05/11/05 - issue #28663, fix to speed up processing - skip records where instring=outstring.
*		RBT 07/14/05 - issue #29289, clear variables before select statement.
*			GG 10/16/07 - #125791 - fix for DDDTShared
*
* Purpose of Stored Procedure
*
*     Find and format Imported Values to datatype specification in DDDTShared
*
*
* Notes about Stored Procedure
*
*
* returns 0 if successfull
* returns 1 and error msg if failed
*
*************************************************************************/
          
(@importid varchar(20), @importtemplate varchar(10), @rectype varchar(30), @msg varchar(80) = '' output)
          
 as
 set nocount on
  
  
 declare @inputtype int, @datatype varchar(30), @format varchar(30), @outstring varchar(100), @test varchar(20),
 @rcode int, @rc int, @count int
  
 --loop control
 declare @outercomplete int, @innercomplete int
  
 --cursor variables
 declare @identifier int, @instring varchar(100)
  
 --validation of input parameters
 if @importtemplate is null
 begin
 	select @rcode = 1, @msg = 'Missing Import Template'
 	goto bspexit
 end
 
 if @importid is null
 begin
 	select @rcode = 1, @msg = 'Missing Import Id'
 	goto bspexit
 end
          
         --cursor for outer loop
         declare Ident_curs cursor local fast_forward for
         select Identifier, RecordType from IMWE e where ImportId = @importid and 
         ImportTemplate = @importtemplate and UploadVal is not null and Identifier in
         	(select Identifier from IMTD d where ImportTemplate = @importtemplate and 
         	d.RecordType = e.RecordType and Datatype is not null) group by Identifier, RecordType
          
         open Ident_curs
         
         fetch next from Ident_curs into @identifier, @rectype
         
         select @outercomplete = 0
         
         while @outercomplete = 0
         begin
         	if @@fetch_status = 0
             	begin
         			declare Format_Val_curs cursor local fast_forward for
         			select distinct (UploadVal)
         			from IMWE where ImportId = @importid and RecordType = @rectype and isnull(UploadVal,'')<>'' and Identifier = @identifier
         			open Format_Val_curs
         			
         			fetch next from Format_Val_curs into @instring
         
         			select @innercomplete = 0
         
         			while @innercomplete = 0
         			begin
        				if @@fetch_status = 0
        				begin
        					select @datatype = Datatype
        					from IMTD with (nolock)
        					where ImportTemplate = @importtemplate and 
        					RecordType = @rectype and Identifier = @identifier
        
        					if isnull(@datatype,'') = 'bPct'	--issue #26468
     					begin	
     						close Format_Val_curs		--issue #26782
     						deallocate Format_Val_curs
        						goto getnextrec
        					end
     
   					--issue #29289
   					select @inputtype = null, @format = null, @count = null
   
 					select @inputtype = InputType, @format = InputMask, @count = InputLength
 					from dbo.DDDTShared (nolock)
 					where Datatype = @datatype
     
     				exec @rc = bspHQFormatMultiPart @instring, @format, @outstring output
     
     				if @inputtype = 1
     					begin
     						exec @rcode = bspIMFormatStripComma @instring, @outstring output, @msg output
     
     						if @rcode <> 0
     						begin
     							select @rcode = 1
     						end
     					end
     					if @inputtype = 0
     					begin
     						if @format = 'L' or @format is null
     						begin
     							select @outstring = @instring + SPACE(@count-DATALENGTH(@instring))
     						end
     
     						if @format = 'R'
     						begin
     							select @outstring = SPACE(@count-DATALENGTH(@instring)) + @instring
     						end
     					end
     
     					if @outstring is null or @outstring = ''
     						select @outstring = @instring
    
     					--issue #28663
    					if @instring <> @outstring
    					begin
    	 					update IMWE set UploadVal = @outstring
    	 					where ImportId = @importid and ImportTemplate = @importtemplate and
     						RecordType = @rectype and Identifier = @identifier and UploadVal = @instring
     					end
    
     					select @outstring = null
     						fetch next from Format_Val_curs into @instring
     				end
     				else
     				begin
     					select @innercomplete = 1
     					close Format_Val_curs
     					deallocate Format_Val_curs
     				end
     			end
     getnextrec:
     			fetch next from Ident_curs into @identifier, @rectype
         	end
         	else
         		begin
         			select @outercomplete = 1
         			close Ident_curs
         			deallocate Ident_curs
         		end
         end
         select @rcode = 0
         
         bspexit:
         	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMIMWEDataTypeFormat] TO [public]
GO
