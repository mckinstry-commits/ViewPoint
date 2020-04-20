SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMBidtekDefaultsEMLB]
/***********************************************************
* CREATED BY: Danf
* MODIFIED BY: DANF 03/19/02 - Added Record Type
*		CC	02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
*		CC  05/29/09 - Issue #133516 - Correct defaulting of Company
*		TRL 10/29/09-Issue133294 - Re-wrote procedure
*		AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
*
* Usage: Equipment Location Transfer Import
*	Used by Imports to create values for needed or missing
*      data based upon Bidtek default rules.
*
* Input params:
*	@ImportId	Import Identifier
*	@ImportTemplate	Import ImportTemplate
*
* Output params:
*	@msg		error message
*
* Return code:
*	0 = success, 1 = failure
************************************************************/
(@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), @Form varchar(20), @rectype varchar(30), @msg varchar(256) output)

as

set nocount on
   
declare @rcode int, @recode int, @desc varchar(256), @defaultvalue varchar(30), 
@minEquipRecSeq int,@Dflt_FromJCCo bCompany, @Dflt_FromJob bJob, @Dflt_FromLocation bLoc, @x smalldatetime, @z smalldatetime

  
declare @SourceID int, @BatchTransTypeID int, @CompanyID int,  @fromlocationid int, @fromjccoid int, @fromjobid int,
@CoId int, @ToJCCoId int, @ToJobId int, @ToLocationId int, @DateInId int, @TimeInId int, @EquipmentId int
   
/* check required input params */
if isnull(@ImportId,'')=''
begin
	select @desc = 'Missing ImportId.', @rcode = 1
	goto bspexit
end
if isnull(@ImportTemplate,'')=''
begin
	select @desc = 'Missing ImportTemplate.', @rcode = 1
	goto bspexit
end

if isnull(@Form,'')=''
begin
	select @desc = 'Missing Form.', @rcode = 1
	goto bspexit
end
  
-- Check ImportTemplate detail for columns to set Bidtek Defaults
select IMTD.DefaultValue From dbo.IMTD with(nolock)  Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
   
if @@rowcount = 0
begin
	select @desc='No Bidtek Defaults set up for ImportTemplate ' + @ImportTemplate +'.'
	goto bspexit
end

DECLARE 
	@OverwriteSource 	 			bYN,
	@OverwriteBatchTransType 	bYN,
	@OverwriteFromJCCo 	 		bYN,
	@OverwriteFromJob 	 			bYN,
	@OverwriteFromLocation 	 	bYN,
	@OverwriteCo						bYN,
	@IsCoEmpty 						bYN,
	@IsSourceEmpty 					bYN,
	@IsMthEmpty 						bYN,
	@IsBatchIdEmpty 					bYN,
	@IsBatchSeqEmpty 				bYN,
	@IsBatchTransTypeEmpty 		bYN,
	@IsMeterTransEmpty 			bYN,
	@IsEquipmentEmpty 				bYN,
	@IsFromJCCoEmpty 				bYN,
	@IsFromJobEmpty 				bYN,
	@IsFromLocationEmpty 		bYN,
	@IsToJCCoEmpty 					bYN,
	@IsToJobEmpty 					bYN,
	@IsToLocationEmpty 			bYN,
	@IsDateInEmpty 					bYN,
	@IsTimeInEmpty 					bYN,
	@IsEstOutEmpty 					bYN,
	@IsMemoEmpty 					bYN,
	@IsNotesEmpty 					bYN
			
SELECT @OverwriteSource = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Source', @rectype);
SELECT @OverwriteBatchTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BatchTransType', @rectype);
SELECT @OverwriteFromJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'FromJCCo', @rectype);
SELECT @OverwriteFromJob = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'FromJob', @rectype);
SELECT @OverwriteFromLocation = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'FromLocation', @rectype);
SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);
      
select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From dbo.IMTD with(nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
begin
	 UPDATE IMWE
	 SET IMWE.UploadVal = @Company
	 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
end

select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From dbo.IMTD with(nolock)
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
begin
	 UPDATE IMWE
	 SET IMWE.UploadVal = @Company
	 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
end
   
select @SourceID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Source', @rectype, 'Y')
if isnull(@SourceID,0) <> 0 AND ISNULL(@OverwriteSource, 'Y') = 'Y'
begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'EMXfer'
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @SourceID
end

if isnull(@SourceID,0) <> 0 AND (ISNULL(@OverwriteSource, 'Y') = 'N')
begin
	 UPDATE IMWE
	 SET IMWE.UploadVal = 'EMXfer'
	 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @SourceID
	 AND isnull(IMWE.UploadVal,'')=''
end
   
select @BatchTransTypeID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BatchTransType', @rectype, 'Y')
if isnull( @BatchTransTypeID,0) <>0 AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'Y')
begin
	 UPDATE IMWE
	 SET IMWE.UploadVal = 'A'
	 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
