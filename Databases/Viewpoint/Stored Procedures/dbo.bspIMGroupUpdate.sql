SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMGroupUpdate    Script Date: 02/09/2000 9:36:08 AM ******/
    CREATE        proc [dbo].[bspIMGroupUpdate]
     /****************************************************************************
     * CREATED BY: 	DANF 05/22/2000
     *              DANF 02/06/2002
     * 				DANF 10/26/2004 - Issue 25901 Added with ( nolock ) and local fast forward cursor.
     *			    DANF 02/14/08 - Issue 127050 speed up query statement.
     *
     * USAGE:
     * 	Update Payroll enddating
     *
     * INPUT PARAMETERS:
     *
     * OUTPUT PARAMETERS:
   
     *	See Select statement below
     *
     * RETURN VALUE:
     * 	0 	    Success
     *	1 & message Failure
     *
     *****************************************************************************/
     (@importid varchar(20), @msg varchar(120) output)
   
     as
     set nocount on
   
     declare @rcode as integer, @prgroupid as int, @prcoid as int, @prenddateid as int, @prmonthid as int,
             @imweprco bCompany, @imweprgroup bGroup, @imweprenddate bDate, @imwemonth bDate,
             @prco bCompany, @prgroup bGroup, @prenddate bDate, @covar as varchar(60), @groupvar as varchar(60),
             @desc varchar(120), @var varchar(60), @cur as int
   
     select @rcode = 0, @cur = 0
   
     begin
   
   if @importid is null
     begin
     select @rcode = 1
     goto bspexit
     end
   
     select @prcoid = Identifier
     from DDUD with (nolock)
     where Form = 'PRTimeCards' and ColumnName = 'Co'
   
     select @prgroupid = Identifier
     from DDUD with (nolock)
     where Form = 'PRTimeCards' and ColumnName = 'PRGroup'
   
     select @prenddateid = Identifier
     from DDUD with (nolock)
     where Form = 'PRTimeCards' and ColumnName = 'PREndDate'
   
   
     select @prmonthid = Identifier
     from DDUD with (nolock)
     where Form = 'PRTimeCards' and ColumnName = 'Mth'
   
   
   declare WorkEditCursor cursor local fast_forward for
   select distinct(RecordSeq)
   from IMWE
   where ImportId = @importid
   Order by IMWE.RecordSeq
   
   open WorkEditCursor
   -- set open cursor flag
   select @cur = 1
   
   declare @Recseq int
   
   fetch next from WorkEditCursor into @Recseq
   
   
   
     if @@fetch_status = 0
      begin
   
       nxtseq:

   /* Old Code
   select @covar=Co.Co, @groupvar=PRGroup.PRGroup
   from bIMWE w with (nolock)
   left join (select  ImportId, ImportTemplate, RecordType, Identifier, RecordSeq, UploadVal AS 'Co' from bIMWE with (nolock) 
   		where Identifier=@prcoid
              group by ImportId,ImportTemplate, Form,  RecordType, Identifier, RecordSeq, UploadVal) 
   	     as Co on Co.ImportId=w.ImportId and Co.ImportTemplate=w.ImportTemplate and Co.RecordType=w.RecordType and Co.RecordSeq=w.RecordSeq
    left join (select  ImportId, ImportTemplate, RecordType, Identifier, RecordSeq, UploadVal AS 'PRGroup' from bIMWE with (nolock) 
   		where Identifier=@prgroupid
              group by ImportId,ImportTemplate, Form,  RecordType, Identifier, RecordSeq, UploadVal) 
   	     as PRGroup on PRGroup.ImportId=w.ImportId and PRGroup.ImportTemplate=w.ImportTemplate and PRGroup.RecordType=w.RecordType and PRGroup.RecordSeq=w.RecordSeq
    where w.ImportId = @importid and w.RecordSeq=@Recseq
   group by Co.Co, PRGroup.PRGroup
	*/
   
	   select @covar=Co.Co, @groupvar=PRGroup.PRGroup
	   from (select  ImportId, ImportTemplate, RecordType, Identifier, RecordSeq, UploadVal AS 'Co' from bIMWE with (nolock) 
				where Identifier=@prcoid
				  group by ImportId,ImportTemplate, Form,  RecordType, Identifier, RecordSeq, UploadVal) 
			   as Co 
		left join (select  ImportId, ImportTemplate, RecordType, Identifier, RecordSeq, UploadVal AS 'PRGroup' from bIMWE with (nolock) 
				where Identifier=@prgroupid
				  group by ImportId,ImportTemplate, Form,  RecordType, Identifier, RecordSeq, UploadVal) 
			   as PRGroup on PRGroup.ImportId=Co.ImportId and PRGroup.ImportTemplate=Co.ImportTemplate and PRGroup.RecordType=Co.RecordType and PRGroup.RecordSeq=Co.RecordSeq
		where Co.ImportId = @importid and Co.RecordSeq=@Recseq
	   group by Co.Co, PRGroup.PRGroup

       select @imweprco = null,@imweprgroup = null
   
       if @covar is not null and isnumeric(@covar)=1 select @imweprco = convert(int, @covar)
   
       if @groupvar is not null and isnumeric(@groupvar)=1 select @imweprgroup = convert(int, @groupvar)
   
   /*
   
       select @var = UploadVal
       from IMWE with (nolock)
       where ImportId = @importid and RecordSeq = @Recseq and Identifier = @prcoid
   
       select @imweprco = null
       if @var is not null and isnumeric(@var)=1 select @imweprco = convert(int, @var)
   
       select @var =  UploadVal
       from IMWE  with (nolock)
       where ImportId = @importid and RecordSeq = @Recseq and Identifier = @prgroupid
   
       select @imweprgroup = null
       if @var is not null and isnumeric(@var)=1 select @imweprgroup = convert(int, @var)
   */
       select @prenddate = PREndDate
       from IMPR with (nolock)
       where ImportId = @importid and Co = @imweprco and PRGroup = @imweprgroup
   
       select @imwemonth = BeginMth
       from PRPC with (nolock)
       where PRCo = @imweprco and PRGroup = @imweprgroup and PREndDate = @prenddate
   
       Update IMWE
       Set UploadVal = convert(varchar(60),@prenddate)
       where ImportId = @importid and RecordSeq = @Recseq and Identifier = @prenddateid
   
       Update IMWE
       Set UploadVal = convert(varchar(60),@imwemonth)
       where ImportId = @importid and RecordSeq = @Recseq and Identifier = @prmonthid
   
       fetch next from WorkEditCursor into @Recseq
       if @@fetch_status = 0 goto nxtseq
      end
   
   bspexit:
   
   if @cur = 1
    begin
      close WorkEditCursor
      deallocate WorkEditCursor
    end
   
   select @msg = isnull(@desc,'Group Update') + char(13) + char(10) + '[bspIMGroupUpdate]'
   
   return @rcode
   end

GO
GRANT EXECUTE ON  [dbo].[bspIMGroupUpdate] TO [public]
GO
