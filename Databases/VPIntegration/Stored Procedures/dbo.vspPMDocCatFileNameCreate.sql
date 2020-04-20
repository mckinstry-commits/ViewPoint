SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************/
CREATE PROCEDURE [dbo].[vspPMDocCatFileNameCreate]
/***********************************************************
* CREATED By:	CHS 08/03/2009 - issue #24641
* MODIFIED By:
*				GF 05/06/2010 - issue #139393 PMSM revision missing ending quotation
*				GF 03/18/2011 - TK-02604 SUBCO
*				GF 03/28/2011 - TK-03298 COR
*				GF 04/05/2011 - TK-03643 PURCHASECO
*				JG 05/03/2011 - TK-04388 CCO
*
*
* USAGE:
* creates the file name that will be used in PM Documents and
* also for test purposes in PM Document Category Overrides.
*
* PASS:
* PMCo				PM Company
* DocCat			Document Category
* FileNameList		user defined file name info
* Project			PM Project
* DocType			PM document type
* Document			PM Document
* @rfq_pco			PM RFQ PCO
* @doc_rev			PM Document Revision number
* @doc_date			PM Document Date
* @doc_log			PM Document Log
* @vendorgroup		PM Vendor Group
* @firm				PM Firm
* @contact			PM Contact
* @status			PM Status Code
* @contract			PM Contract for Project
*
*
* 
* OUTPUT PARAMETERS
* @msg     Error message if invalid or the filename list is invalid
*
* RETURN VALUE
*   0 Success
*   1 fail
*****************************************************/ 
(@pmco bCompany = null, @doccat varchar(10) = null, @filenamelist nvarchar(max) = null,
 @project bProject = null, @doctype VARCHAR(30) = null, @document VARCHAR(30) = null, 
 @rfq_pco VARCHAR(30) = null, @doc_rev tinyint = null, @doc_date bDate = null,
 @doc_log int = null, @vendorgroup bGroup = null, @firm bigint = null, @contact bigint = null,
 @status varchar(6) = null, @contract bContract = null, @msg nvarchar(max) = null output)
as
set nocount on

declare @rcode int, @array_value varchar(255), @file_position int, @file_value varchar(30),
		@column_value varchar(100), @columns nvarchar(max),
		@start_position int, @end_position int, @column_results nvarchar(100),
		@sql nvarchar(max), @firm_where nvarchar(500), @contact_where nvarchar(500),
		@param_definition nvarchar(500), @column_result nvarchar(100),
		@opencursor int, @partstring nvarchar(100), @parttable nvarchar(100),
		@partcolumn nvarchar(100), @results nvarchar(100), @usestdfilename char(1),
		@pmcu_ovrfilename varchar(500), @apco dbo.bCompany, @status_where nvarchar(100),
		@contract_where nvarchar(100)

set @rcode = 0
	
---- initialize document categories if not exist
if not exists(select 1 from dbo.PMCU where DocCat = @doccat)
	begin
	declare @init_sql nvarchar(max)
	set @init_sql = 'exec dbo.vspPMCTInitialize'
	exec (@init_sql)
	end
	
---- first validate whole phase to JC Job Phase
select @usestdfilename = UseStdFileName, @pmcu_ovrfilename=OvrFileName
from dbo.PMCU with (nolock) where DocCat=@doccat
if @@rowcount = 0
	begin
	set @usestdfilename = 'Y'
	set @pmcu_ovrfilename = null
	end

if isnull(@pmcu_ovrfilename,'') = '' set @usestdfilename = 'Y'

---- if we do not have a @filenamelist then use @pmcu_ovrfilename
if isnull(@filenamelist,'') = ''
	begin
	set @filenamelist = @pmcu_ovrfilename
	end

set @columns = @filenamelist

---- when firm is null we are in test mode and need to retrieve values
---- needed to test the filename list override
if @firm is null
	begin
	select @apco=p.APCo, @vendorgroup = h.VendorGroup
	from dbo.PMCO p with (nolock) join dbo.HQCO h with (nolock) on h.HQCo = p.APCo
	where p.PMCo = @pmco
	if @@rowcount = 0 set @vendorgroup = null

	---- get first Firm from PMFM and First Contact for Firm from PMPM
	if @vendorgroup is not null
		begin
		if exists(select top 1 1 from dbo.PMPM with (nolock) where VendorGroup = @vendorgroup)
			begin
			select top 1 @firm = FirmNumber, @contact = ContactCode
			from dbo.PMPM with (nolock) where VendorGroup = @vendorgroup
			order by VendorGroup, FirmNumber, ContactCode
			end
		end
	end

