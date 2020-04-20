SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***************************************/
CREATE PROC [dbo].[vspMREntityUpdate]
/*************************************
* CREATED BY:	GP 11/10/2008
* Modified By:	GF 01/21/2008
*				GF 09/30/2009 - issue #135814 - delete frl_seg_code and frl_acct_code rows first, then re-added.
*				GF 03/10/2010 - issue #138600 - wrap gl account description and part description with isnulls.
*
*
*		
*		Input Parameters:
*			Entity - Company
*    
*		Output Parameters:
*			rcode - 0 Success
*					1 Failure
*			msg - Return Message
*
**************************************/
(@Entity int = null)

with execute as 'viewpointcs'
	
as
set nocount on

declare @rcode smallint, @msg varchar(255)
		
select @rcode = 0

---- must have entity
if @Entity is null
	begin
	goto vspexit
	end

declare @LenWithMask tinyint, @LenWithOutMask tinyint, @NaturalSeg tinyint,
		@L1 tinyint, @L2 tinyint, @L3 tinyint, @L4 tinyint, @L5 tinyint, @L6 tinyint,
		@S1 char(1), @S2 char(1), @S3 char(1), @S4 char(1), @S5 char(1), @S6 char(1),
		@SP1 tinyint, @SP2 tinyint, @SP3 tinyint, @SP4 tinyint, @SP5 tinyint, @SP6 tinyint

exec @rcode = dbo.vspFRXGetAcctMask @LenWithMask output, @LenWithOutMask output, @NaturalSeg output,
			@L1 output, @L2 output, @L3 output, @L4 output, @L5 output, @L6 output, @S1 output,
			@S2 output, @S3 output, @S4 output, @S5 output, @S6 output, @SP1 output, @SP2 Output,
			@SP3 output, @SP4 output, @SP5 output, @SP6 output

----------------------------- 
---- insert frl_seg_ctrl ----
-----------------------------
begin try

	if @L1 > 0
		begin
		insert frl_seg_ctrl(entity_num, seg_num, seg_desc, seg_start_pos, seg_length, last_updated)
		select @Entity, d.PartNo, d.Description, @SP1, @L1, current_timestamp
		from bGLPD d with (nolock)
		where d.GLCo = @Entity and d.PartNo = 1
		and not exists(select 1 from dbo.frl_seg_ctrl c with (nolock) where c.entity_num = d.GLCo
				and c.seg_num = d.PartNo)
		end

	if @L2 > 0
		begin
		insert frl_seg_ctrl(entity_num, seg_num, seg_desc, seg_start_pos, seg_length, last_updated)
		select @Entity, d.PartNo, d.Description, @SP2, @L2, current_timestamp
		from bGLPD d with (nolock)
		where d.GLCo = @Entity and d.PartNo = 2
		and not exists(select 1 from dbo.frl_seg_ctrl c with (nolock) where c.entity_num = d.GLCo
				and c.seg_num = d.PartNo)
		end

	if @L3 > 0
		begin
		insert frl_seg_ctrl(entity_num, seg_num, seg_desc, seg_start_pos, seg_length, last_updated)
		select @Entity, d.PartNo, d.Description, @SP3, @L3, current_timestamp
		from bGLPD d with (nolock)
		where d.GLCo = @Entity and d.PartNo = 3
		and not exists(select 1 from dbo.frl_seg_ctrl c with (nolock) where c.entity_num = d.GLCo
				and c.seg_num = d.PartNo)
		end

	if @L4 > 0
		begin
		insert frl_seg_ctrl(entity_num, seg_num, seg_desc, seg_start_pos, seg_length, last_updated)
		select @Entity, d.PartNo, d.Description, @SP4, @L4, current_timestamp
		from bGLPD d with (nolock)
		where d.GLCo = @Entity and d.PartNo = 4
		and not exists(select 1 from dbo.frl_seg_ctrl c with (nolock) where c.entity_num = d.GLCo
				and c.seg_num = d.PartNo)
		end

	if @L5 > 0
		begin
		insert frl_seg_ctrl(entity_num, seg_num, seg_desc, seg_start_pos, seg_length, last_updated)
		select @Entity, d.PartNo, d.Description, @SP5, @L5, current_timestamp
		from bGLPD d with (nolock)
		where d.GLCo = @Entity and d.PartNo = 5
		and not exists(select 1 from dbo.frl_seg_ctrl c with (nolock) where c.entity_num = d.GLCo
				and c.seg_num = d.PartNo)
		end

	if @L6 > 0
		begin
		insert frl_seg_ctrl(entity_num, seg_num, seg_desc, seg_start_pos, seg_length, last_updated)
		select @Entity, d.PartNo, d.Description, @SP6, @L6, current_timestamp
		from bGLPD d with (nolock)
		where d.GLCo = @Entity and d.PartNo = 6
		and not exists(select 1 from dbo.frl_seg_ctrl c with (nolock) where c.entity_num = d.GLCo
				and c.seg_num = d.PartNo)
		end

