SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[vspPMImportEstimate]

  /*************************************
  * CREATED BY:		GP 03/11/2009
  * MODIFIED BY:	GP 07/06/2009 - Issue 133428 Timberline imports dynamic.
  *					GP 12/14/2009 - Issue 136451 varchar to float conversion error
  *					GF 02/10/2010 - issue #138042 - changes to store the import value not formatted to our data type.
  *					GP 07/05/2011 - TK-06552 uncommented code to set delimited file defaults *DO NOT COMMENT OUT AGAIN*
  *					GF 01/06/2011 - TK-11537 expand ColumnName to 128 characters.
  *
  *		Calls parser, sends out Template, Delimiter, and RecordType.
  *		Returns a table variable by Seq, ColumnName, and relevant Value.
  *		These values are then inserted into the PM Work Tables.
  *
  *		Input Parameters:
  *			PMCo
  *			Template
  *			ImportID
  *			RetainPCT
  *			VPUsername
  *    
  *		Output Parameters:
  *			rcode - 0 Success
  *					1 Failure
  *			msg - Return Message
  *		
  **************************************/
	(@PMCo bCompany = null, @Template varchar(10) = null, @ImportID varchar(10) = null,
		@VPUsername bVPUserName = null, @RetainPCT bPct = null, @msg varchar(500) = null output)
	as
	set nocount on


declare @rcode smallint, @PhaseGroup bGroup, @FileType char(1), @ImportRoutine varchar(20), @UserRoutine varchar(30),
	@DelimValue char(1), @OtherDelim char(1), @DefaultSIRegion varchar(6), @ItemOption char(1), 
	@ContractItem bContractItem, @ItemDesc bItemDesc, @RecordTypeCol int, @BegRecTypePos int, @EndRecTypePos int,
	@RecTypeLen int, @Delimiter char(1), @DelimCombo char(2), @OpenCursor int, @ValidCnt int, @Seq int, 
	@DataRow varchar(max), @InputString varchar(max), @Complete int, @Counter int, @RecordType varchar(20), 
	@errmsg varchar(500), @FixedItem varchar(30), @FixedPhase bPhase, @FixedDesc bItemDesc, @FixedNotes varchar(max), 
	@FixedCostType varchar(60), @FixedUnits varchar(60), @FixedUM varchar(60), @FixedUnitCost varchar(60),
	@FixedECM varchar(60), @FixedVendor varchar(60), @FixedWCRetgPct varchar(60), @FixedMaterial varchar(60),
	@FixedJob varchar(30), @FixedPhone varchar(20), @FixedFax varchar(20), @FixedMailAddress1 varchar(60),
	@FixedMailAddress2 varchar(60), @FixedMailCity varchar(30), @FixedMailState varchar(4), @FixedMailZip varchar(12),
	@FixedShipAddress1 varchar(60), @FixedShipAddress2 varchar(60), @FixedShipCity varchar(30), @FixedShipState varchar(4),
	@FixedShipZip varchar(12),
	@SQLString nvarchar(max), @i int,
	----TK-11537
	@ColumnName varchar(128), @Value varchar(max), @InsertSeq int, 
	@ReturnRecType varchar(20), @PhaseID varchar(20), @FixedMisc1 varchar(60), @FixedMisc2 varchar(60), @FixedMisc3 varchar(60),
	@SQLInsert nvarchar(max), @SQLValues nvarchar(max), @MatlGroup bGroup, @APCo bCompany, @FixedAmount varchar(60),
	@Amount decimal(16,2), @VendorGroup bGroup, @Units bUnits, @UnitCost bUnitCost, @RecTypeID varchar(10),
	--To build update for fixed width
	@x int, @FixedValue varchar(max), @FixedBegPos int, @FixedEndPos int,
	----TK-11537
	@FixedColumnName varchar(128), 
	@FixedSQLString nvarchar(max), @CurrentKeyID bigint, @FixedSQLString1 nvarchar(max)

---- #138042
create table #ColumnValues ( 
	Seq int, 
	Template varchar(20),
	----TK-11537
	ColumnName varchar(128),
	Value varchar(max),
	ImportValue varchar(max))