---- when status is null need to retrieve values for the first status code
---- used when testing filename list override
---- status is used in the following categories:
---- OTHER, RFI, RFQ, SUBMIT, INSPECT, TEST, DRAWING
if @status is null
	begin
	select top 1 @status = Status
	from dbo.PMSC with (nolock)
	order by Status
	end

if @project is null
	begin
	select top 1 @project = Job
	from dbo.JCJM with (nolock)
	where JCJM.JCCo=@pmco and JCJM.JobStatus < 2
	order by JCJM.JCCo, JCJM.Job
	end
	
if @contract is null and @project is not null
	begin
	select top 1 @contract = Contract
	from dbo.JCJM with (nolock)
	where JCJM.JCCo=@pmco and JCJM.Job=@project
	order by JCJM.JCCo, JCJM.Job, JCJM.Contract
	end

---- build the where clause for firm and contact
---- will either used parameters of test defaults
set @firm_where = ' from dbo.PMFM where dbo.PMFM.VendorGroup = ' + convert(varchar(10),@vendorgroup) + ' and dbo.PMFM.FirmNumber = ' + convert(varchar(10),@firm)
set @contact_where = ' from dbo.PMPM where dbo.PMPM.VendorGroup = ' + convert(varchar(10),@vendorgroup) + ' and dbo.PMPM.FirmNumber = ' + convert(varchar(10), @firm) + ' and dbo.PMPM.ContactCode = ' + convert(varchar(10), @contact)
set @status_where = ' from dbo.PMSC where dbo.PMSC.Status = ' + char(39) + isnull(@status,'') + char(39)
set @contract_where = ' from dbo.JCCM where dbo.JCCM.JCCo = ' + convert(varchar(10),@pmco) + ' and dbo.JCCM.Contract = ' + char(39) + isnull(@contract,'') + char(39)