end try

begin catch
	
	--Log errors in vDDAL.
	insert vDDAL(DateTime, HostName, UserName, ErrorNumber, Description, SQLRetCode, UnhandledError, Informational,
		Assembly, Class, [Procedure], AssemblyVersion, StackTrace, FriendlyMessage, LineNumber, Event, Company,
		Object, CrystalErrorID, ErrorProcedure)
	values(current_timestamp, host_name(), suser_name(), error_number(), error_message(), null, 0, 1, 
		'VF', null, 'vspMREntityUpdate', null, null, 'Error getting MR segment control information.', 
		error_line(), null, @Entity, null, null, null)

end catch


-------------------------
-- Insert frl_seg_code --
-------------------------
begin try

	---- remove segment codes from frl_seg_code first.
	delete dbo.frl_seg_code where entity_num = @Entity

	insert frl_seg_code(entity_num, seg_num, seg_code, seg_code_desc, is_parent, email, last_updated)
	select distinct i.GLCo, i.PartNo, substring(i.Instance, 1, s.seg_length),
	---- #138600
			isnull(min(i.Description),'Missing Description in Viewpoint'), 0, null, current_timestamp
	---- #138600
	from bGLPI i with (nolock)
	join frl_seg_ctrl s with (nolock) on s.entity_num = i.GLCo and s.seg_num = i.PartNo
	where i.GLCo = @Entity
	and not exists(select top 1 1 from frl_seg_code c with (nolock) where c.entity_num = i.GLCo
		and c.seg_num = i.PartNo and c.seg_code = substring(i.Instance, 1, s.seg_length))
	group by i.GLCo, i.PartNo, substring(i.Instance, 1, s.seg_length)

end try

begin catch

	--Log errors in vDDAL.
	insert vDDAL(DateTime, HostName, UserName, ErrorNumber, Description, SQLRetCode, UnhandledError, Informational,
		Assembly, Class, [Procedure], AssemblyVersion, StackTrace, FriendlyMessage, LineNumber, Event, Company,
		Object, CrystalErrorID, ErrorProcedure)
	values(current_timestamp, host_name(), suser_name(), error_number(), error_message(), null, 0, 1, 
		'VF', null, 'vspMREntityUpdate', null, null, 'Error getting MR segment code information.', 
		error_line(), null, @Entity, null, null, null)

end catch


-----------------------------
-- Insert frl_account_code --
-----------------------------
begin try

	---- remove account codes from frl_acct_code first.
	delete dbo.frl_acct_code where entity_num = @Entity

	---- now add account codes in from GLAC
	insert frl_acct_code(entity_num, acct_code, seg01_code, seg02_code, seg03_code, seg04_code,
				seg05_code, seg06_code, acct_desc, acct_type, normal_bal_rule, acct_status,
				last_updated, rollup_level, attr01, attr02, attr03)
	select @Entity, substring(i.AllParts,1,@LenWithOutMask),
			case when @L1 = 0 then null else substring(i.Part1,1,@L1) end,
			case when @L2 = 0 then null else substring(i.Part2,1,@L2) end,
			case when @L3 = 0 then null else substring(i.Part3,1,@L3) end,
			case when @L4 = 0 then null else substring(i.Part4,1,@L4) end,
			case when @L5 = 0 then null else substring(i.Part5,1,@L5) end,
			case when @L6 = 0 then null else substring(i.Part6,1,@L6) end,
			---- #138600
			ISNULL(i.Description,'Missing Description in Viewpoint'), isnull(i.AcctType, 'M'),
			---- #138600
			case when i.NormBal = 'D' then 2 else 1 end, 
			case when i.Active = 'Y' then 0 else 1 end,
			current_timestamp, 0, null, null, nuLL
	from bGLAC i with (nolock) 
	where i.GLCo = @Entity and isnull(i.AllParts,'') <> ''
	and not exists(select top 1 1 from frl_acct_code c with (nolock) where c.entity_num = @Entity
	and rtrim(c.acct_code) = substring(i.AllParts,1, @LenWithOutMask))

end try

begin catch

	--Log errors in vDDAL.
	insert vDDAL(DateTime, HostName, UserName, ErrorNumber, Description, SQLRetCode, UnhandledError, Informational,
		Assembly, Class, [Procedure], AssemblyVersion, StackTrace, FriendlyMessage, LineNumber, Event, Company,
		Object, CrystalErrorID, ErrorProcedure)
	values(current_timestamp, host_name(), suser_name(), error_number(), error_message(), null, 0, 1, 
		'VF', null, 'vspMREntityUpdate', null, null, 'Error inserting account codes information.', 
		error_line(), null, @Entity, null, null, null)

end catch




vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMREntityUpdate] TO [public]
GO
