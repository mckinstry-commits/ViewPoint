SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL, vspVAGetDatatypeSecurityEntries
-- Create date: 4/25/2008
--	
-- Modified: 6/9/08: Added PMCo
--										 3/1/09: Added joins to DDBICompanies
--										 7/29/09: Added EMCo
--											5/5/10: Added joins to the Qualifier column
-- Description:	Gets the key ID's for security entries in DDDS
-- =============================================
CREATE PROCEDURE [dbo].[vspVAGetDatatypeSecurityEntries] 
	-- Add the parameters for the stored procedure here
	(@datatype VARCHAR(30)) 
	
AS
BEGIN


   
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    if @datatype = 'bJob'
    begin
	
		select j.KeyID, d.SecurityGroup, Name from JCJM j
		join DDDS d on d.Instance = j.Job and d.Qualifier = j.JCCo
		join DDSG g on g.SecurityGroup = d.SecurityGroup
		join DDBICompanies b on b.Co = d.Qualifier
		where Datatype = @datatype
		return
		
	end
	
	if @datatype = 'bContract'
	
	begin
		Select KeyID, d.SecurityGroup, Name from JCCM c
		join DDDS d on d.Instance = c.Contract and d.Qualifier = c.JCCo
		join DDSG g on g.SecurityGroup = d.SecurityGroup
		join DDBICompanies b on b.Co = d.Qualifier
		where Datatype = @datatype
		return
	end
	
	if @datatype = 'bJCCo'
	begin
		Select Distinct(KeyID), d.SecurityGroup, Name, Datatype from JCCO c
		join DDDS d on d.Instance = c.JCCo and d.Qualifier = c.JCCo
		join DDSG g on g.SecurityGroup = d.SecurityGroup
		join DDBICompanies b on b.Co = d.Qualifier
		where Datatype = @datatype
		return
	end
		
	if @datatype = 'bPMCo'
	begin
		Select Distinct(KeyID), d.SecurityGroup, Name, Datatype from PMCO c
		join DDDS d on d.Instance = c.PMCo and d.Qualifier = c.PMCo
		join DDSG g on g.SecurityGroup = d.SecurityGroup
		join DDBICompanies b on b.Co = d.Qualifier
		where Datatype = @datatype
	return
	end
	
		if @datatype = 'bEMCo'
	begin
		Select Distinct(KeyID), d.SecurityGroup, Name, Datatype from EMCO c
		join DDDS d on d.Instance = c.EMCo and d.Qualifier = c.EMCo
		join DDSG g on g.SecurityGroup = d.SecurityGroup
		join DDBICompanies b on b.Co = d.Qualifier
		where Datatype = @datatype
		return
	end
	
			if @datatype = 'bHRCo'
	begin
		Select Distinct(KeyID), d.SecurityGroup, Name, Datatype from HRCO c
		join DDDS d on d.Instance = c.HRCo and d.Qualifier = c.HRCo
		join DDSG g on g.SecurityGroup = d.SecurityGroup
		join DDBICompanies b on b.Co = d.Qualifier
		where Datatype = @datatype
		return
	end
	
END

GO
GRANT EXECUTE ON  [dbo].[vspVAGetDatatypeSecurityEntries] TO [public]
GO
