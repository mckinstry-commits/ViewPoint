SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMOPDesc    Script Date: 09/16/2005 ******/
CREATE   proc [dbo].[vspPMOPDesc]
/*************************************
 * Created By:	GF 09/16/2005
 * Modified by: GF 05/14/2011 TK-05205
 *				JG 05/19/2011 TK-05323 - Now grabs default status
 *				GP 06/27/2011 TK-06443  Added @SubCOExists and @POCOExists output params
 *
 * called from PMPCO to return project PCO key description
 * and PCO totals.
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * PCOType		PM PCO Type
 * PCO			PM PCO
 *
 * Returns:
 * BeginStatus			PMSC Beginning Status
 * Issue				PM PCO Issue
 * IntExt				PM PCO IntExt flag
 *
 *
 * Success returns:
 *	0 and Description from PMOP
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @pcotype bDocType, @pco bPCO,
 @BeginStatus bStatus = null output, @pcoissue bIssue = null output,
 @pcointext varchar(1) = 'E' output, @pcoexists bYN = 'N' output, 
 @pcodesc bDesc = null output, @rfqexists bYN = 'N' output,
 @SubCOExists bYN = 'N' output, @POCOExists bYN = 'N' output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @errmsg varchar(255)

select @rcode = 0, @msg = '', @retcode = 0, @pcoexists = 'N', @pcointext = 'I', @rfqexists = 'N'

---- get description from PMOP
if isnull(@pco,'') <> ''
	begin
	select @msg = Description, @pcoissue=Issue, @pcointext=IntExt, @pcodesc=Description
	from dbo.PMOP with (nolock) where PMCo=@pmco
	and Project=@project and PCOType=@pcotype and PCO=@pco
	if @@rowcount <> 0 select @pcoexists='Y'

	---- check if RFQ's exists for PCO
	if exists(select PMCo from PMRQ with (nolock) where PMCo=@pmco and Project=@project
					and PCOType=@pcotype and PCO=@pco)
		begin
		select @rfqexists = 'Y'
		end
	end

---- get beginning status for PCO TK-05205
SET @BeginStatus = NULL

-- --- PM Company Parameter Beg Status validation already requires Active for All forms = "Yes"
SELECT @BeginStatus = PMCO.BeginStatus FROM dbo.PMCO  WHERE PMCo=@pmco and BeginStatus is not null 

IF @BeginStatus = NULL
BEGIN	
	SELECT  @BeginStatus = min([Status]) FROM dbo.PMSC WHERE  DocCat = 'PCO' AND CodeType = 'B'

	IF @BeginStatus = NULL
	begin
		SELECT  @BeginStatus = min([Status]) FROM dbo.PMSC WHERE   CodeType = 'B' and ActiveAllYN='Y'
	end
END

--Check if item detail records contain SubCO or POCO
if exists (select top 1 1 from dbo.PMOL where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and SubCO is not null)
begin
	set @SubCOExists = 'Y'
end

if exists (select top 1 1 from dbo.PMOL where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and POCONum is not null)
begin
	set @POCOExists = 'Y'
end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMOPDesc] TO [public]
GO