declare @FixedValues table ( 
	Seq int identity(1,1), 
	Template varchar(20) not null,
	----TK-11537
	ColumnName varchar(128) not null,
	Value varchar(max) null,
	BegPos int null,
	EndPos int null )
		
select @rcode = 0, @OpenCursor = 0, @ValidCnt = 0, @RecordType = 'Estimate',
	@FixedMisc1 = '', @FixedMisc2 = '', @FixedMisc3 = '', @FixedCostType = '', @FixedUnits = '', @FixedUM = '', 
	@FixedUnitCost = '', @FixedECM = '', @FixedVendor = '', @FixedWCRetgPct = '', @FixedMaterial = ''

-- VALIDATION --
if @PMCo is null
begin
	select @msg = 'Missing PM Company!', @rcode = 1
	goto vspexit
end

if @Template is null
begin
	select @msg = 'Missing Template!', @rcode = 1
	goto vspexit
end

if @ImportID is null
begin
	select @msg = 'Missing Import Id!', @rcode = 1
	goto vspexit
end

if @VPUsername is null
begin
	select @msg = 'Missing Viewpoint User Name!', @rcode = 1
	goto vspexit
end

--Get Import Template Data
select @ImportRoutine=ImportRoutine, @FileType=FileType, @DelimValue=Delimiter,
	   @OtherDelim=OtherDelim, @DefaultSIRegion=DefaultSIRegion, @ItemOption=ItemOption,
	   @ContractItem=ContractItem, @ItemDesc=ItemDescription, @RecordTypeCol=RecordTypeCol,
	   @BegRecTypePos=BegRecTypePos, @EndRecTypePos=EndRecTypePos
from PMUT with (nolock) where Template=@Template
if @@rowcount = 0
begin
	select @msg = 'Invalid Import Template!', @rcode = 1
	goto vspexit
end

--Make sure FileType is Delimited or Fixed
if @FileType not in ('D','F')
begin
	select @msg = 'Currently, only F-Fixed Length and D-Delimited file types can be processed.', @rcode = 1
	goto vspexit
end

--Set RecTypeLen for Fixed width files
if @FileType = 'F'
begin
	if @BegRecTypePos = @EndRecTypePos
	begin
		select @RecTypeLen = 1
	end
	else
	begin
		select @RecTypeLen = @EndRecTypePos - @BegRecTypePos + 1
	end
end

--Set the Delimiter based on DelimValue
if @DelimValue = '0' set @Delimiter = char(9)
if @DelimValue = '1' set @Delimiter = ';'
if @DelimValue = '2' set @Delimiter = ','
if @DelimValue = '3' set @Delimiter = char(32)
if @DelimValue = '4' set @Delimiter = '|'
if @DelimValue = '5' set @Delimiter = @OtherDelim

set @DelimCombo = '"' + @Delimiter

--Populate fixed value temp table
insert into @FixedValues(Template,ColumnName,BegPos,EndPos)
select @Template, ColumnName, BegPos, EndPos from PMUD with (nolock) where Template=@Template and RecordType=@RecordType
order by Seq

--Check for correct record type 136451
select @RecTypeID = isnull(EstimateInfoID,6) from dbo.PMUR with (nolock) where Template=@Template


