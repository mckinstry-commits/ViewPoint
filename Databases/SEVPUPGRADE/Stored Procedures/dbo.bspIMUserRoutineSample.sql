SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMUserRoutineSample    Script Date: 10/11/99 ******/
   CREATE        proc [dbo].[bspIMUserRoutineSample]
   /***********************************************************
    * CREATED BY:
    *
    *
    * Usage:
    *	Used by Imports to create values for needed or missing
    *  data based upon Bidtek default rules. 
    *  This is designed to be used for import progress entries.
    *
    * Input params:
    *  @Company		Current Company
    *	@ImportId	   	Import Identifier
    *	@ImportTemplate	Import ImportTemplate
    *  @Form  			Imporrt Form
    *
    * Output params:
    *	@msg		error message
    *
    * Return code:
    *	0 = success, 1 = failure
    ************************************************************/
   
    (@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), @Form varchar(20), @msg varchar(120) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @desc varchar(120)
   
   /* check required input params */
   
   if @ImportId is null
     begin
     select @desc = 'Missing ImportId.', @rcode = 1
     goto bspexit
     end
   if @ImportTemplate is null
     begin
     select @desc = 'Missing ImportTemplate.', @rcode = 1
     goto bspexit
     end
   
   if @Form is null
     begin
     select @desc = 'Missing Form.', @rcode = 1
     goto bspexit
    end
   
   
   /* This sample will update the Co column for all records in the imported file
      First we get the Co column ID for the update statement.
      Then we update imwe with the current company value
   
   declare @CompanyID int
   
   select @CompanyID = DDUD.Identifier From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
   if @@rowcount <> 0
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
    end */
   
   
   
   /* This sample code will update the taxcode and tax amount columns to 0
      As in the above example we need the ID of the TaxCode and TaxAmount column.
      Then we update the IMWE table setting the column to 0.
   
   
   declare @TaxAmountID int, @TaxBasisID int
   
   select @TaxBasisID = DDUD.Identifier From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxBasis'
   
   select @TaxAmountID = DDUD.Identifier From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxAmount'
   
   UPDATE IMWE
   SET IMWE.UploadVal = 0
   where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.UploadVal is null and
   (IMWE.Identifier = @TaxAmountID or IMWE.Identifier = @TaxBasisID )*/
   
   
   /*
   
   declare @HaulTotalID int, @HaulBasisID int, @HaulRateID int,
   		@PayTotalID int, @PayBasisID int, @PayRateID int
   
   select @HaulBasisID = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HaulBasis'
   
   select @HaulTotalID = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HaulTotal'
   
   select @HaulRateID = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HaulRate'
   
   select @PayBasisID = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PayBasis'
   
   select @PayTotalID = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PayTotal'
   
   select @PayRateID = DDUD.Identifier From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PayRate'
   
    declare WorkEditCursor cursor for
    select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
        from IMWE with (nolock)
        inner join DDUD with (nolock) on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
        where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form and
        IMWE.Identifier in (@HaulTotalID, @HaulBasisID, @HaulRateID, @PayTotalID, @PayBasisID, @PayRateID)
        Order by IMWE.RecordSeq, IMWE.Identifier
   
   open WorkEditCursor
   -- set open cursor flag
   
   declare @Recseq int, @Tablename varchar(20), @Column varchar(30), @Uploadval varchar(60), @Ident int,
           @importid varchar(10), @seq int, @Identifier int
   
   declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
           @columnlist varchar(255), @complete int, @counter int, @records int, @oldrecseq int
   
   declare @HaulTotal bDollar, @HaulBasis bDollar, @HaulRate bUnitCost,
   		@PayTotal bDollar, @PayBasis bDollar, @PayRate bUnitCost
   
   fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
   
   select @currrecseq = @Recseq, @complete = 0, @counter = 1
   
   -- while cursor is not empty
   while @complete = 0
   
   begin
   
     if @@fetch_status <> 0
       select @Recseq = -1
   
       --if rec sequence = current rec sequence flag
     if @Recseq = @currrecseq
       begin
   
       If @Column='HaulRate' and  isnumeric(@Uploadval) =1 select @HaulRate = Convert( numeric(16,5), @Uploadval)
       If @Column='HaulBasis' and  isnumeric(@Uploadval) =1 select @HaulBasis = Convert( numeric(16,2), @Uploadval)
       If @Column='HaulTotal' and  isnumeric(@Uploadval) =1 select @HaulTotal = Convert( numeric(16,2), @Uploadval)
       If @Column='PayRate' and  isnumeric(@Uploadval) =1 select @PayRate = Convert( numeric(16,5), @Uploadval)
       If @Column='PayBasis' and  isnumeric(@Uploadval) =1 select @PayBasis = Convert( numeric(16,2), @Uploadval)
       If @Column='PayTotal' and  isnumeric(@Uploadval) =1 select @PayTotal = Convert( numeric(16,2), @Uploadval)
   
              --fetch next record
   
           if @@fetch_status <> 0
             select @complete = 1
   
           select @oldrecseq = @Recseq
   
           fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
   
       end
   
     else
   
       begin
   
   
       If isnull(@HaulBasis,0)=0 and isnull(@HaulRate,0)<>0 and isnull(@HaulTotal,0)<>0
    	     begin
   			select @HaulBasis = @HaulTotal / @HaulRate
   
            UPDATE IMWE
   	     SET IMWE.UploadVal = @HaulBasis
   	     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @HaulBasisID
           end
   
       If isnull(@PayBasis,0)=0 and isnull(@PayRate,0)<>0 and isnull(@PayTotal,0)<>0
    	     begin
   			select @PayBasis = @payTotal / @PayRate
   
            UPDATE IMWE
   	     SET IMWE.UploadVal = @PayBasis
   	     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @PayBasisID
           end
   
   
               select @currrecseq = @Recseq
               select @counter = @counter + 1
   
           end
   
   end
   
   
   
   close WorkEditCursor
   deallocate WorkEditCursor
   
   
   */
   bspexit:
       select @msg = isnull(@desc,'User Routine') + char(13) + char(10) + '[bspIMUserRoutineSample]'
   
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMUserRoutineSample] TO [public]
GO
