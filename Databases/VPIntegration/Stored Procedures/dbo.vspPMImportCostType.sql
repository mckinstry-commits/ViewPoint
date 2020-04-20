SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[vspPMImportCostType]

/*************************************
* CREATED BY:	GP 02/18/2009
* MODIFIED BY:	GP 06/30/2009 - issue 134186 added check for cost type rollup before insert.
*				GP 07/14/2009 - Issue 133428 added defaults and ud insert to Timberline import.
*				GP 10/23/2009 - Issue 136125 cost value now imports properly for fixed width files.
*				GP 12/14/2009 - Issue 136451 varchar to float conversion error
*				GP 12/15/2009 - Issue 136786 leaving insert string values null causing entire string null
*				GF 02/10/2010 - issue #138042 - changes to store the import value not formatted to our data type.
*				GP 06/10/2010 - issue #139960 - user override on UM not found, broken by 138042
*				GF 01/20/2011 - issue #142984 - remmed out #139960 line of code.
*				GF 01/06/2011 - TK-11537 expand ColumnName to 128 characters.
*
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
	@ReturnRecType varchar(20), @ItemID varchar(20) ,@PhaseGroup bGroup,
		--CostType specific params
		@DItem varchar(16), @ItemLength varchar(10), @InputMask varchar(30),
		@FixedUnits varchar(60), @FixedUM varchar(60), @FixedUnitCost varchar(60),
		@FixedSIRegion varchar(60), @FixedSICode varchar(60), @FixedRetainPCT varchar(60),
		@FixedAmt varchar(60), @FixedCostType varchar(60), @FixedHours varchar(60), @FixedBillFlag varchar(60), 
		@FixedItemUnitFlag varchar(60), @FixedPhaseUnitFlag varchar(60), @PCT bPct, @FixedMisc1 varchar(60),
		@FixedMisc2 varchar(60), @FixedMisc3 varchar(60), @FixedCosts varchar(30), 
		@SQLInsert nvarchar(max), @SQLValues nvarchar(max), @RecTypeID varchar(10),
		--To fill import value columns
		@ImportItem varchar(30), @ImportPhase varchar(30), @ImportCostType varchar(30), @ImportUM varchar(30),
		--To hold values to send for formatting
		@ImportBillFlag char(1), @ImportItemUnitFlag bYN, @ImportPhaseUnitFlag bYN, @ImportHours bHrs, 
		@ImportUnits bUnits, @ImportCosts bDollar, @ImportNotes varchar(max),
		--To hold formatted values for insert
		@InsertItem bContractItem, @InsertPhase bPhase, @InsertCostType bJCCType, @InsertUM bUM, @InsertUnits bUnits,
		@InsertCosts bDollar, @InsertHours bHrs, @InsertBillFlag char(1), @InsertItemUnitFlag bYN, 
		@InsertPhaseUnitFlag bYN,
		--To build update for fixed width
		@x int, @FixedValue varchar(max), @FixedBegPos int, @FixedEndPos int,
		----TK-11537
		@FixedColumnName varchar(128), 
		@FixedSQLString nvarchar(max), @LastInsertSeq int,
		--To check if rollup was completed in delimited
		@costonly bYN, @vimportum varchar(30), @vhours bHrs, @vunits bUnits, @vcosts bDollar, @vsequence int,
		@CurrentKeyID bigint

----#138042
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

select @rcode = 0, @OpenCursor = 0, @ValidCnt = 0, @RecordType = 'CostType'

select @FixedItem = '', @FixedPhase = '', @FixedCostType = '', @FixedUM = '', @FixedBillFlag = '', @FixedItemUnitFlag = '',
		@FixedPhaseUnitFlag = '', @FixedHours = '', @FixedUnits = '', @FixedUnitCost = '', @FixedNotes = '',
		@FixedMisc1 = '', @FixedMisc2 = '', @FixedMisc3 = '', @FixedCosts = ''

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

--Get phase group from HQCO
select @PhaseGroup=PhaseGroup from HQCO where HQCo=@PMCo
if @@rowcount = 0
begin
	select @msg = 'Invalid HQ Company, cannot find phase group.', @rcode = 1
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
select @RecTypeID = isnull(CostTypeID,3) from dbo.PMUR with (nolock) where Template=@Template


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

		if @ImportRoutine = 'Timberline' goto Timberline

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

			set @x = @x + 1
		end	

		--Get Fixed Values--
		select @FixedItem = Value from @FixedValues where Template=@Template and ColumnName='Item'

		select @FixedPhase = Value from @FixedValues where Template=@Template and ColumnName='Phase'

		select @FixedCostType = Value from @FixedValues where Template=@Template and ColumnName='CostType'

		select @FixedUnits = Value from @FixedValues where Template=@Template and ColumnName='Units'

		select @FixedUM = Value from @FixedValues where Template=@Template and ColumnName='UM'

		select @FixedHours = Value from @FixedValues where Template=@Template and ColumnName='Hours'

		select @FixedCosts = Value from @FixedValues where Template=@Template and ColumnName='Costs'

		select @FixedBillFlag = Value from @FixedValues where Template=@Template and ColumnName='BillFlag'

		select @FixedItemUnitFlag = Value from @FixedValues where Template=@Template and ColumnName='ItemUnitFlag'

		select @FixedPhaseUnitFlag = Value from @FixedValues where Template=@Template and ColumnName='PhaseUnitFlag'

		select @FixedNotes = Value from @FixedValues where Template=@Template and ColumnName='Notes'

		if isnull(@FixedUM,'') = '' set @FixedUM = 'LS'
		---- set empty strings to null
		if @FixedNotes = '' set @FixedNotes = null
		---- remove commas before insert
		select @FixedHours = replace(@FixedHours,',','')
		select @FixedUnits = replace(@FixedUnits,',','')
		select @FixedCosts = replace(@FixedCosts,',','')

		--Insert into bPMWD
		exec @rcode = dbo.bspPMWDAdd @PMCo, @ImportID, @PhaseGroup, @FixedItem, @FixedPhase, @FixedCostType, 
			@FixedUM, @FixedBillFlag, @FixedItemUnitFlag, @FixedPhaseUnitFlag, @FixedHours, @FixedUnits, @FixedCosts,
			@FixedMisc1, @FixedMisc2, @FixedMisc3, @FixedNotes, @errmsg output
		if @rcode <> 0 
		begin
			select @msg = @errmsg, @rcode = 1
			goto vspexit
		end

		--UPDATE NEW/UD COLUMNS--
		--Set initial parameter values
		set @FixedSQLString = 'update PMWD set'

		--Get last insert sequence
		select @LastInsertSeq=max(Sequence) from PMWD with (nolock) where ImportId=@ImportID and PMCo=@PMCo

		--Step through and build string
		set @x = 14

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
	
					set @i = @i + 1
				end			

				-------------------------
				-- BUILD INSERT STRING --
				-------------------------
				set @i = 1
				---- #138042
				select @ImportItem = isnull(ImportValue,'') from #ColumnValues where ColumnName='Item'
				select @ImportPhase = isnull(ImportValue,'') from #ColumnValues where ColumnName='Phase'
				select @ImportCostType = isnull(ImportValue,'') from #ColumnValues where ColumnName='CostType'
				select @ImportUM = isnull(ImportValue,'') from #ColumnValues where ColumnName='UM'
				---- #138042
				select @ImportBillFlag = Value from #ColumnValues where ColumnName='BillFlag'
				select @ImportItemUnitFlag = Value from #ColumnValues where ColumnName='ItemUnitFlag'
				select @ImportPhaseUnitFlag = Value from #ColumnValues where ColumnName='PhaseUnitFlag'
				select @ImportHours = isnull(cast(replace(Value,',','') as float),0) from #ColumnValues where ColumnName='Hours'
				select @ImportUnits = isnull(cast(replace(Value,',','') as float),0) from #ColumnValues where ColumnName='Units'
				select @ImportCosts = isnull(cast(replace(Value,',','') as float),0) from #ColumnValues where ColumnName='Costs'
				select @ImportNotes = Value from #ColumnValues where ColumnName='Notes'
				select @InsertSeq = isnull(max(Sequence),0) + 1 from PMWD with (nolock) where ImportId=@ImportID
				set @SQLInsert = 'insert PMWD(ImportId,Sequence,PMCo,PhaseGroup,ImportItem,ImportPhase,ImportCostType,ImportUM,'
				set @SQLValues = ' values(' + char(39) + @ImportID + char(39) + ',' + 
					ltrim(rtrim((cast(@InsertSeq as char(10))))) + ',' + cast(@PMCo as varchar(3)) + ',' +
					cast(@PhaseGroup as varchar(10)) + ',' + char(39) + @ImportItem + char(39) + ',' + 
					char(39) + @ImportPhase + char(39) + ',' + char(39) + @ImportCostType + char(39) + ',' +
					char(39) + @ImportUM + char(39) + ','
					
				-- 139960 and #142984 set UM to Value just incase user default/override present
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
							exec @rcode = dbo.vspPMImportFormatCostType @PMCo, @ImportID, @ImportRoutine, @PhaseGroup, @ImportItem, 
								@ImportPhase, @ImportCostType, @ImportUM, @ImportBillFlag, @ImportItemUnitFlag,
								@ImportPhaseUnitFlag, @ImportHours, @ImportUnits, @ImportCosts,null, null, null, 
								@ImportNotes, 
								@InsertItem output, null, null, null, null,
								null, null, null, null, null, @costonly output, null, @errmsg output

							if @InsertItem is not null set @Value = @InsertItem
							--select @InsertItem = null
						end
						if @ColumnName = 'Phase'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatCostType @PMCo, @ImportID, @ImportRoutine, @PhaseGroup, @ImportItem, 
								@ImportPhase, @ImportCostType, @ImportUM, @ImportBillFlag, @ImportItemUnitFlag,
								@ImportPhaseUnitFlag, @ImportHours, @ImportUnits, @ImportCosts,null, null, null, 
								@ImportNotes, 
								null, @InsertPhase output, null, null, null,
								null, null, null, null, null, @costonly output, null, @errmsg output

							if @InsertPhase is not null set @Value = @InsertPhase
							--select @InsertPhase = null
						end
						if @ColumnName = 'CostType'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatCostType @PMCo, @ImportID, @ImportRoutine, @PhaseGroup, @ImportItem, 
								@ImportPhase, @ImportCostType, @ImportUM, @ImportBillFlag, @ImportItemUnitFlag,
								@ImportPhaseUnitFlag, @ImportHours, @ImportUnits, @ImportCosts,null, null, null, 
								@ImportNotes, 
								null, null, @InsertCostType output, null, null,
								null, null, null, null, null, @costonly output, null, @errmsg output

							if @InsertCostType is not null set @Value = @InsertCostType
							--select @InsertCostType = null
							if isnull(@Value,'') = '' set @Value = null
							if isnumeric(@Value) = 0 set @Value = null
						end
						if @ColumnName = 'UM'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatCostType @PMCo, @ImportID, @ImportRoutine, @PhaseGroup, @ImportItem, 
								@ImportPhase, @ImportCostType, @ImportUM, @ImportBillFlag, @ImportItemUnitFlag,
								@ImportPhaseUnitFlag, @ImportHours, @ImportUnits, @ImportCosts,null, null, null, 
								@ImportNotes, 
								null, null, null, @InsertUM output, null,
								null, null, null, null, null, @costonly output, null, @errmsg output

							if @InsertUM is not null set @Value = @InsertUM
							--select @InsertUM = null
						end
						if @ColumnName = 'Units'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatCostType @PMCo, @ImportID, @ImportRoutine, @PhaseGroup, @ImportItem, 
								@ImportPhase, @ImportCostType, @ImportUM, @ImportBillFlag, @ImportItemUnitFlag,
								@ImportPhaseUnitFlag, @ImportHours, @ImportUnits, @ImportCosts,null, null, null, 
								@ImportNotes, 
								null, null, null, null, @InsertUnits output,
								null, null, null, null, null, @costonly output, null, @errmsg output

							if @InsertUnits is not null set @Value = @InsertUnits
							--select @InsertUnits = null
						end
						if @ColumnName = 'Costs'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatCostType @PMCo, @ImportID, @ImportRoutine, @PhaseGroup, @ImportItem, 
								@ImportPhase, @ImportCostType, @ImportUM, @ImportBillFlag, @ImportItemUnitFlag,
								@ImportPhaseUnitFlag, @ImportHours, @ImportUnits, @ImportCosts,null, null, null, 
								@ImportNotes, 
								null, null, null, null, null,
								@InsertCosts output, null, null, null, null, @costonly output, null, @errmsg output

							if @InsertCosts is not null set @Value = @InsertCosts
							--select @InsertCosts = null
						end
						if @ColumnName = 'Hours'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatCostType @PMCo, @ImportID, @ImportRoutine, @PhaseGroup, @ImportItem, 
								@ImportPhase, @ImportCostType, @ImportUM, @ImportBillFlag, @ImportItemUnitFlag,
								@ImportPhaseUnitFlag, @ImportHours, @ImportUnits, @ImportCosts,null, null, null, 
								@ImportNotes, 
								null, null, null, null, null,
								null, @InsertHours output, null, null, null, @costonly output, null, @errmsg output

							if @InsertHours is not null set @Value = @InsertHours
							--select @InsertHours = null
						end
						if @ColumnName = 'BillFlag'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatCostType @PMCo, @ImportID, @ImportRoutine, @PhaseGroup, @ImportItem, 
								@ImportPhase, @ImportCostType, @ImportUM, @ImportBillFlag, @ImportItemUnitFlag,
								@ImportPhaseUnitFlag, @ImportHours, @ImportUnits, @ImportCosts,null, null, null, 
								@ImportNotes, 
								null, null, null, null, null,
								null, null, @InsertBillFlag output, null, null, @costonly output, null, @errmsg output

							if @InsertBillFlag is not null set @Value = @InsertBillFlag
							--select @InsertBillFlag = null
						end
						if @ColumnName = 'ItemUnitFlag'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatCostType @PMCo, @ImportID, @ImportRoutine, @PhaseGroup, @ImportItem, 
								@ImportPhase, @ImportCostType, @ImportUM, @ImportBillFlag, @ImportItemUnitFlag,
								@ImportPhaseUnitFlag, @ImportHours, @ImportUnits, @ImportCosts,null, null, null, 
								@ImportNotes, 
								null, null, null, null, null,
								null, null, null, @InsertItemUnitFlag output, null, @costonly output, null, @errmsg output

							if @InsertItemUnitFlag is not null set @Value = @InsertItemUnitFlag
							--select @InsertItemUnitFlag = null
						end
						if @ColumnName = 'PhaseUnitFlag'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatCostType @PMCo, @ImportID, @ImportRoutine, @PhaseGroup, @ImportItem, 
								@ImportPhase, @ImportCostType, @ImportUM, @ImportBillFlag, @ImportItemUnitFlag,
								@ImportPhaseUnitFlag, @ImportHours, @ImportUnits, @ImportCosts,null, null, null, 
								@ImportNotes, 
								null, null, null, null, null,
								null, null, null, null, @InsertPhaseUnitFlag output, @costonly output, null, @errmsg output

							if @InsertPhaseUnitFlag is not null set @Value = @InsertPhaseUnitFlag
							--select @InsertPhaseUnitFlag = null
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

				set @SQLInsert = stuff(@SQLInsert, len(@SQLInsert), 1, '')
				set @SQLInsert = @SQLInsert + ')'
				set @SQLValues = stuff(@SQLValues, len(@SQLValues), 1, '')
				set @SQLValues = @SQLValues + ')'
				set @SQLString = @SQLInsert + @SQLValues
				
				--Roll up cost types if needed
				if @InsertCostType is not null
				begin
					select @vsequence=Sequence, @vhours=Hours, @vunits=Units, @vcosts=Costs, @vimportum=UM
					from bPMWD with (nolock) where PMCo=@PMCo and ImportId=@ImportID and Item=@InsertItem
					and Phase=@InsertPhase and CostType=@InsertCostType
					if @@rowcount <> 0
					begin
						if @costonly = 'N'
						begin
							if @vimportum = @InsertUM
							begin
								select @vunits=@vunits+@InsertUnits
							end
							select @vhours=@vhours+@InsertHours, @vcosts=@vcosts+@InsertCosts
						end
						else
						begin
							select @vcosts=@vcosts+@InsertCosts
						end

						update bPMWD set Hours=@vhours, Units=@vunits, Costs=@vcosts
						where PMCo=@PMCo and ImportId=@ImportID and Sequence=@vsequence
						
						goto Next_Phase_Record
					end
				end
				else
				begin
					select @vsequence=Sequence, @vhours=Hours, @vunits=Units, @vcosts=Costs, @vimportum=UM
					from bPMWD with (nolock) where PMCo=@PMCo and ImportId=@ImportID and ImportItem=@InsertItem
					and ImportPhase=@InsertPhase and ImportCostType=@InsertCostType
					if @@rowcount <> 0
					begin
						if @costonly = 'N'
						begin
							if @vimportum=@InsertUM
							begin
								select @vunits=@vunits+@InsertUnits
							end
							select @vhours=@vhours+@InsertHours, @vcosts=@vcosts+@InsertCosts
						end
						else
						begin
							select @vcosts=@vcosts+@InsertCosts
						end

						update bPMWD set Hours=@vhours, Units=@vunits, Costs=@vcosts
						where PMCo=@PMCo and ImportId=@ImportID and Sequence=@vsequence	
						
						goto Next_Phase_Record
					end		
				end

				--Insert record
				execute sp_executesql @SQLString
				set @Complete = 1
				
			end
		end
		
		goto Next_Phase_Record


	Timberline:
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
				--Make sure that returned values are Phase record type
				select @ReturnRecType = Value from #ColumnValues where Template=@Template and ColumnName='RecordType'
				select @ItemID = isnull(CostTypeID,3) from PMUR with (nolock) where Template=@Template
				if @ReturnRecType <> @ItemID goto Process_Loop

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

				--Get Fixed Values--
				select @FixedPhase = LTRIM(ImportValue) from #ColumnValues where Template=@Template and ColumnName='Phase'

				select @FixedCostType = LTRIM(ImportValue) from #ColumnValues where Template=@Template and ColumnName='CostType'

				select @FixedUnits = LTRIM(Value) from #ColumnValues where Template=@Template and ColumnName='Units'

				select @FixedUM = LTRIM(ImportValue) from #ColumnValues where Template=@Template and ColumnName='UM'

				select @FixedHours = LTRIM(Value) from #ColumnValues where Template=@Template and ColumnName='Hours'
				
				select @FixedCosts = LTRIM(Value) from #ColumnValues where Template=@Template and ColumnName='Costs'

				if isnull(@FixedUM,'') = '' set @FixedUM = 'LS'
				---- set empty strings to null
				if @FixedNotes = '' set @FixedNotes = null
				---- remove commas before insert
				select @FixedHours = replace(@FixedHours,',','')
				select @FixedUnits = replace(@FixedUnits,',','')
				select @FixedUnitCost = replace(@FixedUnitCost,',','')

				Insert into bPMWD
				exec @rcode = dbo.vspPMImportFormatCostType @PMCo, @ImportID, @ImportRoutine, @PhaseGroup, @ImportItem, 
					@FixedPhase, @FixedCostType, @FixedUM, @ImportBillFlag, @ImportItemUnitFlag,
					@ImportPhaseUnitFlag, @FixedHours, @FixedUnits, @FixedCosts, null, null, null, 
					@ImportNotes, 
					null, null, null, null, null,
					null, null, null, null, null, null, @CurrentKeyID output, @errmsg output
				if @rcode <> 0 
				begin
					select @msg = @errmsg, @rcode = 1
					goto vspexit
				end
				
				--UPDATE NEW/UD COLUMNS--
				if @CurrentKeyID is not null
				begin
					--Set initial parameter values
					set @FixedSQLString = 'update PMWD set'

					--Step through and build string
					set @i = 1

					while @i <= (select count(1) from #ColumnValues where Template=@Template)
					begin
						select @Value=Value, @ColumnName=ColumnName from #ColumnValues where Template=@Template and Seq=@i

						if substring(@ColumnName, 1, 2) = 'ud'
						begin
							set @Value = char(39) + @Value + char(39)

							set @FixedSQLString = @FixedSQLString + ' ' + @ColumnName + '=' + 
								isnull(@Value,'null') + ','
						end

						set @i = @i + 1
					end

					--Cleanup and execute SQL string
					set @FixedSQLString = stuff(@FixedSQLString, len(@FixedSQLString), 1, '')
					set @FixedSQLString = @FixedSQLString + ' where KeyID='+cast(@CurrentKeyID as varchar(20))

					--If ud found, execute
					if patindex('%ud%', @FixedSQLString) > 0
					begin
						execute sp_executesql @FixedSQLString
					end
					
					set @CurrentKeyID = null
				end

				set @Complete = 1
			end
		end

	Next_Phase_Record:
		select @FixedItem = '', @FixedDesc = '', @FixedPhase = '', @FixedNotes = '' --, @xmisc1 = '', @xmisc2 = '', @xmisc3 = ''
		select @InsertItem = null, @InsertPhase = null, @InsertCostType = null, @InsertUM = null, @InsertUnits = null,
			@InsertCosts = null, @InsertHours = null, @InsertBillFlag = null, @InsertItemUnitFlag = null, 
			@InsertPhaseUnitFlag = null 
		set @ValidCnt = @ValidCnt + 1
		goto Process_Loop

	Process_Loop_End:
		select @msg = 'Cost Type records: ' + cast(@ValidCnt as varchar(6)) + '. '

end try

begin catch
	select @msg = 'Error: ' + error_message() + char(13) + char(10) + 
		'Upload failed, make sure PM Import Template Detail information is correct.' + char(13) + char(10) +
		'CostType - Record ' + cast((@ValidCnt + 1) as varchar(6)) + char(13) + char(10) + 
		'vspPMImportCostType line ' + cast(error_line() as varchar(3)), @rcode = 1
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
GRANT EXECUTE ON  [dbo].[vspPMImportCostType] TO [public]
GO