begin try
	--Create cursor
	declare bcPMWX cursor LOCAL FAST_FORWARD for select Seq, DataRow
	from PMWX where PMCo=@PMCo and ImportId=@ImportID and isnull(RecType,@RecTypeID)=@RecTypeID

	--Open cursor
	open bcPMWX
	select @OpenCursor = 1, @ValidCnt = 0

	--Cycle through records using cursor
	Process_Loop:
		fetch next from bcPMWX into @Seq, @DataRow

		if (@@fetch_status <> 0) goto Process_Loop_End

		if @ImportRoutine = 'Timberline' goto Delimited_File

		if @FileType = 'F' goto FixedLength_File
		if @FileType = 'D' goto Delimited_File
		goto Process_Loop

	FixedLength_File:
		select @FixedBegPos = BegPos, @FixedEndPos = EndPos from PMUD with (nolock) where Template=@Template and
			RecordType=@RecordType and ColumnName='RecordType'

		if substring(@DataRow, @FixedBegPos, @FixedEndPos-@FixedBegPos) <> @RecTypeID goto Process_Loop

		--Trim spaces & make sure there is data
		set @DataRow = ltrim(rtrim(@DataRow))
		if len(@DataRow) = 0 goto Process_Loop
		--Fill with spaces to at least 200 characters for parsing substrings
		if len(@DataRow) < 412 select @DataRow = @DataRow + SPACE(411)

		--Step through and get all values
		set @x = 1

		while @x <= (select count(1) from @FixedValues)
		begin
			select @FixedColumnName=ColumnName, @FixedBegPos=BegPos, @FixedEndPos=EndPos from @FixedValues where Seq=@x

			set @Value = ltrim(rtrim(substring(@DataRow, @FixedBegPos, @FixedEndPos-@FixedBegPos)))

			update @FixedValues
			set Value = @Value
			where Template = @Template and ColumnName = @FixedColumnName

			set @x = @x + 1
		end		

		--Step through default values
		set @x = 1

		while @x <= (select count(1) from @FixedValues)
		begin
			select @FixedColumnName=ColumnName, @Value=Value, @FixedBegPos=BegPos from @FixedValues where Seq=@x
					
			exec dbo.vspPMImportDefaultValues @Template, @RecordType, @FixedColumnName, @Value, 
				@Value output, @msg output
	
			update @FixedValues
			set Value = @Value
			where Template = @Template and ColumnName = @FixedColumnName

			set @x = @x + 1
		end

		--Step through calculated default values
		set @x = 1

		while @x <= (select count(1) from @FixedValues)
		begin
			select @FixedColumnName=ColumnName, @Value=Value from @FixedValues where Seq=@x

			set @x = @x + 1
		end	

		--Get Fixed Values--
		select @FixedJob = Value from @FixedValues where Template=@Template and ColumnName='ProjectCode'

		select @FixedDesc = Value from @FixedValues where Template=@Template and ColumnName='Description'

		select @FixedPhone = Value from @FixedValues where Template=@Template and ColumnName='JobPhone'

		select @FixedFax = Value from @FixedValues where Template=@Template and ColumnName='JobFax'

		select @FixedMailAddress1 = Value from @FixedValues where Template=@Template and ColumnName='MailAddress'

		select @FixedMailAddress2 = Value from @FixedValues where Template=@Template and ColumnName='MailAddress2'

		select @FixedMailCity = Value from @FixedValues where Template=@Template and ColumnName='MailCity'

		select @FixedMailState = Value from @FixedValues where Template=@Template and ColumnName='MailState'

		select @FixedMailZip = Value from @FixedValues where Template=@Template and ColumnName='MailZip'

		select @FixedShipAddress1 = Value from @FixedValues where Template=@Template and ColumnName='ShipAddress'

		select @FixedShipAddress2 = Value from @FixedValues where Template=@Template and ColumnName='ShipAddress2'

		select @FixedShipCity = Value from @FixedValues where Template=@Template and ColumnName='ShipCity'

		select @FixedShipState = Value from @FixedValues where Template=@Template and ColumnName='ShipState'

		select @FixedShipZip = Value from @FixedValues where Template=@Template and ColumnName='ShipZip'

		select @FixedNotes = Value from @FixedValues where Template=@Template and ColumnName='Notes'

		--Set empty strings to null
		if @FixedDesc = '' set @FixedDesc = null
		if @FixedPhone = '' set @FixedPhone = null
		if @FixedFax = '' set @FixedFax = null
		if @FixedMailAddress1 = '' set @FixedMailAddress1 = null
		if @FixedMailAddress2 = '' set @FixedMailAddress2 = null
		if @FixedMailCity = '' set @FixedMailCity = null
		if @FixedMailState = '' set @FixedMailState = null
		if @FixedMailZip = '' set @FixedMailZip = null
		if @FixedShipAddress1 = '' set @FixedShipAddress1 = null
		if @FixedShipAddress2 = '' set @FixedShipAddress2 = null
		if @FixedShipCity = '' set @FixedShipCity = null
		if @FixedShipState = '' set @FixedShipState = null
		if @FixedShipZip = '' set @FixedShipZip = null
		if @FixedNotes = '' set @FixedNotes = null

		update PMWH set EstimateCode=@FixedJob, Description=@FixedDesc, JobPhone=@FixedPhone, JobFax=@FixedFax,
			MailAddress=@FixedMailAddress1, MailCity=@FixedMailCity, MailState=@FixedMailState, MailZip=@FixedMailZip,
			MailAddress2=@FixedMailAddress2, ShipAddress=@FixedShipAddress1, ShipCity=@FixedShipCity, ShipState=@FixedShipState,
			ShipZip=@FixedShipZip, ShipAddress2=@FixedShipAddress2, SIRegion=@DefaultSIRegion, Notes=@FixedNotes
		where PMCo=@PMCo and ImportId=@ImportID
		
		--UPDATE NEW/UD COLUMNS--
		--Set initial parameter values
		select @x = 1, @FixedSQLString = 'update PMWH set'

		--Step through and build string
		while @x <= (select count(1) from @FixedValues)
		begin
			select @FixedColumnName=ColumnName, @FixedValue=Value from @FixedValues where Seq=@x

			select @FixedValue = Value from @FixedValues where Template=@Template and ColumnName=@FixedColumnName

			set @FixedValue = char(39) + @FixedValue + char(39)

			set @FixedSQLString = @FixedSQLString + ' ' + @FixedColumnName + '=' + 
				isnull(@FixedValue,'null') + ','
			set @x = @x + 1
		end

		--Cleanup and execute SQL string
		set @FixedSQLString = stuff(@FixedSQLString, len(@FixedSQLString), 1, '')
		set @FixedSQLString = @FixedSQLString + ' where ImportId='+char(39)+@ImportID+char(39)+
			' and PMCo='+cast(@PMCo as varchar(3))

		if @FixedColumnName is not null
		begin
			execute sp_executesql @FixedSQLString
		end
		-------------------------

		goto vspexit

	Delimited_File:
		select @InputString = @DataRow, @Complete = 0, @Counter = 1
		if isnull(@InputString,'') = '' goto Process_Loop

		--Clear #ColumnValues table of pre-existing data
		delete #ColumnValues		

		while @Complete = 0
		begin
			--Get column names and values from parser
			insert into #ColumnValues exec dbo.vspPMImportParse @InputString, @Delimiter, @Template, @RecordType, @errmsg output
			if exists(select top 1 1 from #ColumnValues where Template=@Template)
			begin
				------------------
				-- GET DEFAULTS --
				------------------
				set @i = 1
				--Step through values and defaults
				while @i <= (select count(1) from #ColumnValues where Template=@Template)
				begin
					select @Value=Value, @ColumnName=ColumnName from #ColumnValues where Template=@Template and Seq=@i

					--Check for default values
					exec dbo.vspPMImportDefaultValues @Template, @RecordType, @ColumnName, @Value, 
						@Value output, @msg output
			
					update #ColumnValues
					set Value = @Value
					where Template=@Template and ColumnName=@ColumnName

					set @i = @i + 1
				end

				-----------------------------
				-- GET CALCULATED DEFAULTS --
				-----------------------------
				set @i = 1
				--Step through calculated defaults
				while @i <= (select count(1) from #ColumnValues where Template=@Template)
				begin
					select @ColumnName=ColumnName, @Value=Value from #ColumnValues where Template=@Template and Seq=@i
	
					set @i = @i + 1
				end			

				-------------------------
				-- BUILD INSERT STRING --
				-------------------------
				select @FixedJob = Value from #ColumnValues where Template=@Template and ColumnName='ProjectCode'
				select @FixedDesc = Value from #ColumnValues where Template=@Template and ColumnName='Description'
				select @FixedPhone = Value from #ColumnValues where Template=@Template and ColumnName='JobPhone'
				select @FixedFax = Value from #ColumnValues where Template=@Template and ColumnName='JobFax'
				select @FixedMailAddress1 = Value from #ColumnValues where Template=@Template and ColumnName='MailAddress'
				select @FixedMailCity = Value from #ColumnValues where Template=@Template and ColumnName='MailCity'
				select @FixedMailState = Value from #ColumnValues where Template=@Template and ColumnName='MailState'
				select @FixedMailZip = Value from #ColumnValues where Template=@Template and ColumnName='MailZip'
				select @FixedMailAddress2 = Value from #ColumnValues where Template=@Template and ColumnName='MailAddress2'
				select @FixedShipAddress1 = Value from #ColumnValues where Template=@Template and ColumnName='ShipAddress'
				select @FixedShipCity = Value from #ColumnValues where Template=@Template and ColumnName='ShipCity'
				select @FixedShipState = Value from #ColumnValues where Template=@Template and ColumnName='ShipState'
				select @FixedShipZip = Value from #ColumnValues where Template=@Template and ColumnName='ShipZip'
				select @FixedShipAddress2 = Value from #ColumnValues where Template=@Template and ColumnName='ShipAddress2'
				select @FixedNotes = Value from #ColumnValues where Template=@Template and ColumnName='Notes'

				update PMWH 
				set EstimateCode=@FixedJob, Description=@FixedDesc, JobPhone=@FixedPhone, JobFax=@FixedFax,
					MailAddress=@FixedMailAddress1, MailCity=@FixedMailCity, MailState=@FixedMailState, MailZip=@FixedMailZip,
					MailAddress2=@FixedMailAddress2, ShipAddress=@FixedShipAddress1, ShipCity=@FixedShipCity, ShipState=@FixedShipState,
					ShipZip=@FixedShipZip, ShipAddress2=@FixedShipAddress2, SIRegion=@DefaultSIRegion, Notes=@FixedNotes
				where PMCo=@PMCo and ImportId=@ImportID
				if @@rowcount <> 0
				begin
					--Set initial parameter values
					set @FixedSQLString1 = 'update PMWH set'

					--Step through and build string
					set @i = 1

					while @i <= (select count(1) from #ColumnValues where Template=@Template)
					begin
						select @Value=Value, @ColumnName=ColumnName from #ColumnValues where Template=@Template and Seq=@i

						if substring(@ColumnName, 1, 2) = 'ud'
						begin
							set @Value = char(39) + @Value + char(39)

							set @FixedSQLString1 = @FixedSQLString1 + ' ' + @ColumnName + '=' + 
								isnull(@Value,'null') + ','
						end

						set @i = @i + 1
					end

					--Cleanup and execute SQL string
					set @FixedSQLString1 = stuff(@FixedSQLString1, len(@FixedSQLString1), 1, '')
					set @FixedSQLString = @FixedSQLString1 + ' where PMCo='+cast(@PMCo as varchar(3)) + 
						' and ImportId='+char(39)+@ImportID+char(39)

					--If ud found, execute
					if patindex('%ud%', @FixedSQLString1) > 0
					begin
						execute sp_executesql @FixedSQLString
					end
				end

				set @Complete = 1
			end
		end


	Next_Phase_Record:
		select @FixedItem = '', @FixedDesc = '', @FixedPhase = '', @FixedNotes = '', @FixedMisc1 = '', @FixedMisc2 = '',
			@FixedMisc3 = '', @FixedCostType = '', @FixedUnits = '', @FixedUM = '', 
			@FixedUnitCost = '', @FixedECM = '', @FixedVendor = '', @FixedWCRetgPct = '', @FixedMaterial = ''
		set @ValidCnt = @ValidCnt + 1
		goto Process_Loop

	Process_Loop_End:
		select @msg = 'Estimate records: ' + cast(@ValidCnt as varchar(6)) + '. '

end try

begin catch
	select @msg = 'Error: ' + error_message() + char(13) + char(10) + 
		'Upload failed, make sure PM Import Template Detail information is correct.' + char(13) + char(10) +
		'Estimate - Record ' + cast(@ValidCnt as varchar(6)) + char(13) + char(10) +
		'vspPMImportEstimate line ' + cast(error_line() as varchar(3)), @rcode = 1
	goto vspexit
end catch


vspexit:
	drop table #ColumnValues

	if @OpenCursor = 1
	begin
		close bcPMWX
		deallocate bcPMWX
  		select @OpenCursor = 0
  	end

	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMImportEstimate] TO [public]
GO