---- when document is null we are in test mode and need to retrieve values
---- needed to test the subject line override
if @document is null
	begin
	---- Other Documents - PMOD
	if @doccat = 'OTHER'
		begin
		if exists(select top 1 1 from dbo.PMOD with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @doctype = DocType, @document = Document
			from dbo.PMOD with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, DocType, Document
			end
		end

	---- Approved Change Orders - PMOH
	if @doccat = 'ACO'
		begin
		if exists(select top 1 1 from dbo.PMOH with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @document = ACO
			from dbo.PMOH with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, ACO
			end
		end

	---- Pending Change Orders - PMOP
	if @doccat = 'PCO'
		begin
		if exists(select top 1 1 from dbo.PMOP with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @doctype = PCOType, @document = PCO
			from dbo.PMOP with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, PCOType, PCO
			end
		end
	
	---- RFI = PMRI
	if @doccat = 'RFI'
		begin
		if exists(select top 1 1 from dbo.PMRI with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @doctype = RFIType, @document = RFI
			from dbo.PMRI with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, RFIType, RFI
			end
		end
	
	---- RFQ = PMRQ
	if @doccat = 'RFQ'
		begin
		if exists(select top 1 1 from dbo.PMRQ with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @doctype = PCOType, @rfq_pco=PCO, @document = RFQ
			from dbo.PMRQ with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, PCOType, PCO, RFQ
			end
		end
		
	---- SUBMIT = PMSM
	if @doccat = 'SUBMIT'
		begin
		if exists(select top 1 1 from dbo.PMSM with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @doctype = SubmittalType, @document = Submittal, @doc_rev = Rev
			from dbo.PMSM with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, SubmittalType, Submittal, Rev
			end
		end
		
	---- TRANSMIT = PMTM
	if @doccat = 'TRANSMIT'
		begin
		if exists(select top 1 1 from dbo.PMTM with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @document = Transmittal
			from dbo.PMTM with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, Transmittal
			end
		end
	
	---- SUB - SLHD
	if @doccat = 'SUB'
		begin
		if exists(select top 1 1 from dbo.SLHD with (nolock) where SLCo=@pmco and Job=@project)
			begin
			select top 1 @document = SL
			from dbo.SLHD with (nolock) where SLCo=@pmco and Job=@project
			order by SLCo, SL
			---- if no SL found for project, look by company
			if @@rowcount = 0
				begin
				select top 1 @document = SL
				from dbo.SLHD with (nolock) where SLCo=@pmco
				order by SLCo, SL
				end
			end
		end
		
	---- PURCHASE - POHD
	if @doccat = 'PURCHASE'
		begin
		if exists(select top 1 1 from dbo.POHD with (nolock) where POCo=@pmco and Job=@project)
			begin
			select top 1 @document = PO
			from dbo.POHD with (nolock) where POCo=@pmco and Job=@project
			order by POCo, PO
			---- if no PO found for project, look by company
			if @@rowcount = 0
				begin
				select top 1 @document = PO
				from dbo.POHD with (nolock) where POCo=@pmco
				order by POCo, PO
				end
			end
		end
		
	---- INSPECT = PMIL
	if @doccat = 'INSPECT'
		begin
		if exists(select top 1 1 from dbo.PMIL with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @doctype = InspectionType, @document = InspectionCode
			from dbo.PMIL with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, InspectionType, InspectionCode
			end
		end
	
	---- TEST = PMTL
	if @doccat = 'TEST'
		begin
		if exists(select top 1 1 from dbo.PMTL with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @doctype = TestType, @document = TestCode
			from dbo.PMTL with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, TestType, TestCode
			end
		end

	---- PUNCH = PMPU
	if @doccat = 'PUNCH'
		begin
		if exists(select top 1 1 from dbo.PMPU with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @document = PunchList
			from dbo.PMPU with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, PunchList
			end
		end
		
	---- DRAWING = PMDG
	if @doccat = 'DRAWING'
		begin
		if exists(select top 1 1 from dbo.PMDG with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @doctype = DrawingType, @document = Drawing
			from dbo.PMDG with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, DrawingType, Drawing
			end
		end
		
	---- DAILYLOG = PMDL
	if @doccat = 'DAILYLOG'
		begin
		if exists(select top 1 1 from dbo.PMDL with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @doc_date = LogDate, @doc_log = DailyLog
			from dbo.PMDL with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, LogDate, DailyLog
			end
		end
		
	---- MTG = PMMM
	if @doccat = 'MTG'
		begin
		if exists(select top 1 1 from dbo.PMMM with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @doctype = MeetingType, @doc_date = MeetingDate, @doc_log = Meeting, @doc_rev = MinutesType
			from dbo.PMMM with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, MeetingType, MeetingDate, Meeting, MinutesType
			end
		END
		
	---- ISSUE = PMIM TFS #793
	if @doccat = 'ISSUE'
		begin
		if exists(select top 1 1 from dbo.PMIM with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @doctype = Type, @document = CONVERT(VARCHAR(10), Issue)
			from dbo.PMIM with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, Type, Issue
			end
		END
		
	---- SUBCO = PMSubcontracCO TK-02604
	if @doccat = 'SUBCO'
		begin
		if exists(select top 1 1 from dbo.PMSubcontractCO with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @doctype = SL, @document = CONVERT(VARCHAR(10), SubCO)
			from dbo.PMSubcontractCO with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, SL, SubCO
			END
		END

	---- COR = PMChangeOrderRequest TK-03297
	if @doccat = 'COR'
		begin
		if exists(select top 1 1 from dbo.PMChangeOrderRequest with (nolock) where PMCo=@pmco and Contract=@contract)
			begin
			select top 1 @doc_date = Date, @document = CONVERT(VARCHAR(10), COR)
			from dbo.PMChangeOrderRequest with (nolock) where PMCo=@pmco and Contract=@contract
			order by PMCo, Contract, COR, Date
			END
		END
		
	---- COR = PMContractChangeOrder TK-04388
	if @doccat = 'CCO'
		begin
		if exists(select top 1 1 from dbo.PMContractChangeOrder with (nolock) where PMCo=@pmco and Contract=@contract)
			begin
			select top 1 @doc_date = Date, @document = CONVERT(VARCHAR(10), ID)
			from dbo.PMContractChangeOrder with (nolock) where PMCo=@pmco and Contract=@contract
			order by PMCo, Contract, ID, Date
			END
		END
		
	---- PURCHASECO = PMPOCO TK-03643
	if @doccat = 'PURCHASECO'
		begin
		if exists(select top 1 1 from dbo.PMPOCO with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @doctype = PO, @document = CONVERT(VARCHAR(10), POCONum)
			from dbo.PMPOCO with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, PO, POCONum
			END
		END
		
	---- add more later
	end


---- create table variable to store table, column, and output for each
---- column as defined in the filename List String that will be returned output
declare @filenametable table
(
	PartString		nvarchar(100) not null,
	PartTable		nvarchar(100) not null,
	PartColumn		nvarchar(100) not null,
	Results			nvarchar(100) null
)

select @columns = replace(@columns,'[','{')
select @columns = replace(@columns,']','}')

---- parse out the columns and check if in INFORMATION_SCHEMA.COLUMNS
---- Loop through the string searching for separtor characters
WHILE PATINDEX('%{%', @columns) <> 0 
    BEGIN
		
		select @start_position = 0, @end_position = 0, @array_value = null, @file_position = 0,
			   @file_value = null, @column_value = null
		select @start_position = PATINDEX('%{%', @columns)
		select @end_position = PATINDEX('%}%', @columns)
		
		select @array_value = substring(@columns, @start_position, @end_position - @start_position + 1)
		select @array_value = ltrim(rtrim(@array_value))
		select @array_value = replace(@array_value,'{','[')
		select @array_value = replace(@array_value,'}',']')
		
		---- now split the @array_value into file and column values
		select @file_position = PATINDEX('%.%', @array_value)
		if @file_position > 3
			begin
			select @file_value = substring(@array_value, 1, @file_position - 1)
			select @column_value = substring(@array_value, @file_position + 1, datalength(@array_value))
			
			select @file_value = replace(@file_value,'[','')
			select @column_value = replace(@column_value,']','')
			
			set @column_results = null
			---- validate to SCHEMA
			if exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @file_value and COLUMN_NAME = @column_value)
				begin
					if @file_value = 'PMSC'
						begin
						if @doccat in ('OTHER','RFI','RFQ','SUBMIT','INSPECT','TEST','DRAWING')
							begin
							set @sql = N'SELECT @value_out = convert(nvarchar(100), PMSC.' + @column_value + ')'
							set @sql = @sql + @status_where
							set @param_definition = N'@value_out nvarchar(100) output'
							
							execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
							set @column_results = isnull(@column_result,'');
							end
						end
					
					if @file_value = 'JCCM'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), JCCM.' + @column_value + ')'
						set @sql = @sql + @contract_where
						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end
					
					if @file_value = 'PMFM'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMFM.' + @column_value + ')'
						set @sql = @sql + @firm_where
						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end
						
					if @file_value = 'PMPM'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMPM.' + @column_value + ')'
						set @sql = @sql + @contact_where
						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end
						
					if @file_value = 'JCJM'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), JCJM.' + @column_value + ')'
						set @sql = @sql + ' from dbo.JCJM where JCJM.JCCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and JCJM.Job = ''' + @project + ' '''

						set @param_definition = N'@value_out nvarchar(100) output'

						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end
			
					if @file_value = 'PMDL'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMDL.' + @column_value + ')'
						set @sql = @sql + ' from dbo.PMDL where PMDL.PMCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and PMDL.Project = ''' + @project + ' '''
						set @sql = @sql + ' and PMDL.LogDate = ''' + convert(varchar(30), @doc_date, 101) + ' '''
						set @sql = @sql + ' and PMDL.DailyLog = '  + convert(varchar(10), @doc_log)						

						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end

					if @file_value = 'PMDG'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMDG.' + @column_value + ')'
						set @sql = @sql + ' from dbo.PMDG where PMDG.PMCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and PMDG.Project = ''' + @project + ' '''
						set @sql = @sql + ' and PMDG.DrawingType = ''' + @doctype + ' '''
						set @sql = @sql + ' and PMDG.Drawing = ''' + @document + ' '''

						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end

					if @file_value = 'PMOH'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMOH.' + @column_value + ')'
						set @sql = @sql + ' from dbo.PMOH where PMOH.PMCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and PMOH.Project = ''' + @project + ' '''
						set @sql = @sql + ' and PMOH.ACO = ''' + @document + ' '''

						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end

					if @file_value = 'PMIL'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMIL.' + @column_value + ')'
						set @sql = @sql + ' from dbo.PMIL where PMIL.PMCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and PMIL.Project = ''' + @project + ' '''
						set @sql = @sql + ' and PMIL.InspectionType = ''' + @doctype + ' '''
						set @sql = @sql + ' and PMIL.InspectionCode = ''' + @document + ' '''

						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end

					if @file_value = 'PMMM'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMMM.' + @column_value + ')'
						set @sql = @sql + ' from dbo.PMMM where PMMM.PMCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and PMMM.Project = ''' + @project + ' '''
						set @sql = @sql + ' and PMMM.MeetingType = ''' + @doctype + ' '''
						set @sql = @sql + ' and PMMM.MeetingDate = ''' + convert(varchar(30), @doc_date, 101) + ' '''
						set @sql = @sql + ' and PMDM.Meeting = '  + convert(varchar(10), @doc_log)	
						set @sql = @sql + ' and PMMM.MintuesType = ' + convert(varchar(10), @doc_rev)

						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end

					if @file_value = 'PMOD'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMOD.' + @column_value + ')'
						set @sql = @sql + ' from dbo.PMOD where PMOD.PMCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and PMOD.Project = ''' + @project + ' '''
						set @sql = @sql + ' and PMOD.DocType = ''' + @doctype + ' '''
						set @sql = @sql + ' and PMOD.Document = ''' + @document + ' '''

						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end

					if @file_value = 'PMOP'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMOP.' + @column_value + ')'
						set @sql = @sql + ' from dbo.PMOP where PMOP.PMCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and PMOP.Project = ''' + @project + ' '''
						set @sql = @sql + ' and PMOP.PCOType = ''' + @doctype + ' '''
						set @sql = @sql + ' and PMOP.PCO = ''' + @document + ' '''

						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end

					if @file_value = 'PMPU'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMPU.' + @column_value + ')'
						set @sql = @sql + ' from dbo.PMPU where PMPU.PMCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and PMPU.Project = ''' + @project + ' '''
						set @sql = @sql + ' and PMPU.PunchList = ''' + @document + ' '''

						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end

					if @file_value = 'POHD'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), POHD.' + @column_value + ')'
						set @sql = @sql + ' from dbo.POHD where POHD.JCCo = ' + convert(nvarchar(10),@pmco)
						----set @sql = @sql + ' and POHD.Job = ''' + @project + ' '''
						set @sql = @sql + ' and POHD.SL = ''' + @document + ' '''

						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end

					if @file_value = 'PMRI'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMRI.' + @column_value + ')'
						set @sql = @sql + ' from dbo.PMRI where PMRI.PMCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and PMRI.Project = ''' + @project + ' '''
						set @sql = @sql + ' and PMRI.RFIType = ''' + @doctype + ' '''
						set @sql = @sql + ' and PMRI.RFI = ''' + @document + ' '''

						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end

					if @file_value = 'PMRQ'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMRQ.' + @column_value + ')'
						set @sql = @sql + ' from dbo.PMRQ where PMRQ.PMCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and PMRQ.Project = ''' + @project + ' '''
						set @sql = @sql + ' and PMRQ.PCOType = ''' + @doctype + ' '''
						set @sql = @sql + ' and PMRQ.PCO = ''' + @rfq_pco + ' '''
						set @sql = @sql + ' and PMRQ.RFQ = ''' + @document + ' '''

						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end

					if @file_value = 'SLHD'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), SLHD.' + @column_value + ')'
						set @sql = @sql + ' from dbo.SLHD where SLHD.SLCo = ' + convert(nvarchar(10),@pmco)
						----set @sql = @sql + ' and SLHD.Job = ''' + @project + ' '''
						set @sql = @sql + ' and SLHD.SL = ''' + @document + ' '''

						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end

					if @file_value = 'PMSM'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMSM.' + @column_value + ')'
						set @sql = @sql + ' from dbo.PMSM where PMSM.PMCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and PMSM.Project = ''' + @project + ' '''
						set @sql = @sql + ' and PMSM.SubmittalType = ''' + @doctype + ' '''
						set @sql = @sql + ' and PMSM.Submittal = ''' + @document + ' '''
						----#139393
						set @sql = @sql + ' and PMSM.Rev = ''' + convert(nvarchar(10),@doc_rev) + ''''

						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end

					if @file_value = 'PMTL'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMTL.' + @column_value + ')'
						set @sql = @sql + ' from dbo.PMTL where PMTL.PMCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and PMTL.Project = ''' + @project + ' '''
						set @sql = @sql + ' and PMTL.TestType = ''' + @doctype + ' '''
						set @sql = @sql + ' and PMTL.TestCode = ''' + @document + ' '''

						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end

					if @file_value = 'PMTM'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMTM.' + @column_value + ')'
						set @sql = @sql + ' from dbo.PMTM where PMTM.PMCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and PMTM.Project = ''' + @project + ' '''
						set @sql = @sql + ' and PMTM.Transmittal = ''' + @document + ' '''

						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end
					
					----TFS #793
					if @file_value = 'PMIM'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMIM.' + @column_value + ')'
						set @sql = @sql + ' from dbo.PMIM where PMIM.PMCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and PMIM.Project = ''' + @project + ' '''
						set @sql = @sql + ' and PMIM.Issue = ' + CONVERT(VARCHAR(10),@document)
						
						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						END
					
					----TK-02604
					if @file_value = 'PMSubcontractCO'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMSubcontractCO.' + @column_value + ')'
						set @sql = @sql + ' from dbo.PMSubcontractCO where PMSubcontractCO.PMCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and PMSubcontractCO.Project = ''' + @project + ' '''
						SET @sql = @sql + ' and PMSubcontractCO.SL = ''' + @doctype + ' '''
						set @sql = @sql + ' and PMSubcontractCO.SubCO = ' + CONVERT(VARCHAR(10),@document)
						
						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						END
						
					----TK-03298
					if @file_value = 'PMChangeOrderRequest'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMChangeOrderRequest.' + @column_value + ')'
						set @sql = @sql + ' from dbo.PMChangeOrderRequest where PMChangeOrderRequest.PMCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and PMChangeOrderRequest.Contract = ''' + @contract + ' '''
						set @sql = @sql + ' and PMChangeOrderRequest.COR = ' + CONVERT(VARCHAR(10),@document)
						
						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						END
						
					----TK-04388
					if @file_value = 'PMContractChangeOrder'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMContractChangeOrder.' + @column_value + ')'
						set @sql = @sql + ' from dbo.PMContractChangeOrder where PMContractChangeOrder.PMCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and PMContractChangeOrder.Contract = ''' + @contract + ' '''
						set @sql = @sql + ' and PMContractChangeOrder.ID = ' + CONVERT(VARCHAR(10),@document)
						
						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						END
						
					----TK-03643
					if @file_value = 'PMPOCO'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMPOCO.' + @column_value + ')'
						set @sql = @sql + ' from dbo.PMPOCO where PMPOCO.PMCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and PMPOCO.Project = ''' + @project + ' '''
						SET @sql = @sql + ' and PMPOCO.PO = ''' + @doctype + ' '''
						set @sql = @sql + ' and PMPOCO.POCONum = ' + CONVERT(VARCHAR(10),@document)
						
						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						END
				end
			
			---- insert rows int @filenametable
			insert @filenametable(PartString, PartTable, PartColumn, Results)
			select @array_value, @file_value, @column_value, @column_results
			end
		
		select @columns = stuff(@columns, 1, @end_position, '')
		
	END


