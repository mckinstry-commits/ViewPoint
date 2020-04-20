
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[vspPMImportMatlDetail]

  /*************************************
  * CREATED BY:		GP 03/11/2009
  * MODIFIED BY:	GP 12/14/2009 - Issue 136451 varchar to float conversion error
  *					GP 12/15/2009 - Issue 136786 leaving insert string values null causing entire string null
  *					GP 02/04/2010 - Issue 137927 description returned on formatting procedures now goes to 'MatlDescription'
  *					GF 02/10/2010 - issue #138042 - changes to store the import value not formatted to our data type.
  *					GP 04/27/2010 - Issue 139225 skip insert of records that have been rolled up
  *					GF 02/10/2011 - issue #143294 changed @xnotes to varchar(max)
  *					GF 01/06/2011 - TK-11537 expand ColumnName to 128 characters.
  *					ScottP 02/07/2013 - TFS-39923 When importing a multi-part ud field from a delimited file,
  *						format it to the using the proper format string before saving value to the field in the table
  *					ScottP 03/12/2013 - TFS-39923 Separate declare and set statements to make code compatible with SQL 2005
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


declare @rcode smallint, @PhaseGroup bGroup, @FileType char(1), @ImportRoutine varchar(20), @UserRoutine varchar(30),
	@DelimValue char(1), @OtherDelim char(1), @DefaultSIRegion varchar(6), @ItemOption char(1), 
	@ContractItem bContractItem, @ItemDesc bItemDesc, @RecordTypeCol int, @BegRecTypePos int, @EndRecTypePos int,
	@RecTypeLen int, @Delimiter char(1), @DelimCombo char(2), @OpenCursor int, @ValidCnt int, @Seq int, 
	@DataRow varchar(max), @InputString varchar(MAX), @Complete int, @Counter int, @RecordType varchar(20), 
	@errmsg varchar(500), @FixedItem varchar(30), @FixedPhase bPhase, @FixedDesc bItemDesc, @FixedNotes varchar(max), 
	@FixedCostType varchar(60), @FixedUnits varchar(60), @FixedUM varchar(60), @FixedUnitCost varchar(60),
	@FixedECM varchar(60), @FixedVendor varchar(60), @FixedWCRetgPct varchar(60), @FixedMaterial varchar(60),
	@SQLString nvarchar(max), @i int,
	----TK-11537
	@ColumnName varchar(128), @Value varchar(max), @InsertSeq int, 
	@ReturnRecType varchar(20), @PhaseID varchar(20), @FixedMisc1 varchar(60), @FixedMisc2 varchar(60), @FixedMisc3 varchar(60),
	@SQLInsert nvarchar(max), @SQLValues nvarchar(max), @MatlGroup bGroup, @APCo bCompany, @FixedAmount varchar(60),
	@Amount decimal(16,2), @VendorGroup bGroup, @Units bUnits, @UnitCost bUnitCost, @RecTypeID varchar(10),
		--To fill import value columns
		@ImportItem varchar(30), @ImportPhase varchar(30), @ImportCostType varchar(30), @ImportMaterial varchar(30), 
		@ImportVendor varchar(30), @ImportUM varchar(30),
		--To hold values to send for formatting
		@ImportDesc bItemDesc, @ImportUnits bUnits, @ImportUnitCost bUnitCost, 
		@ImportECM bECM, @ImportAmount bDollar, @ImportNotes varchar(max),
		--To hold formatted values for insert
		@InsertItem bContractItem, @InsertPhase bPhase, @InsertMaterial bMatl, @InsertCostType bJCCType,
		@InsertVendor bVendor, @InsertUM bUM, @InsertUnits bUnits, @InsertUnitCost bUnitCost, @InsertAmount bDollar,
		@InsertDesc bItemDesc,
		--To build update for fixed width
		@x int, @FixedValue varchar(max), @FixedBegPos int, @FixedEndPos int,
		----TK-11537
		@FixedColumnName varchar(128), 
		@FixedSQLString nvarchar(max), @LastInsertSeq int,
		--139225 rolled up matl detail records
		@RolledUp bYN

---- #138042
create table #ColumnValues ( 
	Seq int, 
	Template varchar(20),
	----TK-11537
	ColumnName varchar(128),
	Value varchar(MAX),
	ImportValue varchar(MAX))
		
declare @FixedValues table ( 
	Seq int identity(1,1), 
	Template varchar(20) not null,
	----TK-11537
	ColumnName varchar(128) not null,
	Value varchar(max) null,
	BegPos int null,
	EndPos int null )

select @rcode = 0, @OpenCursor = 0, @ValidCnt = 0, @RecordType = 'MatlDetail',
	@FixedMisc1 = '', @FixedMisc2 = '', @FixedMisc3 = '', @FixedCostType = '', @FixedUnits = '', @FixedUM = '', 
	@FixedUnitCost = '', @FixedECM = '', @FixedVendor = '', @FixedWCRetgPct = '', @FixedMaterial = '',
	@RolledUp = 'N'

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

--Get PhaseGroup from bHQCO
select @PhaseGroup=PhaseGroup, @MatlGroup=MatlGroup from HQCO with (nolock) where HQCo=@PMCo
if @@rowcount = 0
begin
	select @msg = 'Invalid HQ Company, cannot find phase group.', @rcode = 1
	goto vspexit
end

--Get APCo
select @APCo = APCo from PMCO where PMCo=@PMCo
if @@rowcount = 0 select @APCo = @PMCo

--Get VendorGroup from HQCO
select @VendorGroup=VendorGroup from HQCO where HQCo=@APCo
if @@rowcount = 0
begin
	select @msg = 'Invalid HQ Company, cannot find vendor group.', @rcode = 1
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
select @RecTypeID = isnull(MaterialDetailID,5) from dbo.PMUR with (nolock) where Template=@Template


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
		if len(@DataRow) < 800 select @DataRow = @DataRow + SPACE(200)

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
					where Template=@Template and ColumnName=@FixedColumnName
				end
			end

			set @x = @x + 1
		end	

		--Get Fixed Values--
		select @FixedItem = Value from @FixedValues where Template=@Template and ColumnName='Item'

		select @FixedPhase = Value from @FixedValues where Template=@Template and ColumnName='Phase'

		select @FixedCostType = Value from @FixedValues where Template=@Template and ColumnName='CostType'

		select @FixedUnits = Value from @FixedValues where Template=@Template and ColumnName='Units'

		select @FixedUM = Value from @FixedValues where Template=@Template and ColumnName='UM'

		select @FixedUnitCost = Value from @FixedValues where Template=@Template and ColumnName='UnitCost'

		select @FixedMaterial = Value from @FixedValues where Template=@Template and ColumnName='Material'

		select @FixedVendor = Value from @FixedValues where Template=@Template and ColumnName='Vendor'

		select @FixedDesc = Value from @FixedValues where Template=@Template and ColumnName='MatlDescription'

		select @FixedAmount = Value from @FixedValues where Template=@Template and ColumnName='Amount'

		select @FixedNotes = Value from @FixedValues where Template=@Template and ColumnName='Notes'

		--Parse fixed length data row
		set @FixedECM = 'E'
		--Set empty strings to null
		if @FixedDesc = '' set @FixedDesc = null
		if @FixedNotes = '' set @FixedNotes = null
		if @FixedUM = '' set @FixedUM = null
		if @FixedMaterial = '' set @FixedMaterial = null

		--Check values
		if isnull(@FixedUM,'') = '' set @FixedUM = 'LS'
		if isnull(@FixedUnits,'') = '' set @FixedUnits = '0'
		if isnull(@FixedUnitCost,'') = '' set @FixedUnitCost = '0'
		--Calculate amount
		select @Amount = cast(@FixedUnits as decimal(16,3)) * cast(@FixedUnitCost as decimal(16,5))
		select @FixedAmount = convert(varchar(30),@Amount)
		---- remove commas before insert
		select @FixedAmount = replace(@FixedAmount,',','')
		select @FixedUnits = replace(@FixedUnits,',','')
		select @FixedUnitCost = replace(@FixedUnitCost,',','')	

		--Insert into bPMWM
		exec @rcode = dbo.bspPMWMAdd @PMCo, @ImportID, @PhaseGroup, @MatlGroup, @VendorGroup, @FixedItem, @FixedPhase,
			@FixedCostType, @FixedMaterial, @FixedVendor, @FixedUM, @FixedDesc, @FixedUnits, @FixedUnitCost, @FixedECM, 
			@FixedAmount, @FixedMisc1, @FixedMisc2, @FixedMisc3, @FixedNotes, @errmsg output
		if @rcode <> 0 
		begin
			select @msg = @errmsg, @rcode = 1
			goto vspexit
		end

		--UPDATE NEW/UD COLUMNS--
		--Set initial parameter values
		set @FixedSQLString = 'update PMWM set'

		--Get last insert sequence
		select @LastInsertSeq=max(Sequence) from PMWM with (nolock) where ImportId=@ImportID and PMCo=@PMCo

		--Step through and build string
		set @x = 14

		while @x <= (select count(1) from @FixedValues)
		begin
			select @FixedColumnName=ColumnName, @FixedValue=Value from @FixedValues where Seq=@x

			select @FixedValue = Value from @FixedValues where Template=@Template and ColumnName=@FixedColumnName

			if @FixedColumnName='MatlGroup' set @FixedValue = isnull(@FixedValue,@MatlGroup)
			if @FixedColumnName='PhaseGroup' set @FixedValue = isnull(@FixedValue,@PhaseGroup)
			if @FixedColumnName='VendorGroup' set @FixedValue = isnull(@FixedValue,@VendorGroup)

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
	
					if substring(@Value,1,2) = '**'
					begin
						if @ColumnName = 'Amount'
						begin
							select @Units = Value from #ColumnValues where Template=@Template and ColumnName='Units'
							select @UnitCost = Value from #ColumnValues where Template=@Template and ColumnName='UnitCost'							
							set @Value = @Units * @UnitCost
					
							update #ColumnValues
							set Value = @Value
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
				select @ImportPhase = isnull(ImportValue,'') from #ColumnValues where ColumnName='Phase'
				select @ImportCostType = isnull(ImportValue,'') from #ColumnValues where ColumnName='CostType'
				select @ImportMaterial = isnull(ImportValue,'') from #ColumnValues where ColumnName='Material'
				select @ImportVendor = isnull(ImportValue,'') from #ColumnValues where ColumnName='Vendor'
				select @ImportUM = isnull(ImportValue,'') from #ColumnValues where ColumnName='UM'
				---- #138042
				select @ImportDesc = Value from #ColumnValues where ColumnName='Description'
				select @ImportUnits = isnull(cast(replace(Value,',','') as float),0) from #ColumnValues where ColumnName='Units'
				select @ImportUnitCost = isnull(cast(replace(Value,',','') as float),0) from #ColumnValues where ColumnName='UnitCost'
				select @ImportECM = Value from #ColumnValues where ColumnName='ECM'
				select @ImportAmount = isnull(cast(replace(Value,',','') as float),0) from #ColumnValues where ColumnName='Amount'
				select @ImportNotes = Value from #ColumnValues where ColumnName='Notes'
				select @InsertSeq = isnull(max(Sequence),0) + 1 from PMWM with (nolock) where ImportId=@ImportID
				set @SQLInsert = 'insert PMWM(ImportId,Sequence,PMCo,PhaseGroup,VendorGroup,MatlGroup,ImportItem,
					ImportPhase,ImportCostType,ImportMaterial,ImportVendor,ImportUM,'
				set @SQLValues = ' values(' + char(39) + @ImportID + char(39) + ',' + 
					ltrim(rtrim((cast(@InsertSeq as char(10))))) + ',' + cast(@PMCo as varchar(3)) + ',' +
					cast(@PhaseGroup as varchar(10)) + ',' + cast(@VendorGroup as varchar(10)) + ',' +
					cast(@MatlGroup as varchar(10)) + ',' + char(39) + @ImportItem + char(39) + ',' + 
					char(39) +@ImportPhase + char(39) + ',' + char(39) + @ImportCostType + char(39) + ',' +
					char(39) + @ImportMaterial + char(39) + ',' + char(39) + @ImportVendor + char(39) + ',' + 
					char(39) + @ImportUM + char(39) + ','
	
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
							exec @rcode = dbo.vspPMImportFormatMatlDetail 'N', @PMCo, @ImportID, @PhaseGroup, @MatlGroup, 
								@VendorGroup, @ImportItem, @ImportPhase, @ImportCostType, @ImportMaterial, 
								@ImportVendor, @ImportUM, @ImportDesc, @ImportUnits, @ImportUnitCost, @ImportECM, 
								@ImportAmount, null, null, null, @ImportNotes, 
								@InsertItem output, null, null, null, null,
								null, null, null, null, @InsertDesc output, null, @errmsg output

							if @InsertItem is not null set @Value = @InsertItem
							if @InsertDesc is not null update #ColumnValues set Value=@InsertDesc where Template=@Template and ColumnName='MatlDescription'
							select @InsertItem = null, @InsertDesc = null
						end
						if @ColumnName = 'Phase'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatMatlDetail 'N', @PMCo, @ImportID, @PhaseGroup, @MatlGroup, 
								@VendorGroup, @ImportItem, @ImportPhase, @ImportCostType, @ImportMaterial, 
								@ImportVendor, @ImportUM, @ImportDesc, @ImportUnits, @ImportUnitCost, @ImportECM, 
								@ImportAmount, null, null, null, @ImportNotes, 
								null, @InsertPhase output, null, null, null,
								null, null, null, null, @InsertDesc output, null, @errmsg output

							if @InsertPhase is not null set @Value = @InsertPhase
							if @InsertDesc is not null update #ColumnValues set Value=@InsertDesc where Template=@Template and ColumnName='MatlDescription'
							select @InsertPhase = null, @InsertDesc = null
						end
						if @ColumnName = 'Material'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatMatlDetail 'Y', @PMCo, @ImportID, @PhaseGroup, @MatlGroup, 
								@VendorGroup, @ImportItem, @ImportPhase, @ImportCostType, @ImportMaterial, 
								@ImportVendor, @ImportUM, @ImportDesc, @ImportUnits, @ImportUnitCost, @ImportECM, 
								@ImportAmount, null, null, null, @ImportNotes, 
								null, null, @InsertMaterial output, null, null,
								null, null, null, null, @InsertDesc output, @RolledUp output, @errmsg output

							set @Value = @InsertMaterial
							if @InsertDesc is not null update #ColumnValues set Value=@InsertDesc where Template=@Template and ColumnName='MatlDescription'
							select @InsertMaterial = null, @InsertDesc = null
						end
						if @ColumnName = 'CostType'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatMatlDetail 'N', @PMCo, @ImportID, @PhaseGroup, @MatlGroup, 
								@VendorGroup, @ImportItem, @ImportPhase, @ImportCostType, @ImportMaterial, 
								@ImportVendor, @ImportUM, @ImportDesc, @ImportUnits, @ImportUnitCost, @ImportECM, 
								@ImportAmount, null, null, null, @ImportNotes, 
								null, null, null, @InsertCostType output, null,
								null, null, null, null, null, null, @errmsg output

							if @InsertCostType is not null set @Value = @InsertCostType
							select @InsertCostType = null
							if isnull(@Value,'') = '' set @Value = null
							if isnumeric(@Value) = 0 set @Value = null
						end
						if @ColumnName = 'Vendor'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatMatlDetail 'N', @PMCo, @ImportID, @PhaseGroup, @MatlGroup, 
								@VendorGroup, @ImportItem, @ImportPhase, @ImportCostType, @ImportMaterial, 
								@ImportVendor, @ImportUM, @ImportDesc, @ImportUnits, @ImportUnitCost, @ImportECM, 
								@ImportAmount, null, null, null, @ImportNotes, 
								null, null, null, null, @InsertVendor output,
								null, null, null, null, null, null, @errmsg output

							if @InsertVendor is not null set @Value = @InsertVendor
							select @InsertVendor = null
							if isnull(@Value,'') = '' set @Value = null
							if isnumeric(@Value) = 0 set @Value = null
						end
						if @ColumnName = 'UM'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatMatlDetail 'N', @PMCo, @ImportID, @PhaseGroup, @MatlGroup, 
								@VendorGroup, @ImportItem, @ImportPhase, @ImportCostType, @ImportMaterial, 
								@ImportVendor, @ImportUM, @ImportDesc, @ImportUnits, @ImportUnitCost, @ImportECM, 
								@ImportAmount, null, null, null, @ImportNotes, 
								null, null, null, null, null,
								@InsertUM output, null, null, null, null, null, @errmsg output

							if @InsertUM is not null set @Value = @InsertUM
							select @InsertUM = null
						end
						if @ColumnName = 'Units'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatMatlDetail 'N', @PMCo, @ImportID, @PhaseGroup, @MatlGroup, 
								@VendorGroup, @ImportItem, @ImportPhase, @ImportCostType, @ImportMaterial, 
								@ImportVendor, @ImportUM, @ImportDesc, @ImportUnits, @ImportUnitCost, @ImportECM, 
								@ImportAmount, null, null, null, @ImportNotes, 
								null, null, null, null, null,
								null, @InsertUnits output, null, null, null, null, @errmsg output

							if @InsertUnits is not null set @Value = @InsertUnits
							select @InsertUnits = null
						end
						if @ColumnName = 'UnitCost'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatMatlDetail 'N', @PMCo, @ImportID, @PhaseGroup, @MatlGroup, 
								@VendorGroup, @ImportItem, @ImportPhase, @ImportCostType, @ImportMaterial, 
								@ImportVendor, @ImportUM, @ImportDesc, @ImportUnits, @ImportUnitCost, @ImportECM, 
								@ImportAmount, null, null, null, @ImportNotes, 
								null, null, null, null, null,
								null, null, @InsertUnitCost output, null, null, null, @errmsg output

							if @InsertUnitCost is not null set @Value = @InsertUnitCost
							select @InsertUnitCost = null
						end
						if @ColumnName = 'Amount'
						begin
							set @Value = null
							exec @rcode = dbo.vspPMImportFormatMatlDetail 'N', @PMCo, @ImportID, @PhaseGroup, @MatlGroup, 
								@VendorGroup, @ImportItem, @ImportPhase, @ImportCostType, @ImportMaterial, 
								@ImportVendor, @ImportUM, @ImportDesc, @ImportUnits, @ImportUnitCost, @ImportECM, 
								@ImportAmount, null, null, null, @ImportNotes, 
								null, null, null, null, null,
								null, null, null, @InsertAmount output, null, null, @errmsg output

							if @InsertAmount is not null set @Value = @InsertAmount
							select @InsertAmount = null
						end
						if substring(@ColumnName, 1, 2) = 'ud'
						begin							 
							declare @datatype varchar(20)
							declare @inputtype int, @format varchar(30)
							declare @inputValue varchar(50), @outputValue varchar(50)							
							set @datatype = null
							set @inputtype = null
							set @format = null
							set @inputValue = null
							set @outputValue = null
							
							select @datatype = Datatype from dbo.PMUD where Template=@Template and RecordType=@RecordType and ColumnName=@ColumnName

 							select @inputtype = InputType, @format = InputMask
 								from dbo.DDDTShared where Datatype = @datatype
 								 		
 							if @inputtype = 5
 							begin
 								-- format for value using muti part mask
 								set @inputValue = convert(varchar(50), @Value)								
 								
     							exec @rcode = bspHQFormatMultiPart @inputValue, @format, @outputValue output
     							set @Value = RTRIM(@outputValue)
     						end
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
							
				if @RolledUp = 'Y'
				begin
					goto Next_Phase_Record
				end
 
				--Insert record
				execute sp_executesql @SQLString
				set @Complete = 1
			end
		end
		
		goto Next_Phase_Record
		

	Next_Phase_Record:
		select @FixedItem = '', @FixedDesc = '', @FixedPhase = '', @FixedNotes = '', @FixedMisc1 = '', @FixedMisc2 = '',
			@FixedMisc3 = '', @FixedCostType = '', @FixedUnits = '', @FixedUM = '', 
			@FixedUnitCost = '', @FixedECM = '', @FixedVendor = '', @FixedWCRetgPct = '', @FixedMaterial = '',
			@RolledUp = 'N'
		set @ValidCnt = @ValidCnt + 1
		goto Process_Loop

	Process_Loop_End:
		select @msg = 'MatlDetail records: ' + cast(@ValidCnt as varchar(6)) + '. '

end try

begin catch
	select @msg = 'Error: ' + error_message() + char(13) + char(10) + 
		'Upload failed, make sure PM Import Template Detail information is correct.' + char(13) + char(10) +
		'MaterialDetail - Record ' + cast(@ValidCnt as varchar(6)) + char(13) + char(10) +
		'vspPMImportMatlDetail line ' + cast(error_line() as varchar(3)), @rcode = 1
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

	if @rcode <> 0 select @msg = @msg + isnull(@msg,'')
	return @rcode




GO

GRANT EXECUTE ON  [dbo].[vspPMImportMatlDetail] TO [public]
GO
