SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[vspPMImportItem]

  /*************************************
  * CREATED BY:		GP 02/18/2009
  * MODIFIED BY:	GP 10/20/2009 - Issue #136222 added code to handle template master IncrementBy
  *					GP 10/27/2009 - issue 136329, fixed amount calculation on duplicate item records.
  *					GP 11/03/2009 - issue 135149, added VP Default for BillType field to fixed & delimeted code
  *					GF 11/07/2009 - issue #136446 wrap item with isnulls when checking for existing row
  *					GP 12/14/2009 - Issue 136451 varchar to float conversion error
  *					GP 12/15/2009 - Issue 136786 leaving insert string values null causing entire string null
  *					GF 12/15/2009 - issue #137070 use SIC description for item when none exists.
  *					GF 12/16/2009 - issue #137056 problem with duplicate item when increment by is zero.
  *					GF 02/10/2010 - issue #138042 - changes to store the import value not formatted to our data type.
  *					GF 02/10/2010 - issue #137957 - one item option and also items in the import file
  *					GP 06/10/2010 - issue #139960 - user override on UM not found, broken by 138042
  *					GF 01/20/2011 - issue #142984 - remmed out #139960 line of code.
  *					GP 07/05/2011 - TK-06552/TK-07610 uncommented code to set delimited file defaults *DO NOT COMMENT OUT AGAIN*
  *					GF 01/06/2011 - TK-11537 expand ColumnName to 128 characters.
  *
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


declare @rcode smallint, @FileType char(1), @ImportRoutine varchar(20), @UserRoutine varchar(30),
	@DelimValue char(1), @OtherDelim char(1), @DefaultSIRegion varchar(6), @ItemOption char(1), 
	@ContractItem bContractItem, @ItemDesc bItemDesc, @RecordTypeCol int, @BegRecTypePos int, @EndRecTypePos int,
	@RecTypeLen int, @Delimiter char(1), @DelimCombo char(2), @OpenCursor int, @ValidCnt int, @Seq int, 
	@DataRow varchar(max), @InputString varchar(max), @Complete int, @Counter int, @RecordType varchar(20), 
	@errmsg varchar(500), @FixedItem varchar(30), @FixedPhase bPhase, @FixedDesc bItemDesc, @FixedNotes varchar(max), 
	@SQLString nvarchar(max), @i int,
	----TK-11537
	@ColumnName varchar(128), @Value varchar(max), @InsertSeq int, 
	@ReturnRecType varchar(20), @ItemID varchar(20),
	--Item specific params
	@DItem varchar(16), @ItemLength varchar(10), @InputMask varchar(30),
	@FixedUnits varchar(60), @FixedUM varchar(60), @FixedUnitCost varchar(60),
	@FixedSIRegion varchar(60), @FixedSICode varchar(60), @FixedRetainPCT varchar(60),
	@FixedAmt varchar(60), @PCT bPct, @FixedMisc1 varchar(60), @FixedMisc2 varchar(60), @FixedMisc3 varchar(60),
	@Units bUnits, @UnitCost bUnitCost, @SQLInsert nvarchar(max), @SQLValues nvarchar(max), @RecTypeID varchar(10),
	--To fill import value columns
	@ImportItem varchar(30), @ImportUM varchar(30), 
	--To hold values to send for formatting
	@ImportSIRegion varchar(6), @ImportSICode varchar(16), @ImportDesc bItemDesc,
	@ImportAmount bDollar, @ImportUnits bUnits, @ImportUnitCost bUnitCost, @ImportNotes varchar(max),
	--To hold formatted values for insert
	@InsertItem bContractItem, @InsertSIRegion varchar(6), @InsertSICode varchar(16), 
	@InsertRetainPCT bPct, @InsertAmount bDollar, @InsertUnits bUnits,
	@InsertUnitCost bUnitCost, @InsertUM bUM, @InsertDesc bItemDesc, ----#137070
	--To build update for fixed width
	@x int, @FixedValue varchar(max), @FixedBegPos int, @FixedEndPos int,
	----TK-11537
	@FixedColumnName varchar(128), 
	@FixedSQLString nvarchar(max), @LastInsertSeq int,
	--To do update instead of insert for delimited
	@iItem bContractItem, @iSeq int, @iUM bUM, @iAmount bDollar, @iUnits bUnits, 
	@IncrementByOrig smallint, @IncrementBy bigint, @IsNumericTestValue varchar(max),
	@ImportYN char(1)

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
		
select @rcode = 0, @OpenCursor = 0, @ValidCnt = 0, @RecordType = 'Item',
	@FixedMisc1 = '', @FixedMisc2 = '', @FixedMisc3 = ''

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
	   @BegRecTypePos=BegRecTypePos, @EndRecTypePos=EndRecTypePos, @IncrementByOrig=IncrementBy
from PMUT with (nolock) where Template=@Template
if @@rowcount = 0
begin
	select @msg = 'Invalid Import Template!', @rcode = 1
	goto vspexit
end

---- #137056
if isnull(@IncrementByOrig,0) < 1 set @IncrementByOrig = 1

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


--Get input mask for bContractItem and create default item
select @InputMask = InputMask, @ItemLength = convert(varchar(10), InputLength) from dbo.DDDTShared (nolock) 
	where Datatype = 'bContractItem'
if isnull(@InputMask,'') = '' select @InputMask = 'R'
if isnull(@ItemLength,'') = '' select @ItemLength = '16'
if @InputMask in ('R','L')
begin
	select @InputMask = @ItemLength + @InputMask + 'N'
end 

exec bspHQFormatMultiPart '1', @InputMask, @DItem output

----Find Item records, parse them, then upload into PMWI #137957
set @ImportYN = 'N'
select @ImportYN=ContractItem from dbo.PMUR with (nolock) where Template=@Template

--When Item Option = 'I' add one item
if @ItemOption = 'I'
	begin
	set @FixedItem = isnull(@ContractItem,@DItem)
	set @FixedDesc = isnull(@ItemDesc,' Add via import process')
	set @FixedUnits = '0'
	set @FixedUM = 'LS'
	set @FixedUnitCost = '0'
	set @FixedSIRegion = @DefaultSIRegion
	set @FixedRetainPCT = convert(varchar(15),@RetainPCT)
	--Check if retain pct > 1 then divide by 100
	set @PCT = convert(float, @RetainPCT)
	if @PCT > 1 set @PCT = @PCT / 100
	set @FixedRetainPCT = convert(varchar(30), @PCT)

	--Set empty strings to null
	if @FixedDesc = '' set @FixedDesc = null
	if @FixedUM = '' set @FixedUM = null
	if @FixedNotes = '' set @FixedNotes = null
 
	--Execute stored proc to insert item record
	exec @rcode = dbo.bspPMWIAdd @PMCo, @ImportID, @FixedItem, @FixedSIRegion, @FixedSICode, @FixedDesc, @FixedUM, 
				@FixedRetainPCT, @FixedAmt, @FixedUnits, @FixedUnitCost, @FixedMisc1, @FixedMisc2, @FixedMisc3, @FixedNotes,
				@errmsg output
	if @rcode <> 0 
		begin
		select @msg = @errmsg, @rcode = 1
		goto vspexit
		end
	
	---- if we are not importing item records then we are done #137957
	if @ImportYN = 'N' goto vspexit
end



--Check for correct record type 136451
select @RecTypeID = isnull(ContractItemID,1) from dbo.PMUR with (nolock) where Template=@Template

if @ImportRoutine = 'Timberline' goto vspexit


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
		if len(@DataRow) < 200 select @DataRow = @DataRow + SPACE(200)

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

			if substring(@Value,1,2) = '**'
			begin
				if @FixedColumnName = 'Amount'
				begin
					select @Units = Value from @FixedValues where Template=@Template and ColumnName='Units'
					select @UnitCost = Value from @FixedValues where Template=@Template and ColumnName='UnitCost'							
					set @Value = @Units * @UnitCost
			
					update @FixedValues
					set Value = @Value
					where Template = @Template and ColumnName = @FixedColumnName
				end

				if @FixedColumnName = 'BillDescription'
				begin
					update @FixedValues
					set Value = (select Value from @FixedValues where Template=@Template and ColumnName='Description')
					where Template = @Template and ColumnName = @FixedColumnName
				end

				if @FixedColumnName = 'SIRegion'
				begin
					update @FixedValues
					set Value = (select DefaultSIRegion from PMUT with (nolock) where Template=@Template)
					where Template = @Template and ColumnName = @FixedColumnName
				end

				if @FixedColumnName = 'RetainPCT'
				begin
					update @FixedValues
					set Value = cast(@RetainPCT as varchar(10))
					where Template = @Template and ColumnName = @FixedColumnName
				end
				
				if @FixedColumnName = 'BillType' --135149
				begin
					update @FixedValues
					set Value = (select DefaultBillType from JCCO with (nolock) where JCCo=@PMCo)
					where Template = @Template and ColumnName = @FixedColumnName
				end
			end

			set @x = @x + 1
		end	

		--Get Fixed Values--
		select @FixedItem = Value from @FixedValues where Template=@Template and ColumnName='Item'

		select @FixedDesc = Value from @FixedValues where Template=@Template and ColumnName='Description'

		select @FixedUnits = Value from @FixedValues where Template=@Template and ColumnName='Units'

		select @FixedUM = Value from @FixedValues where Template=@Template and ColumnName='UM'

		select @FixedUnitCost = Value from @FixedValues where Template=@Template and ColumnName='UnitCost'

		select @FixedAmt = Value from @FixedValues where Template=@Template and ColumnName='Amount'

		select @FixedSICode = Value from @FixedValues where Template=@Template and ColumnName='SICode'

		select @FixedNotes = Value from @FixedValues where Template=@Template and ColumnName='Notes'
		
		set @FixedSIRegion = @DefaultSIRegion

		set @FixedRetainPCT = convert(varchar(15),@RetainPCT)

		if isnull(@FixedUM,'') = '' set @FixedUM = 'LS'
		------ check if retain pct > 1 then divide by 100
		set @PCT = convert(float, @RetainPCT)
		if @PCT > 1 set @PCT = @PCT / 100
		set @FixedRetainPCT = convert(varchar(30), @PCT)
		---- set empty strings to null
		if @FixedDesc = '' set @FixedDesc = null
		if @FixedUM = '' set @FixedUM = null
		if @FixedNotes = '' set @FixedNotes = null
		---- remove commas before insert
		select @FixedAmt = replace(@FixedAmt,',','')
		select @FixedUnits = replace(@FixedUnits,',','')
		select @FixedUnitCost = replace(@FixedUnitCost,',','')

		--Insert into bPMWI
		exec @rcode = dbo.bspPMWIAdd @PMCo, @ImportID, @FixedItem, @FixedSIRegion, @FixedSICode, @FixedDesc, 
			@FixedUM, @FixedRetainPCT, @FixedAmt, @FixedUnits, @FixedUnitCost, @FixedMisc1, @FixedMisc2, @FixedMisc3, @FixedNotes, @errmsg output
		if @rcode <> 0 
		begin
			select @msg = @errmsg, @rcode = 1
			goto vspexit
		end

		--UPDATE NEW/UD COLUMNS--
		--Set initial parameter values
		set @FixedSQLString = 'update PMWI set'

		--Get last insert sequence
		select @LastInsertSeq=max(Sequence) from PMWI with (nolock) where ImportId=@ImportID and PMCo=@PMCo

		--Step through and build string
		set @x = 13

		while @x <= (select count(1) from @FixedValues)
		begin
			select @FixedColumnName=ColumnName, @FixedValue=Value from @FixedValues where Seq=@x

			select @FixedValue = Value from @FixedValues where Template=@Template and ColumnName=@FixedColumnName

			set @FixedValue = char(39) + @FixedValue + char(39)

			set @FixedSQLString = @FixedSQLString + ' ' + @FixedColumnName + '=' + isnull(@FixedValue,'null') + ','
			set @x = @x + 1
		end

		--Cleanup and execute SQL string
		set @FixedSQLString = stuff(@FixedSQLString, len(@FixedSQLString), 1, '')
		set @FixedSQLString = @FixedSQLString + ' where ImportId='+char(39)+@ImportID+char(39)+
			' and Sequence='+cast(@LastInsertSeq as varchar(5))+' and PMCo='+cast(@PMCo as varchar(3))

		execute sp_executesql @FixedSQLString
		-------------------------

		goto Next_Phase_Record


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
	
					if substring(@Value,1,2) = '**'
					begin
						if @ColumnName = 'Amount'
						begin
							select @Units = Value from #ColumnValues where Template=@Template and ColumnName='Units'
							select @UnitCost = Value from #ColumnValues where Template=@Template and ColumnName='UnitCost'							
							set @Value = isnull(@Units,0) * isnull(@UnitCost,0)
					
							update #ColumnValues
							set Value = @Value
							where Template=@Template and ColumnName=@ColumnName
						end

						if @ColumnName = 'BillDescription'
						begin
							update #ColumnValues
							set Value = (select Value from #ColumnValues where Template=@Template and ColumnName='Description')
							where Template=@Template and ColumnName=@ColumnName
						end

						if @ColumnName = 'SIRegion'
						begin
							update #ColumnValues
							set Value = (select DefaultSIRegion from PMUT with (nolock) where Template=@Template)
							where Template=@Template and ColumnName=@ColumnName
						end

						if @ColumnName = 'RetainPCT'
						begin
							update #ColumnValues
							set Value = cast(@RetainPCT as varchar(10))
							where Template=@Template and ColumnName=@ColumnName
						end
						
						if @ColumnName = 'BillType' --135149
						begin
							update #ColumnValues
							set Value = (select DefaultBillType from JCCO with (nolock) where JCCo=@PMCo)
							where Template=@Template and ColumnName=@ColumnName
						end						
					end

					set @i = @i + 1
				end	

				-------------------------
				-- BUILD INSERT STRING --
				-------------------------
				set @i = 1
				---- #138042
				select @ImportItem = isnull(ImportValue,'') from #ColumnValues where ColumnName='Item'
				select @ImportUM = isnull(ImportValue,'') from #ColumnValues where ColumnName='UM'
				---- #138042
				select @ImportSIRegion = Value from #ColumnValues where ColumnName='SIRegion'
				select @ImportSICode = Value from #ColumnValues where ColumnName='SICode'
				select @ImportDesc = Value from #ColumnValues where ColumnName='Description'
				select @ImportAmount = isnull(cast(replace(Value,',','') as float),0) from #ColumnValues where ColumnName='Amount'
				select @ImportUnits = isnull(cast(replace(Value,',','') as float),0) from #ColumnValues where ColumnName='Units'
				select @ImportUnitCost = isnull(cast(replace(Value,',','') as float),0) from #ColumnValues where ColumnName='UnitCost'
				select @ImportNotes = Value from #ColumnValues where ColumnName='Notes'
	
				select @InsertSeq = isnull(@IncrementBy,@IncrementByOrig)
				select @IncrementBy = @IncrementByOrig + isnull(@IncrementBy,@InsertSeq)
				
				---- check to verify that the @InsertSeq does not already exist in PMWI #137957
				if exists(select 1 from dbo.bPMWI with (nolock) where PMCo=@PMCo and ImportId = @ImportID and Sequence=@InsertSeq)
					begin
					select @InsertSeq = isnull(@IncrementBy,@IncrementByOrig)
					select @IncrementBy = @IncrementByOrig + isnull(@IncrementBy,@InsertSeq)
					end
				
				set @SQLInsert = 'insert PMWI(ImportId,Sequence,PMCo,ImportItem,ImportUM,'
				set @SQLValues = ' values(' + char(39) + @ImportID + char(39) + ',' + 
					ltrim(rtrim((cast(@InsertSeq as char(10))))) + ',' + cast(@PMCo as varchar(3)) + ',' +
					char(39) + @ImportItem + char(39) + ',' + char(39) + @ImportUM + char(39) + ','
					
				----#139960 and #142984 set UM to Value just incase user default/override present
				----select @ImportUM = case when isnull(Value,'') <> '' then Value end from #ColumnValues where ColumnName='UM'					
	
				while @i <= (select count(1) from #ColumnValues where Template=@Template)
				begin
					select @ColumnName=ColumnName, @Value=Value from #ColumnValues where Template=@Template and Seq=@i			
					
					--Do not add RecordType or ProjectCode
					if @ColumnName in ('RecordType','ProjectCode')
					begin
						set @i = @i + 1
					end
					else
					begin
						--Format values & check for cross references
						if @ColumnName = 'Item'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatItem @PMCo, @ImportID, @ImportItem, @ImportSIRegion, 
								@ImportSICode, @ImportDesc, @ImportUM, @RetainPCT, @ImportAmount, @ImportUnits, 
								@ImportUnitCost,null, null, null, @ImportNotes, 
								@InsertItem output, null, null, 
								null, null, null, null, null, null, @errmsg output

							if @InsertItem is not null select @Value = @InsertItem, @iItem = @InsertItem
							select @InsertItem = NULL
						end
						if @ColumnName = 'SIRegion'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatItem @PMCo, @ImportID, @ImportItem, @ImportSIRegion, 
								@ImportSICode, @ImportDesc, @ImportUM, @RetainPCT, @ImportAmount, @ImportUnits, 
								@ImportUnitCost,null, null, null, @ImportNotes, 
								null, @InsertSIRegion output, null, 
								null, null, null, null, null, null, @errmsg output

							if @InsertSIRegion is not null set @Value = @InsertSIRegion
							select @InsertSIRegion = null
						end
						if @ColumnName = 'SICode'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatItem @PMCo, @ImportID, @ImportItem, @ImportSIRegion, 
								@ImportSICode, @ImportDesc, @ImportUM, @RetainPCT, @ImportAmount, @ImportUnits, 
								@ImportUnitCost,null, null, null, @ImportNotes, 
								null, null, @InsertSICode output, 
								null, null, null, null, null, @InsertDesc output, @errmsg output ---- #137070

							if @InsertSICode is not null set @Value = @InsertSICode
							---- #137070
							if @InsertDesc is not null update #ColumnValues set Value=@InsertDesc where Template=@Template and ColumnName='Description'
							select @InsertSICode = null, @InsertDesc = NULL
						end
						if @ColumnName = 'RetainPCT'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatItem @PMCo, @ImportID, @ImportItem, @ImportSIRegion, 
								@ImportSICode, @ImportDesc, @ImportUM, @RetainPCT, @ImportAmount, @ImportUnits, 
								@ImportUnitCost,null, null, null, @ImportNotes, 
								null, null, null, 
								@InsertRetainPCT output, null, null, null, null, null, @errmsg output

							if @InsertRetainPCT is not null set @Value = @InsertRetainPCT
							select @InsertRetainPCT = null
						end
						if @ColumnName = 'Amount'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatItem @PMCo, @ImportID, @ImportItem, @ImportSIRegion, 
								@ImportSICode, @ImportDesc, @ImportUM, @RetainPCT, @ImportAmount, @ImportUnits, 
								@ImportUnitCost,null, null, null, @ImportNotes, 
								null, null, null, 
								null, @InsertAmount output, null, null, null, null, @errmsg output

							set @Value = isnull(@InsertAmount,0)
							--select @InsertAmount = null
						end
						if @ColumnName = 'Units'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatItem @PMCo, @ImportID, @ImportItem, @ImportSIRegion, 
								@ImportSICode, @ImportDesc, @ImportUM, @RetainPCT, @ImportAmount, @ImportUnits, 
								@ImportUnitCost,null, null, null, @ImportNotes, 
								null, null, null, 
								null, null, @InsertUnits output, null, null, null, @errmsg output

							if @InsertUnits is not null set @Value = @InsertUnits
							--select @InsertUnits = null
						end
						if @ColumnName = 'UnitCost'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatItem @PMCo, @ImportID, @ImportItem, @ImportSIRegion, 
								@ImportSICode, @ImportDesc, @ImportUM, @RetainPCT, @ImportAmount, @ImportUnits, 
								@ImportUnitCost,null, null, null, @ImportNotes, 
								null, null, null, 
								null, null, null, @InsertUnitCost output, null, null, @errmsg output

							if @InsertUnitCost is not null set @Value = @InsertUnitCost
							select @InsertUnitCost = null
						end
						if @ColumnName = 'UM'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatItem @PMCo, @ImportID, @ImportItem, @ImportSIRegion, 
								@ImportSICode, @ImportDesc, @ImportUM, @RetainPCT, @ImportAmount, @ImportUnits, 
								@ImportUnitCost,null, null, null, @ImportNotes, 
								null, null, null, 
								null, null, null, null, @InsertUM output, null, @errmsg output

							if @InsertUM is not null set @Value = @InsertUM
							select @InsertUM = null
						end

						--Skip null and empty values, let default constraints handle them
						if @Value is null or @Value = ''
						begin
							set @i = @i + 1
							goto NextColumn
						end

						--Add column name and value
						set @SQLInsert = @SQLInsert + @ColumnName + ','

						set @Value = replace(@Value,'''','''''')
						set @Value = char(39) + @Value + char(39)
						set @SQLValues = @SQLValues + isnull(@Value,'null') + ','

						set @i = @i + 1
					end
					
					NextColumn: --To skip empty columns
				end		

				--Remove trailing comma & close parenthesis
				set @SQLInsert = stuff(@SQLInsert, len(@SQLInsert), 1, '')
				set @SQLInsert = @SQLInsert + ')'
				set @SQLValues = stuff(@SQLValues, len(@SQLValues), 1, '')
				set @SQLValues = @SQLValues + ')'
				set @SQLString = @SQLInsert + @SQLValues

				--Check if record exists, if so just update values, else insert
				----#136446
				select @iSeq = Sequence, @iUM = UM, @iAmount = Amount, @iUnits = Units
					from bPMWI with (nolock) where PMCo=@PMCo and ImportId=@ImportID and isnull(Item,'')=isnull(@iItem,'') and ImportItem=@ImportItem
				if @@rowcount <> 0
				begin
   					select @iAmount = isnull(@iAmount,0) + isnull(@InsertAmount,0)
   					if @iUM = @InsertUM select @iUnits = isnull(@iUnits,0) + isnull(@InsertUnits,0)
  					
   					update bPMWI
   					set Amount = @iAmount, Units = @iUnits
   					where PMCo = @PMCo and ImportId = @ImportID and Sequence = @iSeq
   					
   					set @ValidCnt = @ValidCnt - 1
				end
				else
				begin
					--Insert record	
					execute sp_executesql @SQLString
				end	
				
				select @InsertAmount = null	
				select @InsertUnits = null
						
				set @Complete = 1			
			end
		end
		
		goto Next_Phase_Record
		

	Next_Phase_Record:
		select @FixedItem = '', @FixedDesc = '', @FixedPhase = '', @FixedNotes = '', @FixedMisc1 = '', @FixedMisc2 = '', @FixedMisc3 = ''
		set @ValidCnt = @ValidCnt + 1
		goto Process_Loop

	Process_Loop_End:
		select @msg = 'Item records: ' + cast(@ValidCnt as varchar(6)) + '. '

end try

begin catch
	select @msg = 'Error: ' + error_message() + char(13) + char(10) + 
		'Upload failed, make sure PM Import Template Detail information is correct.' + char(13) + char(10) +
		'Item - Record ' + cast((@ValidCnt + 1) as varchar(6)) + char(13) + char(10) + 
		'vspPMImportItem line ' + cast(error_line() as varchar(3)), @rcode = 1
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
GRANT EXECUTE ON  [dbo].[vspPMImportItem] TO [public]
GO