end
    
if isnull( @BatchTransTypeID,0) <>0 AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'N')
begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'A'
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
	AND isnull(IMWE.UploadVal,'')=''
end
   
select @fromjccoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'FromJCCo', @rectype, 'Y')

select @fromjobid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'FromJob', @rectype, 'Y')

select @fromlocationid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'FromLocation', @rectype, 'Y')

select @CoId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Co', @rectype, 'N')

select @ToJCCoId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ToJCCo', @rectype, 'N')

select @ToJobId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ToJob', @rectype, 'N')

select @ToLocationId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ToLocation', @rectype, 'N')

select @DateInId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DateIn', @rectype, 'N')

select @TimeInId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TimeIn', @rectype, 'N')

select @EquipmentId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Equipment', @rectype, 'N')
   
UPDATE IMWE
SET IMWE.UploadVal =substring(IMWE.UploadVal,1,2) + ':' + substring(IMWE.UploadVal,3,2)
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
and IMWE.Identifier = @TimeInId and Len(IMWE.UploadVal) = 4 and isnumeric(IMWE.UploadVal) =1
         
declare  @Co bCompany, @Mth bMonth, @BatchId bBatchID, @BatchSeq int, @BatchTransType char, @Source bSource,
@Equipment bEquip, @FromJCCo bCompany, @FromJob bJob, @FromLocation bLoc, @DateIn bDate, @TimeIn bDate,
@DateInV varchar(30)
   
declare WorkEditCursor cursor for
select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
from dbo.IMWE
inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
Order by IMWE.RecordSeq, IMWE.Identifier
   
open WorkEditCursor
-- set open cursor flag

--#142350 removing @importid
DECLARE @Recseq int,
    @Tablename varchar(20),
    @Column varchar(30),
    @Uploadval varchar(60),
    @Ident int

declare @crcsq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
@columnlist varchar(255), @complete int, @counter int, @records int, @oldrecseq int

fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval

select @crcsq = @Recseq, @complete = 0, @counter = 1

