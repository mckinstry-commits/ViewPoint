SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************/
CREATE PROCEDURE [dbo].[vspPMDocCatSubjectLineCreate]
/***********************************************************
* CREATED By:	CHS 08/03/2009 - issue #24641
* MODIFIED By:	GF 08/05/2009 - added more categories
*				GF 05/06/2010 - issue #139393 PMSM revision missing ending quotation
*				GF 09/03/2010 - issue #141031 change to use date only function
*				GF 10/18/2010 - TFS #793 for issue log
*				GF 03/18/2011 - TK-02604 SUBCO
*				GF 03/28/2011 - TK-03298 COR
*				GF 04/05/2011 - TK-03643 PURCHASECO
*
*
* USAGE:
* creates the subject line that will be used in PM Documents and
* also for test purposes in PM Document Category Overrides.
*
* PASS:
* PMCo				PM Company
* DocCat			Document Category
* SubjectLineList	user defined subject line info
* Project			PM Project
* DocType			PM document type
* Document			PM Document
*
*
* 
* OUTPUT PARAMETERS
* @msg     Error message if invalid or the subject line text
*
* RETURN VALUE
*   0 Success
*   1 fail
*****************************************************/ 
(@pmco bCompany = null, @doccat varchar(10) = null, @subjectlinelist nvarchar(max),
 @project bProject = null, @doctype VARCHAR(30) = null, @document VARCHAR(30) = null, 
 @rfq_pco VARCHAR(30) = null, @doc_rev tinyint = null, @doc_date bDate = null,
 @doc_log int = null, @Contract bContract = NULL, @msg nvarchar(max) = null output)
as
set nocount on

declare @rcode int, @array_value varchar(255), @file_position int, @file_value varchar(30),
		@column_value varchar(100), @columns nvarchar(max),
		@start_position int, @end_position int, @column_results nvarchar(100),
		@sql nvarchar(max), @contact_where nvarchar(500),
		@param_definition nvarchar(500), @column_result nvarchar(100),
		@opencursor int, @partstring nvarchar(100), @parttable nvarchar(100),
		@partcolumn nvarchar(100), @results nvarchar(100),
		----TFS #793 TK-03294
		@Issue INTEGER, @SubCO INTEGER, @COR INTEGER, @POCONum INTEGER

set @rcode = 0
set @columns = @subjectlinelist

----TFS #793
SET @Issue = NULL
IF @doccat = 'ISSUE' SET @Issue = CONVERT(INT, @document)
----TK-02607
SET @SubCO = NULL
IF @doccat = 'SUBCO' SET @SubCO = CONVERT(INT, @document)
----TK-03297
SET @COR = NULL
IF @doccat = 'COR' SET @COR = CONVERT(INT, @document)
----TK-03643
SET @POCONum = NULL
IF @doccat = 'PURCHASECO' SET @POCONum = CONVERT(INT, @document)

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
		if exists(select top 1 1 from dbo.POHD with (nolock) where POCo=@doc_rev and PO=@document)
			begin
			select top 1 @document = PO
			from dbo.POHD with (nolock) where POCo=@doc_rev and PO=@document
			order by POCo, PO
			---- if no PO found for project, look by company
			----if @@rowcount = 0
			----	begin
			----	select top 1 @document = PO
			----	from dbo.POHD with (nolock) where POCo=@doc_rev
			----	order by POCo, PO
			----	end
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
		
	---- ISSUE = PMIM TFS#793
	if @doccat = 'ISSUE'
		begin
		if exists(select top 1 1 from dbo.PMIM with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @doctype = Type, @document = CONVERT(VARCHAR(10), Issue)
			from dbo.PMIM with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, Type, Issue
			end
		end
	---- SUBCO = PMSubcontractCO TK-02604
	if @doccat = 'SUBCO'
		begin
		if exists(select top 1 1 from dbo.PMSubcontractCO with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @doctype = SL, @document = CONVERT(VARCHAR(10), SubCO), @SubCO=SubCO
			from dbo.PMSubcontractCO with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, SL, SubCO
			END
		END
	---- COR = PMChangeOrderRequest TK-03298
	if @doccat = 'COR'
		begin
		if exists(select top 1 1 from dbo.PMChangeOrderRequest with (nolock) where PMCo=@pmco and Contract=@Contract)
			begin
			select top 1 @doc_date = Date, @document = CONVERT(VARCHAR(10), COR), @COR=COR
			from dbo.PMChangeOrderRequest with (nolock) where PMCo=@pmco and Contract=@Contract
			order by PMCo, Contract, COR, Date
			END
		END
	---- PURCHASECO = PMPurchaseCO TK-03643
	if @doccat = 'PURCHASECO'
		begin
		if exists(select top 1 1 from dbo.PMPOCO with (nolock) where PMCo=@pmco and Project=@project)
			begin
			select top 1 @doctype = PO, @document = CONVERT(VARCHAR(10), POCONum), @POCONum=POCONum
			from dbo.PMPOCO with (nolock) where PMCo=@pmco and Project=@project
			order by PMCo, Project, PO, POCONum
			END
		END
	---- add more later
	end


---- create table variable to store table, column, and output for each
---- column as defined in the CC List String that will be returned output
declare @subjectlinetable table
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
						set @sql = @sql + ' from dbo.POHD where POHD.POCo = ' + convert(nvarchar(10),@doc_rev)
						set @sql = @sql + ' and POHD.PO = ''' + @document + ' '''

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
						END
						
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
						
					----TK-02607
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
						set @sql = @sql + ' and PMChangeOrderRequest.Contract = ''' + @Contract + ' '''
						set @sql = @sql + ' and PMChangeOrderRequest.COR = ' + CONVERT(VARCHAR(10),@document)

						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						END
						
					if @file_value = 'JCCM'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), JCCM.' + @column_value + ')'
						set @sql = @sql + ' from dbo.JCCM where JCCM.JCCo = ' + convert(nvarchar(10),@pmco)
						set @sql = @sql + ' and JCCM.Contract = ''' + @Contract + ' '''

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
			
			---- insert rows int @subjectlinetable
			insert @subjectlinetable(PartString, PartTable, PartColumn, Results)
			select @array_value, @file_value, @column_value, @column_results
			end
		
		select @columns = stuff(@columns, 1, @end_position, '')
		
	END


-- declare cursor on @subjectlinetable and replace columns in @subjectlinelist with results
declare bcCCList cursor local fast_forward for select p.PartString, p.PartTable, p.PartColumn, p.Results
from @subjectlinetable p
group by p.PartString, p.PartTable, p.PartColumn, p.Results

-- open cursor
open bcCCList
select @opencursor = 1

CCList_loop:
fetch next from bcCCList into @partstring, @parttable, @partcolumn, @results

if @@fetch_status <> 0 goto CCList_end

select @subjectlinelist = replace(@subjectlinelist, @partstring, isnull(ltrim(rtrim(@results)),''))

select @subjectlinelist = replace(@subjectlinelist, '[SysDateNum]', dbo.vfDateOnly())

goto CCList_loop

CCList_end:
	if @opencursor = 1
		begin
		close bcCCList
		deallocate bcCCList
		set @opencursor = 0
		end


select @msg = @subjectlinelist


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDocCatSubjectLineCreate] TO [public]
GO