-- declare cursor on @filenametable and replace columns in @filenamelist with results
declare bcFileNameList cursor local fast_forward for select p.PartString, p.PartTable, p.PartColumn, p.Results
from @filenametable p
group by p.PartString, p.PartTable, p.PartColumn, p.Results

-- open cursor
open bcFileNameList
select @opencursor = 1

FileNameList_loop:
fetch next from bcFileNameList into @partstring, @parttable, @partcolumn, @results

if @@fetch_status <> 0 goto FileNameList_end


---- need to replace special characters that cannot be used in file naming
---- special charaters not allowed: '/\:;<>|?*&"
set @results = isnull(ltrim(rtrim(@results)),'')
set @results = replace(@results,char(39),'')
set @results = replace(@results,'\','')
set @results = replace(@results,'/','')
set @results = replace(@results,':','')
set @results = replace(@results,';','')
set @results = replace(@results,'<','')
set @results = replace(@results,'>','')
set @results = replace(@results,'|','')
set @results = replace(@results,'?','')
set @results = replace(@results,'*','')
set @results = replace(@results,'&','')
set @results = replace(@results,'"','')
set @results = replace(@results,'.','')

select @filenamelist = replace(@filenamelist, @partstring, isnull(@results,''))

select @filenamelist = replace(@filenamelist, '[SysDateNum]', CONVERT(VARCHAR(10), GETDATE(), 112))-- + datepart(dd, getdate()))

goto FileNameList_loop

FileNameList_end:
	if @opencursor = 1
		begin
		close bcFileNameList
		deallocate bcFileNameList
		set @opencursor = 0
		end


select @msg = @filenamelist


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDocCatFileNameCreate] TO [public]
GO