-- while cursor is not empty
while @complete = 0
begin
     if @@fetch_status <> 0  select @Recseq = -1
   
       --if rec sequence = current rec sequence flag
     if @Recseq = @crcsq
		begin
			If @Column='Co' and isnumeric(@Uploadval) =1 select @Co = Convert( int, @Uploadval)
			If @Column='Mth' and isdate(@Uploadval) =1 select @Mth = Convert( smalldatetime, @Uploadval)
			/*	If @Column='BatchSeq' and  isnumeric(@Uploadval) =1 select @BatchSeq = @Uploadval
			If @Column='BatchTransType' select @BatchTransType = @Uploadval*/
			If @Column='Source' select @Source = @Uploadval
			If @Column='Equipment' select @Equipment = @Uploadval
			/*  If @Column='EMTransType' select @EMTransType = @Uploadval*/
			If @Column='FromJCCo' and isnumeric(@Uploadval) =1 select @FromJCCo = convert(decimal(10,2),@Uploadval)
			If @Column='FromJob' select @FromJob = @Uploadval
			If @Column='FromLocation' select @FromLocation = @Uploadval
			If @Column='DateIn' and isdate(@Uploadval) = 1 select @DateIn = Convert( smalldatetime,@Uploadval), @DateInV = @Uploadval
			If @Column='TimeIn' and isdate(@Uploadval) = 1 select @TimeIn = Convert( smalldatetime,@Uploadval)
   
			IF @Column='Co' 
				IF @Uploadval IS NULL
					SET @IsCoEmpty = 'Y'
				ELSE
					SET @IsCoEmpty = 'N'
					
			IF @Column='Source' 
				IF @Uploadval IS NULL
					SET @IsSourceEmpty = 'Y'
				ELSE
					SET @IsSourceEmpty = 'N'
					
			IF @Column='Mth' 
				IF @Uploadval IS NULL
					SET @IsMthEmpty = 'Y'
				ELSE
					SET @IsMthEmpty = 'N'
					
			IF @Column='BatchId' 
				IF @Uploadval IS NULL
					SET @IsBatchIdEmpty = 'Y'
				ELSE
					SET @IsBatchIdEmpty = 'N'
					
			IF @Column='BatchSeq' 
				IF @Uploadval IS NULL
					SET @IsBatchSeqEmpty = 'Y'
				ELSE
					SET @IsBatchSeqEmpty = 'N'
					
			IF @Column='BatchTransType' 
				IF @Uploadval IS NULL
					SET @IsBatchTransTypeEmpty = 'Y'
				ELSE
					SET @IsBatchTransTypeEmpty = 'N'
					
			IF @Column='MeterTrans' 
				IF @Uploadval IS NULL
					SET @IsMeterTransEmpty = 'Y'
				ELSE
					SET @IsMeterTransEmpty = 'N'
					
			IF @Column='Equipment' 
				IF @Uploadval IS NULL
					SET @IsEquipmentEmpty = 'Y'
				ELSE
					SET @IsEquipmentEmpty = 'N'
					
			IF @Column='FromJCCo' 
				IF isnull(@Uploadval,'')=''
					SET @IsFromJCCoEmpty = 'Y'
				ELSE
					SET @IsFromJCCoEmpty = 'N'
					
			IF @Column='FromJob' 
				IF isnull(@Uploadval,'')=''
					SET @IsFromJobEmpty = 'Y'
				ELSE
					SET @IsFromJobEmpty = 'N'
					
			IF @Column='FromLocation' 
				IF isnull(@Uploadval,'')=''
					SET @IsFromLocationEmpty = 'Y'
				ELSE
					SET @IsFromLocationEmpty = 'N'
					
			IF @Column='ToJCCo' 
				IF @Uploadval IS NULL
					SET @IsToJCCoEmpty = 'Y'
				ELSE
					SET @IsToJCCoEmpty = 'N'
					
			IF @Column='ToJob' 
				IF @Uploadval IS NULL
					SET @IsToJobEmpty = 'Y'
				ELSE
					SET @IsToJobEmpty = 'N'
					
			IF @Column='ToLocation' 
				IF @Uploadval IS NULL
					SET @IsToLocationEmpty = 'Y'
				ELSE
					SET @IsToLocationEmpty = 'N'
					
			IF @Column='DateIn' 
				IF @Uploadval IS NULL
					SET @IsDateInEmpty = 'Y'
				ELSE
					SET @IsDateInEmpty = 'N'
					
			IF @Column='TimeIn' 
				IF @Uploadval IS NULL
					SET @IsTimeInEmpty = 'Y'
				ELSE
					SET @IsTimeInEmpty = 'N'
					
			IF @Column='EstOut' 
				IF @Uploadval IS NULL
					SET @IsEstOutEmpty = 'Y'
				ELSE
					SET @IsEstOutEmpty = 'N'
					
			IF @Column='Memo' 
				IF @Uploadval IS NULL
					SET @IsMemoEmpty = 'Y'
				ELSE
					SET @IsMemoEmpty = 'N'
					
			IF @Column='Notes' 
				IF @Uploadval IS NULL
					SET @IsNotesEmpty = 'Y'
				ELSE
					SET @IsNotesEmpty = 'N'   
   
			--fetch next record
			if @@fetch_status <> 0
			select @complete = 1

			select @oldrecseq = @Recseq

			fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
		end
     else
    		begin
    			select @x =null, @z = null , @minEquipRecSeq=Null
			select @x= min(convert(smalldatetime,b.ImportedVal)) , @z=min(isnull(convert(smalldatetime,c.ImportedVal),'') ) from  IMWE a 
			Left join IMWE b on a.ImportId = b.ImportId and a.ImportTemplate = b.ImportTemplate and a.Form = b.Form and a.RecordSeq = b.RecordSeq
			Left join IMWE c on a.ImportId = c.ImportId and a.ImportTemplate = c.ImportTemplate and a.Form = c.Form and a.RecordSeq = c.RecordSeq
			where a.ImportTemplate=@ImportTemplate and a.ImportId=@ImportId and a.UploadVal=@Equipment and a.Identifier = @EquipmentId 
			and b.Identifier = @DateInId and c.Identifier = @TimeInId 
					 
			select top 1 @minEquipRecSeq = c.RecordSeq from  IMWE a 
			Left join IMWE b on a.ImportId = b.ImportId and a.ImportTemplate = b.ImportTemplate and a.Form = b.Form and a.RecordSeq = b.RecordSeq
			Left join IMWE c on a.ImportId = c.ImportId and a.ImportTemplate = c.ImportTemplate and a.Form = c.Form and a.RecordSeq = c.RecordSeq
			where a.ImportTemplate=@ImportTemplate and a.ImportId=@ImportId and a.UploadVal=@Equipment and a.Identifier = @EquipmentId
			and b.Identifier = @DateInId and c.Identifier = @TimeInId 
			and convert(smalldatetime,b.ImportedVal) = @x and  isnull(convert(smalldatetime,c.ImportedVal),'') = @z
			
			if isnull(@fromjccoid,0)<>0 AND  (ISNULL(@OverwriteFromJCCo, 'N') = 'Y' OR ISNULL(@IsFromJCCoEmpty, 'Y') = 'Y')
			begin
				-- Set From JCCo to prior ToJCCo for the same piece of equipment where the date and time is less than the current record.
				select Top 1 @FromJCCo = ToJCCo.UploadVal
				from bIMWE Co
				join bIMWE ToJCCo 
				on Co.ImportId=ToJCCo.ImportId and Co.ImportTemplate=ToJCCo.ImportTemplate and Co.Form=ToJCCo.Form and Co.RecordSeq=ToJCCo.RecordSeq
				join bIMWE DateIn 
				on Co.ImportId=DateIn.ImportId and Co.ImportTemplate=DateIn.ImportTemplate and Co.Form=DateIn.Form and Co.RecordSeq=DateIn.RecordSeq
				join bIMWE TimeIn 
				on Co.ImportId=TimeIn.ImportId and Co.ImportTemplate=TimeIn.ImportTemplate and Co.Form=TimeIn.Form and Co.RecordSeq=TimeIn.RecordSeq
				join bIMWE Equipment
				on Co.ImportId=Equipment.ImportId and Co.ImportTemplate=Equipment.ImportTemplate and Co.Form=Equipment.Form and Co.RecordSeq=Equipment.RecordSeq
				where Co.ImportTemplate=@ImportTemplate and Co.ImportId=@ImportId and Co.Identifier=@CoId and ToJCCo.Identifier=@ToJCCoId 
				and DateIn.Identifier=@DateInId and TimeIn.Identifier=@TimeInId and Equipment.Identifier=@EquipmentId
				and Equipment.UploadVal = isnull(@Equipment,'') and convert(smalldatetime,DateIn.UploadVal) <= isnull(@DateIn,'')  
				and convert(smalldatetime,TimeIn.UploadVal) < isnull(@TimeIn,'')
				--and convert(smalldatetime,isnull(TimeIn.UploadVal,DateIn.UploadVal)) < case when isnull(@TimeIn,'') <> '' then @TimeIn else @DateIn end  
				order by convert(smalldatetime,DateIn.UploadVal) desc, convert(smalldatetime,TimeIn.UploadVal)desc
			
				if @minEquipRecSeq = @crcsq
					begin				
						exec @rcode = dbo.vspEMImportEquipCurrentLocation @Co, @Equipment, @Dflt_FromJCCo output,null ,null, @desc  output
						if @rcode =1 
						begin
							goto bspexit
						end
						
						UPDATE IMWE
						SET IMWE.UploadVal = @Dflt_FromJCCo
						where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@minEquipRecSeq and IMWE.Identifier = @fromjccoid			
					end
				else 		   	
					begin
						UPDATE IMWE
						SET IMWE.UploadVal = @FromJCCo
						where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @fromjccoid
					end
			end
			
			if isnull(@fromjobid,0)<>0 AND  (ISNULL(@OverwriteFromJob, 'N') = 'Y' OR ISNULL(@IsFromJobEmpty, 'Y') = 'Y')
			begin
				-- Set From Job to prior ToJob for the same piece of equipment where the date and time is less than the current record.
				select Top 1 @FromJob = ToJob.UploadVal
				from bIMWE Co
				join bIMWE ToJob 
				on Co.ImportId=ToJob.ImportId and Co.ImportTemplate=ToJob.ImportTemplate and Co.Form=ToJob.Form and Co.RecordSeq=ToJob.RecordSeq
				join bIMWE DateIn 
				on Co.ImportId=DateIn.ImportId and Co.ImportTemplate=DateIn.ImportTemplate and Co.Form=DateIn.Form and Co.RecordSeq=DateIn.RecordSeq
				join bIMWE TimeIn 
				on Co.ImportId=TimeIn.ImportId and Co.ImportTemplate=TimeIn.ImportTemplate and Co.Form=TimeIn.Form and Co.RecordSeq=TimeIn.RecordSeq
				join bIMWE Equipment
				on Co.ImportId=Equipment.ImportId and Co.ImportTemplate=Equipment.ImportTemplate and Co.Form=Equipment.Form and Co.RecordSeq=Equipment.RecordSeq
				where Co.ImportTemplate=@ImportTemplate and Co.ImportId=@ImportId and Co.Identifier=@CoId and ToJob.Identifier=@ToJobId 
				and DateIn.Identifier=@DateInId and TimeIn.Identifier=@TimeInId and Equipment.Identifier=@EquipmentId
				and Equipment.UploadVal = isnull(@Equipment,'') and convert(smalldatetime,DateIn.UploadVal) <= isnull(@DateIn,'')	
				and convert(smalldatetime,TimeIn.UploadVal) < isnull(@TimeIn,'')
				--and convert(smalldatetime,isnull(TimeIn.UploadVal,DateIn.UploadVal)) < case when isnull(@TimeIn,'') <> '' then @TimeIn else @DateIn end 
				order by convert(smalldatetime,DateIn.UploadVal) desc, convert(smalldatetime,TimeIn.UploadVal)desc
						
			 	if @minEquipRecSeq = @crcsq
					begin				
						exec @rcode = dbo.vspEMImportEquipCurrentLocation @Co, @Equipment, null,@Dflt_FromJob output ,null, @desc  output
						if @rcode = 1
						begin
							goto bspexit
						end
								
						UPDATE IMWE
						SET IMWE.UploadVal = @Dflt_FromJob
						where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@minEquipRecSeq and IMWE.Identifier = @fromjobid
					end
				else
					begin
						UPDATE IMWE
						SET IMWE.UploadVal = @FromJob
						where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @fromjobid
					end
			 end	
			 		
			if isnull(@fromlocationid,0)<>0 AND (ISNULL(@OverwriteFromLocation, 'N') = 'Y' OR ISNULL(@IsFromLocationEmpty, 'Y') = 'Y')
			begin
				-- Set From Location to prior ToLocation for the same piece of equipment where the date and time is less than the current record.
				select Top 1 @FromLocation = ToLocation.UploadVal
				from bIMWE Co
				join bIMWE ToLocation 
				on Co.ImportId=ToLocation.ImportId and Co.ImportTemplate=ToLocation.ImportTemplate and Co.Form=ToLocation.Form and Co.RecordSeq=ToLocation.RecordSeq
				join bIMWE DateIn 
				on Co.ImportId=DateIn.ImportId and Co.ImportTemplate=DateIn.ImportTemplate and Co.Form=DateIn.Form and Co.RecordSeq=DateIn.RecordSeq
				join bIMWE TimeIn 
				on Co.ImportId=TimeIn.ImportId and Co.ImportTemplate=TimeIn.ImportTemplate and Co.Form=TimeIn.Form and Co.RecordSeq=TimeIn.RecordSeq
				join bIMWE Equipment
				on Co.ImportId=Equipment.ImportId and Co.ImportTemplate=Equipment.ImportTemplate and Co.Form=Equipment.Form and Co.RecordSeq=Equipment.RecordSeq
				where Co.ImportTemplate=@ImportTemplate and Co.ImportId=@ImportId and Co.Identifier=@CoId and ToLocation.Identifier=@ToLocationId 
				and DateIn.Identifier=@DateInId and TimeIn.Identifier=@TimeInId and Equipment.Identifier=@EquipmentId
				and Equipment.UploadVal = isnull(@Equipment,'') and convert(smalldatetime,DateIn.UploadVal) <= isnull(@DateIn,'') 
				and  convert(smalldatetime,TimeIn.UploadVal) < isnull(@TimeIn,'')
				--and convert(smalldatetime,isnull(TimeIn.UploadVal,DateIn.UploadVal)) < case when isnull(@TimeIn,'') <> '' then @TimeIn else @DateIn end 
				order by convert(smalldatetime,DateIn.UploadVal) desc, convert(smalldatetime,TimeIn.UploadVal)desc
			
		 		if @minEquipRecSeq = @crcsq
					begin				
						exec @rcode = dbo.vspEMImportEquipCurrentLocation @Co, @Equipment, null,null ,@Dflt_FromLocation output, @desc  output
						if @rcode = 1
						begin
							goto bspexit
						end
						
						UPDATE IMWE
						SET IMWE.UploadVal = @Dflt_FromLocation
						where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@minEquipRecSeq  and IMWE.Identifier = @fromlocationid
					end
				else
					begin	
						UPDATE IMWE
						SET IMWE.UploadVal = @FromLocation
						where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @fromlocationid
					end
			end
			select @crcsq = @Recseq
			select @counter = @counter + 1
		end
end
   
close WorkEditCursor
deallocate WorkEditCursor
   
bspexit:
	select @msg = isnull(@desc,'Equipment Transfers') + char(13) + char(10) + '[bspIMBidtekDefaultsEMLB]'
	return @rcode





GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsEMLB] TO [public]
GO
